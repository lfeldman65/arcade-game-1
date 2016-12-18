//
//  PlayViewController.m
//  Bowling
//
//  Created by Maurice on 11/16/16.
//  Copyright © 2016 Larry Feldman. All rights reserved.
//

#import "PlayViewController.h"

#define charSpeedScale 0.3
#define ammoSpeed 40.0
#define enemySpeed 5.0
#define missileSpeed 10
#define controlHeight 150.0
#define bottomAchieve 20000
#define skyWidth 7000
#define truckScore 250
#define atomScore 500
#define missileScore 1000
#define enemyChopperScore 500
#define gameTime .05
#define offScreen -1000


@interface PlayViewController ()


- (IBAction)backPressed:(id)sender;

@property (strong, nonatomic) IBOutlet UIView *leftView;
@property (strong, nonatomic) IBOutlet UIImageView *ammoImage;
@property (strong, nonatomic) IBOutlet UIImageView *gateImage;

@property (strong, nonatomic) IBOutlet UIImageView *character;
@property (strong, nonatomic) UIImageView *fireChopper;
@property (strong, nonatomic) UIImageView *flameMissile;
@property (strong, nonatomic) UIImageView *flameEnemyChopper;

@property (strong, nonatomic) IBOutlet UILabel *scoreLabel;
@property (strong, nonatomic) IBOutlet UILabel *shieldLabel;
@property (strong, nonatomic) IBOutlet UIImageView *finishLine;

@property (strong, nonatomic) IBOutlet UIImageView *bombImage;
@property (strong, nonatomic) IBOutlet UIImageView *enemyChopper;

@property (strong, nonatomic) IBOutlet UILabel *fireballLabel;
@property (strong, nonatomic) IBOutlet UIImageView *skyBG;

@property (retain, nonatomic) AVAudioPlayer *ammoPlayer;
@property (retain, nonatomic) AVAudioPlayer *overPlayer;
@property (retain, nonatomic) AVAudioPlayer *whooshPlayer;

@property (strong, nonatomic) NSTimer *gameTimer;
@property (strong, nonatomic) NSTimer *ammoTimer;
@property (strong, nonatomic) IBOutlet UIButton *playButton;

@property (strong, nonatomic) NSMutableArray *fireAnimation;
@property (strong, nonatomic) NSMutableArray *wallAnimation;
@property (strong, nonatomic) NSMutableArray *truckArray;
@property (strong, nonatomic) NSMutableArray *fireArray;
@property (strong, nonatomic) NSMutableArray *padArray;
@property (strong, nonatomic) IBOutlet UIImageView *missileImage;


- (IBAction)shootPressed:(id)sender;
- (IBAction)bombPressed:(id)sender;


@property (nonatomic) float charVelocityX;
@property (nonatomic) float charVelocityY;
@property (nonatomic) float ammoVelocityX;
@property (nonatomic) float ammoVelocityY;
@property (nonatomic) float bombVelocityX;
@property (nonatomic) float bombVelocityY;


- (IBAction)playButtonPressed:(id)sender;

@end

@implementation PlayViewController

BOOL ammoInFlight;
BOOL bombInFlight;
BOOL missileInFlight;

BOOL bombPressed;
BOOL shootPressed;

BOOL lastFaceRight;
BOOL lastShootRight;

BOOL soundIsOn;

double screenWidth;
double screenHeight;
double charWidth;
double charHeight;
double ufoSpeed;
double timePassed;

int score;
int shield;
int atomCount;
int deviceScaler;

int level;

CGPoint missileVector;


