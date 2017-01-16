//
//  PlayViewController.m
//  Bowling
//
//  Created by Maurice on 11/16/16.
//  Copyright © 2016 Larry Feldman. All rights reserved.
//

#import "PlayViewController.h"

#define charSpeedScale 0.25
#define ammoSpeed 60.0
#define enemyChopperSpeed 5.0
#define jetSpeed 9.0
#define missileSpeed 10.0
#define controlHeight 130.0
#define bottomAchieve 30000
#define skyWidth 10000
#define truckScore 250
#define atomScore 500
#define missileScore 2000
#define parachuteScore 100
#define enemyChopperScore 500
#define jetScore 1000
#define levelDoneScore 10000
#define gameTime .05
#define offScreen -1000
#define numTrucks 10
#define initialLives 3


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
@property (strong, nonatomic) IBOutlet UIImageView *jet;

@property (strong, nonatomic) IBOutlet UILabel *livesLabel;
@property (strong, nonatomic) IBOutlet UILabel *wallLabel;
@property (strong, nonatomic) IBOutlet UILabel *portalLabel;
@property (strong, nonatomic) IBOutlet UILabel *atomLabel;

@property (strong, nonatomic) UIImageView *fireChopper;
@property (strong, nonatomic) UIImageView *flameMissile;
@property (strong, nonatomic) UIImageView *flameEnemyChopper;
@property (strong, nonatomic) UIImageView *flameJet;
@property (strong, nonatomic) UIImageView *hitFire;

@property (strong, nonatomic) IBOutlet UILabel *scoreLabel;
@property (strong, nonatomic) IBOutlet UILabel *shieldLabel;

@property (strong, nonatomic) IBOutlet UILabel *fireballLabel;

@property (retain, nonatomic) AVAudioPlayer *bangplayer;
@property (retain, nonatomic) AVAudioPlayer *portalplayer;
@property (retain, nonatomic) AVAudioPlayer *atomPlayer;
@property (retain, nonatomic) AVAudioPlayer *endPlayer;
@property (retain, nonatomic) AVAudioPlayer *shootingPlayer;

@property (strong, nonatomic) NSTimer *gameTimer;
@property (strong, nonatomic) NSTimer *ammoTimer;
@property (strong, nonatomic) IBOutlet UIButton *playButton;

@property (strong, nonatomic) NSMutableArray *fireAnimation;
@property (strong, nonatomic) NSMutableArray *wallAnimation;
@property (strong, nonatomic) NSMutableArray *finishAnimation;
@property (strong, nonatomic) NSMutableArray *chopAnimation;
@property (strong, nonatomic) NSMutableArray *truckArray;
@property (strong, nonatomic) NSMutableArray *fireArray;
@property (strong, nonatomic) NSMutableArray *atomArray;
@property (strong, nonatomic) IBOutlet UIImageView *parachuteImage;


- (IBAction)shootPressed:(id)sender;
- (IBAction)bombPressed:(id)sender;
- (IBAction)shootReleased:(id)sender;


