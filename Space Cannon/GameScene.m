//
//  GameScene.m
//  Space Cannon
//
//  Created by R. Clark Morrow on 10/24/14.
//  Copyright (c) 2014 self. All rights reserved.
//

#import "GameScene.h"
#import "GameMenu.h"
#import "GameBall.h"
#import <AVFoundation/AVFoundation.h>


@implementation GameScene {
    
    AVAudioPlayer *_audioPlayer;
    SKNode *_mainLayer;
    SKSpriteNode *_cannon;
    SKSpriteNode *_ammoDisplay;
    SKLabelNode *_scoreLabel;
    SKLabelNode *_pointLabel;
    SKSpriteNode *_pauseButton;
    SKSpriteNode *_resumeButton;
    
    GameMenu *_menu;
    BOOL _didShoot;
    BOOL _gameOver;
    BOOL _multiMode;
    int _killCount;
    SKAction *_bounceSound;
    SKAction *_deepExplosionSound;
    SKAction *_explosionSound;
    SKAction *_laserSound;
    SKAction *_shieldUpSound;
    SKAction *_zapSound;
    
    NSUserDefaults *_userDefaults;
    NSMutableArray *_shieldPool;
    CGFloat _frameWidth;
    
}


static const CGFloat SHOOT_SPEED          = 1000.0;
static const CGFloat HALO_LOW_ANGLE       = 200.0 * M_PI / 180.0;
static const CGFloat HALO_HIGH_ANGLE      = 340.0 * M_PI / 180.0;
static const CGFloat HALO_SPEED           = 100.0;

static const uint32_t HALO_CATEGORY       = 0x1 << 0;
static const uint32_t BALL_CATEGORY       = 0x1 << 1;
static const uint32_t EDGE_CATEGORY       = 0x1 << 2;
static const uint32_t SHIELD_CATEGORY     = 0x1 << 3;
static const uint32_t LIFE_BAR_CATEGORY   = 0x1 << 4;
static const uint32_t SHIELD_UP_CATEGORY  = 0X1 << 5;
static const uint32_t MULTI_SHOT_CATEGORY = 0x1 << 6;

static NSString * const TOP_SCORE_KEY    = @"TopScore";
static NSString * const MUSIC_PLAY_KEY   = @"MusicOn";


static inline CGVector radiansToVector(CGFloat radians){
    
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    return vector;
}

static inline CGFloat randomInRange(CGFloat low, CGFloat high){
    CGFloat value = arc4random_uniform(UINT32_MAX) / (CGFloat)UINT32_MAX;
    return value * (high - low) + low;
}

