/*
    ParselyTracker.m
    ParselyiOS

    Copyright 2016 Parse.ly

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

#import "ParselyTracker.h"
#import "Reachability.h"

#import <CommonCrypto/CommonDigest.h>

#define DEFAULT_FLUSH_INTERVAL 60
#define DEFAULT_URLREF @"parsely_mobile_sdk"

@implementation ParselyTracker

ParselyTracker *instance;  /*!< Singleton instance */

-(void)trackURL:(NSString *)url{
    [self track:url withIDType:kUrl];
}

-(void)trackPostID:(NSString *)postid{
    [self track:postid withIDType:kPostId];
}

-(void)track:(NSString *)identifier withIDType:(kIdType)idtype{
    PLog(@"Track called for %@", identifier);

    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:identifier forKey:[idNameMap objectForKey:[NSNumber numberWithInt:idtype]]];
    [params setObject:[NSNumber numberWithDouble:timestamp] forKey:@"ts"];
    [params setObject:deviceInfo forKey:@"data"];
    [eventQueue addObject:params];

    PLog(@"%@", params);

    if([self queueSize] >= queueSizeLimit + 1){
        PLog(@"Queue size exceeded, expelling oldest event to persistent memory");
        [self persistQueue];
        [eventQueue removeObjectAtIndex:0];
    }

    if([self storedEventsCount] > storageSizeLimit){
        [self expelStoredEvent];
    }

    if(_timer == nil){
        [self setFlushTimer];
        PLog(@"Flush timer set to %d", self.flushInterval);
    }
}

-(void)flush{
    PLog(@"%d events in queue, %d stored events", [eventQueue count], [[self getStoredQueue] count]);

    if([eventQueue count] == 0 && [[self getStoredQueue] count] == 0){
        [self stopFlushTimer];
        return;
    }

    if(![self isReachable]){
        PLog(@"Network unreachable. Not flushing.");
        return;
    }

    // prepare to flush by merging the memory queue with the stored queue
    // NOTE: typically this merge will be fully redundant, except in the case where the app terminated with items still in the queue
    NSArray *storedQueue = [self getStoredQueue];
    NSMutableSet *newQueue = [NSMutableSet setWithArray:eventQueue];
    if(storedQueue != nil){
        [newQueue addObjectsFromArray:storedQueue];
    }

    PLog(@"Flushing queue...");
    [self sendBatchRequest:newQueue];
    PLog(@"done");

    // now that we've sent the requests, vaporize them
    [eventQueue removeAllObjects];
    [self purgeStoredQueue];

    if([eventQueue count] == 0 && [[self getStoredQueue] count] == 0){
        PLog(@"Event queue empty, flush timer cleared.");
        [self stopFlushTimer];
    }
}

-(void)sendBatchRequest:(NSSet *)queue{
    // create an efficiently packed object for the GET parameters
    NSMutableDictionary *batchDict = [NSMutableDictionary dictionary];
    NSArray *queueArray = [queue allObjects];

    // the object contains only one copy of the queue's invariant data
    [batchDict setObject:[[queueArray objectAtIndex:0] objectForKey:@"data"] forKey:@"data"];
    NSMutableArray *events = [NSMutableArray array];

    // and a list of url/timestamp dictionaries
    for(NSDictionary *event in queueArray){
        NSString *field, *value;
        if([event objectForKey:@"url"] != nil){
            field = @"url";
            value = [event objectForKey:@"url"];
        } else if([event objectForKey:@"postid"] != nil){
            field = @"postid";
            value = [event objectForKey:@"postid"];
        }
        [events addObject:[[NSDictionary alloc] initWithObjectsAndKeys:
                                                   value, field,
                                                   [event objectForKey:@"ts"], @"ts",
                                                   nil]];
    }
    [batchDict setObject:events forKey:@"events"];

    PLog(@"%@", [self JSONWithDictionary:batchDict]);

    [self apiConnectionWithURL:[NSString stringWithFormat:@"%@mobileproxy", rootUrl] andData:[self JSONWithDictionary:batchDict]];
    PLog(@"Requested %@mobileproxy", rootUrl);
}

