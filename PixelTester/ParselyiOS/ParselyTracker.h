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

#import <Foundation/Foundation.h>

#ifdef PARSELY_DEBUG
#define PLog( s, ... ) NSLog( @"<%@:(%d)> [Parsely] %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define PLog(s, ...)
#endif

@interface ParselyTracker : NSObject
{
    NSTimer *_timer;
    NSMutableArray *eventQueue;
#ifdef PARSELY_DEBUG
    BOOL __debug_wifioff;
#endif
}

@property (nonatomic) NSString *uuidKey;
@property (nonatomic) NSString *apiKey;
@property (nonatomic) NSString *rootUrl;
@property (nonatomic) NSString *storageKey;
@property (nonatomic) NSInteger queueSizeLimit;
@property (nonatomic) NSInteger flushInterval;
@property (nonatomic) BOOL shouldFlushOnBackground;

// returns a reference to the singleton, must be called after sharedInstanceWithApiKey:
+(ParselyTracker *)sharedInstance;
// instantiate the singleton Parsely SDK object
+(ParselyTracker *)sharedInstanceWithApiKey:(NSString *)apikey;
// add a pixel request to the queue
-(void)track:(NSString *)url;
// stop sending events
-(void)stop;
// start sending events
-(void)start;

-(id)initWithApiKey:(NSString *)apikey andFlushInterval:(NSInteger)flushint;

-(NSInteger)queueSize;
-(NSInteger)storedEventsCount;
-(BOOL)flushTimerIsActive;
#ifdef PARSELY_DEBUG
-(void)__debugWifiOn;
-(void)__debugWifiOff;
#endif

@end