-(void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
   
    _frameWidth = self.frame.size.width;
    
    //Turn off gravity.
    
    self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
    self.physicsWorld.contactDelegate = self;
    
    
    // Add Background.
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Starfield"];
    background.position = CGPointZero;
    background.anchorPoint = CGPointZero;
    background.blendMode = SKBlendModeReplace;
    background.size = self.frame.size;
    [self addChild:background];
    
    // Add edges.
    
    SKNode *leftEdge = [[SKNode alloc]init];
    leftEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height +100)];
    leftEdge.position = CGPointZero;
    leftEdge.physicsBody.categoryBitMask = EDGE_CATEGORY;
    [self addChild:leftEdge];
    
    
    SKNode *rightEdge = [[SKNode alloc]init];
    rightEdge.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointZero toPoint:CGPointMake(0.0, self.size.height +100)];
    rightEdge.position = CGPointMake(self.size.width, 0.0);
    rightEdge.physicsBody.categoryBitMask = EDGE_CATEGORY;
    [self addChild:rightEdge];
    
    //Add Main Layer.
    
    _mainLayer = [[SKNode alloc]init];
    [self addChild:_mainLayer];
    
    //Add Cannon.
    _cannon = [SKSpriteNode spriteNodeWithImageNamed:@"Cannon"];
    _cannon.size = [self resizeNode:_cannon];
    _cannon.position = CGPointMake(self.size.width * 0.5, 0.0);
    [self addChild:_cannon];
    
    //Create cannon rotate actions.
    
    SKAction  *rotateCannon = [SKAction sequence:@[[SKAction rotateByAngle:M_PI duration:2],[SKAction rotateByAngle:-M_PI duration:1]]];
    [_cannon runAction:[SKAction repeatActionForever:rotateCannon]];
    
    //Create spawn halo actions.
    
    SKAction *spawnHalo = [SKAction sequence:@[[SKAction waitForDuration:2 withRange:1], [SKAction performSelector:@selector(spawnHalo) onTarget:self]]];
    [self runAction:[SKAction repeatActionForever:spawnHalo] withKey:@"SpawnHalo"];
    
    //Create Spawn Shield Up actions
    
    SKAction *spawnShieldPowerUp = [SKAction sequence:@[[SKAction waitForDuration:15 withRange:4],[SKAction performSelector:@selector(spawnShieldPowerUp) onTarget:self]]];
    [self runAction:[SKAction repeatActionForever:spawnShieldPowerUp]];
    
    // Setup Ammo & Shields
    
    _ammoDisplay = [SKSpriteNode spriteNodeWithImageNamed:@"Ammo5"];
    _ammoDisplay.size = [self resizeNode:_ammoDisplay];
    _ammoDisplay.anchorPoint = CGPointMake(0.5, 0.0);
    _ammoDisplay.position = _cannon.position;
    [self addChild:_ammoDisplay];
    

    SKAction *incrementAmmo = [SKAction sequence:@[[SKAction waitForDuration:1], [SKAction runBlock:^{
        if (!self.multiMode) self.ammo++;
    }]]];
    [self runAction:[SKAction repeatActionForever:incrementAmmo]];
    
    _shieldPool = [[NSMutableArray alloc]init];
    
    for (int i = 0; i < 6; i++){
        SKSpriteNode *shield = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
       // shield.size = CGSizeMake(_frameWidth * 0.166, shield.size.height);
        shield.size = [self resizeNode:shield];
        // shield.position = CGPointMake(35 + (50 * i), 90);
        shield.position = CGPointMake((_frameWidth / 9.143) + ((_frameWidth / 6.4) * i), 90);
        shield.name = @"shield";
        shield.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(shield.size.width, shield.size.height)];
        shield.physicsBody.categoryBitMask = SHIELD_CATEGORY;
        shield.physicsBody.collisionBitMask = 0;
        [_shieldPool addObject:shield];
    }
    
    //Setup pause & resume button
    
    _pauseButton = [SKSpriteNode spriteNodeWithImageNamed:@"PauseButton"];
    _pauseButton.size = [self resizeNode: _pauseButton];
    _pauseButton.position = CGPointMake(self.size.width - 30, 20);
    [self addChild:_pauseButton];
    
    _resumeButton = [SKSpriteNode spriteNodeWithImageNamed:@"ResumeButton"];
    _resumeButton.size = [self resizeNode:_resumeButton];
    _resumeButton.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.5);
    [self addChild:_resumeButton];
    
    
    //Setup Labels
    
    _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
    _scoreLabel.position = CGPointMake(15, 10);
    _scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _scoreLabel.fontSize = 15;
    [self addChild:_scoreLabel];
    
    _pointLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
    _pointLabel.position = CGPointMake(15, 30);
    _pointLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _pointLabel.fontSize = 15;
    [self addChild:_pointLabel];
    
    //Setup Sounds
    _bounceSound = [SKAction playSoundFileNamed:@"Bounce.caf" waitForCompletion:NO];
    _deepExplosionSound = [SKAction playSoundFileNamed:@"DeepExplosion.caf" waitForCompletion:NO];
    _explosionSound = [SKAction playSoundFileNamed:@"Explosion.caf" waitForCompletion:NO];
    _laserSound = [SKAction playSoundFileNamed:@"Laser.caf" waitForCompletion:NO];
    _shieldUpSound = [SKAction playSoundFileNamed:@"ShieldUp.caf" waitForCompletion:NO];
    _zapSound = [SKAction playSoundFileNamed:@"Zap.caf" waitForCompletion:NO];
    
    
    //Setup Menu
    _menu = [[GameMenu alloc]init];
    _menu.position = CGPointMake(self.size.width * 0.5, self.size.height - 220);
    [self addChild:_menu];
    
    //Set initial values
    self.ammo = 5;
    self.score = 0;
    self.pointValue = 1;
    _gameOver = YES;
    _scoreLabel.hidden = YES;
    _pointLabel.hidden = YES;
    _pauseButton.hidden = YES;
    _resumeButton.hidden = YES;
    self.multiMode = NO;
   
    
    //Load top score
    _userDefaults = [NSUserDefaults standardUserDefaults];
    _menu.topScore = (int)[_userDefaults integerForKey:TOP_SCORE_KEY];
    
    //Setup Audio Player & load music
    
    NSURL *audioURL = [[NSBundle mainBundle] URLForResource:@"ObservingTheStar" withExtension:@"caf"];
    NSError *error = nil;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioURL error:&error];
    
    if (!_audioPlayer ) {
        NSLog(@"Error Loading Audio Player: %@:", error);
    }
    else {
        _audioPlayer.numberOfLoops = -1;
        _audioPlayer.volume = 0.1;
        [_audioPlayer play];
    }
    
    _menu.musicPlaying = YES;
}

