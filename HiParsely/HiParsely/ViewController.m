#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    hasConnection = YES;
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    [self.view setBackgroundColor:[UIColor grayColor]];
    
    UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"parsely_logo_horizontal"]];
    [logoView setFrame:CGRectMake(48, 40, 200, 57)];
    [self.view addSubview:logoView];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self
               action:@selector(trackPage)
     forControlEvents:UIControlEventTouchDown];
    [button setTitle:@"Track URL" forState:UIControlStateNormal];
    button.frame = CGRectMake(80.0, 110.0, 160.0, 40.0);
    [self.view addSubview:button];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button2 addTarget:self
               action:@selector(trackPostID)
     forControlEvents:UIControlEventTouchDown];
    [button2 setTitle:@"Track Post ID" forState:UIControlStateNormal];
    button2.frame = CGRectMake(80.0, 160.0, 160.0, 40.0);
    [self.view addSubview:button2];
    
#ifdef PARSELY_DEBUG
    connectionButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [connectionButton addTarget:self
               action:@selector(toggleSimulatedConnection)
     forControlEvents:UIControlEventTouchDown];
    [connectionButton setTitle:@"Lose connection" forState:UIControlStateNormal];
    connectionButton.frame = CGRectMake(80.0, 210.0, 160.0, 40.0);
    [self.view addSubview:connectionButton];
#endif
    
    queueStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, bounds.size.height-120, bounds.size.width, 90)];
    [queueStatusLabel setNumberOfLines:0];
    [queueStatusLabel setText:[NSString stringWithFormat:@"%d queued events\n%d stored events\nflush rate %ds",
                               (int)[[ParselyTracker sharedInstance] queueSize], (int)[[ParselyTracker sharedInstance] storedEventsCount], (int)[[ParselyTracker sharedInstance] flushInterval]]];
    [queueStatusLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:queueStatusLabel];
    
    [NSTimer scheduledTimerWithTimeInterval:.1
                                     target:self
                                   selector:@selector(updateQueueStatusLabel)
                                   userInfo:nil
                                    repeats:YES];
}

-(void)updateQueueStatusLabel{
    [queueStatusLabel setText:[NSString stringWithFormat:@"%d queued events\n%d stored events\n%@",
                               (int)[[ParselyTracker sharedInstance] queueSize], (int)[[ParselyTracker sharedInstance] storedEventsCount],
                               [[ParselyTracker sharedInstance] flushTimerIsActive] ?
                                    [NSString stringWithFormat:@"flush rate %ds", (int)[[ParselyTracker sharedInstance] flushInterval]] :
                                    @"timer inactive"]];
}

-(void)toggleSimulatedConnection{
    if(hasConnection){
        hasConnection = NO;
#ifdef PARSELY_DEBUG
        [[ParselyTracker sharedInstance] __debugWifiOff];
#endif
        [connectionButton setTitle:@"Regain connection" forState:UIControlStateNormal];
    } else {
        hasConnection = YES;
#ifdef PARSELY_DEBUG
        [[ParselyTracker sharedInstance] __debugWifiOn];
#endif
        [connectionButton setTitle:@"Lose connection" forState:UIControlStateNormal];
    }
}

-(void)trackPage{
    [[ParselyTracker sharedInstance] trackURL:@"http://somesite.com/not-a-real-url.html"];
}

-(void)trackPostID{
    [[ParselyTracker sharedInstance] trackPostID:@"12353-983124-876153"];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

@end