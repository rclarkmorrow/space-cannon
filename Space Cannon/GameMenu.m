//
//  GameMenu.m
//  Space Cannon
//
//  Created by R. Clark Morrow on 10/25/14.
//  Copyright (c) 2014 self. All rights reserved.
//

#import "GameMenu.h"

@implementation GameMenu

{
    SKLabelNode *_scoreLabel;
    SKLabelNode *_topScoreLabel;
    SKSpriteNode *_title;
    SKSpriteNode *_scoreBoard;
    SKSpriteNode *_playButton;
    SKSpriteNode *_musicButton;
}

-(id)init
{
    self = [super init];
    if (self) {
        _title = [SKSpriteNode spriteNodeWithImageNamed:@"Title"];
        _title.position = CGPointMake(0, 140);
        [self addChild:_title];
        
        _scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"ScoreBoard"];
        _scoreBoard.position = CGPointMake(0, 70);
        [self addChild:_scoreBoard];
        
        _playButton = [SKSpriteNode spriteNodeWithImageNamed:@"PlayButton"];
        _playButton.position = CGPointMake(0, 0);
        _playButton.name = @"play";
        [self addChild:_playButton];
        
        _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternative"];
        _scoreLabel.fontSize = 30;
        _scoreLabel.position = CGPointMake(-52, -20);
        [_scoreBoard addChild:_scoreLabel];
    
        _topScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternative"];
        _topScoreLabel.fontSize = 30;
        _topScoreLabel.position = CGPointMake(48, -20);
        [_scoreBoard addChild:_topScoreLabel];
        
        _musicButton = [SKSpriteNode spriteNodeWithImageNamed:@"MusicOnButton"];
        _musicButton.position = CGPointMake((_playButton.size.width * 0.5) + (_musicButton.size.width * 0.5 + 10), 0);
        _musicButton.name = @"music";
        [self addChild:_musicButton];
        
        self.score = 0;
        self.topScore = 0;
        self.touchable = YES;
    }
    return self;
}

-(void)hide {
    self.touchable = NO;
    
    SKAction *animateMenu = [SKAction scaleTo:0.0 duration:0.5];
    animateMenu.timingMode = SKActionTimingEaseIn;
    [self runAction:animateMenu completion:^{
        self.hidden = YES;
        self.xScale = 1.0;
        self.yScale = 1.0;
    }];
}
-(void)show {
    self.hidden = NO;
    self.touchable = NO;
    
    SKAction *fadeIn= [SKAction fadeInWithDuration:1.0];
    
    _title.position = CGPointMake(0, 280);
    _title.alpha = 0;
    SKAction *animateTitle = [SKAction group:@[[SKAction moveToY:140 duration:0.5], fadeIn]];
    animateTitle.timingMode = SKActionTimingEaseOut;
    [_title runAction:animateTitle];
    
    _scoreBoard.xScale = 4.0;
    _scoreBoard.yScale = 4.0;
    _scoreBoard.alpha = 0.0;
    SKAction *animateScoreBoard = [SKAction group:@[[SKAction scaleTo:1 duration:0.5], fadeIn]];
    animateScoreBoard.timingMode = SKActionTimingEaseOut;
    [_scoreBoard runAction:animateScoreBoard];
    
    _playButton.alpha = 0.0;
    SKAction *animatePlayButton = [SKAction fadeInWithDuration:2];
    animatePlayButton.timingMode = SKActionTimingEaseIn;
    [_playButton runAction:animatePlayButton completion:^{
        self.touchable = YES;
    }];
    
    _musicButton.alpha = 0.0;
    [_musicButton runAction:animatePlayButton];
}

-(void)setScore:(int)score{
    _score = score;
    _scoreLabel.text = [[NSNumber numberWithInt:score] stringValue];
}

-(void)setTopScore:(int)topScore{
    _topScore = topScore;
    _topScoreLabel.text = [[NSNumber numberWithInt:topScore] stringValue];
}

-(void)setMusicPlaying:(BOOL)musicPlaying {
    _musicPlaying = musicPlaying;
    
    if (_musicPlaying) {
        _musicButton.texture = [SKTexture textureWithImageNamed:@"MusicOnButton"];
    }
    else {
        _musicButton.texture = [SKTexture textureWithImageNamed:@"MusicOffButton"];
    }
}

@end
