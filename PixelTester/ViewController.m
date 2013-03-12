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
    
    hasConnection = YES;
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, bounds.size.width, 40)];
    [title setFont:[UIFont fontWithName:@"Arial" size:26]];
    [title setTextColor:[UIColor whiteColor]];
    [title setBackgroundColor:[UIColor blackColor]];
    [title setTextAlignment:NSTextAlignmentCenter];
    [title setText:@"Parsely SDK Test App"];
    [self.view addSubview:title];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self
               action:@selector(trackPage)
     forControlEvents:UIControlEventTouchDown];
    [button setTitle:@"Track page" forState:UIControlStateNormal];
    button.frame = CGRectMake(80.0, 110.0, 160.0, 40.0);
    [self.view addSubview:button];
    
    connectionButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [connectionButton addTarget:self
               action:@selector(toggleSimulatedConnection)
     forControlEvents:UIControlEventTouchDown];
    [connectionButton setTitle:@"Lose connection" forState:UIControlStateNormal];
    connectionButton.frame = CGRectMake(80.0, 160.0, 160.0, 40.0);
    [self.view addSubview:connectionButton];
    
    queueStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, bounds.size.height-70, bounds.size.width, 40)];
    [queueStatusLabel setText:[NSString stringWithFormat:@"%d queued events, flush rate %ds", [[ParselyTracker sharedInstance] queueSize], [[ParselyTracker sharedInstance] flushInterval]]];
    [queueStatusLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:queueStatusLabel];
    
    [NSTimer scheduledTimerWithTimeInterval:.1
                                     target:self
                                   selector:@selector(updateQueueStatusLabel)
                                   userInfo:nil
                                    repeats:YES];
}

-(void)updateQueueStatusLabel{
    [queueStatusLabel setText:[NSString stringWithFormat:@"%d queued events, %@",
                               [[ParselyTracker sharedInstance] queueSize],
                               [[ParselyTracker sharedInstance] flushTimerIsActive] ?
                                    [NSString stringWithFormat:@"flush rate %ds", [[ParselyTracker sharedInstance] flushInterval]] :
                                    @"timer inactive"]];
}

-(void)toggleSimulatedConnection{
    if(hasConnection){
        hasConnection = NO;
        [[ParselyTracker sharedInstance] __debugWifiOff];
        [connectionButton setTitle:@"Regain connection" forState:UIControlStateNormal];
    } else {
        hasConnection = YES;
        [[ParselyTracker sharedInstance] __debugWifiOn];
        [connectionButton setTitle:@"Lose connection" forState:UIControlStateNormal];
    }
}

-(void)trackPage{
    [[ParselyTracker sharedInstance] track:@"http://arstechnica.com/some-old-thing"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end