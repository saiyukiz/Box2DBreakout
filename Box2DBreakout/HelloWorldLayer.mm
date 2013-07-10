//
//  HelloWorldLayer.mm
//  Box2DBreakout
//
//  Created by Sam Lee on 2013/04/19.
//  Copyright __MyCompanyName__ 2013年. All rights reserved.
//

// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#import "GameOverLayer.h"


//#import "PhysicsSprite.h"
#import "SimpleAudioEngine.h"

enum {
	kTagParentNode = 1,
};


#pragma mark - HelloWorldLayer

@interface HelloWorldLayer()
-(void) initPhysics;
-(void) addNewSpriteAtPosition:(CGPoint)p;
-(void) createMenu;
@end

@implementation HelloWorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	if( (self=[super init])) {
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"background-music-aac.caf"];
		
		// enable events
		
		self.isTouchEnabled = YES;
		self.isAccelerometerEnabled = YES;
		CGSize winSize = [CCDirector sharedDirector].winSize;
        
        b2Vec2 gravity = b2Vec2(0.0f, 0.0f);
        _world = new b2World(gravity);
        
        b2BodyDef groundBodyDef;
        groundBodyDef.position.Set(0,0);
        _groundBody = _world->CreateBody(&groundBodyDef);
        
        b2EdgeShape groundBox;
        b2FixtureDef groundBoxDef;
        groundBoxDef.shape = &groundBox;
        
        groundBox.Set(b2Vec2(0,0), b2Vec2(winSize.width/PTM_RATIO, 0));
        _bottomFixture = _groundBody->CreateFixture(&groundBoxDef);
        
        groundBox.Set(b2Vec2(0, 0), b2Vec2(0, winSize.height/PTM_RATIO));
        _groundBody->CreateFixture(&groundBoxDef);
        
        groundBox.Set(b2Vec2(0, winSize.height/PTM_RATIO), b2Vec2(winSize.width/PTM_RATIO, winSize.height/PTM_RATIO ));
        _groundBody->CreateFixture(&groundBoxDef);
        
        groundBox.Set(b2Vec2(winSize.width/PTM_RATIO, winSize.height/PTM_RATIO), b2Vec2(winSize.width/PTM_RATIO, 0));
        _groundBody->CreateFixture(&groundBoxDef);
        
        CCSprite *ball = [CCSprite spriteWithFile:@"ball.png"];
        ball.position = ccp(100,100);
        ball.tag = 1;
        [self addChild:ball];
        
        CCSprite *paddle = [CCSprite spriteWithFile:@"paddle.png"];
        paddle.position = ccp(winSize.width/2, 50);
        [self addChild:paddle];
        
        //ball body
        b2BodyDef ballBodyDef;
        ballBodyDef.type = b2_dynamicBody;
        ballBodyDef.position.Set(100/PTM_RATIO, 100/PTM_RATIO);
        ballBodyDef.userData = ball;
        b2Body *ballBody = _world->CreateBody(&ballBodyDef);
        
        //circle shape
        b2CircleShape circle;
        circle.m_radius = 26.0/PTM_RATIO;
        
        //shape definition 
        b2FixtureDef ballShapeDef;
        ballShapeDef.shape = &circle;
        ballShapeDef.density = 1.0f;
        ballShapeDef.friction = 0.f;
        ballShapeDef.restitution = 1.0f;
        _ballFixture = ballBody->CreateFixture(&ballShapeDef);
        
        b2Vec2 force = b2Vec2(10,10);
        ballBody->ApplyLinearImpulse(force, ballBodyDef.position);
        
        //paddle body
        b2BodyDef paddleBodyDef;
        paddleBodyDef.type = b2_dynamicBody;
        paddleBodyDef.position.Set(winSize.width/2 / PTM_RATIO, 50/PTM_RATIO);
        paddleBodyDef.userData = paddle;
        _paddleBody = _world->CreateBody(&paddleBodyDef);
        
        //paddle shape
        b2PolygonShape paddleShape;
        paddleShape.SetAsBox(paddle.contentSize.width/PTM_RATIO/2, paddle.contentSize.height/PTM_RATIO/2);
        
        //paddle shape definition
        b2FixtureDef paddleShapeDef;
        paddleShapeDef.shape = &paddleShape;
        paddleShapeDef.density = 10.0f;
        paddleShapeDef.friction = 0.4f;
        paddleShapeDef.restitution = 0.1f;
        _paddleFixture = _paddleBody->CreateFixture(&paddleShapeDef);
      
        //restrict paddle
        b2PrismaticJointDef jointDef;
        b2Vec2 worldAxis(1.0f, 0.0f);
        jointDef.collideConnected = true;
        jointDef.Initialize(_groundBody, _paddleBody, _paddleBody->GetWorldCenter(), worldAxis);
        _world->CreateJoint(&jointDef);
        
        
        _contactListener = new MyContactListener();
        _world->SetContactListener(_contactListener);
        
        
        for(int i = 0; i < 4; i++){
            static int padding = 20;
            
            //create block and add to layer
            CCSprite *block = [CCSprite spriteWithFile:@"block.png"];
            int xOffset = padding + block.contentSize.width/2 + ((block.contentSize.width+padding)* i);
            block.position = ccp(xOffset, 250);
            block.tag = 2;
            [self addChild:block];
            
            //block body
            b2BodyDef blockBodyDef;
            blockBodyDef.type = b2_dynamicBody;
            blockBodyDef.position.Set(xOffset/PTM_RATIO, 250/PTM_RATIO);
            blockBodyDef.userData = block;
            b2Body *blockBody = _world->CreateBody(&blockBodyDef);
            
            //block shape
            b2PolygonShape blockShape;
            blockShape.SetAsBox(block.contentSize.width/PTM_RATIO/2, block.contentSize.height/PTM_RATIO/2);
            
            //shape definition
            b2FixtureDef blockShapeDef;
            blockShapeDef.shape = &blockShape;
            blockShapeDef.density = 10.0;
            blockShapeDef.friction = 0.0;
            blockShapeDef.restitution = 0.1f;
            blockBody->CreateFixture(&blockShapeDef);
            
        }
        
        [self schedule:@selector(tick:)];
	}
	return self;
}


