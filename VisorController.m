//
//  VisorController.m
//  Visor
//
//  Created by Nicholas Jitkoff on 6/1/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "VisorController.h"
#import "VisorWindow.h"
#import "NDHotKeyEvent_QSMods.h"
#define VisorTerminalDefaults @"VisorTerminal" 
#import "VisorTermController.h"
#import <QuartzComposer/QuartzComposer.h>
#import "CGSPrivate.h"

bool	useSlide=true;
bool	useFade=true;

int		fadeTime=0.1; // 30000



@interface InspectorController : NSWindowController
{
	@public
    TermController *termController;
    NSPopUpButton *popUpButton;
    NSTabView *tabView;
    id bufferInspector;
	id colorInspector;
    id displayInspector;
    id emulationInspector;
    id processesInspector;
    id shellInspector;
	id windowInspector;
    id keyMappingInspector;
}
+ (InspectorController *)sharedInspectorController;
@end

@implementation VisorController
+ (VisorController*) sharedInstance
{
	static VisorController* plugin = nil;
	if (plugin == nil)
		plugin = [[VisorController alloc] init];
	return plugin;
}
+ (void) install
{
	NSDictionary *defaults=[NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[self class]]pathForResource:@"Defaults" ofType:@"plist"]];
	//NSLog(@"defaults %@",defaults);
	[[NSUserDefaults standardUserDefaults]registerDefaults:defaults];
	[VisorController sharedInstance];
}

- (id) init {
	self = [super init];
	if (self != nil) {
    NSDictionary *defaults=[NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[self class]]pathForResource:@"Defaults" ofType:@"plist"]];
    //NSLog(@"defaults %@",defaults);
    [[NSUserDefaults standardUserDefaults]registerDefaults:defaults];
    
		hotkey=nil;
		[NSBundle loadNibNamed:@"Visor" owner:self];

		//if the default VisorShowStatusItem doesn't exist, set it to true by default
		if (![[NSUserDefaults standardUserDefaults] objectForKey:@"VisorShowStatusItem"]) {
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"VisorShowStatusItem"];
		}
		
		//add the "Visor Preferences..." item to the Terminal menu
		id <NSMenuItem> prefsMenuItem = [[statusMenu itemAtIndex:[statusMenu numberOfItems] - 1] copy];
		[[[[NSApp mainMenu] itemAtIndex:0] submenu] insertItem:prefsMenuItem atIndex:3];
		[prefsMenuItem release];
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"VisorShowStatusItem"]) {
			[self activateStatusMenu];
		}
		

		
		[self enableHotKey];
		[self initEscapeKey];
		
		// Watch for hotkey changes
		[[NSUserDefaultsController sharedUserDefaultsController]addObserver:self
																 forKeyPath:@"values.VisorHotKey"
																	options:nil
																	context:nil];
		
		[[NSUserDefaultsController sharedUserDefaultsController]addObserver:self
																 forKeyPath:@"values.VisorBackgroundAnimationFile"
																	options:nil
																	context:nil];
		// added drp
		
		[[NSUserDefaultsController sharedUserDefaultsController]addObserver:self
																 forKeyPath:@"values.VisorUseFade"
																	options:nil
																	context:nil];															
		
		
		[[NSUserDefaultsController sharedUserDefaultsController]addObserver:self
																 forKeyPath:@"values.VisorUseSlide"
																	options:nil
																	context:nil];				
		
		[[NSUserDefaultsController sharedUserDefaultsController]addObserver:self
																 forKeyPath:@"values.VisorAnimationSpeed"
																	options:nil
																	context:nil];
		
		[[NSUserDefaultsController sharedUserDefaultsController]addObserver:self
																 forKeyPath:@"values.VisorShowStatusItem"
																	options:nil
																	context:nil];
		
		NSWindow *window=[[self controller] window];
		if ([[NSUserDefaults standardUserDefaults]boolForKey:@"VisorUseBackgroundAnimation"]){
			[self backgroundWindow];
		}
	}
	return self;
}

