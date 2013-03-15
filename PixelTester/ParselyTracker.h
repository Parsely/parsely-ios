#import <Foundation/Foundation.h>

#ifdef PARSELY_DEBUG
#define PLog( s, ... ) NSLog( @"<%@:(%d)> [Parsely] %@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define PLog(s, ...)
#endif

@interface ParselyTracker : NSObject
{
    NSString *_rootUrl, *_apikey;
    NSInteger _flushInterval;
    NSTimer *_timer;
    NSMutableArray *eventQueue;
#ifdef PARSELY_DEBUG
    BOOL __debug_wifioff;
#endif
}

@property (nonatomic) NSString *uuidKey;
@property (nonatomic) NSString *storageKey;
@property (nonatomic) NSInteger queueSizeLimit;
@property (nonatomic) BOOL shouldFlushOnBackground;

+(ParselyTracker *)sharedInstance;
+(ParselyTracker *)sharedInstanceWithApiKey:(NSString *)apikey;
// add a pixel request to the queue
-(void)track:(NSString *)url;
// stop sending events
-(void)stop;
// start sending events
-(void)start;

-(id)initWithApiKey:(NSString *)apikey andFlushInterval:(NSInteger)flushint;

-(NSString *)rootUrl;
-(NSInteger)queueSize;
-(NSInteger)storedEventsCount;
-(NSInteger)flushInterval;
-(BOOL)flushTimerIsActive;
#ifdef PARSELY_DEBUG
-(void)__debugWifiOn;
-(void)__debugWifiOff;
#endif

@end
