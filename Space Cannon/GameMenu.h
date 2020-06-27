//
//  GameMenu.h
//  Space Cannon
//
//  Created by R. Clark Morrow on 10/25/14.
//  Copyright (c) 2014 self. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface GameMenu : SKNode

@property (nonatomic) int score;
@property (nonatomic) int topScore;
@property (nonatomic) BOOL touchable;
@property (nonatomic) BOOL musicPlaying;

-(void)hide;
-(void)show;

@end