@property (nonatomic) float charVelocityX;
@property (nonatomic) float charVelocityY;
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
    
    self.chopAnimation = [[NSMutableArray alloc] init];
    
    for (int i = 1; i <= 2 ; i++)
    {
        [self.chopAnimation addObject:[UIImage imageNamed:[NSString stringWithFormat:@"chop%d", i]]];
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
    
    // Game over sound
    
    resourcePath = [[NSBundle mainBundle] resourcePath];
    resourcePath = [resourcePath stringByAppendingString:@"/theEnd.mp3"];
    
    self.endPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:resourcePath] error:&err];
    
    if(err)
    {
        NSLog(@"Failed with reason: %@", [err localizedDescription]);
    }
    else
    {
        self.endPlayer.delegate = self;
        self.endPlayer.numberOfLoops = 0;
        self.endPlayer.currentTime = 0;
        self.endPlayer.volume = 1.0;
    }
    
    // Atom Sound
    
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
    
    // Shooting Sound
    
    resourcePath = [[NSBundle mainBundle] resourcePath];
    resourcePath = [resourcePath stringByAppendingString:@"/shooting2.mp3"];
    
    self.shootingPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:resourcePath] error:&err];
    
    if(err)
    {
        NSLog(@"Failed with reason: %@", [err localizedDescription]);
    }
    else
    {
        self.shootingPlayer.delegate = self;
        self.shootingPlayer.numberOfLoops = -1;
        self.shootingPlayer.currentTime = 0;
        self.shootingPlayer.volume = 1.0;
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
    self.finishLine.animationDuration = 0.5;
    self.finishLine.animationRepeatCount = 0;
    [self.finishLine startAnimating];
    
    self.enemyChopper.animationImages = self.chopAnimation;
    self.enemyChopper.animationDuration = 0.2;
    self.enemyChopper.animationRepeatCount = 0;
    [self.enemyChopper startAnimating];
    
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
    lives = initialLives;
    level = 1;
    score = 0;
    timePassed = 0;
    self.playButton.hidden = true;
    self.character.hidden = false;
    self.wallLabel.hidden = false;
    self.portalLabel.hidden = false;
    lastFaceRight = true;
    lastShootRight = true;
    bombPressed = false;
    shootPressed= false;
    
    [self resetImages];
    [self initLevel];
    
    self.gameTimer = [NSTimer scheduledTimerWithTimeInterval:gameTime target:self selector:@selector(gameGuts) userInfo:nil repeats:YES];
}

-(void)initLevel
{
    self.character.image = [UIImage imageNamed:@"chopperRight2.png"];
    
    if(level > 1)
    {
        self.wallLabel.hidden = true;
        self.portalLabel.hidden = true;
    }
    
    atomCount = 0;
    [self updateScore:0];
    self.shieldLabel.text = [NSString stringWithFormat:@"Level: %d", level];
    [self updateLives:0];
    self.character.center = CGPointMake(.25*screenWidth, (screenHeight - controlHeight)/2);
    self.ammoImage.center = CGPointMake(offScreen, offScreen);
    self.bombImage.center = CGPointMake(offScreen, offScreen);
    [self resetMissile];
    self.enemyChopper.center = CGPointMake(screenWidth + 300, [self randomHeight]);
    self.jet.center = CGPointMake(screenWidth + 500, [self randomHeight]);
    self.gateImage.frame = CGRectMake(skyWidth*deviceScaler - 1.2*screenWidth, 0, 10, screenHeight - controlHeight);
    self.wallLabel.center = CGPointMake(self.gateImage.center.x - self.wallLabel.frame.size.width/2, self.gateImage.center.y);
    self.skyBG.frame = CGRectMake(0, 0, skyWidth*deviceScaler, screenHeight - controlHeight);
    self.finishLine.frame = CGRectMake(skyWidth*deviceScaler - screenWidth, screenHeight/2 - 100*deviceScaler, 150*deviceScaler, 150*deviceScaler);
    self.portalLabel.center = CGPointMake(self.finishLine.center.x, self.finishLine.center.y - self.finishLine.frame.size.height/2 - 15.0*deviceScaler);
    
    self.parachuteImage.center = CGPointMake(screenWidth, -100);

    self.finishLine.layer.cornerRadius =.5*self.finishLine.layer.frame.size.height;
    self.finishLine.layer.masksToBounds = YES;
    
    self.truckArray = [NSMutableArray new];
    self.fireArray = [NSMutableArray new];
    self.atomArray = [NSMutableArray new];
    
    int truckXDelta = (skyWidth*deviceScaler)/numTrucks - 50;
    
    for(int i = 1; i <= numTrucks; i++)
    {
        UIImageView *truckView = [[UIImageView alloc] initWithFrame:CGRectMake(i*truckXDelta, screenHeight - controlHeight - 75.0*deviceScaler, 100*deviceScaler,60*deviceScaler)];
        truckView.image = [UIImage imageNamed:@"armyTruckLeft.png"];
        [self.truckArray addObject:truckView];
        
        UIImageView *fireView = [[UIImageView alloc] initWithFrame:CGRectMake(i*truckXDelta, screenHeight - controlHeight - 75.0*deviceScaler, 100*deviceScaler, 60*deviceScaler)];
        [self.fireArray addObject:fireView];
    }
    
    for(int i = 1; i < numTrucks; i++)
    {
        UIImageView *atomView = [[UIImageView alloc] initWithFrame:CGRectMake(i*truckXDelta + .5*screenWidth, [self randomHeight], 45*deviceScaler, 50*deviceScaler)];
        atomView.image = [UIImage imageNamed:@"atom.png"];
        [self.atomArray addObject:atomView];
    }
    
    self.fireChopper = [[UIImageView alloc] initWithFrame:CGRectMake(self.character.center.x, self.character.center.y, 80.0*deviceScaler, 80.0*deviceScaler)];
    [self.view addSubview:self.fireChopper];
    
    self.flameMissile = [[UIImageView alloc] initWithFrame:CGRectMake(self.missileImage.center.x, self.missileImage.center.y, 80.0*deviceScaler, 80.0*deviceScaler)];
    [self.view addSubview:self.flameMissile];
    
    self.flameEnemyChopper = [[UIImageView alloc] initWithFrame:CGRectMake(self.enemyChopper.center.x, self.enemyChopper.center.y, 80.0*deviceScaler, 80.0*deviceScaler)];
    [self.view addSubview:self.flameEnemyChopper];
    
    self.flameJet = [[UIImageView alloc] initWithFrame:CGRectMake(self.jet.center.x, self.jet.center.y, 80.0*deviceScaler, 80.0*deviceScaler)];
    [self.view addSubview:self.flameJet];
    
    ammoInFlight = false;
    bombInFlight = false;
    missileInFlight = false;
    lastFaceRight = true;
    self.charVelocityX = 0;
    self.charVelocityY = 0;
}