- (void)viewDidLoad
{
    [super viewDidLoad];
    screenWidth = self.view.frame.size.width;
    screenHeight = self.view.frame.size.height;
    charWidth = self.character.frame.size.width;
    charHeight = self.character.frame.size.height;
    self.character.hidden = true;
    self.playButton.hidden = true;
    self.leftView.multipleTouchEnabled = true;
    self.view.multipleTouchEnabled = true;
    NSNumber* soundOn = [[NSUserDefaults standardUserDefaults] objectForKey:@"soundOn"];
    soundIsOn = [soundOn boolValue];
    
    self.fireAnimation = [[NSMutableArray alloc] init];
    
    for (int i = 1; i <= 17 ; i++)
    {
        [self.fireAnimation addObject:[UIImage imageNamed:[NSString stringWithFormat:@"fire%d", i]]];
    }
    
    self.wallAnimation = [[NSMutableArray alloc] init];
    
    for (int i = 1; i <= 3 ; i++)
    {
        [self.wallAnimation addObject:[UIImage imageNamed:[NSString stringWithFormat:@"barrier%d", i]]];
    }
    
    // Ammo sound
    
    NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
    resourcePath = [resourcePath stringByAppendingString:@"/Cosmic.mp3"];
    NSError* err;
    
    self.ammoPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:resourcePath] error:&err];
    
    if(err)
    {
        NSLog(@"Failed with reason: %@", [err localizedDescription]);
    }
    else
    {
        self.ammoPlayer.delegate = self;
        self.ammoPlayer.numberOfLoops = 0;
        self.ammoPlayer.currentTime = 0;
        self.ammoPlayer.volume = 1.0;
    }
    
    // Game Over sound
    
    resourcePath = [[NSBundle mainBundle] resourcePath];
    resourcePath = [resourcePath stringByAppendingString:@"/gameOver.mp3"];
    
    self.overPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:resourcePath] error:&err];
    
    if(err)
    {
        NSLog(@"Failed with reason: %@", [err localizedDescription]);
    }
    else
    {
        self.overPlayer.delegate = self;
        self.overPlayer.numberOfLoops = 0;
        self.overPlayer.currentTime = 0;
        self.overPlayer.volume = 1.0;
    }
    
    // Whoosh sound
    
    resourcePath = [[NSBundle mainBundle] resourcePath];
    resourcePath = [resourcePath stringByAppendingString:@"/whoosh.mp3"];
    
    self.whooshPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:resourcePath] error:&err];
    
    if(err)
    {
        NSLog(@"Failed with reason: %@", [err localizedDescription]);
    }
    else
    {
        self.whooshPlayer.delegate = self;
        self.whooshPlayer.numberOfLoops = 0;
        self.whooshPlayer.currentTime = 0;
        self.whooshPlayer.volume = 1.0;
    }
    
    deviceScaler = 1;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        deviceScaler = 2;
    }
    
    self.gateImage.animationImages = self.wallAnimation;
    self.gateImage.animationDuration = 1.0;
    self.gateImage.animationRepeatCount = 0;
    [self.gateImage startAnimating];
    
    [self playButtonPressed:nil];
}


- (IBAction)playButtonPressed:(id)sender
{
    level = 1;
    score = 0;
    timePassed = 0;
    self.playButton.hidden = true;
    self.character.hidden = false;
    
    [self initLevel];
    
    self.gameTimer = [NSTimer scheduledTimerWithTimeInterval:gameTime target:self selector:@selector(gameGuts) userInfo:nil repeats:YES];
}