-(void) newGame {
    
    [_mainLayer removeAllChildren];
    
    //Add Shields
    
    while (_shieldPool.count > 0) {
        [_mainLayer addChild:[_shieldPool objectAtIndex:0]];
        [_shieldPool removeObjectAtIndex:0];
    }
   
    // Setup Life Bar
    
    SKSpriteNode *lifeBar = [SKSpriteNode spriteNodeWithImageNamed:@"BlueBar"];
    lifeBar.size =  [self resizeNode:lifeBar];
    lifeBar.position = CGPointMake(self.size.width * 0.5, 70);
    lifeBar.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(-lifeBar.size.width * 0.5, 0) toPoint:CGPointMake(lifeBar.size.width * 0.5, 0)];
    lifeBar.physicsBody.categoryBitMask = LIFE_BAR_CATEGORY;
    [_mainLayer addChild:lifeBar];
    
    //Set Initial Values
    [self actionForKey:@"SpawnHalo"].speed = 1.0;
    self.ammo = 5;
    self.score = 0;
    self.pointValue = 1;
    _killCount = 0;
    _scoreLabel.hidden = NO;
    _pointLabel.hidden = NO;
    _pauseButton.hidden = NO;
    _gameOver = NO;
    [_menu hide];
    self.multiMode = NO;
    
    
}

-(void) setAmmo:(int)ammo {
    if (ammo >= 0 && ammo <= 5){
        _ammo = ammo;
        _ammoDisplay.texture = [SKTexture textureWithImageNamed: [NSString stringWithFormat:@"Ammo%d", ammo]];
    }
}

-(void) setScore:(int)score {
    _score = score;
    _scoreLabel.text = [NSString stringWithFormat:@"Score: %d", score];
}

-(void) setPointValue:(int)pointValue {
    _pointValue = pointValue;
    _pointLabel.text = [NSString stringWithFormat:@"Point Multiplier: %d", pointValue];
}

-(void) setMultiMode:(BOOL)multiMode {
    _multiMode = multiMode;
    if (multiMode) {
        _cannon.texture = [SKTexture textureWithImageNamed:@"GreenCannon"];
    }
    else {
        _cannon.texture = [SKTexture textureWithImageNamed:@"Cannon"];
    }
}

-(void) setGamePaused:(BOOL)gamePaused {
    if (!_gameOver) {
        self.paused = gamePaused;
        _gamePaused = gamePaused;
        _pauseButton.hidden = gamePaused;
        _resumeButton.hidden = !gamePaused;
    }
}

-(void)shoot {
    
    GameBall *ball = [GameBall spriteNodeWithImageNamed:@"Ball"];
    ball.size = [self resizeNode:ball];
    ball.name = @"ball";
    CGVector rotationVector = radiansToVector(_cannon.zRotation);
    ball.position = CGPointMake(_cannon.position.x + (_cannon.size.width * 0.5 * rotationVector.dx), _cannon.position.y + (_cannon.size.width * 0.5 *rotationVector.dy));
    
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:6.0];
    ball.physicsBody.velocity = CGVectorMake(rotationVector.dx * SHOOT_SPEED, rotationVector.dy * SHOOT_SPEED);
    ball.physicsBody.restitution = 1.0;
    ball.physicsBody.linearDamping = 0.0;
    ball.physicsBody.friction = 0.0;
    ball.physicsBody.categoryBitMask = BALL_CATEGORY;
    ball.physicsBody.collisionBitMask = EDGE_CATEGORY;
    ball.physicsBody.contactTestBitMask = EDGE_CATEGORY | SHIELD_UP_CATEGORY | MULTI_SHOT_CATEGORY;
    [self runAction:_laserSound];
    [_mainLayer addChild:ball];
    
    //Create trail
    NSString *ballTrailPath = [[NSBundle mainBundle] pathForResource:@"BallTrail" ofType:@"sks"];
    SKEmitterNode *ballTrail = [NSKeyedUnarchiver unarchiveObjectWithFile:ballTrailPath];
    ballTrail.particleTexture = [SKTexture textureWithImageNamed:@"spark"];
    ballTrail.targetNode = _mainLayer;
    [_mainLayer addChild:ballTrail];
    ball.trail = ballTrail;
    [ball updateTrail];
}