-(void)gameGuts
{
    timePassed = timePassed + gameTime;
    
    if ([LeftViewController isInLeft])
    {
        lastFaceRight = true;
        
        if([LeftViewController findDistanceX] < 0)
        {
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
            self.bombImage.center = CGPointMake(self.character.center.x, self.character.center.y + 10.0*deviceScaler);
            self.bombVelocityX = self.charVelocityX;
            self.bombVelocityY = 2.0*deviceScaler;
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
                self.ammoImage.center = CGPointMake(self.character.center.x + 10.0*deviceScaler, self.character.center.y + 5.0*deviceScaler);
                ammoInFlight = true;
                lastShootRight = true;
                
            } else {
                
                self.ammoImage.center = CGPointMake(self.character.center.x - 10.0*deviceScaler, self.character.center.y + 5.0*deviceScaler);
                ammoInFlight = true;
                lastShootRight = false;
            }
        }
    }
    self.gateImage.center = CGPointMake(self.gateImage.center.x - self.charVelocityX, self.gateImage.center.y);
    self.wallLabel.center = CGPointMake(self.wallLabel.center.x - self.charVelocityX, self.wallLabel.center.y);
    self.portalLabel.center = CGPointMake(self.portalLabel.center.x - self.charVelocityX, self.portalLabel.center.y);
    self.finishLine.center = CGPointMake(self.finishLine.center.x - self.charVelocityX, self.finishLine.center.y);
    
    [self moveTrucks];
    [self moveAtoms];

    if([self trucksToRightOfChopper] >= 0)
    {
        [self fireMissile];
        
    } else {
        
        self.missileImage.center = CGPointMake(-offScreen, offScreen);
    }
    
    if(level >= 2)
    {
        [self moveEnemyChopper];
    }
    
    if(level >= 3)
    {
        [self moveParachute];
    }
    
    if(level >= 4)
    {
        [self moveJet];
    }

    [self collisionBetweenBombAndTruck];
    [self collisionBetweenCharAndChute];
    [self collisionBetweenMissileAndChopper];
    [self collisionBetweenAmmoAndEnemyChopper];
    [self collisionBetweenAmmoAndJet];
    [self collisionBetweenAmmoAndMissile];
    [self collisionBetweenCharAndChopper];
    [self collisionBetweenCharAndJet];
    [self collisionBetweenBombAndEnemyChopper];
    [self collisionBetweenBombAndJet];
    [self collisionBetweenBombAndMissile];
    [self collisionBetweenCharAndAtom];
    [self collisionBetweenCharAndFence];
    [self collisionBetweenCharAndFinish];
}