-(void)initLevel
{
    atomCount = 0;
    self.scoreLabel.text = [NSString stringWithFormat:@"Score: %d", score];
    self.shieldLabel.text = [NSString stringWithFormat:@"Level: %d", level];
    self.character.center = CGPointMake(.2*screenWidth, (screenHeight - controlHeight)/2);
    self.ammoImage.center = CGPointMake(offScreen, offScreen);
    self.bombImage.center = CGPointMake(offScreen, offScreen);
    self.missileImage.center = CGPointMake(screenWidth + 300, [self randomHeight]);
    self.enemyChopper.center = CGPointMake(screenWidth + 300, [self randomHeight]);
    self.gateImage.frame = CGRectMake(skyWidth - 2*screenWidth, 0, 10, screenHeight - controlHeight);
    self.skyBG.frame = CGRectMake(0, 0, skyWidth, screenHeight - controlHeight);
    self.finishLine.frame = CGRectMake(skyWidth - screenWidth, screenHeight/2, 50, 50);
    
    self.truckArray = [NSMutableArray new];
    self.fireArray = [NSMutableArray new];
    self.padArray = [NSMutableArray new];
    
    int truckXDelta = 1.5*screenWidth;
    
    for(int i = 1; i < 11; i++)
    {
        UIImageView *truckView = [[UIImageView alloc] initWithFrame:CGRectMake(i*truckXDelta, screenHeight - controlHeight - 75.0, 100,60)];
        truckView.image = [UIImage imageNamed:@"armyTruckLeft.png"];
        [self.truckArray addObject:truckView];
        
        UIImageView *fireView = [[UIImageView alloc] initWithFrame:CGRectMake(i*truckXDelta, screenHeight - controlHeight - 75.0, 100,60)];
        [self.fireArray addObject:fireView];
    }
    
    for(int i = 1; i < 10; i++)
    {
        UIImageView *padView = [[UIImageView alloc] initWithFrame:CGRectMake(i*truckXDelta + .5*screenWidth, [self randomHeight], 50, 50)];
        padView.image = [UIImage imageNamed:@"atom.png"];
        [self.padArray addObject:padView];
    }
    
    self.fireChopper = [[UIImageView alloc] initWithFrame:CGRectMake(self.character.center.x, self.character.center.y, 80.0, 80.0)];
    [self.view addSubview:self.fireChopper];
    
    self.flameMissile = [[UIImageView alloc] initWithFrame:CGRectMake(self.missileImage.center.x, self.missileImage.center.y, 80.0, 80.0)];
    [self.view addSubview:self.flameMissile];
    
    self.flameEnemyChopper = [[UIImageView alloc] initWithFrame:CGRectMake(self.enemyChopper.center.x, self.enemyChopper.center.y, 80.0, 80.0)];
    [self.view addSubview:self.flameEnemyChopper];
    
    ammoInFlight = false;
    bombInFlight = false;
    missileInFlight = false;
    lastFaceRight = true;
    self.charVelocityX = 0;
    self.charVelocityY = 0;
    
    bombPressed = false;
    shootPressed= false;
    
}

-(void)gameGuts
{
    self.gateImage.center = CGPointMake(self.gateImage.center.x - self.charVelocityX, self.gateImage.center.y);
    self.finishLine.center = CGPointMake(self.finishLine.center.x - self.charVelocityX, self.finishLine.center.y);

    timePassed = timePassed + gameTime;
    
    if ([LeftViewController isInLeft])
    {
        lastFaceRight = true;
        
        if([LeftViewController findDistanceX] < 0) {
            
            lastFaceRight = false;
        }
        
        [self moveChopper];
        
    } else {
        
        self.charVelocityX = 0;
        self.charVelocityY = 0;
        
    }
    
    if(bombPressed)
    {
        if(bombInFlight)
        {
            [self moveBomb];
            
        } else {
            
            NSLog(@"here");
            self.bombImage.center = CGPointMake(self.character.center.x, self.character.center.y + 10.0);
            self.bombVelocityX = self.charVelocityX;
            self.bombVelocityY = 2.0;
            bombInFlight = true;
        }
    }
    
    if (shootPressed)
    {
        if(ammoInFlight)
        {
            if(lastShootRight)
            {
                self.ammoImage.image = [UIImage imageNamed:@"ammoRight.png"];
                [self shootGunRight];
                
            } else {
                
                self.ammoImage.image = [UIImage imageNamed:@"ammoLeft.png"];
                [self shootGunLeft];
            }
            
        } else {
            
            if(lastFaceRight)
            {
                self.ammoImage.center = CGPointMake(self.character.center.x + 10.0, self.character.center.y + 5.0);
                ammoInFlight = true;
                lastShootRight = true;
                
            } else {
                
                self.ammoImage.center = CGPointMake(self.character.center.x - 10.0, self.character.center.y + 5.0);
                ammoInFlight = true;
                lastShootRight = false;
            }
    }
}
    
    [self moveTrucks];
    [self moveAtoms];

    [self collisionBetweenBombAndTruck];
    
    if(level >= 1)
    {
        [self moveEnemyChopper];
    }
    
    if([self trucksToRightOfChopper] >= 2)
    {
        [self fireMissile];
    }
    
  //  [self collisionBetweenMissileAndChopper];
    [self collisionBetweenAmmoAndEnemyChopper];
    [self collisionBetweenAmmoAndMissile];
 //   [self collisionBetweenCharAndChopper];
    [self collisionBetweenBombAndEnemyChopper];
    [self collisionBetweenBombAndMissile];
    [self collisionBetweenCharAndAtom];
    [self collisionBetweenCharAndFence];
    [self collisionBetweenCharAndFinish];



}