-(void) spawnHalo {

    //Increase Spawn Speed.
    
    SKAction *spawnHaloAction = [self actionForKey:@"SpawnHalo"];
    if (spawnHaloAction.speed < 1.5) {
        spawnHaloAction.speed +=0.01;
    }
    
    
    //Create Halo Node.
    
    SKSpriteNode *halo = [SKSpriteNode spriteNodeWithImageNamed:@"Halo"];
    halo.size = [self resizeNode:halo];
    halo.position = CGPointMake(randomInRange(halo.size.width * 0.5, self.size.width - (halo.size.width * 0.5)), self.size.height + (halo.size.height * 0.5));
    halo.name = @"halo";
    halo.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:16.0];
    CGVector direction = radiansToVector(randomInRange(HALO_LOW_ANGLE, HALO_HIGH_ANGLE));
    halo.physicsBody.velocity = (CGVectorMake(direction.dx * HALO_SPEED, direction.dy * HALO_SPEED));
    halo.physicsBody.restitution = 1.0;
    halo.physicsBody.linearDamping = 0.0;
    halo.physicsBody.friction = 0.0;
    halo.physicsBody.categoryBitMask = HALO_CATEGORY;
    halo.physicsBody.collisionBitMask = 0;
    halo.physicsBody.contactTestBitMask = BALL_CATEGORY | SHIELD_CATEGORY | LIFE_BAR_CATEGORY | EDGE_CATEGORY;
    
    int haloCount = 0;
    for (SKNode *node in _mainLayer.children){
        if ([node.name isEqualToString:@"halo"]) haloCount++;
    }

    if (!_gameOver && haloCount > 3) {
        //ceate bomb powerup
        halo.texture = [SKTexture textureWithImageNamed:@"HaloBomb"];
        halo.userData = [[NSMutableDictionary alloc]init];
        [halo.userData setValue:@YES forKey:@"isBomb"];
    }
    else if (!_gameOver && arc4random_uniform(6) == 0) {
        halo.texture = [SKTexture textureWithImageNamed:@"HaloX"];
        halo.userData = [[NSMutableDictionary alloc]init];
        [halo.userData setValue:@YES forKey:@"Multiplier"];
    }
    
    [_mainLayer addChild:halo];
}

-(void)spawnShieldPowerUp {
    
    if (_shieldPool.count > 0 && !_gameOver) {
        int dirTest = arc4random_uniform(2);
        int xVelocity;
        int xPosition;
        CGFloat angularV;
        SKSpriteNode *shieldUp = [SKSpriteNode spriteNodeWithImageNamed:@"Block"];
        shieldUp.size = [self resizeNode:shieldUp];
        
        switch (dirTest){
            case 0:
                xVelocity = -100;
                xPosition = self.size.width + shieldUp.size.width;
                angularV = M_PI;
                break;
            default:
                xVelocity = 100;
                xPosition = shieldUp.size.width * -1.0;
                angularV = M_PI * -1.0;
                break;
        }
        
        shieldUp.position = CGPointMake(xPosition, randomInRange(150, self.size.height - 100));
        shieldUp.name = @"shieldUp";
        shieldUp.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(42, 9)];
        shieldUp.physicsBody.categoryBitMask = SHIELD_UP_CATEGORY;
        shieldUp.physicsBody.velocity = CGVectorMake(xVelocity, randomInRange(-40, 40));
        shieldUp.physicsBody.angularVelocity = angularV;
        shieldUp.physicsBody.linearDamping = 0.0;
        shieldUp.physicsBody.angularDamping = 0.0;
        shieldUp.physicsBody.collisionBitMask = 0;
        [_mainLayer addChild:shieldUp];
    }
}

