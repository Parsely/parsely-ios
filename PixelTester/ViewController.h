//
//  ViewController.h
//  PixelTester
//
//  Created by Emmett Butler on 3/8/13.
//  Copyright (c) 2013 Emmett Butler. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParselyTracker.h"

@interface ViewController : UIViewController
{
    UIButton *connectionButton;
    UILabel *queueStatusLabel;
    BOOL hasConnection;
}
@end