-(void)moveChopper
{
    self.charVelocityX = deviceScaler*charSpeedScale*[LeftViewController findDistanceX];
    self.charVelocityY = deviceScaler*charSpeedScale*[LeftViewController findDistanceY];
    
    self.fireChopper.center = CGPointMake(self.character.center.x, self.character.center.y);
    
    self.character.image = [UIImage imageNamed:@"chopperRight.png"];
    
    if(!lastFaceRight)
    {
        self.character.image = [UIImage imageNamed:@"chopperLeft.png"];
    }
    
    if(self.character.center.y >= screenHeight - controlHeight - self.character.frame.size.height)
    {
        self.charVelocityX = 0;   // landing on ground
        self.character.center = CGPointMake(self.character.center.x, screenHeight - controlHeight - self.character.frame.size.height);
    }
    
    self.character.center = CGPointMake(self.character.center.x, self.character.center.y + self.charVelocityY);
    self.skyBG.center = CGPointMake(self.skyBG.center.x - self.charVelocityX, self.skyBG.center.y);
    
    if(self.character.center.y < 2*self.character.frame.size.height)
    {
        self.character.center = CGPointMake(self.character.center.x, 2*self.character.frame.size.height);
    }
    
    if(self.character.center.y >= screenHeight - controlHeight - 35)
    {
      //  self.character.center = CGPointMake(self.character.center.x, screenHeight - controlHeight - 35);
    }
    
    if(self.skyBG.center.x >= skyWidth/2)
    {
        self.skyBG.center = CGPointMake(skyWidth/2, self.skyBG.center.y);
        self.charVelocityX = 0;
    }
    
    if(self.skyBG.center.x <= -skyWidth/2 + screenWidth)
    {
        self.skyBG.center = CGPointMake(-skyWidth/2 + screenWidth, self.skyBG.center.y);
        self.charVelocityX = 0;
    }
}


-(void)moveTrucks
{
    for(UIImageView *iv in self.truckArray)
    {
        iv.center =  CGPointMake(iv.center.x - self.charVelocityX, iv.center.y);
        [self.view addSubview:iv];
    }
    
    for(UIImageView *iv in self.fireArray)
    {
        iv.center =  CGPointMake(iv.center.x - self.charVelocityX, iv.center.y);
        [self.view addSubview:iv];
    }
}

-(void)moveAtoms
{
    for(UIImageView *iv in self.padArray)
    {
        iv.center =  CGPointMake(iv.center.x - self.charVelocityX, iv.center.y);
        [self.view addSubview:iv];
    }
}

-(void)moveEnemyChopper
{
    self.enemyChopper.center = CGPointMake(self.enemyChopper.center.x - self.charVelocityX - deviceScaler*enemySpeed, self.enemyChopper.center.y);
    
    if(self.enemyChopper.center.x < -100)
    {
        self.enemyChopper.center = CGPointMake(screenWidth + 300, [self randomHeight]);
    }
    
    self.flameEnemyChopper.center = CGPointMake(self.enemyChopper.center.x, self.enemyChopper.center.y);
}

