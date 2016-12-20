//
//  PlayViewController.m
//  Bowling
//
//  Created by Maurice on 11/16/16.
//  Copyright © 2016 Larry Feldman. All rights reserved.
//

#import "PlayViewController.h"

#define charSpeedScale 0.25
#define ammoSpeed 50.0
#define enemySpeed 5.0
#define missileSpeed 10
#define controlHeight 130.0
#define bottomAchieve 20000
#define skyWidth 10000
#define truckScore 250
#define atomScore 500
#define missileScore 1000
#define enemyChopperScore 500
#define levelDoneScore 10000
#define gameTime .05
#define offScreen -1000
#define numTrucks 10


@interface PlayViewController ()


- (IBAction)backPressed:(id)sender;

@property (strong, nonatomic) IBOutlet UIView *leftView;
@property (strong, nonatomic) IBOutlet UIImageView *ammoImage;
@property (strong, nonatomic) IBOutlet UIImageView *gateImage;
@property (strong, nonatomic) IBOutlet UIImageView *character;
@property (strong, nonatomic) IBOutlet UIImageView *skyBG;
@property (strong, nonatomic) IBOutlet UIImageView *finishLine;
@property (strong, nonatomic) IBOutlet UIImageView *bombImage;
@property (strong, nonatomic) IBOutlet UIImageView *enemyChopper;
@property (strong, nonatomic) IBOutlet UIImageView *missileImage;
@property (strong, nonatomic) IBOutlet UILabel *livesLabel;

@property (strong, nonatomic) UIImageView *fireChopper;
@property (strong, nonatomic) UIImageView *flameMissile;
@property (strong, nonatomic) UIImageView *flameEnemyChopper;

@property (strong, nonatomic) IBOutlet UILabel *scoreLabel;
@property (strong, nonatomic) IBOutlet UILabel *shieldLabel;

@property (strong, nonatomic) IBOutlet UILabel *fireballLabel;

@property (retain, nonatomic) AVAudioPlayer *bangplayer;
@property (retain, nonatomic) AVAudioPlayer *portalplayer;
@property (retain, nonatomic) AVAudioPlayer *atomPlayer;

@property (strong, nonatomic) NSTimer *gameTimer;
@property (strong, nonatomic) NSTimer *ammoTimer;
@property (strong, nonatomic) IBOutlet UIButton *playButton;

@property (strong, nonatomic) NSMutableArray *fireAnimation;
@property (strong, nonatomic) NSMutableArray *wallAnimation;
@property (strong, nonatomic) NSMutableArray *finishAnimation;
@property (strong, nonatomic) NSMutableArray *truckArray;
@property (strong, nonatomic) NSMutableArray *fireArray;
@property (strong, nonatomic) NSMutableArray *atomArray;


- (IBAction)shootPressed:(id)sender;
- (IBAction)bombPressed:(id)sender;
- (IBAction)shootReleased:(id)sender;


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
double timePassed;

int score;
int atomCount;
int deviceScaler;

int level;
int lives;