-(void) spawnMultiShotPowerUp {
    
    int dirTest = arc4random_uniform(2);
    int xVelocity;
    int xPosition;
    CGFloat angularV;
    SKSpriteNode *multiShotUp = [SKSpriteNode spriteNodeWithImageNamed:@"MultiShotPowerUp"];
    multiShotUp.size = [self resizeNode:multiShotUp];
    switch (dirTest){
        case 0:
            xVelocity = -100;
            xPosition = self.size.width + multiShotUp.size.width;
            angularV = M_PI;
            break;
        default:
            xVelocity = 100;
            xPosition = multiShotUp.size.width * -1.0;
            angularV = M_PI * -1.0;
            break;
    }
    
    multiShotUp.position = CGPointMake(xPosition, randomInRange(150, self.size.height - 100));
    multiShotUp.name = @"multiShotUp";
    multiShotUp.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:12.0];
    multiShotUp.physicsBody.categoryBitMask = MULTI_SHOT_CATEGORY;
    multiShotUp.physicsBody.velocity = CGVectorMake(xVelocity, randomInRange(-40, 40));
    multiShotUp.physicsBody.angularVelocity = angularV;
    multiShotUp.physicsBody.linearDamping = 0.0;
    multiShotUp.physicsBody.angularDamping = 0.0;
    multiShotUp.physicsBody.collisionBitMask = 0;
    [_mainLayer addChild:multiShotUp];
    
    
}

-(void)didEvaluateActions {
    if (self.gamePaused) self.paused = YES;
    else self.paused = NO;
}


-(void) didBeginContact:(SKPhysicsContact *)contact {
    
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    NSLog(@"did contact");
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else{
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if (firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == BALL_CATEGORY) {
        
        self.score += self.pointValue;
    
        [self addHaloExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [self runAction:_explosionSound];
        
        if ([[firstBody.node.userData valueForKey:@"Multiplier"] boolValue]) {
            self.pointValue++;
        }
        else if ([[firstBody.node.userData valueForKey:@"isBomb"] boolValue]) {
            firstBody.node.name = nil;
            [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
                [self addHaloExplosion:node.position withName:@"HaloExplosion"];
                self.score += self.pointValue;
                [node removeFromParent];
            }];
        }
        
        _killCount++;
        if (_killCount %10 == 0) {
            [self spawnMultiShotPowerUp];
            
        }
        
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    
    if (firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == SHIELD_CATEGORY) {
        
        [self addHaloExplosion:firstBody.node.position withName:@"HaloExplosion"];
        [self runAction:_explosionSound];
        [_shieldPool addObject:secondBody.node];
        [secondBody.node removeFromParent];
        
        if ([[firstBody.node.userData valueForKey:@"isBomb"]boolValue]){
            [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
                [self addHaloExplosion:node.position withName:@"HaloExplosion"];
                [_shieldPool addObject:node];
                [node removeFromParent];
            }];
        }
        firstBody.categoryBitMask = 0;
        [firstBody.node removeFromParent];
    }

    if (firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == LIFE_BAR_CATEGORY) {
        [self addHaloExplosion:firstBody.node.position withName:@"LifeBarExplosion"];
        [self runAction:_deepExplosionSound];
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
        [self gameOver];
    }
    
    if (firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == EDGE_CATEGORY) {
        [self addHaloExplosion:contact.contactPoint withName:@"BallEdgeExplosion"];
        if ([firstBody.node isKindOfClass:[GameBall class]]) {
            ((GameBall*)firstBody.node).bounces++;
            if (((GameBall*)firstBody.node).bounces > 3) [firstBody.node removeFromParent];
            self.pointValue = 1;
        }
        [self runAction:_bounceSound];
    }
    
    if (firstBody.categoryBitMask == HALO_CATEGORY && secondBody.categoryBitMask == EDGE_CATEGORY) {
        firstBody.velocity = (CGVectorMake(firstBody.velocity.dx * -1.0, firstBody.velocity.dy));
        [self runAction:_zapSound];
    }
    
    if (firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == SHIELD_UP_CATEGORY){
        if (_shieldPool.count > 0) {
            int randomIndex = arc4random_uniform((int)_shieldPool.count);
            [_mainLayer addChild:[_shieldPool objectAtIndex:randomIndex]];
            [_shieldPool removeObjectAtIndex:randomIndex];
            [self runAction:_shieldUpSound];
        }
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
    
    if (firstBody.categoryBitMask == BALL_CATEGORY && secondBody.categoryBitMask == MULTI_SHOT_CATEGORY){
        self.multiMode = YES;
        [self runAction:_shieldUpSound];
        self.ammo = 5;
        [firstBody.node removeFromParent];
        [secondBody.node removeFromParent];
    }
}

-(void)gameOver {
    
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addHaloExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addHaloExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];
    [_mainLayer enumerateChildNodesWithName:@"shield" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addHaloExplosion:node.position withName:@"HaloExplosion"];
        [_shieldPool addObject:node];
        [node removeFromParent];
    }];
    
    [_mainLayer enumerateChildNodesWithName:@"shieldUp" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addHaloExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];
    
    [_mainLayer enumerateChildNodesWithName:@"multiShotUp" usingBlock:^(SKNode *node, BOOL *stop) {
        [self addHaloExplosion:node.position withName:@"HaloExplosion"];
        [node removeFromParent];
    }];


    _menu.score = self.score;
    if (self.score > _menu.topScore) {
        _menu.topScore = self.score;
        [_userDefaults setInteger:self.score forKey:TOP_SCORE_KEY];
        [_userDefaults synchronize];
    }
    _gameOver = YES;
    _scoreLabel.hidden = YES;
    _pointLabel.hidden = YES;
    _pauseButton.hidden = YES;
    [self runAction:[SKAction waitForDuration:1] completion:^{
        [_menu show];
    }];
    
}

