//
//  SDKTests.m
//  SDKTests
//
//  Created by Emmett Butler on 4/26/13.
//  Copyright (c) 2013 Emmett Butler. All rights reserved.
//

#import "SDKTests.h"
#import "ParselyTracker.h"

@implementation SDKTests

-(void)setUp{
    [super setUp];
    
    testapikey = @"examplesite.com";
    testurl = @"http://examplesite.com/something.html";
    testpostid = @"417236415-12395871235";
}

-(void)tearDown{
    // Tear-down code here.
    
    [super tearDown];
}

/*! 
 * Tests that the tracker was properly initialized
 */
-(void)testInitialization{
    [ParselyTracker sharedInstanceWithApiKey:testapikey];
    STAssertEquals([[ParselyTracker sharedInstance] apiKey], testapikey, @"API key not set correctly");
}

/*!
 * Tests that events queue properly
 */
-(void)testTrackEventQueued{
    [[ParselyTracker sharedInstance] flush];
    [[ParselyTracker sharedInstance] trackURL:testurl];
    [[ParselyTracker sharedInstance] trackURL:testpostid];
    STAssertEquals([[ParselyTracker sharedInstance] queueSize], 2, @"Events not queued correctly");
}

/*!
 * Tests that flushing actually does empty the queue
 */
-(void)testPostFlushQueueSize{
    [[ParselyTracker sharedInstance] trackURL:testurl];
    [[ParselyTracker sharedInstance] trackURL:testpostid];
    [[ParselyTracker sharedInstance] flush];
    STAssertEquals([[ParselyTracker sharedInstance] queueSize], 0, @"Queue not empty after flush");
    STAssertEquals([[ParselyTracker sharedInstance] storedEventsCount], 0, @"Stored queue not empty after flush");
}

/*!
 * Tests the maximum number of events that can be fit in local storage
 */
-(void)testManyEventsQueuedAndLocalStorage{
    int n = [ParselyTracker sharedInstance]->storageSizeLimit;
    [[ParselyTracker sharedInstance] flush];
    for(int i = 0; i < n; i++){
        [[ParselyTracker sharedInstance] trackURL:testurl];
    }
    STAssertEquals([[ParselyTracker sharedInstance] queueSize], [ParselyTracker sharedInstance]->queueSizeLimit, @"Queue size limit discrepancy");
    STAssertEquals([[ParselyTracker sharedInstance] storedEventsCount], n, @"Events not stored locally");
}

@end
