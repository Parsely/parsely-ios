//
//  ViewController.m
//  PixelTester
//
//  Created by Emmett Butler on 3/8/13.
//  Copyright (c) 2013 Emmett Butler. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [[ParselyTracker sharedInstance] track:@"http://arstechnica.com/some-old-thing"];
    [[ParselyTracker sharedInstance] flush];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end