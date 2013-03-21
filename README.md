If you want to track activity on your iPhone app, first clone this repository with

    git clone http://github.com/Parsely/parsely-ios.git

This repository contains three main directories:

`ParselyiOS` is the Parsely iOS SDK source code
`HiParsely` is an XCode project demonstrating how to integrate the SDK into an app
`Documentation` is the target directory for the Doxygen document generator


Integrating with XCode
----------------------

Adding Parsely to your iOS app is easy!

1. Drag and drop the ParselyiOS folder into your XCode project
2. Check the box labeled "Copy items into destination Group's folder"
3. Ensure that the following frameworks are included in the "Link Binary with Libraries" build phase

*  Foundation.framework

*  SystemConfiguration.framework

Including the SDK
-----------------

In any file that uses the Parsely SDK, be sure to add the line

    #import "ParselyTracker.h"

at the top of the file.

Parsely Initialization
----------------------

Before using the SDK, you must initialize the Parsely object with your public api key. This is usually best to do in the `applicationDidFinishLaunchingWithOptions:` method of the `AppDelegate`.

    - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

        self.viewController = [[ViewController alloc] init];
        self.window.rootViewController = self.viewController;

        [ParselyTracker sharedInstanceWithApiKey:@"dailycaller.com"];  // initialize the Parsely tracker

        [self.window makeKeyAndVisible];
        return YES;
    }

Pageview Tracking
-----------------

To register a pageview event with Parsely, simply use the `track:` call.

    [[ParselyTracker sharedInstance] track:@"http://dailycaller.com/2013/03/19/alison-brie-is-the-future-of-television-photos/"];

This call requires the canonical URL of the page corresponding to the post currently being viewed.