-(void)fireMissile
{
    self.missileImage.center = CGPointMake(self.missileImage.center.x - self.charVelocityX - deviceScaler*missileSpeed, self.missileImage.center.y);
    
    if(self.missileImage.center.x < -100)
    {
        self.missileImage.center = CGPointMake(screenWidth + 300, [self randomHeight]);
    }
    
    self.flameMissile.center = CGPointMake(self.missileImage.center.x, self.missileImage.center.y);
}


-(int)trucksToRightOfChopper
{
    int num = 0;
    
    for(UIImageView *iv in self.truckArray)
    {
        if(!iv.hidden && (iv.center.x > self.character.center.x))
        {
            num++;
        }
    }
    return num;
}


-(void)collisionBetweenBombAndTruck
{
    int i = 0;
    
    for(UIImageView *iv in self.truckArray)
    {
        if(!iv.hidden)
        {
            if(CGRectIntersectsRect(self.bombImage.frame, iv.frame))
            {
                [self updateScore:truckScore];
                self.bombImage.center = CGPointMake(offScreen, offScreen);
                bombPressed = false;
                bombInFlight = false;
                UIImageView *hitFire = [self.fireArray objectAtIndex:i];
                iv.hidden = true;
                hitFire.animationImages = self.fireAnimation;
                hitFire.animationDuration = 1.0;
                hitFire.animationRepeatCount = 1;
                [hitFire startAnimating];
            }
        }
        i++;
    }
}


-(void)collisionBetweenCharAndAtom
{
    for(UIImageView *iv in self.padArray)
    {
        if(!iv.hidden)
        {
            if(CGRectIntersectsRect(self.character.frame, iv.frame))
            {
                atomCount++;
                self.fireballLabel.text = [NSString stringWithFormat:@"%d", atomCount];
                iv.hidden = true;
                if(atomCount >= 1)
                {
                    self.gateImage.center = CGPointMake(-offScreen, offScreen);
                }
            }
        }
    }
}

-(void)collisionBetweenCharAndFence
{
    if(CGRectIntersectsRect(self.gateImage.frame, self.character.frame))
    {
        self.fireChopper.animationImages = self.fireAnimation;
        self.fireChopper.animationDuration = 1.0;
        self.fireChopper.animationRepeatCount = 1;
        [self.fireChopper startAnimating];
        self.character.hidden = true;
        self.gateImage.frame = CGRectMake(skyWidth - 2*screenWidth, 0, 10, screenHeight - controlHeight);

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self gameOver];
        });
    }
}


-(void)collisionBetweenMissileAndChopper
{
    if(CGRectIntersectsRect(self.missileImage.frame, self.character.frame))
    {
        self.missileImage.center = CGPointMake(screenWidth + 300, [self randomHeight]);
        self.fireChopper.animationImages = self.fireAnimation;
        self.fireChopper.animationDuration = 1.0;
        self.fireChopper.animationRepeatCount = 1;
        [self.fireChopper startAnimating];
        self.character.hidden = true;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self gameOver];
        });
    }
}

-(void)collisionBetweenCharAndChopper
{
    if(CGRectIntersectsRect(self.character.frame, self.enemyChopper.frame))
    {
        [self updateScore:enemyChopperScore];
        self.enemyChopper.center = CGPointMake(screenWidth + 300, [self randomHeight]);
        self.fireChopper.animationImages = self.fireAnimation;
        self.fireChopper.animationDuration = 1.0;
        self.fireChopper.animationRepeatCount = 1;
        [self.fireChopper startAnimating];
        self.character.hidden = true;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self gameOver];
        });
    }
}