-(void)persistQueue{
    PLog(@"Persisting event queue");

    // get the previously stored queue, merge current queue and re-store
    NSMutableSet *storedQueue = [NSMutableSet setWithArray:[self getStoredQueue]];
    [storedQueue addObjectsFromArray:eventQueue];

    [[NSUserDefaults standardUserDefaults] setObject:[storedQueue allObjects] forKey:storageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)purgeStoredQueue{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:storageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)expelStoredEvent{
    NSArray *storedQueue = [self getStoredQueue];
    NSMutableArray *mutableCopy = [NSMutableArray arrayWithArray:storedQueue];
    [mutableCopy removeObjectAtIndex:0];
    [[NSUserDefaults standardUserDefaults] setObject:(NSArray *)mutableCopy forKey:storageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSArray *)getStoredQueue{
    return [[NSUserDefaults standardUserDefaults] objectForKey:storageKey];
}

-(NSString *)getSiteUuid{
    NSString *uuid = [[NSUserDefaults standardUserDefaults] objectForKey:uuidKey];
    if(uuid == nil){
        uuid = [self generateSiteUuid];
    }
    return uuid;
}

-(void)setFlushTimer{
    @synchronized(self){
        if([self flushTimerIsActive]){
            [self stopFlushTimer];
        }
        _timer = [NSTimer scheduledTimerWithTimeInterval:self.flushInterval
                                                  target:self
                                                selector:@selector(flush)
                                                userInfo:nil
                                                 repeats:YES];
    }
}

-(void)stopFlushTimer{
    @synchronized(self){
        if(_timer){
            [_timer invalidate];
        }
        _timer = nil;
    }
}

-(NSMutableDictionary *)collectDeviceInfo{
    NSMutableDictionary *dInfo = [NSMutableDictionary dictionary];

    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (bundleName == nil) {
        bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    }
    [dInfo setObject:(bundleName ? bundleName : @"") forKey:@"appname"];

    [dInfo setObject:[self getSiteUuid] forKey:@"parsely_site_uuid"];
    [dInfo setObject:self.apiKey forKey:@"idsite"];

    [dInfo setObject:@"Apple" forKey:@"manufacturer"];
    [dInfo setObject:self.urlref forKey:@"urlref"];
    [dInfo setObject:[[UIDevice currentDevice] systemName] forKey:@"os"];
    [dInfo setObject:[[UIDevice currentDevice] systemVersion] forKey:@"os_version"];

    return dInfo;
}

+(ParselyTracker *)sharedInstance{
    @synchronized(self){
        if(instance == nil){
            PLog(@"Warning: sharedInstance called before sharedInstanceWithApiKey:");
            return nil;
        }
        return instance;
    }
}

+(ParselyTracker *)sharedInstanceWithApiKey:(NSString *)apikey andFlushInterval:(NSInteger)flushint andUrlref:(NSString *)urlref_ {
    @synchronized(self) {
        if (instance == nil) {
            instance = [[ParselyTracker alloc] initWithApiKey:apikey andFlushInterval:flushint andUrlref:urlref_];
        }
        return instance;
    }
}

+(ParselyTracker *)sharedInstanceWithApiKey:(NSString *)apikey andFlushInterval:(NSInteger)flushint {
    @synchronized(self) {
        if (instance == nil) {
            instance = [[ParselyTracker alloc] initWithApiKey:apikey andFlushInterval:flushint andUrlref:DEFAULT_URLREF];
        }
        return instance;
    }
}

+(ParselyTracker *)sharedInstanceWithApiKey:(NSString *)apikey{
    @synchronized(self) {
        if (instance == nil) {
            instance = [[ParselyTracker alloc] initWithApiKey:apikey andFlushInterval:DEFAULT_FLUSH_INTERVAL andUrlref:DEFAULT_URLREF];
        }
        return instance;
    }
}

-(id)initWithApiKey:(NSString *)apikey andFlushInterval:(NSInteger)flushint andUrlref:(NSString *)urlref_ {
    @synchronized(self){
        if(self=[super init]){
            self.apiKey = apikey;
            eventQueue = [NSMutableArray array];
            storageKey = @"parsely-events";
            uuidKey = @"parsely-site-uuid";
            self.shouldFlushOnBackground = YES;
            self.urlref = urlref_;
            self.flushInterval = flushint;
            deviceInfo = [self collectDeviceInfo];
            rootUrl = @"https://srv.pixel.parsely.com/";

            idNameMap = @{[NSNumber numberWithInt:kUrl]: @"url", [NSNumber numberWithInt:kPostId]: @"postid"};

            if([self getStoredQueue]){
                [self setFlushTimer];
            }
            queueSizeLimit = 50;
            storageSizeLimit = 100;
            [self addApplicationObservers];
        }
        return self;
    }
}

// singleton boilerplate

+(id)allocWithZone:(NSZone *)zone{
    @synchronized(self){
        if (instance == nil){
            instance = [super allocWithZone:zone];
            return instance;
        }
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone{
    return self;
}

// accessors

-(NSInteger)queueSize{
    return [eventQueue count];
}

-(NSInteger)storedEventsCount{
    return [[self getStoredQueue] count];
}

-(BOOL)flushTimerIsActive{
    return _timer != nil && [_timer isValid];
}

// helpers

-(NSString *)urlEncodeString:(NSString *)string{
    NSString *retval = (NSString *)CFBridgingRelease(
                                   CFURLCreateStringByAddingPercentEscapes(
                                        NULL,
                                        (__bridge CFStringRef) string,
                                        NULL,
                                        CFSTR("!*'();:@&=+$,/?%#[]"),
                                        kCFStringEncodingUTF8
                                    ));
    return retval;
}

-(NSString *)JSONWithDictionary:(NSDictionary *)info{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:info
                                                       options:0
                                                         error:nil];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

-(void)apiConnectionWithURL:(NSString *)endpoint{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:endpoint]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10];
    [request setHTTPMethod:@"GET"];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *error){}];
}

