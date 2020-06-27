//
//  GameBall.m
//  Space Cannon
//
//  Created by R. Clark Morrow on 10/25/14.
//  Copyright (c) 2014 self. All rights reserved.
//

#import "GameBall.h"

@implementation GameBall

-(void)updateTrail{
    
    if (self.trail) {
        self.trail.position = self.position;
        
    }
}

-(void) removeFromParent {
    
    if (self.trail) {
        self.trail.particleBirthRate = 0;
        
        SKAction *removeTrail = [SKAction sequence:@[[SKAction waitForDuration: self.trail.particleLifetime + self.trail.particleLifetimeRange], [SKAction removeFromParent]]];
        
        [self runAction:removeTrail];
    }
    
    [super removeFromParent];
    
}

@end
