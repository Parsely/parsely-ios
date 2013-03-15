//
// ParselyTracker.h
// ParselyiOS
//
// Copyright 2013 Parse.ly
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "ParselyTracker.h"
#import "Reachability.h"

#import <CommonCrypto/CommonDigest.h>

@implementation ParselyTracker

@synthesize uuidKey, queueSizeLimit, storageKey, shouldFlushOnBackground, flushInterval;

ParselyTracker *instance;

-(void)track:(NSString *)url{
    // add an event to the queue
    
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    
    PLog(@"Track called for test url");
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:[NSString stringWithFormat:@"%lli", 1000000000000 + arc4random() % 9999999999999] forKey:@"rand"];
	[params setObject:self.apiKey forKey:@"idsite"];
    [params setObject:[self urlEncodeString:url] forKey:@"url"];
    [params setObject:@"mobile" forKey:@"urlref"];
    [params setObject:[self urlEncodeString:
                       [NSString stringWithFormat:@"{\"ts\": %f, \"parsely_uuid\": %@}", timestamp, [self getUuid]]]
               forKey:@"data"];
    
    [eventQueue addObject:params];
    [self persistQueue];
    
    if([self queueSize] >= [self queueSizeLimit] + 1){
        PLog(@"Queue size exceeded, expelling event to persistent memory");
        [eventQueue removeObjectAtIndex:0];
    }
    
    if(_timer == nil){
        [self setFlushTimer];
        PLog(@"Flush timer set to %d", self.flushInterval);
    }
}

-(void)flush{
    // remove all events from the queue and send pixel requests
    
    PLog(@"%d events in queue, %d stored events", [eventQueue count], [[self getStoredQueue] count]);
    if([eventQueue count] == 0 && [[self getStoredQueue] count] == 0){
        PLog(@"Event queue empty, flush timer cleared.");
        [self stopFlushTimer];
        return;
    }
    
    if(![self isReachable]){
        PLog(@"Server unreachable. Not flushing.");
        return;
    }
    
    // prepare to flush by merging the memory queue with the stored queue
    NSArray *storedQueue = [self getStoredQueue];
    NSMutableSet *newQueue = [NSMutableSet setWithArray:eventQueue];
    if(storedQueue){
        [newQueue addObjectsFromArray:storedQueue];
    }
    
    PLog(@"Flushing queue...");
    for(NSMutableDictionary *event in newQueue){
        [self flushEvent:event];
    }
    [eventQueue removeAllObjects];
    [self purgeStoredQueue];
    PLog(@"Done");
}

-(void)flushEvent:(NSDictionary *)event{
    PLog(@"Flushing event %@", event);
    NSString *url = [NSString stringWithFormat:@"%@%%3Frand=%@&idsite=%@&url=%@&urlref=%@&data=%@", self.rootUrl,
                     [event objectForKey:@"rand"],
                     [event objectForKey:@"idsite"],
                     [event objectForKey:@"url"],
                     [event objectForKey:@"urlref"],
                     [event objectForKey:@"data"]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10];
    [request setHTTPMethod:@"GET"];
    
    NSError *requestError;
    NSURLResponse *urlResponse = nil;
    
    [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
}

-(void)persistQueue{
    // save the entire event queue to persistent storage
    
    PLog(@"Persisting event queue");
    // get the previously stored queue, add current queue and re-store
    NSMutableSet *storedQueue = [NSMutableSet setWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:self.storageKey]];
    [storedQueue addObjectsFromArray:eventQueue];
    
    [[NSUserDefaults standardUserDefaults] setObject:[storedQueue allObjects] forKey:self.storageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)purgeStoredQueue{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:self.storageKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSArray *)getStoredQueue{
    return [[NSUserDefaults standardUserDefaults] objectForKey:self.storageKey];
}

-(NSString *)getUuid{
    NSString *uuid = [[NSUserDefaults standardUserDefaults] objectForKey:self.uuidKey];
    if(uuid == nil){
        uuid = [self generateUuid];
    }
    return uuid;
}

-(NSString *)generateUuid{
    // same method used by OpenUDID
    NSString *_uuid = nil;
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef cfstring = CFUUIDCreateString(kCFAllocatorDefault, uuid);
    const char *cStr = CFStringGetCStringPtr(cfstring,CFStringGetFastestEncoding(cfstring));
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result );
    CFRelease(uuid);
    
    _uuid = [NSString stringWithFormat:
                 @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%08x",
                 result[0], result[1], result[2], result[3],
                 result[4], result[5], result[6], result[7],
                 result[8], result[9], result[10], result[11],
                 result[12], result[13], result[14], result[15],
                 (NSUInteger)(arc4random() % NSUIntegerMax)];
    
    [[NSUserDefaults standardUserDefaults] setObject:_uuid forKey:self.uuidKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    PLog(@"Generated UDID %@", _uuid);
    
    return _uuid;
}

-(void)start{
    [self setFlushTimer];
}

-(void)stop{
    [self stopFlushTimer];
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
        PLog(@"Flush timer set");
    }
}

-(void)stopFlushTimer{
    @synchronized(self){
        if(_timer){
            [_timer invalidate];
        }
        _timer = nil;
        PLog(@"Flush timer cleared");
    }
}

// singleton boilerplate

+(ParselyTracker *)sharedInstance{
    if(instance == nil){
        PLog(@"Warning: sharedInstance called before sharedInstanceWithApiKey:");
    }
    return instance;
}

+(ParselyTracker *)sharedInstanceWithApiKey:(NSString *)apikey{
    @synchronized(self) {
        if (instance == nil) {
#ifdef PARSELY_DEBUG
            instance = [[ParselyTracker alloc] initWithApiKey:apikey andFlushInterval:5];
#else
            instance = [[ParselyTracker alloc] initWithApiKey:apikey andFlushInterval:60];
#endif
        }
        return instance;
    }
}

-(id)initWithApiKey:(NSString *)apikey andFlushInterval:(NSInteger)flushint{
    @synchronized(self){
        if(self=[super init]){
            self.apiKey = apikey;
            eventQueue = [NSMutableArray array];
            self.storageKey = @"parsely-events";
            self.uuidKey = @"parsely-uuid";
            self.shouldFlushOnBackground = YES;
            self.flushInterval = flushint;
            _rootUrl = @"http://pixel.parsely.com/plogger/";
            
            if([self getStoredQueue]){
                [self setFlushTimer];
            }
#ifdef PARSELY_DEBUG
            __debug_wifioff = NO;
            self.queueSizeLimit = 5;
#else
            self.queueSizeLimit = 50;
#endif
            [self addApplicationObservers];
        }
        return self;
    }
}

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

-(BOOL)isReachable{
    return ([[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] == ReachableViaWiFi
    || [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == ReachableViaWWAN)
#ifdef PARSELY_DEBUG
    && !__debug_wifioff
#endif
    ;
}

-(NSInteger)queueSize{
    return [eventQueue count];
}

-(NSInteger)storedEventsCount{
    return [[self getStoredQueue] count];
}

-(BOOL)flushTimerIsActive{
    return _timer != nil;
}

#ifdef PARSELY_DEBUG
-(void)__debugWifiOff{
    __debug_wifioff = YES;
}

-(void)__debugWifiOn{
    __debug_wifioff = NO;
}
#endif

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
                    [application endBackgroundTask: background_task];
                    background_task = UIBackgroundTaskInvalid;
                }];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self flush];
                    [self stopFlushTimer];
                    [application endBackgroundTask: background_task];
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