-(void)collisionBetweenAmmoAndMissile
{
    if(CGRectIntersectsRect(self.ammoImage.frame, self.missileImage.frame))
    {
        [self updateScore:missileScore];
        self.ammoImage.center = CGPointMake(offScreen, offScreen);
        ammoInFlight = false;
        shootPressed = false;
        self.missileImage.center = CGPointMake(screenWidth + 300, [self randomHeight]);
        self.flameMissile.animationImages = self.fireAnimation;
        self.flameMissile.animationDuration = 1.0;
        self.flameMissile.animationRepeatCount = 1;
        [self.flameMissile startAnimating];
    }
}

-(void)collisionBetweenAmmoAndEnemyChopper
{
    if(CGRectIntersectsRect(self.ammoImage.frame, self.enemyChopper.frame))
    {
        [self updateScore:enemyChopperScore];
        self.ammoImage.center = CGPointMake(offScreen, offScreen);
        ammoInFlight = false;
        shootPressed = false;
        self.enemyChopper.center = CGPointMake(screenWidth + 300, [self randomHeight]);
        self.flameEnemyChopper.animationImages = self.fireAnimation;
        self.flameEnemyChopper.animationDuration = 1.0;
        self.flameEnemyChopper.animationRepeatCount = 1;
        [self.flameEnemyChopper startAnimating];
    }
}

-(void)collisionBetweenBombAndEnemyChopper
{
    if(CGRectIntersectsRect(self.bombImage.frame, self.enemyChopper.frame))
    {
        [self updateScore:enemyChopperScore];
        self.bombImage.center = CGPointMake(offScreen, offScreen);
        bombPressed = false;
        bombInFlight = false;
        self.enemyChopper.center = CGPointMake(screenWidth + 300, [self randomHeight]);
        self.flameEnemyChopper.animationImages = self.fireAnimation;
        self.flameEnemyChopper.animationDuration = 1.0;
        self.flameEnemyChopper.animationRepeatCount = 1;
        [self.flameEnemyChopper startAnimating];
    }
}

-(void)collisionBetweenBombAndMissile
{
    if(CGRectIntersectsRect(self.bombImage.frame, self.missileImage.frame))
    {
        [self updateScore:missileScore];
        self.missileImage.center = CGPointMake(screenWidth + 300, [self randomHeight]);
        self.bombImage.center = CGPointMake(offScreen, offScreen);
        bombPressed = false;
        bombInFlight = false;
        self.flameMissile.animationImages = self.fireAnimation;
        self.flameMissile.animationDuration = 1.0;
        self.flameMissile.animationRepeatCount = 1;
        [self.flameMissile startAnimating];
    }
}

-(void)collisionBetweenCharAndFinish
{
    if(CGRectIntersectsRect(self.character.frame, self.finishLine.frame))
    {
        [self newLevel];
    }
}


-(void)gameOver
{
    [self.gameTimer invalidate];
    [self highScores];
    [self resetImages];
    
    if(soundIsOn)
    {
        [self.overPlayer play];
    }
    
    self.playButton.hidden = false;
    self.character.hidden = true;
    
}

-(void)updateScore:(int)points
{
    score = score + points;
    self.scoreLabel.text = [NSString stringWithFormat:@"Score: %d", score];
}

-(void)resetImages
{
    for(UIImageView *iv in self.truckArray)
    {
        [iv removeFromSuperview];
    }
    
    for(UIImageView *iv in self.padArray)
    {
        [iv removeFromSuperview];
    }
    
    self.gateImage.center = CGPointMake(offScreen, offScreen);
    self.missileImage.center = CGPointMake(offScreen, offScreen);
    self.ammoImage.center = CGPointMake(offScreen, offScreen);
    self.bombImage.center = CGPointMake(offScreen, offScreen);
    self.enemyChopper.center = CGPointMake(offScreen, offScreen);
    self.finishLine.center = CGPointMake(offScreen, offScreen);
}


