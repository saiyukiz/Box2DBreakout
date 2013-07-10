//
//  HelloWorldLayer.h
//  Box2DBreakout
//
//  Created by Sam Lee on 2013/04/19.
//  Copyright __MyCompanyName__ 2013年. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"

#import "MyContactListener.h"

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 32

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
	CCTexture2D *spriteTexture_;	// weak ref
	b2World* _world;					// strong ref
    b2Body *_groundBody;
    b2Fixture *_bottomFixture;
    
    b2Fixture *_ballFixture;
	GLESDebugDraw *m_debugDraw;		// strong ref
    b2MouseJoint *_mouseJoint;
    
    b2Body *_paddleBody;
    b2Fixture *_paddleFixture;
    
    MyContactListener *_contactListener;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