CGPoint missileVector;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSNumber* gameSaved = [[NSUserDefaults standardUserDefaults] objectForKey:@"gameSaved"];
    BOOL isGameSaved = [gameSaved boolValue];
    
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
    
    self.finishAnimation = [[NSMutableArray alloc] init];
    
    for (int i = 1; i <= 5 ; i++)
    {
        [self.finishAnimation addObject:[UIImage imageNamed:[NSString stringWithFormat:@"fractal%d", i]]];
    }
    
    // Explosion sound
    
    NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
    resourcePath = [resourcePath stringByAppendingString:@"/bang.mp3"];
    NSError* err;
    
    self.bangplayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:resourcePath] error:&err];
    
    if(err)
    {
        NSLog(@"Failed with reason: %@", [err localizedDescription]);
    }
    else
    {
        self.bangplayer.delegate = self;
        self.bangplayer.numberOfLoops = 0;
        self.bangplayer.currentTime = 0;
        self.bangplayer.volume = 1.0;
    }
    
    // Portal sound
    
    resourcePath = [[NSBundle mainBundle] resourcePath];
    resourcePath = [resourcePath stringByAppendingString:@"/portal.mp3"];
    
    self.portalplayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:resourcePath] error:&err];
    
    if(err)
    {
        NSLog(@"Failed with reason: %@", [err localizedDescription]);
    }
    else
    {
        self.portalplayer.delegate = self;
        self.portalplayer.numberOfLoops = 0;
        self.portalplayer.currentTime = 0;
        self.portalplayer.volume = 1.0;
    }
    
    // Whoosh sound
    
    resourcePath = [[NSBundle mainBundle] resourcePath];
    resourcePath = [resourcePath stringByAppendingString:@"/atom.mp3"];
    
    self.atomPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:resourcePath] error:&err];
    
    if(err)
    {
        NSLog(@"Failed with reason: %@", [err localizedDescription]);
    }
    else
    {
        self.atomPlayer.delegate = self;
        self.atomPlayer.numberOfLoops = 0;
        self.atomPlayer.currentTime = 0;
        self.atomPlayer.volume = 1.0;
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
    
    self.finishLine.animationImages = self.finishAnimation;
    self.finishLine.animationDuration = 1.0;
    self.finishLine.animationRepeatCount = 0;
    [self.finishLine startAnimating];
    
    if(isGameSaved)
    {
        [self restoreGame];
        
    } else {
        
        [self playButtonPressed:nil];

    }
}

-(void)restoreGame
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:false] forKey:@"gameSaved"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    NSNumber *scoreSaved = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedScore"];
    score = [scoreSaved intValue];

    NSNumber *levelSaved = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedLevel"];
    level = [levelSaved intValue];
    
    NSNumber *livesSaved = [[NSUserDefaults standardUserDefaults] objectForKey:@"savedLives"];
    lives = [livesSaved intValue];
    
    timePassed = 0;
    self.playButton.hidden = true;
    self.character.hidden = false;
    
    [self initLevel];
    
    self.gameTimer = [NSTimer scheduledTimerWithTimeInterval:gameTime target:self selector:@selector(gameGuts) userInfo:nil repeats:YES];
}