NSString 	* stringForCharacter( const unsigned short aKeyCode, unichar aCharacter );

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem{
	if ([menuItem action]==@selector(toggleVisor:)){
		[menuItem setKeyEquivalent:stringForCharacter([hotkey keyCode],[hotkey character])];
		[menuItem setKeyEquivalentModifierMask:[hotkey modifierFlags]];
	}
	return YES;
}

- (IBAction)showPrefs:(id)sender{
	[NSApp activateIgnoringOtherApps:YES];
	[prefsWindow center];
	[prefsWindow makeKeyAndOrderFront:nil];
}

- (IBAction)showAboutBox:(id)sender{
	[NSApp activateIgnoringOtherApps:YES];
	[aboutWindow center];
	[aboutWindow makeKeyAndOrderFront:nil];
}

- (void)activateStatusMenu
{
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    [statusItem retain];
	
	// Set Icon
	NSString *imagePath=[[NSBundle bundleForClass:[self classForCoder]]pathForImageResource:@"Visor"];
	NSImage *image=[[[NSImage alloc]initWithContentsOfFile:imagePath]autorelease];
	[statusItem setImage:image];
	
    [statusItem setHighlightMode:YES];
	[statusItem setTarget:self];
	[statusItem setAction:@selector(toggleVisor:)];
	[statusItem setDoubleAction:@selector(toggleVisor:)];
	
	[statusItem setMenu:statusMenu];
}

- (IBAction)toggleVisor:(id)sender{
	// Hide or show as needed
	if (![[[self controller] window]isVisible]){
		[self showWindow];
	}else{
		[self hideWindow];
	}
	
}


- (void)showWindow{
	[self maybeEnableEscapeKey:YES];
	
	NSScreen *screen=[NSScreen mainScreen];
	NSRect screenRect=[screen frame];
	screenRect.size.height-=21; // Ignore menu area
	
	NSWindow *window=[[self controller] window];
	NSRect showFrame=screenRect; // Shown Frame
								 //	showFrame.origin.y+=NSHeight(screenRect)/2;
								 //	showFrame.size.height=NSHeight(screenRect)/2;
	showFrame=[window frame]; // respect the existing height
	showFrame.size.width=screenRect.size.width;//make it the full screen width
		[window setFrame:showFrame display:NO];
//  [[controller tabView] resizeWindowToAccountForTabsBeingDisplayed:nil]; // Fit terminal to correct size
		
		showFrame=[[controller window]frame];
		showFrame.origin.x+=NSMidX(screenRect)-NSMidX(showFrame); // center horizontally
		showFrame.origin.y=NSMaxY(screenRect)-NSHeight(showFrame); // align to top of screen
		
		[window setAlphaValue:0.0];
		
		[window makeKeyAndOrderFront:self];
		
		[window setFrame:showFrame display:NO];
		
		
		if ([[NSUserDefaults standardUserDefaults]boolForKey:@"VisorUseBackgroundAnimation"]){
			[self backgroundWindow];
			[[backgroundWindow contentView]startRendering];
			[backgroundWindow setFrame:showFrame display:YES];
			[backgroundWindow setAlphaValue:0.0];
			[backgroundWindow orderFront:nil];
			[backgroundWindow setLevel:NSMainMenuWindowLevel-2];	
		}else{
			[self setBackgroundWindow:nil];
		}
		
		[window setLevel:NSMainMenuWindowLevel-1];
		
		[self slideWindows:1];
		[window invalidateShadow];
		
		[window setAlphaValue:
				[[NSUserDefaults standardUserDefaults]
					floatForKey:@"VisorTransparency"]];
		
		//	[controller setNeedsDisplay];	
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	//    [window orderOut:self];
}
//#define DURATION 0.333f

