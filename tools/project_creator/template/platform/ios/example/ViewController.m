//
//  ViewController.m
//  example
//
//  Created by rainfiel on 15-2-14.
//  Copyright (c) 2015年 rainfiel. All rights reserved.
//

#import "ViewController.h"
#import "fw.h"
#import "liosutil.h"

#import <lua.h>
#import <lauxlib.h>

static ViewController* _controller = nil;
static NSString *appFolderPath = nil;

@interface ViewController () {
	int disableGesture;
}
@property (strong, nonatomic) EAGLContext *context;

@end

@implementation ViewController
- (id)init {
	_controller = [super init];
	super.preferredFramesPerSecond = 30;
	set_view_controller((__bridge void *)(_controller));
	return _controller;
}

-(void) loadView {
	CGRect bounds = [UIScreen mainScreen].bounds;
	self.view = [[GLKView alloc] initWithFrame:bounds];
}

+(ViewController*)getLastInstance{
	return _controller;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setGesture ];
	
	self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	
	if (!self.context) {
		NSLog(@"Failed to create ES context");
	}
	
	GLKView *view = (GLKView *)self.view;
	view.context = self.context;
	
	[EAGLContext setCurrentContext:self.context];
	
	CGFloat screenScale = [[UIScreen mainScreen] scale];
	CGRect bounds = [[UIScreen mainScreen] bounds];
	
	printf("screenScale: %f\n", screenScale);
	printf("bounds: x:%f y:%f w:%f h:%f\n",
     bounds.origin.x, bounds.origin.y,
     bounds.size.width, bounds.size.height);
	
	appFolderPath = [[NSBundle mainBundle] resourcePath];
	const char* str = [appFolderPath UTF8String];
	char* folder = (char*)malloc(strlen(str)+1);
	strcpy(folder, str);
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
	if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
		screenScale = [[UIScreen mainScreen] nativeScale];
	}
#endif
	
	struct STARTUP_INFO* startup = (struct STARTUP_INFO*)malloc(sizeof(struct STARTUP_INFO));
	startup->folder = (char*)folder;
	startup->lua_root = NULL;
	startup->script = NULL;
	startup->orix = bounds.origin.x;
	startup->oriy = bounds.origin.y;
	startup->width = bounds.size.width;
	startup->height = bounds.size.height;
	startup->scale = screenScale;
	startup->reload_count = 0;
	startup->serialized = NULL;
	startup->user_data = NULL;
	ejoy2d_fw_init(startup);
}

-(void)viewDidUnload
{
	[super viewDidUnload];
	
	NSLog(@"viewDidUnload");
	
	//  lejoy_unload();
	
	if ([self isViewLoaded] && ([[self view] window] == nil)) {
		self.view = nil;
		
		if ([EAGLContext currentContext] == self.context) {
			[EAGLContext setCurrentContext:nil];
		}
		self.context = nil;
	}
}

-(BOOL)prefersStatusBarHidden
{
	return YES;
}

- (void)update
{
	ejoy2d_fw_update(self.timeSinceLastUpdate);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
	ejoy2d_fw_frame();
}

- (void)dealloc
{
	//lejoy_exit();
	_controller = nil;
	if ([EAGLContext currentContext] == self.context) {
		[EAGLContext setCurrentContext:nil];
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
	return YES;
}

- (void)viewDidLayoutSubviews {
	CGRect bounds = [[UIScreen mainScreen] bounds];
	
	
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
	float version = [[[UIDevice currentDevice] systemVersion] floatValue];
	if (version >= 8.0) {
		ejoy2d_fw_view_layout(1, bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
		return;
	}
#endif
	
	UIDeviceOrientation ori = [[UIDevice currentDevice] orientation];
	if (ori == UIDeviceOrientationLandscapeLeft || ori == UIDeviceOrientationLandscapeRight) {
		ejoy2d_fw_view_layout(1, bounds.origin.x, bounds.origin.y, bounds.size.height, bounds.size.width);
	} else {
		ejoy2d_fw_view_layout(1, bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
	}
}

//gesture
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer *)gr {
	return (disableGesture == 0 ? YES : NO);
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *) gr shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *) ogr {
    return ejoy2d_fw_simul_gesture();
}

- (void) setGesture
{
	UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
																 initWithTarget:self action:@selector(handlePan:)];
	pan.delegate = self;
	[[self view] addGestureRecognizer:pan];
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
																 initWithTarget:self action:@selector(handleTap:)];
	tap.delegate = self;
	[[self view] addGestureRecognizer:tap];
	
	UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc]
																		 initWithTarget:self action:@selector(handlePinch:)];
	pinch.delegate = self;
	[[self view] addGestureRecognizer:pinch];
	
	UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc]
																				 initWithTarget:self action:@selector(handleLongPress:)];
	press.delegate = self;
	[[self view] addGestureRecognizer:press];
}

static int
getStateCode(UIGestureRecognizerState state) {
	switch(state) {
		case UIGestureRecognizerStatePossible: return STATE_POSSIBLE;
		case UIGestureRecognizerStateBegan: return STATE_BEGAN;
		case UIGestureRecognizerStateChanged: return STATE_CHANGED;
		case UIGestureRecognizerStateEnded: return STATE_ENDED;
		case UIGestureRecognizerStateCancelled: return STATE_CANCELLED;
		case UIGestureRecognizerStateFailed: return STATE_FAILED;
			
			// recognized == ended
			// case UIGestureRecognizerStateRecognized: return STATE_RECOGNIZED;
			
		default: return STATE_POSSIBLE;
	}
}

- (void) handlePan:(UIPanGestureRecognizer *) gr {
	int state = getStateCode(gr.state);
	CGPoint trans = [gr translationInView:self.view];
	// CGPoint p = [gr locationInView:self.view];
	CGPoint v = [gr velocityInView:self.view];
	[gr setTranslation:CGPointMake(0,0) inView:self.view];
	ejoy2d_fw_gesture(1, trans.x, trans.y, v.x, v.y, state);
}

- (void) handleTap:(UITapGestureRecognizer *) gr {
	int state = getStateCode(gr.state);
	CGPoint p = [gr locationInView:self.view];
	ejoy2d_fw_gesture(2, p.x, p.y, 0, 0, state);
}

- (void) handlePinch:(UIPinchGestureRecognizer *) gr {
	int state = getStateCode(gr.state);
	CGPoint p = [gr locationInView:self.view];
	ejoy2d_fw_gesture(3, p.x, p.y, (gr.scale * 1024.0), 0.0, state);
	gr.scale = 1;
}

- (void) handleLongPress:(UILongPressGestureRecognizer *) gr {
	int state = getStateCode(gr.state);
	CGPoint p = [gr locationInView:self.view];
	ejoy2d_fw_gesture(4, p.x, p.y, 0, 0, state);
}


//touch
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	// UITouch *touch = [touches anyObject];
	for(UITouch *touch in touches) {
		CGPoint p = [touch locationInView:touch.view];
		disableGesture = ejoy2d_fw_touch(p.x, p.y, TOUCH_BEGIN,0);
	}
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	// UITouch *touch = [touches anyObject];
	for(UITouch *touch in touches) {
		CGPoint p = [touch locationInView:touch.view];
		ejoy2d_fw_touch(p.x, p.y, TOUCH_MOVE,0);
	}
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	// UITouch *touch = [touches anyObject];
	for(UITouch *touch in touches) {
		CGPoint p = [touch locationInView:touch.view];
		ejoy2d_fw_touch(p.x, p.y, TOUCH_END,0);
	}
}

@end
