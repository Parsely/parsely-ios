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

/*! \brief Manages pageview events and analytics data for Parsely on iOS
 *
 *  Accessed as a singleton. Maintains a queue of pageview events in memory and periodically
 *  flushes the queue to the Parsely pixel server.
 */ 
@interface ParselyTracker : NSObject <NSURLConnectionDelegate>
{
    NSTimer *_timer;  /*!< Periodically generates a callback to flush the event queue */
    NSMutableArray *eventQueue;  /*!< Buffer of events, periodically emptied and used to generate pixel requests */
#ifdef PARSELY_DEBUG
    BOOL __debug_wifioff;
#endif
}

@property (nonatomic) NSString *uuidKey;  /*!< Key mapped to the generated uuid in the defaults store */
@property (nonatomic) NSString *apiKey;  /*!< Parsely public API key (eg "dailycaller.com") */
@property (nonatomic) NSString *storageKey;  /*!< Key mapped to the saved event queue in the defaults store */
@property (nonatomic) NSString *rootUrl;  /*!< Root of Parsely's pixel server URL (eg "http://pixel.parsely.com") */
@property (nonatomic) NSInteger queueSizeLimit;  /*!< Maximum number of events held in the in-memory event queue */
@property (nonatomic) NSInteger storageSizeLimit;  /*!< Maximum number of events held in persistent storage */
@property (nonatomic) NSInteger flushInterval;  /*!< The time between event queue flushes expressed in seconds */
@property (nonatomic) BOOL shouldBatchRequests;  /*!< If YES, the event queue is sent as a single request to a proxy server */
@property (nonatomic) BOOL shouldFlushOnBackground;  /*!< If YES, the event queue is automatically flushed when the app enters the background */
@property (nonatomic) NSMutableDictionary *deviceInfo; /*!< Contains static information about the current app and device */

/*! \brief Singleton instance accessor
 *
 *  **Note**: This must be called after `sharedInstanceWithApiKey:`
 *
 *  @return The singleton instance
 */
+(ParselyTracker *)sharedInstance;

/*! \brief Singleton instance factory
 *
 *  **Note**: This must be called before `sharedInstance`
 *
 *  @param apikey The Parsely public API key (eg "dailycaller.com")
 *  @return The singleton instance
 */
+(ParselyTracker *)sharedInstanceWithApiKey:(NSString *)apikey;

/*! \brief Register a pageview event
 *
 *  Places a data structure representing the event into the in-memory queue for later use
 *
 *  **Note**: Events placed into this queue will be discarded if the size of the persistent queue store exceeds `storageSizeLimit`.
 *
 *  @param url The canonical URL of the article being tracked (eg: "http://dailycaller.com/some-old/article.html")
 */
-(void)track:(NSString *)url;

/*!  \brief Generate pixel requests from the queue
 *
 *  Empties the entire queue and sends the appropriate pixel requests.
 *  If `shouldBatchRequests` is YES, the queue is sent as a minimum number of requests.
 *  Called automatically after a number of seconds determined by `flushInterval`.
 */
-(void)flush;

/*! \brief Disallow the SDK from sending pageview events
 *
 *  Invalidates the callback timer responsible for flushing the events queue.
 *  Can be called before or after `start`, but has no effect if used before instantiating the singleton
 */
-(void)stop;

/*! \brief Allow the SDK to send pageview events
 *
 *  Instantiates the callback timer responsible for flushing the events queue.
 *  Can be called before of after `stop`, but has no effect is used before instantiating the singleton
 */
-(void)start;

/*! \brief Singleton constructor
 *
 *  Creates an instance of the class and returns the reference.
 *  Prefer `sharedInstanceWithApiKey:` to this method.
 *
 *  @param apikey Parsely public API key (eg "dailycaller.com")
 *  @param flushint Interval between queue flushes, expressed in seconds
 *  @return The singleton instance
 */
-(id)initWithApiKey:(NSString *)apikey andFlushInterval:(NSInteger)flushint;

/*!  \brief Send a single pixel request
 *
 *  Sends a single request directly to Parsely's pixel server, bypassing the proxy.
 *  Prefer `sendBatchRequest:` to this method, as `sendBatchRequest:` causes less battery usage
 *
 *  @param event A dictionary containing data for a single pageview event
 */
-(void)flushEvent:(NSDictionary *)event;

/*!  \brief Send the entire queue as a single request
 *
 *   Creates a large GET request containing the JSON encoding of the entire queue.
 *   Sends this request to the proxy server, which forwards requests to the pixel server.
 *
 *   @param queue The list of event dictionaries to serialize
 */
-(void)sendBatchRequest:(NSSet *)queue;

/*! \brief Get the size of the queue
 *  
 *  @return The current cardinality of the in-memory event queue
 *
 */
-(NSInteger)queueSize;

/*! \brief Get the size of the persistent store
 *
 *  @return The current number of events stored in persistent memory (the defaults store)
 */
-(NSInteger)storedEventsCount;

/*! \brief Is the callback timer running 
 *
 *  @return `YES` if the callback timer is currently running, `NO` otherwise
 */
-(BOOL)flushTimerIsActive;

#ifdef PARSELY_DEBUG
-(void)__debugWifiOn;
-(void)__debugWifiOff;
#endif

@end
