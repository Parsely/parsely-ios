//
//  ParselyTracker.m
//  PixelTester
//
//  Created by Emmett Butler on 3/8/13.
//  Copyright (c) 2013 Emmett Butler. All rights reserved.
//

#import "ParselyTracker.h"

@implementation ParselyTracker

ParselyTracker *instance;

-(void)track:(NSString *)url{
    // add an event to the queue
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setObject:[NSString stringWithFormat:@"%lli", 1000000000000 + arc4random() % 9999999999999] forKey:@"rand"];
	[params setObject:[self apikey] forKey:@"idsite"];
    [params setObject:[self urlEncodeString:url] forKey:@"url"];
    [params setObject:@"mobile" forKey:@"urlref"];
    [params setObject:@"" forKey:@"data"];
    
    [eventQueue addObject:params];
}

-(void)flush{
    // remove all events from the queue and send pixel requests
    for(NSMutableDictionary *event in eventQueue){
        NSString *url = [NSString stringWithFormat:@"%@%%3Frand=%@&idsite=%@&url=%@&urlref=%@&data=%@", [self rootUrl],
                               [event objectForKey:@"rand"],
                               [event objectForKey:@"idsite"],
                               [event objectForKey:@"url"],
                               [event objectForKey:@"urlref"],
                               [event objectForKey:@"data"]];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                               cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                           timeoutInterval:10];
        [request setHTTPMethod: @"GET"];
        
        NSError *requestError;
        NSURLResponse *urlResponse = nil;
        
        [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&requestError];
    }
    [eventQueue removeAllObjects];
}

-(void)persistQueue{
    // save the entire event queue to persistent storage
}

-(void)persistSingleRequest{
    // save a single event from the queue to persistent storage
}

-(void)configure:(NSString *)apikey{
    [self setApikey:apikey];
}

-(void)setApikey:(NSString *)key{
    _apikey = key;
}

-(NSString *)apikey{
    return _apikey;
}

-(NSString *)rootUrl{
    return _rootUrl;
}

-(NSString *)urlEncodeString:(NSString *)string{
    NSString *retval = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                          NULL,
                                                                          (__bridge CFStringRef) string,
                                                                          NULL,
                                                                          CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                          kCFStringEncodingUTF8));
    return retval;
}

// singleton boilerplate

+(ParselyTracker *)sharedInstance{
    if(instance == nil){
        instance = [[self alloc] init];
    }
    return instance;
}

-(id)init{
    @synchronized(self){
        if(self=[super init]){
            eventQueue = [NSMutableArray array];
#ifdef MOCKSERVER
            _rootUrl = @"http://localhost:8000/plogger/";
#else
            _rootUrl = @"http://the-actual-pixel-server";
#endif
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

@end