-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if (_mouseJoint != NULL) {
        return;
    }
    UITouch *myTouch = [touches anyObject];
    CGPoint location = [myTouch locationInView:[myTouch view]];
    location = [[CCDirector sharedDirector]convertToGL:location];
    b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
    
    if (_paddleFixture->TestPoint(locationWorld)) {
        b2MouseJointDef md;
        md.bodyA = _groundBody;
        md.bodyB = _paddleBody;
        md.target = locationWorld;
        md.collideConnected = true;
        md.maxForce = 1000.0f * _paddleBody->GetMass();
        
        _mouseJoint = (b2MouseJoint *)_world->CreateJoint(&md);
        _paddleBody->SetAwake(true);
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    if(_mouseJoint == NULL){
        return;
    }
    UITouch *myTouch = [touches anyObject];
    CGPoint location = [myTouch locationInView:[myTouch view]];
    location = [[CCDirector sharedDirector]convertToGL:location];
    b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
    
    _mouseJoint->SetTarget(locationWorld);
}

-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if (_mouseJoint) {
        _world->DestroyJoint(_mouseJoint);
        _mouseJoint = NULL;
    }
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    if (_mouseJoint) {
        _world->DestroyJoint(_mouseJoint);
        _mouseJoint = NULL;
    }
}

-(void)tick:(ccTime)dt{
    bool blockFound = false;
    _world->Step(dt, 10, 10);
    for(b2Body *b = _world->GetBodyList(); b; b = b->GetNext()){
        if (b->GetUserData() != NULL) {
            CCSprite *sprite = (CCSprite *)b->GetUserData();
            if(sprite.tag == 2){
                blockFound = true;
            }
            sprite.position = ccp(b->GetPosition().x * PTM_RATIO, b->GetPosition().y * PTM_RATIO);
            sprite.rotation = -1 * CC_RADIANS_TO_DEGREES(b->GetAngle());
            
            if(sprite.tag == 1){
                static int maxSpeed = 10;
                b2Vec2 velocity = b->GetLinearVelocity();
                float32 speed = velocity.Length();
                
                if (speed > maxSpeed) {
                    b->SetLinearDamping(0.5);
                }else if(speed < maxSpeed){
                    b->SetLinearDamping(0.0);
                }
            }

        }
    }
    //check contact
    std::vector<b2Body *>toDestroy;
    std::vector<MyContact>::iterator pos;
    for(pos = _contactListener->_contacts.begin();
        pos != _contactListener->_contacts.end(); ++pos){
        MyContact contact = *pos;
        
        if ((contact.fixtureA == _bottomFixture && contact.fixtureB == _ballFixture) ||
            (contact.fixtureA == _ballFixture && contact.fixtureB == _bottomFixture)) {
            CCScene *gameOverScene = [GameOverLayer sceneWithWon:NO];
            [[CCDirector sharedDirector] replaceScene:gameOverScene];
        }
        
        b2Body *bodyA = contact.fixtureA->GetBody();
        b2Body *bodyB = contact.fixtureB->GetBody();
        if(bodyA->GetUserData() != NULL && bodyB->GetUserData() != NULL){
            CCSprite *spriteA = (CCSprite *) bodyA->GetUserData();
            CCSprite *spriteB = (CCSprite *) bodyB->GetUserData();
            
            //sprite A = ball, sprite B = block
            if (spriteA.tag == 1 && spriteB.tag == 2) {
                if (std::find(toDestroy.begin(), toDestroy.end(), bodyB) == toDestroy.end()) {
                    toDestroy.push_back(bodyB);
                }
            }
            //Sprite A = block, Sprite B = ball
            else if (spriteA.tag == 2 && spriteB.tag == 1) {
                if (std::find(toDestroy.begin(), toDestroy.end(), bodyA) == toDestroy.end()) {
                    toDestroy.push_back(bodyA);
                }
            }
        }
    }
    std::vector<b2Body *>::iterator pos2;
    for (pos2 = toDestroy.begin(); pos2 != toDestroy.end(); ++pos2) {
        b2Body *body = *pos2;
        if (body->GetUserData() != NULL) {
            CCSprite *sprite = (CCSprite *) body->GetUserData();
            [self removeChild:sprite cleanup:YES];
        }
        _world->DestroyBody(body);
    }
    
    if (!blockFound) {
        CCScene *gameOverScene = [GameOverLayer sceneWithWon:YES];
        [[CCDirector sharedDirector] replaceScene:gameOverScene];
    }
    if (toDestroy.size() > 0) {
        [[SimpleAudioEngine sharedEngine] playEffect:@"blip.caf"];
    }
    
    
}

-(void) dealloc
{
	delete _world;
	_groundBody = NULL;
    delete _contactListener;
	[super dealloc];
}	


@end
