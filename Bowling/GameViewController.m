//
//  GameViewController.m
//  Bowling
//
//  Created by Larry Feldman on 5/27/15.
//  Copyright (c) 2015 Larry Feldman. All rights reserved.
//

#import "GameViewController.h"
#define charSpeedScale 0.25
#define ammoSpeed 50.0
#define enemySpeed 5.0
#define missileSpeed 10
#define skyWidth 10000
#define gameTime .05
#define offScreen -1000


@interface GameViewController ()

- (IBAction)gameCenterPressed:(id)sender;
- (IBAction)soundSwitchChanged:(id)sender;
- (IBAction)fullVersionPressed:(id)sender;

@property (strong, nonatomic) IBOutlet UISwitch *soundSwitch;
@property (retain, nonatomic) AVAudioPlayer *ambientPlayer;
@property (strong, nonatomic) IBOutlet UILabel *highScoreLabel;

@property (strong, nonatomic) IBOutlet UIImageView *ammoImage;
@property (strong, nonatomic) IBOutlet UIImageView *gateImage;
@property (strong, nonatomic) IBOutlet UIImageView *character;
@property (strong, nonatomic) IBOutlet UIImageView *skyBG;
@property (strong, nonatomic) IBOutlet UIImageView *finishLine;
@property (strong, nonatomic) IBOutlet UIImageView *bombImage;
@property (strong, nonatomic) IBOutlet UIImageView *enemyChopper;
@property (strong, nonatomic) IBOutlet UIImageView *missileImage;
@property (strong, nonatomic) IBOutlet UILabel *livesLabel;
@property (strong, nonatomic) IBOutlet UIImageView *atomImage;
@property (strong, nonatomic) IBOutlet UIImageView *truckImage;

@property (strong, nonatomic) UIImageView *fireChopper;
@property (strong, nonatomic) UIImageView *flameMissile;
@property (strong, nonatomic) UIImageView *flameEnemyChopper;

@property (strong, nonatomic) IBOutlet UILabel *scoreLabel;
@property (strong, nonatomic) IBOutlet UILabel *shieldLabel;

@property (strong, nonatomic) IBOutlet UILabel *fireballLabel;


@property (strong, nonatomic) NSTimer *gameTimer;
@property (strong, nonatomic) NSTimer *ammoTimer;
@property (strong, nonatomic) IBOutlet UIButton *playButton;

@property (strong, nonatomic) NSMutableArray *fireAnimation;
@property (strong, nonatomic) NSMutableArray *wallAnimation;
@property (strong, nonatomic) NSMutableArray *finishAnimation;
@property (strong, nonatomic) NSMutableArray *truckArray;
@property (strong, nonatomic) NSMutableArray *fireArray;
@property (strong, nonatomic) NSMutableArray *atomArray;



@end

@implementation GameViewController

double screenWidth2;
double screenHeight2;
double timePassed2;

int deviceScaler2;


- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    screenWidth2 = self.view.frame.size.width;
    screenHeight2 = self.view.frame.size.height;
    
    // Background sound

    NSNumber* soundOn = [[NSUserDefaults standardUserDefaults] objectForKey:@"soundOn"];
    BOOL soundIsOn = [soundOn boolValue];
    
    NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
    resourcePath = [resourcePath stringByAppendingString:@"/chopperShort.mp3"];
    NSLog(@"Path to play: %@", resourcePath);
    NSError* err;
    
    self.ambientPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:resourcePath] error:&err];
    
    if(err)
    {
        NSLog(@"Failed with reason: %@", [err localizedDescription]);
    }
    else
    {
        self.ambientPlayer.delegate = self;
        
        if(soundIsOn)
        {
            [self.ambientPlayer play];
        }
        self.ambientPlayer.numberOfLoops = -1;
        self.ambientPlayer.currentTime = 0;
        self.ambientPlayer.volume = 1.0;
    }
    
    // Game Center
    
 //   [[GameCenterManager sharedManager] setDelegate:self];
    BOOL available = [[GameCenterManager sharedManager] checkGameCenterAvailability];
    if (available) {
        NSLog(@"available");
    } else {
        NSLog(@"not available");
    }
    
 //   [[GKLocalPlayer localPlayer] authenticateHandler];
    
    deviceScaler2 = 1;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        deviceScaler2 = 2;
    }
    
    self.skyBG.frame = CGRectMake(0, 0, skyWidth, screenHeight2);
    self.character.center = CGPointMake(-300, [self randomHeight]);
    self.enemyChopper.center = CGPointMake(screenWidth2 + 300, [self randomHeight]);
    self.missileImage.center = CGPointMake(screenWidth2 + 300, [self randomHeight]);
    self.atomImage.center = CGPointMake(screenWidth2 + 300, [self randomHeight]);
    self.truckImage.center = CGPointMake(screenWidth2 + 300, .93*screenHeight2);


}

