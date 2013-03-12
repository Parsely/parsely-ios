//
//  ParselyTracker.m
//  PixelTester
//
//  Created by Emmett Butler on 3/8/13.
//  Copyright (c) 2013 Emmett Butler. All rights reserved.
//

#import "ParselyTracker.h"
#import "Reachability.h"

@implementation ParselyTracker

ParselyTracker *instance;

-(void)track:(NSString *)url{
    // add an event to the queue
    
    PLog(@"Track called for test url");
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:[NSString stringWithFormat:@"%lli", 1000000000000 + arc4random() % 9999999999999] forKey:@"rand"];
	[params setObject:[self apikey] forKey:@"idsite"];
    [params setObject:[self urlEncodeString:url] forKey:@"url"];
    [params setObject:@"mobile" forKey:@"urlref"];
    [params setObject:@"" forKey:@"data"];
    
    [eventQueue addObject:params];
    
    if(_timer == nil){
        [self setFlushTimer];
        PLog(@"Flush timer set to %d", [self flushInterval]);
    }
}

-(void)flush{
    // remove all events from the queue and send pixel requests
    
    if([[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] != ReachableViaWiFi || __debug_wifioff){
        PLog(@"Wifi network unreachable. Not flushing.");
        return;
    }
    
    if([eventQueue count] == 0){
        PLog(@"Event queue empty, flush timer cleared.");
        [self stopFlushTimer];
        return;
    }
    
    PLog(@"Flushing queue...");
    for(NSMutableDictionary *event in eventQueue){
        PLog(@"Flushing event %@", [event objectForKey:@"url"]);
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
    PLog(@"Done");
}

-(void)persistQueue{
    // save the entire event queue to persistent storage
}

-(void)persistSingleRequest{
    // save a single event from the queue to persistent storage
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
            instance = [[ParselyTracker alloc] initWithApiKey:apikey andFlushInterval:60 ];
        }
        return instance;
    }
}

-(id)initWithApiKey:(NSString *)apikey andFlushInterval:(NSInteger)flushint{
    @synchronized(self){
        if(self=[super init]){
            _apikey = apikey;
            eventQueue = [NSMutableArray array];
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

-(NSString *)rootUrl{
    return _rootUrl;
}

-(NSInteger)flushInterval{
    return _flushInterval;
}

-(NSInteger)queueSize{
    return [eventQueue count];
}

-(void)__debugWifiOff{
    __debug_wifioff = YES;
}

-(void)__debugWifiOn{
    __debug_wifioff = NO;
}

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