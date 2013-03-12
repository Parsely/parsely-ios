#import "ParselyTracker.h"
#import "Reachability.h"

@implementation ParselyTracker

ParselyTracker *instance;

-(void)track:(NSString *)url{
    // add an event to the queue
    
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    
    PLog(@"Track called for test url");
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:[NSString stringWithFormat:@"%lli", 1000000000000 + arc4random() % 9999999999999] forKey:@"rand"];
	[params setObject:[self apikey] forKey:@"idsite"];
    [params setObject:[self urlEncodeString:url] forKey:@"url"];
    [params setObject:@"mobile" forKey:@"urlref"];
    [params setObject:[self urlEncodeString:[NSString stringWithFormat:@"{\"ts\": %f}", timestamp]] forKey:@"data"];
    
    [eventQueue addObject:params];
    
    if(_timer == nil){
        [self setFlushTimer];
        PLog(@"Flush timer set to %d", [self flushInterval]);
    }
}

-(void)flush{
    // remove all events from the queue and send pixel requests
    
    PLog(@"%d events in queue, %d stored events", [eventQueue count], [[self getStoredQueue] count]);
    if([eventQueue count] == 0){
        PLog(@"Event queue empty, flush timer cleared.");
        [self stopFlushTimer];
        return;
    }
    
    if(![self isReachable]){
        PLog(@"Wifi network unreachable. Not flushing.");
        [self persistQueue];
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
        PLog(@"Flushing event %@", event);
        NSString *url = [NSString stringWithFormat:@"%@%%3Frand=%@&idsite=%@&url=%@&urlref=%@&data=%@", [self rootUrl],
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
    [eventQueue removeAllObjects];
    [self purgeStoredQueue];
    PLog(@"Done");
}

-(void)persistQueue{
    // save the entire event queue to persistent storage
    
    PLog(@"Persisting event queue");
    // get the previously stored queue, add current queue and re-store
    NSMutableSet *storedQueue = [NSMutableSet setWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:[self storageKey]]];
    [storedQueue addObjectsFromArray:eventQueue];
    
    [[NSUserDefaults standardUserDefaults] setObject:[storedQueue allObjects] forKey:[self storageKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)purgeStoredQueue{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:[self storageKey]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(NSArray *)getStoredQueue{
    return [[NSUserDefaults standardUserDefaults] objectForKey:[self storageKey]];
}

-(void)setFlushTimer{
    @synchronized(self){
        [self stopFlushTimer];
        _timer = [NSTimer scheduledTimerWithTimeInterval:[self flushInterval]
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
#ifdef DEBUG
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
            _apikey = apikey;
            eventQueue = [NSMutableArray array];
            _storageKey = @"parsely-events";
            _flushInterval = flushint;
            __debug_wifioff = NO;
            _rootUrl = @"http://localhost:8000/plogger/";
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

-(void)setApikey:(NSString *)key{
    _apikey = key;
}

-(NSString *)apikey{
    return _apikey;
}

-(BOOL)isReachable{
    return [[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] == ReachableViaWiFi
#ifdef DEBUG
    && !__debug_wifioff
#endif
    ;
}

-(NSString *)storageKey{
    return _storageKey;
}

-(NSString *)rootUrl{
    return _rootUrl;
}

-(NSInteger)flushInterval{
    return _flushInterval;
}

-(NSInteger)queueSize{
    return [eventQueue count];
}

#ifdef DEBUG
-(void)__debugWifiOff{
    __debug_wifioff = YES;
}

-(void)__debugWifiOn{
    __debug_wifioff = NO;
}
#endif

-(BOOL)flushTimerIsActive{
    return _timer != nil;
}

// helpers

-(NSString *)urlEncodeString:(NSString *)string{
    NSString *retval = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                             NULL,
                                                                                             (__bridge CFStringRef) string,
                                                                                             NULL,
                                                                                             CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                                             kCFStringEncodingUTF8));
    return retval;
}

@end