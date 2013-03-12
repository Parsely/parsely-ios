#import <Foundation/Foundation.h>

#ifdef DEBUG
#define PLog( s, ... ) NSLog( @"<%@:(%d)> [Parsely] %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define PLog(s, ...)
#endif

@interface ParselyTracker : NSObject
{
    NSString *_rootUrl, *_apikey, *_storageKey;
    NSInteger _flushInterval;
    NSTimer *_timer;
    NSMutableArray *eventQueue;
#ifdef DEBUG
    BOOL __debug_wifioff;
#endif
}

+(ParselyTracker *)sharedInstance;
+(ParselyTracker *)sharedInstanceWithApiKey:(NSString *)apikey;
-(id)initWithApiKey:(NSString *)apikey andFlushInterval:(NSInteger)flushint;

-(NSString *)rootUrl;
-(NSInteger)queueSize;
-(NSInteger)storedEventsCount;
-(NSInteger)flushInterval;
-(BOOL)flushTimerIsActive;
#ifdef DEBUG
-(void)__debugWifiOn;
-(void)__debugWifiOff;
#endif

// add a pixel request to the queue
-(void)track:(NSString *)url;

// empty the queue and send pixel requests
-(void)flush;

// make sure the whole queue is saved in persistent storage
-(void)persistQueue;

@end
