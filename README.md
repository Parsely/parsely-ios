**NOTICE: this library is deprecated and has been replaced by
[the Swift-based Parse.ly SDK](https://github.com/parsely/analyticssdk-ios). If
integrating with Parse.ly for the first time, do not use this library.**

Parsely iOS SDK
===============

This library provides an interface to Parsely's pageview tracking system. It
provides similar functionality to the
[Parsely Javascript tracker](http://www.parsely.com/docs/integration/tracking/basic.html)
for iOS apps. Full class-level documentation of this library can be found at the
[Parsely website](http://www.parsely.com/sdk/ios/index.html).

Usage
-----

If your application uses Cocoapods you can use the [Parsely Pod](https://cocoapods.org/pods/Parsely) to integrate the SDK.

If you want to track activity on your iPhone app and integrate this code manually, first clone this repository with

    git clone http://github.com/Parsely/parsely-ios.git

This repository's primary purpose is to host the open source Parse.ly iOS SDK,
implemented as an Objective-C class in `/ParselyiOS`. This module is used in `/HiParsely`
as an example of how to integrate the SDK in a typical XCode project. You can
open `HiParsely` as an XCode project and explore a typical SDK integration.


Integrating with XCode
----------------------

To integrate Parse.ly mobile tracking with your iOS app:

1. Drag and drop the ParselyiOS folder into your XCode project
2. Check the box labeled "Copy items into destination Group's folder"
3. Ensure that the `Foundation.framework` and `SystemConfiguration.framework` frameworks are included in the "Link Binary with Libraries" build phase


Using the SDK
-------------

In any file that uses the Parsely SDK, be sure to add the line

    #import "ParselyTracker.h"

at the top of the file.

Before using the SDK, you must initialize the Parsely object with your public api key.
This is usually best to do in the setup phase of your app, for example in the
`applicationDidFinishLaunchingWithOptions:` method of the `AppDelegate`.

    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [ParselyTracker sharedInstanceWithApiKey:@"somesite.com"];  // initialize the Parsely tracker
        [self.window makeKeyAndVisible];
        return YES;
    }

To register a pageview event with Parsely, simply use the `trackURL:` call.

    [[ParselyTracker sharedInstance] trackURL:@"http://dailycaller.com/2013/03/19/alison-brie-is-the-future-of-television-photos/"];

This call requires the canonical URL of the page corresponding to the post currently being viewed.

License
-------

    Copyright 2016 Parse.ly, Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
