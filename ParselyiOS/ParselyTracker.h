/*
    ParselyTracker.h
    ParselyiOS

    Copyright 2016 Parse.ly

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

#import <Foundation/Foundation.h>

#define PLog(s, ...)

/*! \brief Manages pageview events and analytics data for Parsely on iOS
 *
 *  Accessed as a singleton. Maintains a queue of pageview events in memory and periodically
 *  flushes the queue to the Parsely pixel proxy server.
 */
@interface ParselyTracker : NSObject <NSURLConnectionDelegate>
{
    @private
        NSTimer *_timer;  /*!< Periodically generates a callback to flush the event queue */
        NSMutableArray *eventQueue;  /*!< Buffer of events, periodically emptied and used to generate pixel requests */
        NSString *uuidKey;  /*!< Key mapped to the generated uuid in the defaults store */
        NSString *storageKey;  /*!< Key mapped to the saved event queue in the defaults store */
        NSString *rootUrl;  /*!< Root of Parsely's pixel server URL (eg "http://pixel.parsely.com") */
        NSMutableDictionary *deviceInfo; /*!< Contains static information about the current app and device */
        NSDictionary *idNameMap; /*!< Maps kIdTypes to request parameter strings */
    @public
        NSInteger storageSizeLimit;  /*!< Maximum number of events held in persistent storage */
        NSInteger queueSizeLimit;  /*!< Maximum number of events held in the in-memory event queue */
}

/*! \brief types of post identifiers
 *
 *  Representation of the allowed post identifier types
 */
typedef enum _kIdType {
    kUrl, kPostId
} kIdType;

@property (nonatomic) NSString *apiKey;  /*!< Parsely public API key (eg "samplesite.com") */
@property (nonatomic) NSString *urlref;  /*!< The "urlref" value sent with each event. Defaults to "parsely_mobile_sdk" */
@property (nonatomic) NSInteger flushInterval;  /*!< The time between event queue flushes expressed in seconds */
@property (nonatomic) BOOL shouldFlushOnBackground;  /*!< If YES, the event queue is automatically flushed when the app enters the background */

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
 *  @param apikey The Parsely public API key (eg "samplesite.com")
 *  @param flushint Interval between queue flushes, expressed in seconds
 *  @return The singleton instance
 */
+(ParselyTracker *)sharedInstanceWithApiKey:(NSString *)apikey andFlushInterval:(NSInteger)flushint;

/*! \brief Singleton instance factory
 *
 *  **Note**: This must be called before `sharedInstance`
 *
 *  @param apikey The Parsely public API key (eg "samplesite.com")
 *  @param flushint Interval between queue flushes, expressed in seconds
 *  @param urlref_ The urlref value to send with each event
 *  @return The singleton instance
 */
+(ParselyTracker *)sharedInstanceWithApiKey:(NSString *)apikey andFlushInterval:(NSInteger)flushint andUrlref:(NSString *)urlref_;

/*! \brief Singleton instance factory
 *
 *  **Note**: This must be called before `sharedInstance`
 *
 *  @param apikey The Parsely public API key (eg "samplesite.com")
 *  @return The singleton instance
 */
+(ParselyTracker *)sharedInstanceWithApiKey:(NSString *)apikey;

/*! \brief Register a pageview event using a canonical URL
 *
 *  @param url The canonical URL of the article being tracked (eg: "http://samplesite.com/some-old/article.html")
 */
-(void)trackURL:(NSString *)url;

/*! \brief Register a pageview event using a CMS post identifier
 *
 *  @param postid A string uniquely identifying this post. This **must** be unique within Parsely's database.
 */
-(void)trackPostID:(NSString *)postid;

/*! \brief Registers a pageview event
 *
 *  Places a data structure representing the event into the in-memory queue for later use
 *
 *  **Note**: Events placed into this queue will be discarded if the size of the persistent queue store exceeds `storageSizeLimit`.
 */
-(void)track:(NSString *)identifier withIDType:(kIdType)idtype;

/*!  \brief Generate pixel requests from the queue
 *
 *  Empties the entire queue and sends the appropriate pixel requests.
 *  If `shouldBatchRequests` is YES, the queue is sent as a minimum number of requests.
 *  Called automatically after a number of seconds determined by `flushInterval`.
 */
-(void)flush;

/*! \brief Disallow Parsely from sending pageview events
 *
 *  Invalidates the callback timer responsible for flushing the events queue.
 *  Can be called before or after `start`, but has no effect if used before instantiating the singleton
 */
-(void)stopFlushTimer;

/*! \brief Allow Parsely to send pageview events
 *
 *  Instantiates the callback timer responsible for flushing the events queue.
 *  Can be called before of after `stop`, but has no effect is used before instantiating the singleton
 */
-(void)setFlushTimer;

/*! \brief Singleton constructor
 *
 *  Creates an instance of the class and returns the reference.
 *  Prefer `sharedInstanceWithApiKey:` to this method.
 *
 *  @param apikey Parsely public API key (eg "samplesite.com")
 *  @param flushint Interval between queue flushes, expressed in seconds
 *  @param urlref_ The urlref value to send with each event
 *  @return The singleton instance
 */
-(id)initWithApiKey:(NSString *)apikey andFlushInterval:(NSInteger)flushint andUrlref:(NSString *)urlref_;

/*!  \brief Send the entire queue as a single request
 *
 *   Creates a large POST request containing the JSON encoding of the entire queue.
 *   Sends this request to the proxy server, which forwards requests to the pixel server.
 *
 *   @param queue The list of event dictionaries to serialize
 *   @return The HTTP request error encountered during the send, if any
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

@end