-(void)moveChopper
{
    self.charVelocityX = deviceScaler*charSpeedScale*[LeftViewController findDistanceX];
    self.charVelocityY = deviceScaler*charSpeedScale*[LeftViewController findDistanceY];
    
    self.character.image = [UIImage imageNamed:@"chopperRight2.png"];
    
    if(!lastFaceRight)
    {
        self.character.image = [UIImage imageNamed:@"chopperLeft2.png"];
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
    
    if(self.skyBG.center.x >= deviceScaler*skyWidth/2)
    {
        self.skyBG.center = CGPointMake(deviceScaler*skyWidth/2, self.skyBG.center.y);
        self.charVelocityX = 0;
    }
    
    if(self.skyBG.center.x <= -deviceScaler*skyWidth/2 + screenWidth)
    {
        self.skyBG.center = CGPointMake(-deviceScaler*skyWidth/2 + screenWidth, self.skyBG.center.y);
        self.charVelocityX = 0;
    }
}

-(void)moveParachute
{
    self.parachuteImage.center = CGPointMake(self.parachuteImage.center.x - self.charVelocityX, self.parachuteImage.center.y + 2.0*deviceScaler);
    
    if(self.parachuteImage.center.y > screenHeight - controlHeight + self.parachuteImage.frame.size.height/2)
    {
        self.parachuteImage.center = CGPointMake(screenWidth, -100.0);
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
        iv.transform = CGAffineTransformMakeRotation(4*timePassed);
        [self.view addSubview:iv];
    }
}

-(void)moveEnemyChopper
{
    self.enemyChopper.center = CGPointMake(self.enemyChopper.center.x - self.charVelocityX - deviceScaler*enemyChopperSpeed, self.enemyChopper.center.y);
    
    if(self.enemyChopper.center.x < -100)
    {
        self.enemyChopper.center = CGPointMake(screenWidth + 300, [self randomHeight]);
    }
}

-(void)moveJet
{
    self.jet.center = CGPointMake(self.jet.center.x - self.charVelocityX - deviceScaler*jetSpeed, self.jet.center.y);
    
    if(self.jet.center.x < -200)
    {
        self.jet.center = CGPointMake(screenWidth + 500, [self randomHeight]);
    }
}


-(void)fireMissile
{
    self.missileImage.center = CGPointMake(self.missileImage.center.x - self.charVelocityX - deviceScaler*missileSpeed, self.missileImage.center.y);
    
    if(self.missileImage.center.x < -100)
    {
        [self resetMissile];
    }
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
                if(soundIsOn)
                {
                    [self.bangplayer play];
                }
                [self updateScore:truckScore];
                self.bombImage.center = CGPointMake(offScreen, offScreen);
                bombPressed = false;
                bombInFlight = false;
                self.hitFire = [self.fireArray objectAtIndex:i];
                iv.hidden = true;
                self.hitFire.animationImages = self.fireAnimation;
                self.hitFire.animationDuration = 1.0;
                self.hitFire.animationRepeatCount = 1;
                [self.hitFire startAnimating];
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
                if(soundIsOn)
                {
                    [self.atomPlayer play];
                }
                [self updateScore:atomScore];
                atomCount++;
                self.fireballLabel.text = [NSString stringWithFormat:@"%d", atomCount];
                iv.hidden = true;
                if(atomCount >= numTrucks - 1)
                {
                    self.gateImage.center = CGPointMake(offScreen, offScreen);
                    self.wallLabel.hidden = true;
                }
            }
        }
    }
}

-(void)collisionBetweenCharAndFence
{
    if(CGRectIntersectsRect(self.gateImage.frame, self.character.frame))
    {
        if(soundIsOn)
        {
            [self.bangplayer play];
        }
        [self updateLives:-lives];
        self.fireChopper.center = CGPointMake(self.character.center.x, self.character.center.y);
        self.fireChopper.animationImages = self.fireAnimation;
        self.fireChopper.animationDuration = 1.0;
        self.fireChopper.animationRepeatCount = 1;
        [self.fireChopper startAnimating];
        self.gateImage.center = CGPointMake(offScreen, offScreen);
        self.character.center = CGPointMake(offScreen - 1000, offScreen - 1000);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self gameOver];
        });
    }
}