-(void)hideWindow{
	[self maybeEnableEscapeKey:NO];
	
 	NSWindow *window=[[self controller] window];
	NSScreen *screen=[NSScreen mainScreen];
	NSRect screenRect=[screen frame];	
	NSRect showFrame=screenRect; // Shown Frame
	NSRect hideFrame=NSOffsetRect(showFrame,0,NSHeight(screenRect)/2+22); //hidden frame for start of animation
																		  ///	if ([[NSUserDefaults standardUserDefaults]boolForKey:@"VisorUseBackgroundAnimation"]
																		  //	[window setLevel:NSFloatingWindowLevel];
	[self saveDefaults];
	[self slideWindows:0];
	
	//	[NSThread detachNewThreadSelector:@selector(slideOutWindows) toTarget:self withObject:nil];
	[[backgroundWindow contentView]stopRendering];
}

- (void)slideWindows:(BOOL)show{
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc]init];
 	NSWindow *window=[[self controller] window];
	float windowHeight=NSHeight([window frame]);
	CGSConnection cgs = _CGSDefaultConnection();
	int wids[2]={[window windowNumber],[backgroundWindow windowNumber]};
	
	CGAffineTransform transform;
	CGSGetWindowTransform(cgs,wids[0],&transform);
	
	CGAffineTransform newTransforms[2];
	float newAlphas[2];	
	NSTimeInterval t;
	NSDate *date=[NSDate date];
	int windowCount=backgroundWindow?2:1;
	
	// added drp
	float DURATION=[[NSUserDefaults standardUserDefaults]floatForKey:@"VisorAnimationSpeed"];
	
	// The final alpha for the visor window
	float finalAlpha = [[NSUserDefaults standardUserDefaults]
			floatForKey:@"VisorTransparency"];
	
	int windowHeightDelta = 500;
	// added drp
	// if we dont have to animate, dont really bother.
	if(![[NSUserDefaults standardUserDefaults]boolForKey:@"VisorUseSlide"] && ![[NSUserDefaults standardUserDefaults]boolForKey:@"VisorUseFade"])
		DURATION=0.1;
	
	while (DURATION>(t=-[date timeIntervalSinceNow])) {
		float f=t/DURATION;
		
		if (show) f=1.0f-f;
		//	NSLog(@"f %f",f);
		newTransforms[0]=newTransforms[1]=CGAffineTransformTranslate(transform,0,sin(M_PI_2*f)*(windowHeight));
		
		// added drp do we fade in or not?
		if ([[NSUserDefaults standardUserDefaults]boolForKey:@"VisorUseFade"])
		{
			if (backgroundWindow)
				CGSSetWindowAlpha(cgs, wids[1], finalAlpha-(f*1.1)); //background fades faster
			CGSSetWindowAlpha(cgs, wids[0], finalAlpha-f);
		}
		else
		{
			if (backgroundWindow)
				CGSSetWindowAlpha(cgs, wids[1], finalAlpha);
			CGSSetWindowAlpha(cgs, wids[0], finalAlpha);
			
		}
		
		// added drp - do we animate the slide?
		if ([[NSUserDefaults standardUserDefaults]boolForKey:@"VisorUseSlide"])
		{
			CGSSetWindowTransforms(cgs, wids, newTransforms, windowCount); 
		}
		
		[backgroundWindow display];
		usleep(5000);
	}
	
	
	if (!show){// Hide the windows
		[window orderOut:self];
		[backgroundWindow orderOut:nil];
		
	}
	//restore values
	newTransforms[0]=newTransforms[1]=transform;
	CGSSetWindowTransforms(cgs, wids, newTransforms, windowCount); 
	CGSSetWindowAlpha(cgs, wids[1], 1);
	CGSSetWindowAlpha(cgs, wids[0], 1);
	
	[window setAlphaValue:1.0];	// NSWindow caches these values, so let it know
	[backgroundWindow setAlphaValue:1.0];
	
	
}

// Callback for a closed shell
- (void)shell:(id)shell childDidExitWithStatus:(int)status{
	[self hideWindow];
	[self setController:nil];
}

- (void)saveDefaults{	
//	NSDictionary *defaults=[[controller defaults]dictionaryRepresentation];
//	[[NSUserDefaults standardUserDefaults]setObject:defaults forKey:VisorTerminalDefaults];
	//NSLog(@"defaults:%@",defaults);
}
- (void)resignMain:(id)sender{
	if ([[controller window]isVisible]){
		[self toggleVisor:nil];	
	}
}

