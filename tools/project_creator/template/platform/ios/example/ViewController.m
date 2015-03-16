//
//  ViewController.m
//  example
//
//  Created by rainfiel on 15-2-14.
//  Copyright (c) 2015年 rainfiel. All rights reserved.
//

#import "ViewController.h"
#import "winfw.h"


static ViewController* _controller = nil;

@interface ViewController () {
	int disableGesture;
}
@property (strong, nonatomic) EAGLContext *context;

@end

@implementation ViewController
- (id)init {
	_controller = [super init];
	super.preferredFramesPerSecond = 30;
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

	NSString *appFolderPath = [[NSBundle mainBundle] resourcePath];
	const char* folder = [appFolderPath UTF8String];
	#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
	if([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0){
		screenScale = [[UIScreen mainScreen] nativeScale];
	}
	#endif

	struct STARTUP_INFO* startup = (struct STARTUP_INFO*)malloc(sizeof(struct STARTUP_INFO));
	startup->folder = (char*)folder;
	startup->script = NULL;
	startup->orix = bounds.origin.x;
	startup->oriy = bounds.origin.y;
	startup->width = bounds.size.width;
	startup->height = bounds.size.height;
	startup->scale = screenScale;
	startup->reload_count = 0;
	startup->serialized = NULL;
	ejoy2d_win_init(startup);
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

- (void)update
{
	ejoy2d_win_update(self.timeSinceLastUpdate);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
	ejoy2d_win_frame();
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

- (void)viewDidLayoutSubviews {
	CGRect bounds = [[UIScreen mainScreen] bounds];


#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
	float version = [[[UIDevice currentDevice] systemVersion] floatValue];
	if (version >= 8.0) {
		ejoy2d_win_view_layout(1, bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
		return;
	}
#endif

	UIDeviceOrientation ori = [[UIDevice currentDevice] orientation];
	if (ori == UIDeviceOrientationLandscapeLeft || ori == UIDeviceOrientationLandscapeRight) {
		ejoy2d_win_view_layout(1, bounds.origin.x, bounds.origin.y, bounds.size.height, bounds.size.width);
	} else {
		ejoy2d_win_view_layout(1, bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
	}
}

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer *)gr {
	return (disableGesture == 0 ? YES : NO);
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	// UITouch *touch = [touches anyObject];
	for(UITouch *touch in touches) {
		CGPoint p = [touch locationInView:touch.view];
		disableGesture = ejoy2d_win_touch(p.x, p.y, TOUCH_BEGIN);
	}
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	// UITouch *touch = [touches anyObject];
	for(UITouch *touch in touches) {
		CGPoint p = [touch locationInView:touch.view];
		ejoy2d_win_touch(p.x, p.y, TOUCH_MOVE);
	}
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	// UITouch *touch = [touches anyObject];
	for(UITouch *touch in touches) {
		CGPoint p = [touch locationInView:touch.view];
		ejoy2d_win_touch(p.x, p.y, TOUCH_END);
	}
}

@end