-(void)viewDidAppear:(BOOL)animated
{
    timePassed2 = 0;

    NSNumber* sound = [[NSUserDefaults standardUserDefaults] objectForKey:@"soundOn"];
    BOOL soundOn = [sound boolValue];
    if(soundOn)
    {
        self.soundSwitch.on = true;
        
    } else {
        
        self.soundSwitch.on = false;
    }
    
    NSNumber* launched = [[NSUserDefaults standardUserDefaults] objectForKey:@"wasGameLaunched"];
    BOOL wasLaunched = [launched boolValue];
    
    if (!wasLaunched)
    {
     //   NSString *infoString = @"blah blah";
     //   [self showAlertWithTitle:@"Prepare for Lift Off" message:infoString];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:true] forKey:@"wasGameLaunched"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    NSNumber *currentHighScore = [[NSUserDefaults standardUserDefaults] objectForKey:@"highScore"];
    int currentHSInt = [currentHighScore intValue];
    self.highScoreLabel.text = [NSString stringWithFormat:@"High Score: %d", currentHSInt];
    
    self.gameTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(gameGuts) userInfo:nil repeats:YES];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [self.gameTimer invalidate];
}


-(void)gameGuts
{
    timePassed2 = timePassed2 + .05;
    
    self.enemyChopper.center = CGPointMake(self.enemyChopper.center.x - 5.0, self.enemyChopper.center.y);
    
    if(self.enemyChopper.center.x < -300)
    {
        self.enemyChopper.center = CGPointMake(screenWidth2 + 300, [self randomHeight]);
    }
    
    self.missileImage.center = CGPointMake(self.missileImage.center.x - 10.0, self.missileImage.center.y);
    
    if(self.missileImage.center.x < -300)
    {
        self.missileImage.center = CGPointMake(screenWidth2 + 300, [self randomHeight]);
    }
    
    self.atomImage.center = CGPointMake(self.atomImage.center.x - 1.0, self.atomImage.center.y);
    self.atomImage.transform = CGAffineTransformMakeRotation(4*timePassed2);
    
    if(self.atomImage.center.x < -300)
    {
        self.atomImage.center = CGPointMake(self.atomImage.center.x + 300, [self randomHeight]);
    }
    
    self.truckImage.center = CGPointMake(self.truckImage.center.x - 4.0, self.truckImage.center.y);
    
    if(self.truckImage.center.x < -300)
    {
        self.truckImage.center = CGPointMake(screenWidth2 + 300, .93*screenHeight2);
    }
    
    self.character.center = CGPointMake(self.character.center.x + 5.0, self.character.center.y);
    
    if(self.character.center.x > screenWidth2 + 300)
    {
        self.character.center = CGPointMake(-300, [self randomHeight]);
    }
}


-(int)randomHeight
{
    int minY = .4*screenHeight2;
    int maxY = .85*screenHeight2;;
    int rangeY = maxY - minY;
    return (arc4random() % rangeY) + minY;
}

-(int)randomWidth
{
    int minY = 0;
    int maxY = screenWidth2;
    int rangeY = maxY - minY;
    return (arc4random() % rangeY) + minY;
}