-(void)addHaloExplosion:(CGPoint)position withName: (NSString *)name{
    
    NSString *explosionPath = [[NSBundle mainBundle]pathForResource:name ofType:@"sks"];
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:explosionPath];
    explosion.particleTexture = [SKTexture textureWithImageNamed:@"Halo"];
    explosion.position = position;
    [_mainLayer addChild:explosion];
    
    SKAction *removeHaloExplosion = [SKAction sequence:@[[SKAction waitForDuration:1.5], [SKAction removeFromParent]]];
    [explosion runAction:removeHaloExplosion];
}

-(CGSize) resizeNode:(SKSpriteNode *)spriteNode {
    
    CGFloat modWidth = 320 / spriteNode.size.width;
    CGFloat newWidth = _frameWidth / modWidth;
    CGFloat modHeight = newWidth / spriteNode.size.width;
    CGFloat newHeight = spriteNode.size.height * modHeight;
    return CGSizeMake (newWidth, newHeight);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        if (!_gameOver && !self.gamePaused) {
            if (![_pauseButton containsPoint:[touch locationInNode:_pauseButton.parent]]){
                _didShoot = YES;
            }
        }
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        if (_gameOver && _menu.touchable) {
            SKNode *n = [_menu nodeAtPoint:[touch locationInNode:_menu]];
            if ([n.name isEqualToString:@"play"]){
                [self newGame];
            }
            if ([n.name isEqualToString:@"music"]){
                _menu.musicPlaying = !_menu.musicPlaying;
                if (_menu.musicPlaying){
                    [_audioPlayer play];
                }
                else {
                    [_audioPlayer stop];
                }
            }
        }
        else if (!_gameOver){
            if (self.gamePaused) {
                if ([_resumeButton containsPoint:[touch locationInNode:_resumeButton.parent]]){
                    self.gamePaused = NO;
                }
            }
            else if ([_pauseButton containsPoint:[touch locationInNode:_pauseButton.parent]]){
                self.gamePaused = YES;
            }
        }
    }
}

-(void) didSimulatePhysics {

    if (_didShoot) {
        if (self.ammo > 0) {
            self.ammo--;
            [self shoot];
            if (self.multiMode ) {
                for (int i = 1; i < 5; i++){
                    [self performSelector:@selector(shoot) withObject:nil afterDelay:0.1 * i];
                }
                if (self.ammo == 0) {
                    self.multiMode = NO;
                    self.ammo = 5;
                }
            }
        }
        _didShoot = NO;
    }
    
    //Remove Unused Nodes
    
    [_mainLayer enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        if ([node respondsToSelector:@selector(updateTrail)]) {
            [node performSelector:@selector(updateTrail) withObject:nil afterDelay:0.0];
        }
        
        if (!CGRectContainsPoint(self.frame, node.position)) {
            [node removeFromParent];
            self.pointValue = 1;
        }
    }];
    
    [_mainLayer enumerateChildNodesWithName:@"halo" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.y + node.frame.size.height < 0) {
            [node removeFromParent];
        }
    }];
    
    [_mainLayer enumerateChildNodesWithName:@"shieldUp" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.x + node.frame.size.width < 0) {
            [node removeFromParent];
        }
        if (node.position.x > self.frame.size.width + node.frame.size.width) {
            [node removeFromParent];
        }
    }];
    
    [_mainLayer enumerateChildNodesWithName:@"multiShotUp" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.position.x + node.frame.size.width < 0) {
            [node removeFromParent];
        }
        if (node.position.x > self.frame.size.width + node.frame.size.width) {
            [node removeFromParent];
        }
    }];
}
     
-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}


@end