-(void)apiConnectionWithURL:(NSString *)endpoint andData:(NSString *)data{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:endpoint]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10];
    NSString *requestString = [NSString stringWithFormat:@"rqs=%@", [self urlEncodeString:data]];
    NSMutableData *postData = [NSMutableData data];
    [postData appendData:[requestString dataUsingEncoding:NSUTF8StringEncoding]];

    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"%d", (int)[postData length]] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *error){}];
}

-(NSString *)generateSiteUuid{
    // same method used by OpenUDID
    NSString *_uuid = nil;
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef cfstring = CFUUIDCreateString(kCFAllocatorDefault, uuid);
    const char *cStr = CFStringGetCStringPtr(cfstring,CFStringGetFastestEncoding(cfstring));
    unsigned char result[16];
    CC_MD5( cStr, (int)strlen(cStr), result );
    CFRelease(uuid);

    _uuid = [NSString stringWithFormat:
             @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%08x",
             result[0], result[1], result[2], result[3],
             result[4], result[5], result[6], result[7],
             result[8], result[9], result[10], result[11],
             result[12], result[13], result[14], result[15],
             (int)(NSUInteger)(arc4random() % NSUIntegerMax)];
    
    [[NSUserDefaults standardUserDefaults] setObject:_uuid forKey:uuidKey];
    [[NSUserDefaults standardUserDefaults] synchronize];

    PLog(@"Generated UUID %@", _uuid);

    return _uuid;
}

-(BOOL)isReachable{
    return ([[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] == ReachableViaWiFi
            || [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == ReachableViaWWAN);
}

// connection delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    PLog(@"Pixel request successful");
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    PLog(@"Pixel request error: %@", error);
}

// notification observers

-(void)addApplicationObservers{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminate:)
                               name:UIApplicationWillTerminateNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 40000
    if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)] && &UIBackgroundTaskInvalid) {
        if (&UIApplicationDidEnterBackgroundNotification) {
            [notificationCenter addObserver:self
                                   selector:@selector(applicationDidEnterBackground:)
                                       name:UIApplicationDidEnterBackgroundNotification
                                     object:nil];
        }
        if (&UIApplicationWillEnterForegroundNotification) {
            [notificationCenter addObserver:self
                                   selector:@selector(applicationWillEnterForeground:)
                                       name:UIApplicationWillEnterForegroundNotification object:nil];
        }
    }
#endif
}

-(void)applicationWillTerminate:(NSNotification *)notification{
    PLog(@"Application terminated");
    [self persistQueue];
}

-(void)applicationWillResignActive:(NSNotification *)notification{
    PLog(@"Application resigned active");
    @synchronized(self){
        [self stopFlushTimer];
    }
}

-(void)applicationDidBecomeActive:(NSNotification *)notification{
    PLog(@"Application became active");
    @synchronized(self){
        [self setFlushTimer];
    }
}

-(void)applicationDidEnterBackground:(NSNotification *)notification{
    PLog(@"Application entered background");
    @synchronized(self){
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 40000
        if ([self shouldFlushOnBackground] && [[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) {
            if ([[UIDevice currentDevice] isMultitaskingSupported]) {
                UIApplication *application = [UIApplication sharedApplication];
                __block UIBackgroundTaskIdentifier background_task;
                background_task = [application beginBackgroundTaskWithExpirationHandler: ^{
                    [application endBackgroundTask:background_task];
                    background_task = UIBackgroundTaskInvalid;
                }];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    PLog(@"Running background task to flush queue");
                    [self flush];
                    [application endBackgroundTask:background_task];
                    background_task = UIBackgroundTaskInvalid;
                });
            }
        }
#endif
    }
}

-(void)applicationWillEnterForeground:(NSNotification *)notification{
    PLog(@"Application entered foreground");
    @synchronized(self){
        [self setFlushTimer];
    }
}

@end