- (void)shoppingDone:(NSNotification *)notification
{
    NSLog(@"shopping done");
}

- (Shop *)ourNewShop {
    
    if (!_ourNewShop) {
        _ourNewShop = [[Shop alloc] init];
        _ourNewShop.delegate = self;
    }
    return _ourNewShop;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0: {
            [self.ourNewShop makeThePurchase];
            break;
            
        }
            
        case 1: {
            [self.ourNewShop restoreThePurchase];
            break;
            
        }
            
        default: {
            break;
        }
    }
}


# pragma mark - Game Center


- (void)gameCenterManager:(GameCenterManager *)manager availabilityChanged:(NSDictionary *)availabilityInformation {
    NSLog(@"GC Availabilty: %@", availabilityInformation);
    if ([[availabilityInformation objectForKey:@"status"] isEqualToString:@"GameCenter Available"]) {
        
        NSLog(@"Game Center is online, the current player is logged in, and this app is setup.");
        
    } else {
        
     //   NSLog(@"error here1");
    }
    
}

- (void)gameCenterManager:(GameCenterManager *)manager error:(NSError *)error {
    NSLog(@"GCM Error: %@", error);
}

- (void)gameCenterManager:(GameCenterManager *)manager reportedAchievement:(GKAchievement *)achievement withError:(NSError *)error {
    if (!error) {
        NSLog(@"GCM Reported Achievement: %@", achievement);
    } else {
        NSLog(@"GCM Error while reporting achievement: %@", error);
    }
}

- (void)gameCenterManager:(GameCenterManager *)manager reportedScore:(GKScore *)score withError:(NSError *)error {
    if (!error) {
        NSLog(@"GCM Reported Score: %@", score);
    } else {
        NSLog(@"GCM Error while reporting score: %@", error);
    }
}

- (void)gameCenterManager:(GameCenterManager *)manager didSaveScore:(GKScore *)score {
    NSLog(@"Saved GCM Score with value: %lld", score.value);
}

- (void)gameCenterManager:(GameCenterManager *)manager didSaveAchievement:(GKAchievement *)achievement {
    NSLog(@"Saved GCM Achievement: %@", achievement);
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
    if (gameCenterViewController.viewState == GKGameCenterViewControllerStateAchievements) {
        NSLog(@"Displayed GameCenter achievements.");
    } else if (gameCenterViewController.viewState == GKGameCenterViewControllerStateLeaderboards) {
        NSLog(@"Displayed GameCenter leaderboard.");
    } else {
        NSLog(@"Displayed GameCenter controller.");
    }
}

-(void) showLeaderboard {
    [[GameCenterManager sharedManager] presentLeaderboardsOnViewController:self];
}

- (void) loadChallenges {
    // This feature is only supported in iOS 6 and higher (don't worry - GC Manager will check for you and return NIL if it isn't available)
    [[GameCenterManager sharedManager] getChallengesWithCompletion:^(NSArray *challenges, NSError *error) {
        NSLog(@"GC Challenges: %@ | Error: %@", challenges, error);
    }];
}

- (void)gameCenterManager:(GameCenterManager *)manager authenticateUser:(UIViewController *)gameCenterLoginController {
    [self presentViewController:gameCenterLoginController animated:YES completion:^{
        NSLog(@"Finished Presenting Authentication Controller");
    }];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction)gameCenterPressed:(id)sender
{
    [[GameCenterManager sharedManager] presentLeaderboardsOnViewController:self];
}

- (IBAction)soundSwitchChanged:(id)sender {
    
    if(self.soundSwitch.on)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:true] forKey:@"soundOn"];
        [self.ambientPlayer play];
        
    } else {
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:false] forKey:@"soundOn"];
        [self.ambientPlayer pause];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)fullVersionPressed:(id)sender {
    
    NSLog(@"offer purchase");
    [self.ourNewShop validateProductIdentifiers];

}

-(void) showAlertWithTitle:(NSString*) title message:(NSString*) msg
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}


@end