- (void)resignKey:(id)sender{
	if ([[controller window]isVisible]){
		[[controller window]setLevel:NSFloatingWindowLevel];
		[backgroundWindow setLevel:NSFloatingWindowLevel-1];
	}
}

- (void)becomeKey:(id)sender{
	if ([[controller window]isVisible]){
		[[controller window]setLevel:NSMainMenuWindowLevel-1];
		[backgroundWindow setLevel:NSMainMenuWindowLevel-2];
	}
}
- (void)windowResized{
	[backgroundWindow setFrame:[[controller window]frame] display:YES];	
	[self saveDefaults];
}
- (IBAction)inspect:(id)sender{
	//[[self controller] inspector:sender];	
	//	[self toggleVisor:nil];
	//	InspectorController *inspector=	[[InspectorController alloc]init];
	//	[inspector update];
	//	inspector->termController=[controller retain];
	//	[inspector update];
	//	[inspector showWindow:nil];
	//	[[InspectorController sharedInspectorController]];
	
}
- (void)createController{
	// Create window controller
	if (!controller){     
    id profile = [[TTProfileManager sharedProfileManager] profileWithName:@"Visor"];
   
		BOOL sizeWindow=NO;

    NSDisableScreenUpdates();
    controller = [NSApp newWindowControllerWithProfile:profile];
    [[controller window] orderOut:nil];
    NSEnableScreenUpdates();


	//	[controller setDelegate:self];
		NSWindow *oldWin=[controller window];
		NSView *contentView=[oldWin contentView];
		[[contentView retain]autorelease];
		[oldWin setContentView:nil];
		NSLog(@"contentView %@", [controller tabView]);
//		NS_DURING
//			NSView *scroller=[[[controller tabView] subviews]objectAtIndex:1];
//			NSRect rect=[scroller frame];
//			
//			rect.size.height+=rect.origin.y+1;
//			rect.origin.y=0;
//			[scroller setFrame:rect];
//		NS_HANDLER
//			;
//		NS_ENDHANDLER
		
		// Create a new borderless window
		NSWindow *newWin=[[VisorWindow alloc]initWithContentRect:[oldWin frame] styleMask:NSBorderlessWindowMask|NSNonactivatingPanelMask backing:NSBackingStoreBuffered defer:NO];
		[newWin setDelegate:controller];
//		[newWin setInitialFirstResponder:[[controller termView]mainSubview]];
		[newWin setContentView:contentView];		
		[newWin setLevel:NSFloatingWindowLevel];
		[newWin setOpaque:NO];
		[newWin setBackgroundColor:[NSColor lightGrayColor]];
		[controller setWindow:newWin];
		[[NSNotificationCenter defaultCenter]addObserver:self
												selector:@selector(resignMain:)
													name:NSWindowDidResignMainNotification
												  object:newWin];
		[[NSNotificationCenter defaultCenter]addObserver:self
												selector:@selector(resignKey:)
													name:NSWindowDidResignKeyNotification
												  object:newWin];
		[[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(becomeKey:)
                                                name:NSWindowDidBecomeKeyNotification
                                              object:newWin];
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(resized:)
                                                name:NSWindowDidResizeNotification
                                              object:newWin];
    
    
		[newWin setOpaque:NO];
		
		
		if (sizeWindow){
			NSScreen *screen=[NSScreen mainScreen];
			NSRect screenRect=[screen frame];
			screenRect.size.height-=22; // Ignore menu area
			
			NSWindow *window=[[self controller] window];
			NSRect showFrame=screenRect; // Shown Frame
			showFrame.origin.y+=NSHeight(screenRect)/2;
			showFrame.size.height=NSHeight(screenRect)/2;
			[newWin setFrame:showFrame display:NO];
		}
	}	
}