- (IBAction)playButtonPressed:(id)sender
{
    lives = 30;
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
    [self updateScore:0];
    self.shieldLabel.text = [NSString stringWithFormat:@"Level: %d", level];
    [self updateLives:0];
    self.character.center = CGPointMake(.25*screenWidth, (screenHeight - controlHeight)/2);
    self.ammoImage.center = CGPointMake(offScreen, offScreen);
    self.bombImage.center = CGPointMake(offScreen, offScreen);
    [self resetMissile];
    self.enemyChopper.center = CGPointMake(screenWidth + 300, [self randomHeight]);
    self.gateImage.frame = CGRectMake(skyWidth - 1.5*screenWidth, 0, 10, screenHeight - controlHeight);
    self.skyBG.frame = CGRectMake(0, 0, skyWidth, screenHeight - controlHeight);
    self.finishLine.frame = CGRectMake(skyWidth - screenWidth, screenHeight/2 - 100, 200, 200);
    
    self.finishLine.layer.cornerRadius =.5*self.finishLine.layer.frame.size.height;
    self.finishLine.layer.masksToBounds = YES;
    
    self.truckArray = [NSMutableArray new];
    self.fireArray = [NSMutableArray new];
    self.atomArray = [NSMutableArray new];
    
    int truckXDelta = skyWidth/numTrucks;
    
    for(int i = 1; i <= numTrucks; i++)
    {
        UIImageView *truckView = [[UIImageView alloc] initWithFrame:CGRectMake(i*truckXDelta, screenHeight - controlHeight - 75.0, 100,60)];
        truckView.image = [UIImage imageNamed:@"armyTruckLeft.png"];
        [self.truckArray addObject:truckView];
        
        UIImageView *fireView = [[UIImageView alloc] initWithFrame:CGRectMake(i*truckXDelta, screenHeight - controlHeight - 75.0, 100,60)];
        [self.fireArray addObject:fireView];
    }
    
    for(int i = 1; i < numTrucks; i++)
    {
        UIImageView *atomView = [[UIImageView alloc] initWithFrame:CGRectMake(i*truckXDelta + .5*screenWidth, [self randomHeight], 50, 50)];
        atomView.image = [UIImage imageNamed:@"atom.png"];
        [self.atomArray addObject:atomView];
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
    
    if (shootPressed || ammoInFlight)
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
    
    if(level >= 3)
    {
        [self moveEnemyChopper];
    }
    
    if([self trucksToRightOfChopper] >= 2)
    {
        [self fireMissile];
        
    } else {
        
        self.missileImage.center = CGPointMake(-offScreen, offScreen);
    }
    
    [self collisionBetweenMissileAndChopper];
    [self collisionBetweenAmmoAndEnemyChopper];
    [self collisionBetweenAmmoAndMissile];
    [self collisionBetweenCharAndChopper];
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
    
    self.character.center = CGPointMake(self.character.center.x, self.character.center.y + self.charVelocityY);
    self.skyBG.center = CGPointMake(self.skyBG.center.x - self.charVelocityX, self.skyBG.center.y);
    
    if(self.character.center.y >= .65*screenHeight)
    {
        self.character.center = CGPointMake(self.character.center.x, .65*screenHeight);
    }
    
    if(self.character.center.y < .1*screenHeight)
    {
        self.character.center = CGPointMake(self.character.center.x, .1*screenHeight);
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
    for(UIImageView *iv in self.atomArray)
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
        [self resetMissile];
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
                [self.bangplayer play];
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
    for(UIImageView *iv in self.atomArray)
    {
        if(!iv.hidden)
        {
            if(CGRectIntersectsRect(self.character.frame, iv.frame))
            {
                [self.atomPlayer play];
                [self updateScore:atomScore];
                atomCount++;
                self.fireballLabel.text = [NSString stringWithFormat:@"%d", atomCount];
                iv.hidden = true;
                if(atomCount >= numTrucks - 1)
                {
                    self.gateImage.center = CGPointMake(offScreen, offScreen);
                }
            }
        }
    }
}

-(void)collisionBetweenCharAndFence
{
    if(CGRectIntersectsRect(self.gateImage.frame, self.character.frame))
    {
        [self.bangplayer play];
        [self updateLives:-lives];
        self.fireChopper.animationImages = self.fireAnimation;
        self.fireChopper.animationDuration = 1.0;
        self.fireChopper.animationRepeatCount = 1;
        [self.fireChopper startAnimating];
        self.gateImage.frame = CGRectMake(skyWidth - 2*screenWidth, 0, 10, screenHeight - controlHeight);
        self.character.hidden = true;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self gameOver];
        });
    }
}


-(void)collisionBetweenMissileAndChopper
{
    if(CGRectIntersectsRect(self.missileImage.frame, self.character.frame))
    {
        [self.bangplayer play];
        [self updateLives:-1];
        [self resetMissile];
        shootPressed = false;
        self.fireChopper.animationImages = self.fireAnimation;
        self.fireChopper.animationDuration = 1.0;
        self.fireChopper.animationRepeatCount = 1;
        [self.fireChopper startAnimating];
        
        if(lives <= 0)
        {
              self.character.hidden = true;
             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
             [self gameOver];
             });
        }
    }
}

-(void)collisionBetweenCharAndChopper
{
    if(CGRectIntersectsRect(self.character.frame, self.enemyChopper.frame))
    {
        [self.bangplayer play];
        [self updateLives:-1];
        [self updateScore:enemyChopperScore];
        shootPressed = false;
        self.enemyChopper.center = CGPointMake(screenWidth + 300, [self randomHeight]);
        self.fireChopper.animationImages = self.fireAnimation;
        self.fireChopper.animationDuration = 1.0;
        self.fireChopper.animationRepeatCount = 1;
        [self.fireChopper startAnimating];
        
        if(lives <= 0)
        {
            self.character.hidden = true;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self gameOver];
            });
        }
    }
}