-(void)collisionBetweenCharAndChute
{
    if(CGRectIntersectsRect(self.character.frame, self.parachuteImage.frame))
    {
        [self updateScore:parachuteScore];
        self.parachuteImage.center = CGPointMake(screenWidth, -100);
    }
}



-(void)collisionBetweenMissileAndChopper
{
    if(CGRectIntersectsRect(self.missileImage.frame, self.character.frame))
    {
        if(soundIsOn)
        {
            [self.bangplayer play];
        }
        self.fireChopper.center = CGPointMake(self.character.center.x, self.character.center.y);
        [self updateLives:-1];
        [self updateScore:missileScore];
        [self resetMissile];

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
        if(soundIsOn)
        {
            [self.bangplayer play];
        }
        self.fireChopper.center = CGPointMake(self.character.center.x, self.character.center.y);
        [self updateLives:-1];
        [self updateScore:enemyChopperScore];
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

-(void)collisionBetweenCharAndJet
{
    if(CGRectIntersectsRect(self.character.frame, self.jet.frame))
    {
        if(soundIsOn)
        {
            [self.bangplayer play];
        }
        self.fireChopper.center = CGPointMake(self.character.center.x, self.character.center.y);
        self.flameJet.center = CGPointMake(self.jet.center.x, self.jet.center.y);
        [self updateLives:-1];
        [self updateScore:jetScore];
        self.jet.center = CGPointMake(screenWidth + 500, [self randomHeight]);
        self.flameJet.animationImages = self.fireAnimation;
        self.flameJet.animationDuration = 1.0;
        self.flameJet.animationRepeatCount = 1;
        [self.flameJet startAnimating];
        
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
        if(soundIsOn)
        {
            [self.bangplayer play];
        }
        self.flameMissile.center = CGPointMake(self.ammoImage.center.x, self.ammoImage.center.y);
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
        if(soundIsOn)
        {
            [self.bangplayer play];
        }
        self.flameEnemyChopper.center = CGPointMake(self.ammoImage.center.x, self.ammoImage.center.y);
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

-(void)collisionBetweenAmmoAndJet
{
    if(CGRectIntersectsRect(self.ammoImage.frame, self.jet.frame))
    {
        if(soundIsOn)
        {
            [self.bangplayer play];
        }
        self.flameJet.center = CGPointMake(self.ammoImage.center.x, self.ammoImage.center.y);
        self.jet.center = CGPointMake(screenWidth + 500, [self randomHeight]);
        self.ammoImage.center = CGPointMake(offScreen, offScreen);
        ammoInFlight = false;
        [self updateScore:jetScore];
        self.flameJet.animationImages = self.fireAnimation;
        self.flameJet.animationDuration = 1.0;
        self.flameJet.animationRepeatCount = 1;
        [self.flameJet startAnimating];
    }
}


-(void)collisionBetweenBombAndEnemyChopper
{
    if(CGRectIntersectsRect(self.bombImage.frame, self.enemyChopper.frame))
    {
        if(soundIsOn)
        {
            [self.bangplayer play];
        }
        self.flameEnemyChopper.center = CGPointMake(self.bombImage.center.x, self.bombImage.center.y);
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

-(void)collisionBetweenBombAndJet
{
    if(CGRectIntersectsRect(self.bombImage.frame, self.jet.frame))
    {
        if(soundIsOn)
        {
            [self.bangplayer play];
        }
        self.flameJet.center = CGPointMake(self.bombImage.center.x, self.bombImage.center.y);
        self.jet.center = CGPointMake(screenWidth + 500, [self randomHeight]);
        self.bombImage.center = CGPointMake(offScreen, offScreen);
        bombPressed = false;
        bombInFlight = false;
        [self updateScore:jetScore];
        self.flameJet.animationImages = self.fireAnimation;
        self.flameJet.animationDuration = 1.0;
        self.flameJet.animationRepeatCount = 1;
        [self.flameJet startAnimating];
    }
}


-(void)collisionBetweenBombAndMissile
{
    if(CGRectIntersectsRect(self.bombImage.frame, self.missileImage.frame))
    {
        if(soundIsOn)
        {
            [self.bangplayer play];
        }
        self.flameMissile.center = CGPointMake(self.bombImage.center.x, self.bombImage.center.y);
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
    double deltaX = self.character.center.x - self.finishLine.center.x;
    double deltaY = self.character.center.y - self.finishLine.center.y;
    CGPoint point = CGPointMake(deltaX, deltaY);
    if([self magnitude:point] < 50*deviceScaler)
    {
        if(soundIsOn)
        {
            [self.portalplayer play];
        }
        [self.hitFire stopAnimating];
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
        [self.endPlayer play];
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
    if(lives < 0)
    {
        lives = 0;
    }
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
    self.portalLabel.center = CGPointMake(offScreen, offScreen);
    self.wallLabel.center = CGPointMake(offScreen, offScreen);
    self.jet.center = CGPointMake(offScreen - 8000, offScreen);

}


-(int)randomHeight
{
    int minY = .1*screenHeight;
    int maxY = .65*screenHeight;
    int range = maxY - minY;
    return (arc4random() % range) + minY;
  //  return (screenHeight - controlHeight)/2;
}

-(int)randomWidth
{
    int minX = .1*screenWidth;
    int maxX = .9*screenWidth;
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
    
    if(lives > 0)
    {
        [alert addAction:save];
        [alert addAction:resume];
    }

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
        
        [[GameCenterManager sharedManager] saveAndReportScore:score leaderboard:@"com.lfeldman.chopper.score" sortOrder:GameCenterSortOrderHighToLow];
    }
    
    NSNumber *currentHighLevel = [[NSUserDefaults standardUserDefaults] objectForKey:@"highLevel"];
    int currentHLInt = [currentHighLevel intValue];
    
    if(level > currentHLInt)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:level] forKey:@"highLevel"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[GameCenterManager sharedManager] saveAndReportScore:level leaderboard:@"com.lfeldman.chopper.level" sortOrder:GameCenterSortOrderHighToLow];
    }
    
    if(score >= 3*bottomAchieve)
    {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"com.lfeldman.chopper.achievement3" percentComplete:100.00 shouldDisplayNotification:true];
        
    } else if (score >= 2*bottomAchieve)
        
    {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"com.lfeldman.chopper.achievement2" percentComplete:100.00 shouldDisplayNotification:true];
    }
    
    else if (score >= bottomAchieve)
        
    {
        [[GameCenterManager sharedManager] saveAndReportAchievement:@"com.lfeldman.chopper.achievement1" percentComplete:100.00 shouldDisplayNotification:true];
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
    if(soundIsOn)
    {
        [self.shootingPlayer play];
    }
}

- (IBAction)bombPressed:(id)sender
{
    bombPressed = true;
}

- (IBAction)shootReleased:(id)sender
{
    shootPressed = false;
    if(soundIsOn)
    {
        [self.shootingPlayer pause];
    }
}

-(void)moveBomb
{
    self.bombVelocityY = self.bombVelocityY + 1.0*deviceScaler;
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
    self.ammoImage.center = CGPointMake(self.ammoImage.center.x + ammoSpeed*deviceScaler - self.charVelocityX, self.ammoImage.center.y);
    
    if(self.ammoImage.center.x > screenWidth)
    {
        self.ammoImage.center = CGPointMake(offScreen, offScreen);
        ammoInFlight = false;
    }
}

-(void)shootGunLeft
{
    self.ammoImage.center = CGPointMake(self.ammoImage.center.x - ammoSpeed*deviceScaler - self.charVelocityX, self.ammoImage.center.y);
    
    if(self.ammoImage.center.x < 0)
    {
        self.ammoImage.center = CGPointMake(offScreen, offScreen);
        ammoInFlight = false;
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
