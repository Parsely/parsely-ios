Parsely iOS SDK
===============

This library provides an interface to Parsely's pageview tracking system. It
provides similar functionality to the [Parsely Javascript tracker](http://www.parsely.com/docs/integration/tracking/basic.html)
for iOS apps.

Documentation
-------------

Full class-level documentation of this library can be found at the
[Parsely website](http://www.parsely.com/sdk/ios/index.html). This documentation
is generated from the code itself using [Doxygen](http://www.stack.nl/~dimitri/doxygen/).

Usage
-----

If you want to track activity on your iPhone app, first clone this repository with

    git clone http://github.com/Parsely/parsely-ios.git

This repository contains three main directories:

* `ParselyiOS` is the Parsely iOS SDK source code
* `HiParsely` is an XCode project demonstrating how to integrate the SDK into an app
* `Documentation` is the target directory for the Doxygen document generator


Integrating with XCode
----------------------

Adding Parsely to your iOS app is easy!

1. Drag and drop the ParselyiOS folder into your XCode project
2. Check the box labeled "Copy items into destination Group's folder"
3. Ensure that the following frameworks are included in the "Link Binary with Libraries" build phase

*  `Foundation.framework`

*  `SystemConfiguration.framework`

Including the SDK
-----------------

In any file that uses the Parsely SDK, be sure to add the line

    #import "ParselyTracker.h"

at the top of the file.

Parsely Initialization
----------------------

Before using the SDK, you must initialize the Parsely object with your public api key. This is usually best to do in the setup phase of your app, for example in the `applicationDidFinishLaunchingWithOptions:` method of the `AppDelegate`.

    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

        [ParselyTracker sharedInstanceWithApiKey:@"somesite.com"];  // initialize the Parsely tracker

        [self.window makeKeyAndVisible];
        return YES;
    }

Pageview Tracking
-----------------

To register a pageview event with Parsely, simply use the `trackURL:` call.

    [[ParselyTracker sharedInstance] trackURL:@"http://dailycaller.com/2013/03/19/alison-brie-is-the-future-of-television-photos/"];

This call requires the canonical URL of the page corresponding to the post currently being viewed.

License
-------

    Copyright 2014 Parse.ly, Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