-(int)randomHeight
{
    int minY = .1*screenHeight;
    int maxY = .7*screenHeight;;
    int range = maxY - minY;
    return (arc4random() % range) + minY;
  //  return (screenHeight - controlHeight)/2;
}

-(int)randomWidth
{
    int minX = 0;
    int maxX = screenWidth;
    int range = maxX - minX;
    return (arc4random() % range) + minX;
}

- (IBAction)backPressed:(id)sender
{
    [self.gameTimer invalidate];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"What do you want to do, Space Cowboy?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *home = [UIAlertAction actionWithTitle:@"Go Home" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
    {
       [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    UIAlertAction *resume = [UIAlertAction actionWithTitle:@"Resume" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
    {
        self.gameTimer = [NSTimer scheduledTimerWithTimeInterval:gameTime target:self selector:@selector(gameGuts) userInfo:nil repeats:YES];
    }];
    
    UIAlertAction *startOver = [UIAlertAction actionWithTitle:@"Start Over" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
    {
        [self playButtonPressed:nil];
    }];
    
    [alert addAction:home];
    [alert addAction:resume];
    [alert addAction:startOver];

    [self presentViewController:alert animated:YES completion:nil];
}

-(void)highScores
{
    NSNumber *currentHighScore = [[NSUserDefaults standardUserDefaults] objectForKey:@"highScore"];
    int currentHSInt = [currentHighScore intValue];
    
    if(score > currentHSInt)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:score] forKey:@"highScore"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[GameCenterManager sharedManager] saveAndReportScore:score leaderboard:@"com.lfeldman.ufo.score1" sortOrder:GameCenterSortOrderHighToLow];
    }
    
    if(score >= 3*bottomAchieve)
    {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"com.lfeldman.ufo.achievement3" percentComplete:100.00 shouldDisplayNotification:true];
        
    } else if (score >= 2*bottomAchieve)
        
    {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"com.lfeldman.ufo.achievement2" percentComplete:100.00 shouldDisplayNotification:true];
    }
    
    else if (score >= bottomAchieve)
        
    {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"com.lfeldman.ufo.achievement1" percentComplete:100.00 shouldDisplayNotification:true];
    }
}

-(double)magnitude:(CGPoint)point
{
    double mag = sqrt(point.x*point.x + point.y*point.y);
    if (mag == 0)
    {
        mag = .001;
    }
    return mag;
}


- (IBAction)shootPressed:(id)sender
{
    shootPressed = true;
}

- (IBAction)bombPressed:(id)sender
{
    bombPressed = true;
}

-(void)moveBomb
{
    self.bombVelocityY = self.bombVelocityY + 1.0;
    self.bombImage.center = CGPointMake(self.bombImage.center.x + self.bombVelocityX - self.charVelocityX, self.bombImage.center.y + self.bombVelocityY);
    
    if(self.bombImage.center.y > screenHeight - controlHeight)
    {
        self.bombImage.center = CGPointMake(offScreen, offScreen);
        bombInFlight = false;
        bombPressed = false;
    }
}

-(void)shootGunRight
{
    self.ammoImage.center = CGPointMake(self.ammoImage.center.x + ammoSpeed - self.charVelocityX, self.ammoImage.center.y);
    
    if(self.ammoImage.center.x > screenWidth)
    {
        self.ammoImage.center = CGPointMake(offScreen, offScreen);
        ammoInFlight = false;
        shootPressed = false;
    }
}

-(void)shootGunLeft
{
    self.ammoImage.center = CGPointMake(self.ammoImage.center.x - ammoSpeed - self.charVelocityX, self.ammoImage.center.y);
    
    if(self.ammoImage.center.x < 0)
    {
        self.ammoImage.center = CGPointMake(offScreen, offScreen);
        ammoInFlight = false;
        shootPressed = false;
    }
}

-(void)newLevel
{
    level++;
    [self resetImages];
    [self initLevel];

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}




@end
