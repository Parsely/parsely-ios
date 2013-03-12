#import <Foundation/Foundation.h>

#ifdef DEBUG
#define PLog( s, ... ) NSLog( @"<%@:(%d)> [Parsely] %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define PLog(s, ...)
#endif

@interface ParselyTracker : NSObject
{
    NSString *_rootUrl, *_apikey;
    NSInteger _flushInterval;
    NSTimer *_timer;
    BOOL __debug_wifioff;
    NSMutableArray *eventQueue;
}

+(ParselyTracker *)sharedInstance;
+(ParselyTracker *)sharedInstanceWithApiKey:(NSString *)apikey;
-(id)initWithApiKey:(NSString *)apikey andFlushInterval:(NSInteger)flushint;

-(NSString *)rootUrl;
-(NSInteger)queueSize;
-(NSInteger)flushInterval;
-(void)__debugWifiOn;
-(void)__debugWifiOff;
-(BOOL)flushTimerIsActive;

// add a pixel request to the queue
-(void)track:(NSString *)url;

// empty the queue and send pixel requests
-(void)flush;

// make sure the whole queue is saved in persistent storage
-(void)persistQueue;

@end
