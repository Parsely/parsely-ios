//
//  ParselyTracker.h
//  PixelTester
//
//  Created by Emmett Butler on 3/8/13.
//  Copyright (c) 2013 Emmett Butler. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MOCKSERVER 1

@interface ParselyTracker : NSObject
{
    NSString *_rootUrl, *_apikey;
    NSNumber *_flushInterval;
    NSTimer *_timer;
    NSMutableArray *eventQueue;
}

+(ParselyTracker *)sharedInstance;
-(NSString *)rootUrl;

// initial setup of invariant data
-(void)configure:(NSString *)apikey;

// add a pixel request to the queue
-(void)track:(NSString *)url;

// empty the queue and send pixel requests
-(void)flush;

// make sure the whole queue is saved in persistent storage
-(void)persistQueue;

@end