-(void)collisionBetweenAmmoAndMissile
{
    if(CGRectIntersectsRect(self.ammoImage.frame, self.missileImage.frame))
    {
        [self.bangplayer play];
        self.ammoImage.center = CGPointMake(offScreen, offScreen);
        [self resetMissile];
        ammoInFlight = false;
        [self updateScore:missileScore];
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
        [self.bangplayer play];
        self.enemyChopper.center = CGPointMake(screenWidth + 300, [self randomHeight]);
        self.ammoImage.center = CGPointMake(offScreen, offScreen);
        ammoInFlight = false;
        [self updateScore:enemyChopperScore];
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
        [self.bangplayer play];
        self.enemyChopper.center = CGPointMake(screenWidth + 300, [self randomHeight]);
        self.bombImage.center = CGPointMake(offScreen, offScreen);
        bombPressed = false;
        bombInFlight = false;
        [self updateScore:enemyChopperScore];
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
        [self.bangplayer play];
        self.bombImage.center = CGPointMake(offScreen, offScreen);
        [self resetMissile];
        bombPressed = false;
        bombInFlight = false;
        [self updateScore:missileScore];
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
        [self.portalplayer play];
        [self updateLives:1];
        [self updateScore:levelDoneScore];
        [self newLevel];
    }
}

-(void)resetMissile
{
    self.missileImage.center = CGPointMake(screenWidth + 500, [self randomHeight]);
}


-(void)gameOver
{
    [self.gameTimer invalidate];
    [self highScores];
    [self resetImages];
    
    if(soundIsOn)
    {
       // [self.portalplayer play];
    }
    
    self.playButton.hidden = false;
    self.character.hidden = true;
    
}

-(void)updateScore:(int)points
{
    score = score + points;
    self.scoreLabel.text = [NSString stringWithFormat:@"Score: %d", score];
}

-(void)updateLives:(int)life
{
    lives = lives + life;
    self.livesLabel.text = [NSString stringWithFormat:@"%d", lives];
}

-(void)resetImages
{
    for(UIImageView *iv in self.truckArray)
    {
        [iv removeFromSuperview];
    }
    
    for(UIImageView *iv in self.atomArray)
    {
        [iv removeFromSuperview];
    }
    
    self.gateImage.center = CGPointMake(offScreen - 1000, offScreen);
    self.missileImage.center = CGPointMake(offScreen - 2000, offScreen);
    self.ammoImage.center = CGPointMake(offScreen - 3000, offScreen);
    self.bombImage.center = CGPointMake(offScreen - 4000, offScreen);
    self.enemyChopper.center = CGPointMake(offScreen - 5000, offScreen);
    self.finishLine.center = CGPointMake(offScreen - 6000, offScreen);
    self.character.center = CGPointMake(offScreen - 7000, offScreen);

}


-(int)randomHeight
{
    int minY = .1*screenHeight;
    int maxY = .65*screenHeight;;
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

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"What now Ace?" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *home = [UIAlertAction actionWithTitle:@"Go Home" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
    {
       [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    UIAlertAction *save = [UIAlertAction actionWithTitle:@"Save Game" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
                           {
                               [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:true] forKey:@"gameSaved"];
                               [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:score] forKey:@"savedScore"];
                               
                               [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:level] forKey:@"savedLevel"];
                               
                                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:lives] forKey:@"savedLives"];
                               
                               [[NSUserDefaults standardUserDefaults] synchronize];

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
    [alert addAction:save];
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

- (IBAction)shootReleased:(id)sender
{
    shootPressed = false;
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
      //  shootPressed = false;
    }
}

-(void)shootGunLeft
{
    self.ammoImage.center = CGPointMake(self.ammoImage.center.x - ammoSpeed - self.charVelocityX, self.ammoImage.center.y);
    
    if(self.ammoImage.center.x < 0)
    {
        self.ammoImage.center = CGPointMake(offScreen, offScreen);
        ammoInFlight = false;
      //  shootPressed = false;
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
