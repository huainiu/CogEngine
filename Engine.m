//
//  Engine.m
//  CogEngine
//
//  Created by Minh Nguyen on 7/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Engine.h"
#import "EAGLView.h"
#import "Scene.h"
#import "Matrix.h"

#import "Texture.h"

static Engine * _sharedEngine = nil;

@implementation Engine

@synthesize glView;
@synthesize currentScene;

@synthesize animating;
@dynamic animationFrameInterval;

@synthesize dt;
@synthesize width;
@synthesize height;

+ (Engine *)sharedEngine {
	if (!_sharedEngine) {
		_sharedEngine = [[Engine alloc] init];
	}
	
	return _sharedEngine;
}

- (id) init {
	
	if (self = [super init]) {
		animating = FALSE;
        displayLinkSupported = FALSE;
        animationFrameInterval = 1;
        displayLink = nil;
        animationTimer = nil;
		
		// A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
		// class is used as fallback when it isn't available.
		NSString *reqSysVer = @"3.1";
		NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
		if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
			displayLinkSupported = TRUE;
		
		
		//Engine transformation matrices
		projection = [[Matrix alloc] init];
		
		modelview = [[Matrix alloc] init];
	}
	
	return self;
}

- (void)dealloc {
	[projection release];
	[modelview release];
	
	[texture release];
	
	[super dealloc];
}

//Since this is a singleton, we need to run cleanup on the engine to dealloc
- (void)cleanup {
	[self stopAnimation];
	
	//Use properties to set glView, this will release it
	self.glView = nil;
	
	self.currentScene = nil;
}


- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    // Frame interval defines how many display frames must pass between each time the
    // display link fires. The display link will only fire 30 times a second when the
    // frame internal is two on a display that refreshes 60 times a second. The default
    // frame interval setting of one will fire 60 times a second when the display refreshes
    // at 60 times a second. A frame interval setting of less than one results in undefined
    // behavior.
    if (frameInterval >= 1)
    {
        animationFrameInterval = frameInterval;
		
        if (animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
    if (!animating)
    {
        if (displayLinkSupported)
        {
            // CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning, but can be dismissed
            // if the system version runtime check for CADisplayLink exists in -initWithCoder:. The runtime check ensures this code will
            // not be called in system versions earlier than 3.1.
			
            displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(mainLoop:)];
            [displayLink setFrameInterval:animationFrameInterval];
            [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        }
        else
            animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval) target:self selector:@selector(mainLoop:) userInfo:nil repeats:TRUE];
		
        animating = TRUE;
    }
}

- (void)drawVertices:(cgfloat *)vertices size:(cgint)size indices:(cgushort *)indices count:(cgint)count
{
	[glView drawVertices:vertices size:size indices:indices count:count];
}

- (void)setModelMatrix:(Matrix *)transform
{
	[modelview setMatrix:transform];
	[glView setModelMatrix:transform];
}

- (void)multiplyModelMatrix:(Matrix *)transform
{
	[modelview multiply:transform];
	[glView setModelMatrix:modelview];
}

- (void)setTexture:(NSString *)aTexture
{
	if (texture == aTexture)
		return;
	
	[texture release];
	texture = [aTexture copy];
	
	//TODO:get the engine to load it by using the EAGLView
	[[Texture sharedTexture] getTexture:texture];
}

- (void)mainLoop:(id)sender
{
	//Calculate time
	NSLog(@"timer" );
	
	if (displayLinkSupported) {
		NSLog(@"time elapsed: %f", [displayLink duration]);
		
		dt = [displayLink duration];
	}
	else {
		//TODO:Figure out how to get elapsed time from timers
		[animationTimer timeInterval];
	}
	
	[currentScene visit:@selector(update:) withObject:[NSNumber numberWithFloat:dt]];
	
	//Render
	[glView beginRender:sender];
	[currentScene visit:@selector(render:) withObject:[NSNumber numberWithFloat:dt]];
	[glView endRender:sender];
}

- (void)stopAnimation
{
    if (animating)
    {
        if (displayLinkSupported)
        {
            [displayLink invalidate];
            displayLink = nil;
        }
        else
        {
            [animationTimer invalidate];
            animationTimer = nil;
        }
		
        animating = FALSE;
    }
}


@end