- (IBAction)chooseFile:(id)sender{
	NSOpenPanel *panel=[NSOpenPanel openPanel];
	[panel setTitle:@"Select a Quartz Composer (qtz) file"];
	if ([panel runModalForTypes:[NSArray arrayWithObject:@"qtz"]]){
		NSString *path=[panel filename];
		path=[path stringByAbbreviatingWithTildeInPath];
		[[NSUserDefaults standardUserDefaults]setObject:path forKey:@"VisorBackgroundAnimationFile"];
		[[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"VisorUseBackgroundAnimation"];
	}
}
- (void)resized:(NSNotification *)notif {
  if (backgroundWindow) {
    [backgroundWindow setFrame:[[controller window] frame] display:YES]; 
  }
}


- (NSWindow *)backgroundWindow{
	if (!backgroundWindow){
		backgroundWindow = [[[NSWindow class] alloc] initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
		[backgroundWindow setIgnoresMouseEvents:YES];
		[backgroundWindow setBackgroundColor: [NSColor blueColor]];
		[backgroundWindow setOpaque:NO];
		[backgroundWindow setHasShadow:NO];
		[backgroundWindow setReleasedWhenClosed:YES];
		[backgroundWindow setLevel:NSFloatingWindowLevel];
		[backgroundWindow setHasShadow:NO];
		QCView *content=[[[QCView alloc]init]autorelease];
		
		[backgroundWindow setContentView:content];
		
		
		
		NSString *path=[[NSUserDefaults standardUserDefaults]stringForKey:@"VisorBackgroundAnimationFile"];
		path=[path stringByStandardizingPath];
		
		NSFileManager *fm=[NSFileManager defaultManager];
		if (![fm fileExistsAtPath:path]){
			NSLog(@"animation does not exist: %@",path);
			path=nil;
		}
		
		if (!path)
			path=[[NSBundle bundleForClass:[self class]]pathForResource:@"Visor" ofType:@"qtz"];
		
		[content loadCompositionFromFile:path];
		[content startRendering];
		[content setMaxRenderingFrameRate:15.0];
		//	[[controller window] addChildWindow:backgroundWindow ordered:NSWindowBelow];	
	}
	return [[backgroundWindow retain] autorelease];
}

- (void) setBackgroundWindow: (NSWindow *) newBackgroundWindow
{
    if (backgroundWindow != newBackgroundWindow) {
        [backgroundWindow release];
        backgroundWindow = [newBackgroundWindow retain];
    }
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if ([keyPath isEqualToString:@"values.VisorShowStatusItem"]) {
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"VisorShowStatusItem"]) {
			[self activateStatusMenu];
		} else {
			[statusItem release];
			statusItem=nil;
		}
	} else {
		[self enableHotKey];
		[self setBackgroundWindow:nil];
	}

}
- (void)enableHotKey{
	if (hotkey){
		[hotkey setEnabled:NO];
		[hotkey release];
		hotkey=nil;
	}
	NSDictionary *dict=[[NSUserDefaults standardUserDefaults]dictionaryForKey:@"VisorHotKey"];
	if (dict){
		hotkey=(QSHotKeyEvent *)[QSHotKeyEvent hotKeyWithDictionary:dict];
		[hotkey setTarget:self selectorReleased:(SEL)0 selectorPressed:@selector(toggleVisor:)];
		[hotkey setEnabled:YES];	
		[hotkey retain];
	}
}
- (void)initEscapeKey
{
	escapeKey=(QSHotKeyEvent *)[QSHotKeyEvent hotKeyWithKeyCode:53 character:0 modifierFlags:0];
	[escapeKey setTarget:self selectorReleased:(SEL)0 selectorPressed:@selector(toggleVisor:)];
	[escapeKey setEnabled:NO];	
	[escapeKey retain];
}
- (void)maybeEnableEscapeKey:(BOOL)pEnable
{
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"VisorHideOnEscape"])
		[escapeKey setEnabled:pEnable];
}
- (TermController *)controller {
	
	if (!controller)[self createController];
	
	return [[controller retain] autorelease];
}

- (void)setController:(TermController *)value {
    if (controller != value) {
        [controller release];
        controller = [value retain];
    }
}


- (IBAction)setHotKey:(id)sender{
	NSLog(@"sender %@",sender);	
}
@end
