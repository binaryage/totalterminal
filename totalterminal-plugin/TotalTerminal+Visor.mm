#define PROJECT Visor
#include "TotalTerminal+Visor.h"
#include "TotalTerminal+Shortcuts.h"

#import "CGSPrivate.h"
#import "QSBKeyMap.h"
#import <Quartz/Quartz.h>

#define SLIDE_EASING(x) sin(M_PI_2 * (x))
#define ALPHA_EASING(x) (1.0f - (x))
#define SLIDE_DIRECTION(d, x) (d ? (x) : (1.0f - (x)))
#define ALPHA_DIRECTION(d, x) (d ? (1.0f - (x)) : (x))

@interface NSEvent (TotalTerminal)
-(NSUInteger) qsbModifierFlags;
@end

@implementation NSEvent (TotalTerminal)

-(NSUInteger) qsbModifierFlags {
    NSUInteger flags = ([self modifierFlags] & NSDeviceIndependentModifierFlagsMask);

    // Ignore caps lock if it's set http://b/issue?id=637380
    if (flags & NSAlphaShiftKeyMask) {
        flags -= NSAlphaShiftKeyMask;                               // Ignore numeric lock if it's set http://b/issue?id=637380
    }
    if (flags & NSNumericPadKeyMask)
        flags -= NSNumericPadKeyMask;
    return flags;
}

@end

@implementation VisorScreenTransformer

+(Class) transformedValueClass {
    LOG(@"transformedValueClass");
    return [NSNumber class];
}

+(BOOL) allowsReverseTransformation {
    LOG(@"allowsReverseTransformation");

    return YES;
}

-(id) transformedValue:(id)value {
    LOG(@"transformedValue %@", value);
    return [NSString stringWithFormat:@"Screen %d", [value integerValue]];
}

-(id) reverseTransformedValue:(id)value {
    LOG(@"reverseTransformedValue %@", value);
    return [NSNumber numberWithInteger:[[value substringFromIndex:6] integerValue]];
}

@end

@implementation NSWindowController (TotalTerminal)

// ------------------------------------------------------------
// TTWindowController hacks

-(void) SMETHOD (TTWindowController, setCloseDialogExpected):(BOOL)fp8 {
    AUTO_LOGGER();
    if (fp8) {
        // THIS IS A MEGAHACK! (works for me on Leopard 10.5.6)
        // the problem: beginSheet causes UI to lock for NSBorderlessWindowMask NSWindow which is in "closing mode"
        //
        // this hack tries to open sheet before window starts its closing procedure
        // we expect that setCloseDialogExpected is called by Terminal.app once BEFORE window gets into "closing mode"
        // in this case we are able to open sheet before window starts closing and this works even for window with NSBorderlessWindowMask
        // it works like a magic, took me few hours to figure out this random stuff
        TotalTerminal* tt = [TotalTerminal sharedInstance];
        [tt showVisor:false];
        [self displayWindowCloseSheet:1];
    }
}

-(NSRect) window:(NSWindow*)window willPositionSheet:(NSWindow*)sheet usingRect:(NSRect)rect {
    return rect;
}

-(NSRect) SMETHOD (TTWindowController, window):(NSWindow*)window willPositionSheet:(NSWindow*)sheet usingRect:(NSRect)rect {
    AUTO_LOGGER();
    [TotalTerminal sharedInstance];
    return rect;
}

-(id) SMETHOD (TTWindowController, getVisorProfileOrTheDefaultOne) {
    id visorProfile = [TotalTerminal getVisorProfile];

    if (visorProfile) {
        return visorProfile;
    } else {
        id profileManager = [NSClassFromString (@"TTProfileManager")sharedProfileManager];
        return [profileManager defaultProfile];
    }
}

-(id) SMETHOD (TTWindowController, forceVisorProfileIfVisoredWindow) {
    AUTO_LOGGER();
    id res = nil;
    TotalTerminal* tt = [TotalTerminal sharedInstance];
    BOOL isVisorWindow = [tt isVisorWindow:[self window]];

    if (isVisorWindow) {
        LOG(@"  in visor window ... so apply visor profile");
        res = [self SMETHOD (TTWindowController, getVisorProfileOrTheDefaultOne)];
    }
    return res;
}

// swizzled function for original TTWindowController::newTabWithProfile
// this seems to be a good point to intercept new tab creation
// responsible for opening all tabs in Visored window with Visor profile (regardless of "default profile" setting)
-(id) SMETHOD (TTWindowController, newTabWithProfile):(id)arg1 {
    AUTO_LOGGER();
    id profile = [self SMETHOD (TTWindowController, forceVisorProfileIfVisoredWindow)];
    if (profile) {
        arg1 = profile;
    }
    return [self SMETHOD (TTWindowController, newTabWithProfile):arg1];
}

// this is variant of the ^^^
// this seems to be an alternative point to intercept new tab creation
-(id) SMETHOD (TTWindowController, newTabWithProfile):(id)arg1 command:(id)arg2 runAsShell:(BOOL)arg3 {
    AUTO_LOGGER();
    id profile = [self SMETHOD (TTWindowController, forceVisorProfileIfVisoredWindow)];
    if (profile) {
        arg1 = profile;
    }
    return [self SMETHOD (TTWindowController, newTabWithProfile):arg1 command:arg2 runAsShell:arg3];
}

// LION: this is variant of the ^^^
-(id) SMETHOD (TTWindowController, newTabWithProfile):(id)arg1 customFont:(id)arg2 command:(id)arg3 runAsShell:(BOOL)arg4 restorable:(BOOL)arg5 workingDirectory:(id)arg6 sessionClass:(id)arg7
   restoreSession                                    :(id)arg8 {
    id profile = [self SMETHOD (TTWindowController, forceVisorProfileIfVisoredWindow)];

    AUTO_LOGGERF(@"profile=%@", profile);
    if (profile) {
        arg1 = profile;
    }
    return [self SMETHOD (TTWindowController, newTabWithProfile):arg1 customFont:arg2 command:arg3 runAsShell:arg4 restorable:arg5 workingDirectory:arg6 sessionClass:arg7 restoreSession:arg8];
}

// Mountain Lion renaming since v304
-(id) SMETHOD (TTWindowController, makeTabWithProfile):(id)arg1 {
    AUTO_LOGGER();
    id profile = [self SMETHOD (TTWindowController, forceVisorProfileIfVisoredWindow)];
    if (profile) {
        arg1 = profile;
    }
    return [self SMETHOD (TTWindowController, makeTabWithProfile):arg1];
}

-(id) SMETHOD (TTWindowController, makeTabWithProfile):(id)arg1 customFont:(id)arg2 command:(id)arg3 runAsShell:(BOOL)arg4 restorable:(BOOL)arg5 workingDirectory:(id)arg6 sessionClass:(id)arg7
restoreSession                                    :(id)arg8 {
    id profile = [self SMETHOD (TTWindowController, forceVisorProfileIfVisoredWindow)];
    
    AUTO_LOGGERF(@"profile=%@", profile);
    if (profile) {
        arg1 = profile;
    }
    return [self SMETHOD (TTWindowController, makeTabWithProfile):arg1 customFont:arg2 command:arg3 runAsShell:arg4 restorable:arg5 workingDirectory:arg6 sessionClass:arg7 restoreSession:arg8];
}

@end

@interface NSApplication (TotalTerminal)
-(void) newShell:(id)inObject;
@end

@implementation NSApplication (TotalTerminal)

-(void) SMETHOD (TTApplication, sendEvent):(NSEvent*)theEvent {
    NSUInteger type = [theEvent type];

    if (type == NSFlagsChanged) {
        TotalTerminal* tt = [TotalTerminal sharedInstance];
        [tt modifiersChangedWhileActive:theEvent];
    } else if ((type == NSKeyDown) || (type == NSKeyUp)) {
        TotalTerminal* tt = [TotalTerminal sharedInstance];
        [tt keysChangedWhileActive:theEvent];
    } else if (type == NSMouseMoved) {
        // TODO review this: it caused background intialization even if Quartz background was disabled in the preferences
        // => https://github.com/darwin/visor/issues/102#issuecomment-1508598
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalVisorUseBackgroundAnimation"]) {
            [[[TotalTerminal sharedInstance] background] sendEvent:theEvent];
        }
    }
    [self SMETHOD (TTApplication, sendEvent):theEvent];
}

-(BOOL) SMETHOD (TTApplication, applicationShouldHandleReopen):(id)fp8 hasVisibleWindows:(BOOL)fp12 {
    AUTO_LOGGER();
    if ([[TotalTerminal sharedInstance] window] && [[TotalTerminal sharedInstance] isHidden]) {
        NSArray* windows = [[NSClassFromString (@"TTApplication")sharedApplication] windows];
        int count = 0;
        for (id window in windows) {
            if ([[window className] isEqualToString:@"TTWindow"]) {
                count++;
            }
        }
        if (count == 1) {
            // auto-slide only when visor is the only terminal window
            NSLOG1(@"Showing visor because of applicationShouldHandleReopen");
            [[TotalTerminal sharedInstance] performSelector:@selector(showVisor:) withObject:nil afterDelay:0];
        }
    }
    return [self SMETHOD (TTApplication, applicationShouldHandleReopen):fp8 hasVisibleWindows:(BOOL)fp12];
}

@end

@implementation NSWindow (TotalTerminal)

-(id) SMETHOD (TTWindow, initWithContentRect):(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    AUTO_LOGGER();
    TotalTerminal* tt = [TotalTerminal sharedInstance];
    BOOL shouldBeVisorized = ![tt status];
    if (shouldBeVisorized) {
        aStyle = NSBorderlessWindowMask;
        bufferingType = NSBackingStoreBuffered;
    }
    self = [self SMETHOD (TTWindow, initWithContentRect):contentRect styleMask:aStyle backing:bufferingType defer:flag];
    if (shouldBeVisorized) {
        [tt adoptTerminal:self];
    }
    return self;
}

-(BOOL) SMETHOD (TTWindow, canBecomeKeyWindow) {
    BOOL canBecomeKeyWindow = YES;

    TotalTerminal* tt = [TotalTerminal sharedInstance];

    if ([[tt window] isEqual:self] && [tt isHidden]) {
        canBecomeKeyWindow = NO;
    }

    return canBecomeKeyWindow;
}

-(BOOL) SMETHOD (TTWindow, canBecomeMainWindow) {
    BOOL canBecomeMainWindow = YES;

    TotalTerminal* tt = [TotalTerminal sharedInstance];

    if ([[tt window] isEqual:self] && [tt isHidden]) {
        canBecomeMainWindow = NO;
    }

    return canBecomeMainWindow;
}

-(void) SMETHOD (TTWindow, performClose):(id)sender {
    AUTO_LOGGERF(@"sender=%@", sender);
    // XLOG(@"%@", [NSThread callStackSymbols]);
    // close Visor window hard way, for some reason performClose fails for Visor window under Lion
    TotalTerminal* tt = [TotalTerminal sharedInstance];
    if ([[tt window] isEqual:self]) {
        // this check is needed for case when there are running shell commands and Terminal shows closing prompt dialog
        if ([[self windowController] windowShouldClose:sender]) {
            [self close];
            return;
        }
    }
    return [self SMETHOD (TTWindow, performClose):sender];
}

@end

@implementation TotalTerminal (Visor)

-(NSWindow*) window {
    return window_;
}

-(void) setWindow:(NSWindow*)inWindow {
    NSNotificationCenter* dnc = [NSNotificationCenter defaultCenter];

    [inWindow retain];

    [dnc removeObserver:self name:NSWindowDidBecomeKeyNotification object:window_];
    [dnc removeObserver:self name:NSWindowDidResignKeyNotification object:window_];
    [dnc removeObserver:self name:NSWindowDidBecomeMainNotification object:window_];
    [dnc removeObserver:self name:NSWindowDidResignMainNotification object:window_];
    [dnc removeObserver:self name:NSWindowWillCloseNotification object:window_];
    [dnc removeObserver:self name:NSApplicationDidChangeScreenParametersNotification object:nil];

    [window_ release];
    window_ = inWindow;

    if (window_) {
        [dnc addObserver:self selector:@selector(becomeKey:) name:NSWindowDidBecomeKeyNotification object:window_];
        [dnc addObserver:self selector:@selector(resignKey:) name:NSWindowDidResignKeyNotification object:window_];
        [dnc addObserver:self selector:@selector(becomeMain:) name:NSWindowDidBecomeMainNotification object:window_];
        [dnc addObserver:self selector:@selector(resignMain:) name:NSWindowDidResignMainNotification object:window_];
        [dnc addObserver:self selector:@selector(willClose:) name:NSWindowWillCloseNotification object:window_];
        [dnc addObserver:self selector:@selector(didChangeScreenScreenParameters:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
    } else {
        isHidden = YES;
    }
}

// this is called by TTAplication::sendEvent
-(NSWindow*) background {
    return background_;
}

-(void) createBackground {
    if (background_) {
        [self destroyBackground];
    }

    background_ = [[[NSWindow class] alloc] initWithContentRect:NSZeroRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [background_ orderFront:nil];
    [background_ setLevel:NSMainMenuWindowLevel - 2];
    [background_ setIgnoresMouseEvents:YES];
    [background_ setOpaque:NO];
    [background_ setHasShadow:NO];
    [background_ setReleasedWhenClosed:YES];
    [background_ setLevel:NSFloatingWindowLevel];
    [background_ setHasShadow:NO];

    QCView* content = [[QCView alloc] init];

    [content setEventForwardingMask:NSMouseMovedMask];
    [background_ setContentView:content];
    [content release];
    [background_ makeFirstResponder:content];

    NSString* path = [[NSUserDefaults standardUserDefaults] stringForKey:@"TotalTerminalVisorBackgroundAnimationFile"];
    path = [path stringByStandardizingPath];

    NSFileManager* fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        NSLog(@"animation does not exist: %@", path);
        path = nil;
    }
    if (!path) {
        path = [[NSBundle bundleForClass:[self class]] pathForResource:@"Visor" ofType:@"qtz"];
    }
    [content loadCompositionFromFile:path];
    [content setMaxRenderingFrameRate:15.0];
    [self updateAnimationAlpha];
    if (window_ && ![self isHidden]) {
        [window_ orderFront:nil];
    }
}

-(void) destroyBackground {
    if (!background_) {
        return;
    }
    
    [background_ release];
    background_ = nil;
}

// credit: http://tonyarnold.com/entries/fixing-an-annoying-expose-bug-with-nswindows/
-(void) setupExposeTags:(NSWindow*)win {
    CGSConnection cid;
    CGSWindow wid;
    CGSWindowTag tags[2];
    bool showOnEverySpace = [[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalVisorOnEverySpace"];

    wid = [win windowNumber];
    if (wid > 0) {
        cid = _CGSDefaultConnection();
        tags[0] = CGSTagSticky;
        tags[1] = (CGSWindowTag)0;

        if (showOnEverySpace)
            CGSSetWindowTags(cid, wid, tags, 32);
        else
            CGSClearWindowTags(cid, wid, tags, 32);
        tags[0] = (CGSWindowTag)CGSTagExposeFade;
        CGSSetWindowTags(cid, wid, tags, 32);
    }
}

-(float) getVisorAnimationBackgroundAlpha {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"TotalTerminalVisorBackgroundAnimationOpacity"] / 100.0f;
}

-(void) updateAnimationAlpha {
    if ((background_ != nil) && !isHidden) {
        float bkgAlpha = [self getVisorAnimationBackgroundAlpha];
        [background_ setAlphaValue:bkgAlpha];
    }
}

-(float) getVisorProfileBackgroundAlpha {
    id bckColor = background_ ? [[[self class] getVisorProfile] valueForKey:@"BackgroundColor"] : nil;

    return bckColor ? [bckColor alphaComponent] : 1.0;
}

-(void) updateVisorWindowSpacesSettings {
    AUTO_LOGGER();
    if (!window_) {
        return;
    }
    bool showOnEverySpace = [[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalVisorOnEverySpace"];

    if (showOnEverySpace) {
        [window_ setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorIgnoresCycle];
    } else {
        [window_ setCollectionBehavior:NSWindowCollectionBehaviorDefault | NSWindowCollectionBehaviorTransient | NSWindowCollectionBehaviorIgnoresCycle];
    }
}

-(void) updateVisorWindowLevel {
    AUTO_LOGGER();
    if (!window_) {
        return;
    }
    // https://github.com/binaryage/totalterminal/issues/15
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalVisorWindowOnHighLevel"]) {
        [window_ setLevel:NSFloatingWindowLevel];
    } else {
        [window_ setLevel:NSMainMenuWindowLevel - 1];
    }
}

-(void) adoptTerminal:(id)win {
    LOG(@"adoptTerminal window=%@", win);
    if (window_) {
        LOG(@"adoptTerminal called when old window existed");
    }

    [self setWindow:win];
    [self updateVisorWindowLevel];
    [self updateVisorWindowSpacesSettings];

    [self updateStatusMenu];
}

-(void) resetWindowPlacement {
    ScopedNSDisableScreenUpdatesWithDelay disabler(0.05, __FUNCTION__); // prevent ocasional flickering

    [lastPosition_ release];
    lastPosition_ = nil;
    if (window_) {
        float offset = 1.0f;
        if (isHidden)
            offset = 0.0f;
        LOG(@"resetWindowPlacement %@ %f", window_, offset);
        [self applyVisorPositioning];
    } else {
        LOG(@"resetWindowPlacement called for nil window");
    }
}

-(NSString*) position {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"TotalTerminalVisorPosition"];
}

-(NSScreen*) screen {
    int screenIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"TotalTerminalVisorScreen"];
    NSArray* screens = [NSScreen screens];

    if (screenIndex >= [screens count]) {
        screenIndex = 0;
    }
    if ([screens count] <= 0) {
        return nil; // safety net
    }
    return [screens objectAtIndex:screenIndex];
}

- (NSRect)menubarFrame {
    NSArray *screens = [NSScreen screens];
    
    if (!screens)
        return NSZeroRect;
    
    // menubar is the 0th screen (according to the NSScreen docs)
    NSScreen *mainScreen = [screens objectAtIndex:0];
    NSRect frame = [mainScreen frame];
    
    // since the dock can only be on the bottom or the sides, calculate the difference
    // between the frame and the visibleFrame at the top
    NSRect visibleFrame = [mainScreen visibleFrame];
    NSRect menubarFrame;
    
    menubarFrame.origin.x = NSMinX(frame);
    menubarFrame.origin.y = NSMaxY(visibleFrame);
    menubarFrame.size.width = NSWidth(frame);
    menubarFrame.size.height = NSMaxY(frame) - NSMaxY(visibleFrame);
    
    return menubarFrame;
}

// offset==0.0 means window is "hidden" above top screen edge
// offset==1.0 means window is visible right under top screen edge
-(void) placeWindow:(id)win offset:(float)offset {
    NSScreen* screen = [self screen];
    NSRect screenRect = [screen frame];
    NSRect frame = [win frame];
    // respect menubar area
    // see http://code.google.com/p/blacktree-visor/issues/detail?id=19
    NSRect menubar = [self menubarFrame];
    int shift = menubar.size.height - 1; // -1px to hide bright horizontal line on the edge of chromeless terminal window
    
    NSString* position = [self position];
    if ([position hasPrefix:@"Top"]) {
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - round(offset * (NSHeight(frame) + shift));
    }
    if ([position hasPrefix:@"Left"]) {
        frame.origin.x = screenRect.origin.x - NSWidth(frame) + round(offset * NSWidth(frame));
    }
    if ([position hasPrefix:@"Right"]) {
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect) - round(offset * NSWidth(frame));
    }
    if ([position hasPrefix:@"Bottom"]) {
        frame.origin.y = screenRect.origin.y - NSHeight(frame) + round(offset * NSHeight(frame));
    }
    [win setFrameOrigin:frame.origin];
    if (background_) {
        [background_ setFrame:[window_ frame] display:YES];
    }
}

-(void) initializeBackground {
    BOOL useBackground = [[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalVisorUseBackgroundAnimation"];
    if (useBackground) {
        [self createBackground];
    } else {
        [self destroyBackground];
    }
    [self applyVisorPositioning];
}

-(void) resetVisorWindowSize {
    AUTO_LOGGER();
    // this block is needed to prevent "<NSSplitView>: the delegate <InterfaceController> was sent -splitView:resizeSubviewsWithOldSize: and left the subview frames in an inconsistent state" type of message
    // http://cocoadev.com/forums/comments.php?DiscussionID=1092
    // this issue is only on Snow Leopard (10.6), because it is newly using NSSplitViews
    NSRect safeFrame;
    safeFrame.origin.x = 0;
    safeFrame.origin.y = 0;
    safeFrame.size.width = 1000;
    safeFrame.size.height = 1000;
    [window_ setFrame:safeFrame display:NO];

    // this is a better way of 10.5 path for Terminal on Snow Leopard
    // we may call returnToDefaultSize method on our window's view
    // no more resizing issues like described here: http://github.com/darwin/visor/issues/#issue/1
    id controller = [window_ windowController];
    id tabc = [controller selectedTabController];
    id pane = [tabc activePane];
    id view = [pane view];
    [view returnToDefaultSize:self];
}

-(void) applyVisorPositioning {
    AUTO_LOGGER();
    if (!window_) {
        return; // safety net
    }
    NSDisableScreenUpdates();
    NSScreen* screen = [self screen];
    NSRect screenRect = [screen frame];
    NSString* position = [[NSUserDefaults standardUserDefaults] stringForKey:@"TotalTerminalVisorPosition"];
    if (![position isEqualToString:lastPosition_]) {
        // note: cursor may jump during this operation, so do it only in rare cases when position changes
        // for more info see http://github.com/darwin/visor/issues#issue/27
        [self resetVisorWindowSize];
    }
    [lastPosition_ release];
    lastPosition_ = [position retain];
    // respect menubar area
    // see http://code.google.com/p/blacktree-visor/issues/detail?id=19
    NSRect menubar = [self menubarFrame];
    int shift = menubar.size.height - 1; // -1px to hide bright horizontal line on the edge of chromeless terminal window
    if ([position isEqualToString:@"Top-Stretch"]) {
        NSRect frame = [window_ frame];
        frame.size.width = screenRect.size.width;
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - shift;
        [window_ setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Top-Left"]) {
        NSRect frame = [window_ frame];
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - shift;
        [window_ setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Top-Right"]) {
        NSRect frame = [window_ frame];
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect) - NSWidth(frame);
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - shift;
        [window_ setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Top-Center"]) {
        NSRect frame = [window_ frame];
        frame.origin.x = screenRect.origin.x + (NSWidth(screenRect) - NSWidth(frame)) / 2;
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - shift;
        [window_ setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Left-Stretch"]) {
        NSRect frame = [window_ frame];
        frame.size.height = screenRect.size.height - shift;
        frame.origin.x = screenRect.origin.x - NSWidth(frame);
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - NSHeight(frame) - shift;
        [window_ setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Left-Top"]) {
        NSRect frame = [window_ frame];
        frame.origin.x = screenRect.origin.x - NSWidth(frame);
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - NSHeight(frame) - shift;
        [window_ setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Left-Bottom"]) {
        NSRect frame = [window_ frame];
        frame.origin.x = screenRect.origin.x - NSWidth(frame);
        frame.origin.y = screenRect.origin.y;
        [window_ setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Left-Center"]) {
        NSRect frame = [window_ frame];
        frame.origin.x = screenRect.origin.x - NSWidth(frame);
        frame.origin.y = screenRect.origin.y + (NSHeight(screenRect) - NSHeight(frame)) / 2;
        [window_ setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Right-Stretch"]) {
        NSRect frame = [window_ frame];
        frame.size.height = screenRect.size.height - shift;
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect);
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - NSHeight(frame) - shift;
        [window_ setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Right-Top"]) {
        NSRect frame = [window_ frame];
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect);
        frame.origin.y = screenRect.origin.y + NSHeight(screenRect) - NSHeight(frame) - shift;
        [window_ setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Right-Bottom"]) {
        NSRect frame = [window_ frame];
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect);
        frame.origin.y = screenRect.origin.y;
        [window_ setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Right-Center"]) {
        NSRect frame = [window_ frame];
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect);
        frame.origin.y = screenRect.origin.y + (NSHeight(screenRect) - NSHeight(frame)) / 2;
        [window_ setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Bottom-Stretch"]) {
        NSRect frame = [window_ frame];
        frame.size.width = screenRect.size.width;
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y - NSHeight(frame);
        [window_ setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Bottom-Left"]) {
        NSRect frame = [window_ frame];
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y - NSHeight(frame);
        [window_ setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Bottom-Right"]) {
        NSRect frame = [window_ frame];
        frame.origin.x = screenRect.origin.x + NSWidth(screenRect) - NSWidth(frame);
        frame.origin.y = screenRect.origin.y - NSHeight(frame);
        [window_ setFrame:frame display:YES];
    }
    if ([position isEqualToString:@"Bottom-Center"]) {
        NSRect frame = [window_ frame];
        frame.origin.x = screenRect.origin.x + (NSWidth(screenRect) - NSWidth(frame)) / 2;
        frame.origin.y = screenRect.origin.y - NSHeight(frame);
        [window_ setFrame:frame display:YES];
    }
    BOOL shouldForceFullScreenWindow = [[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalVisorFullScreen"];
    if ([position isEqualToString:@"Full Screen"] || shouldForceFullScreenWindow) {
        NSRect frame = [window_ frame];
        frame.size.width = screenRect.size.width;
        frame.size.height = screenRect.size.height - shift;
        frame.origin.x = screenRect.origin.x;
        frame.origin.y = screenRect.origin.y;
        [window_ setFrame:frame display:YES];
    }
    if (background_) {
        [[background_ contentView] startRendering];
    }
    [self slideWindows:!isHidden fast:YES];
    NSEnableScreenUpdates();
}

-(void) showVisor:(BOOL)fast {
    AUTO_LOGGERF(@"fast=%d isHidden=%d", fast, isHidden);
    if (!isHidden) return;

    [self updateStatusMenu];
    [self storePreviouslyActiveApp];
    [self applyVisorPositioning];

    isHidden = false;
    [window_ makeKeyAndOrderFront:self];
    [window_ setHasShadow:YES];
    [NSApp activateIgnoringOtherApps:YES];
    [window_ update];
    [self slideWindows:1 fast:fast];
    [window_ invalidateShadow];
    [window_ update];
}

-(void) hideOnEscape {
    AUTO_LOGGER();
    [self hideVisor:NO];
}

-(void) hideVisor:(BOOL)fast {
    if (isHidden) return;

    AUTO_LOGGER();
    isHidden = true;
    [self updateStatusMenu];
    [window_ update];
    [self slideWindows:0 fast:fast];
    [window_ setHasShadow:NO];
    [window_ invalidateShadow];
    [window_ update];
    if (background_) {
        [[background_ contentView] stopRendering];
    }

    {
        // in case of Visor and classic Terminal.app window
        // this will prevent a brief window blinking before final focus gets restored
        ScopedNSDisableScreenUpdatesWithDelay disabler(0.1, __FUNCTION__);

        BOOL hadKeyStatus = [window_ isKeyWindow];

        // this is important to return focus some other classic Terminal window in case it was active prior Visor sliding down
        // => https://github.com/binaryage/totalterminal/issues/13 and http://getsatisfaction.com/binaryage/topics/return_focus_to_other_terminal_window
        [window_ orderOut:self];

        // if visor window loses key status during open-session, do not transfer key status back to previous app
        // see https://github.com/binaryage/totalterminal/issues/26
        if (hadKeyStatus) {
            [self restorePreviouslyActiveApp]; // this is no-op in case Terminal was active app prior Visor sliding down
        }
    }
}

-(void) slideWindows:(BOOL)direction fast:(bool)fast {
    // true == down
    float bkgAlpha = [self getVisorAnimationBackgroundAlpha];

    if (!fast) {
        BOOL doSlide = [[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalVisorUseSlide"];
        BOOL doFade = [[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalVisorUseFade"];
        float animSpeed = [[NSUserDefaults standardUserDefaults] floatForKey:@"TotalTerminalVisorAnimationSpeed"];
        
        // HACK for Mountain Lion, fading crashes windowing server on my machine
        if (terminalVersion()>FIRST_MOUNTAIN_LION_VERSION) {
            if (![[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalDisableMountainLionFadingHack"]) {
                doFade = false;
            }
        }

        // animation loop
        if (doFade || doSlide) {
            if (!doSlide && direction) {
                // setup final slide position in case of no sliding
                float offset = SLIDE_DIRECTION(direction, SLIDE_EASING(1));
                [self placeWindow:window_ offset:offset];
            }
            if (!doFade && direction) {
                // setup final alpha state in case of no alpha
                float alpha = ALPHA_DIRECTION(direction, ALPHA_EASING(1));
                if (background_) {
                    [background_ setAlphaValue:alpha * bkgAlpha];
                }
                [window_ setAlphaValue:alpha];
            }
            NSTimeInterval t;
            NSDate* date = [NSDate date];
            while (animSpeed > (t = -[date timeIntervalSinceNow])) {
                // animation update loop
                float k = t / animSpeed;
                if (doSlide) {
                    float offset = SLIDE_DIRECTION(direction, SLIDE_EASING(k));
                    [self placeWindow:window_ offset:offset];
                }
                if (doFade) {
                    float alpha = ALPHA_DIRECTION(direction, ALPHA_EASING(k));
                    if (background_) {
                        [background_ setAlphaValue:alpha * bkgAlpha];
                    }
                    [window_ setAlphaValue:alpha];
                }
                usleep(background_ ? 1000 : 5000); // 1 or 5ms
            }
        }
    }

    // apply final slide and alpha states
    float offset = SLIDE_DIRECTION(direction, SLIDE_EASING(1));
    [self placeWindow:window_ offset:offset];
    float alpha = ALPHA_DIRECTION(direction, ALPHA_EASING(1));
    [window_ setAlphaValue:alpha];
    if (background_) {
        [background_ setAlphaValue:alpha * bkgAlpha];
    }
}

-(BOOL) isPinned {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalVisorPinned"];
}

-(void) resignKey:(id)sender {
    LOG(@"resignKey %@", sender);
    isKey = false;
    [self updateEscapeHotKeyRegistration];
    [self updateFullScreenHotKeyRegistration];
    if (!isMain && !isKey && !isHidden && ![self isPinned]) {
        [self hideVisor:false];
    }
}

-(void) resignMain:(id)sender {
    LOG(@"resignMain %@", sender);
    isMain = false;
    if (!isMain && !isKey && !isHidden && ![self isPinned]) {
        [self hideVisor:false];
    }
}

-(void) becomeKey:(id)sender {
    LOG(@"becomeKey %@", sender);
    isKey = true;
    [self updateEscapeHotKeyRegistration];
    [self updateFullScreenHotKeyRegistration];
}

-(void) becomeMain:(id)sender {
    LOG(@"becomeMain %@", sender);
    isMain = true;
}

-(void) didChangeScreenScreenParameters:(id)sender {
    AUTO_LOGGERF(@"sender=%@", sender);
    [self resetWindowPlacement];
}

-(void) willClose:(NSNotification*)inNotification {
    AUTO_LOGGERF(@"notification=%@", inNotification);
    [self setWindow:nil];
    [self updateStatusMenu];
    [self updateMainMenuState];
}

-(void) updateShouldShowTransparencyAlert {
    [self willChangeValueForKey:@"shouldShowTransparencyAlert"];
    [self didChangeValueForKey:@"shouldShowTransparencyAlert"];
}

-(NSNumber*) shouldShowTransparencyAlert {
    return ([[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalVisorUseBackgroundAnimation"] &&
            ((float)[self getVisorProfileBackgroundAlpha] >= 1.0f))
           ? (NSNumber*)kCFBooleanTrue : (NSNumber*)kCFBooleanFalse;
}

-(BOOL) isHidden {
    return isHidden;
}

-(void) updateHotKeyRegistration {
    AUTO_LOGGER();
    GTMCarbonEventDispatcherHandler* dispatcher = [NSClassFromString (@"GTMCarbonEventDispatcherHandler")sharedEventDispatcherHandler];

    if (hotKey_) {
        [dispatcher unregisterHotKey:hotKey_];
        hotKey_ = nil;
        hotModifiers_ = 0;
    }

    NSMenuItem* statusMenuItem = [statusMenu itemAtIndex:0];
    NSString* statusMenuItemKey = @"";
    uint statusMenuItemModifiers = 0;
    [statusMenuItem setKeyEquivalent:statusMenuItemKey];
    [statusMenuItem setKeyEquivalentModifierMask:statusMenuItemModifiers];

    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];

    KeyCombo combo = [self keyComboForShortcut:eToggleVisor];
    BOOL hotkey2Enabled = [ud boolForKey:@"TotalTerminalVisorHotKey2Enabled"];

    if (hotkey2Enabled) {
        // set up double tap if appropriate
        hotModifiers_ = [ud integerForKey:@"TotalTerminalVisorHotKey2Mask"];
        if (!hotModifiers_) {
            hotModifiers_ = NSAlternateKeyMask;
        }
    }
    if (combo.code != -1) {
        // setting hotModifiers_ means we're not looking for a double tap
        hotKey_ = [dispatcher registerHotKey:combo.code
                                   modifiers:combo.flags
                                      target:self
                                      action:@selector(toggleVisor:)
                                    userInfo:nil
                                 whenPressed:YES];

        Class GTMHotKeyTextFieldCellClass = NSClassFromString(@"GTMHotKeyTextFieldCell");
        NSBundle* bundle = [NSBundle bundleForClass:GTMHotKeyTextFieldCellClass];
        statusMenuItemKey = [GTMHotKeyTextFieldCellClass stringForKeycode:combo.code useGlyph:YES resourceBundle:bundle];
        statusMenuItemModifiers = combo.flags;
        [statusMenuItem setKeyEquivalent:statusMenuItemKey];
        [statusMenuItem setKeyEquivalentModifierMask:statusMenuItemModifiers];
    }
}

-(void) updateEscapeHotKeyRegistration {
    AUTO_LOGGER();
    BOOL hideOnEscape = [[NSUserDefaults standardUserDefaults] boolForKey:@"TotalTerminalVisorHideOnEscape"];

    if (hideOnEscape && isKey) {
        if (!escapeHotKey) {
            GTMCarbonEventDispatcherHandler* dispatcher = [NSClassFromString (@"GTMCarbonEventDispatcherHandler")sharedEventDispatcherHandler];
            escapeHotKey = [dispatcher registerHotKey:53 // ESC
                                            modifiers:0
                                               target:self
                                               action:@selector(hideOnEscape)
                                             userInfo:nil
                                          whenPressed:YES];
        }
    } else {
        if (escapeHotKey) {
            GTMCarbonEventDispatcherHandler* dispatcher = [NSClassFromString (@"GTMCarbonEventDispatcherHandler")sharedEventDispatcherHandler];
            [dispatcher unregisterHotKey:escapeHotKey];
            escapeHotKey = nil;
        }
    }
}

-(void) updateFullScreenHotKeyRegistration {
    AUTO_LOGGER();
    if (isKey) {
        if (!fullScreenKey_) {
            // setting hotModifiers_ means we're not looking for a double tap
            GTMCarbonEventDispatcherHandler* dispatcher = [NSClassFromString (@"GTMCarbonEventDispatcherHandler")sharedEventDispatcherHandler];
            fullScreenKey_ = [dispatcher registerHotKey:0x3 // F
                                              modifiers:NSCommandKeyMask|NSAlternateKeyMask
                                                 target:self
                                                 action:@selector(fullScreenToggle:)
                                               userInfo:nil
                                            whenPressed:YES];
        }
    } else {
        if (fullScreenKey_) {
            GTMCarbonEventDispatcherHandler* dispatcher = [NSClassFromString (@"GTMCarbonEventDispatcherHandler")sharedEventDispatcherHandler];
            [dispatcher unregisterHotKey:fullScreenKey_];
            fullScreenKey_ = nil;
        }
    }
}

// Returns the amount of time between two clicks to be considered a double click
-(NSTimeInterval) doubleClickTime {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSTimeInterval doubleClickThreshold = [defaults doubleForKey:@"com.apple.mouse.doubleClickThreshold"];

    // if we couldn't find the value in the user defaults, take a
    // conservative estimate
    if (doubleClickThreshold <= 0.0) {
        doubleClickThreshold = 1.0;
    }
    return doubleClickThreshold;
}

-(void) modifiersChangedWhileActive:(NSEvent*)event {
    // A statemachine that tracks our state via hotModifiersState_. Simple incrementing state.
    if (!hotModifiers_) {
        return;
    }
    NSTimeInterval timeWindowToRespond = lastHotModifiersEventCheckedTime_ + [self doubleClickTime];
    lastHotModifiersEventCheckedTime_ = [event timestamp];
    if (hotModifiersState_ && (lastHotModifiersEventCheckedTime_ > timeWindowToRespond)) {
        // Timed out. Reset.
        hotModifiersState_ = 0;
        return;
    }
    NSUInteger flags = [event qsbModifierFlags];
    NSLOG3(@"modifiersChangedWhileActive: %@ %08x %08x", event, flags, hotModifiers_);
    BOOL isGood = NO;
    if (!(hotModifiersState_ % 2)) {
        // This is key down cases
        isGood = flags == hotModifiers_;
    } else {
        // This is key up cases
        isGood = flags == 0;
    }
    if (!isGood) {
        // reset
        hotModifiersState_ = 0;
        return;
    } else {
        hotModifiersState_ += 1;
    }
    NSLOG3(@"  => %d", hotModifiersState_);
    if (hotModifiersState_ >= 3) {
        // We've worked our way through the state machine to success!
        [self toggleVisor:self];
        hotModifiersState_ = 0;
    }
}

// method that is called when a key changes state and we are active
-(void) keysChangedWhileActive:(NSEvent*)event {
    if (!hotModifiers_) return;

    hotModifiersState_ = 0;
}

// method that is called when the modifier keys are hit and we are inactive
-(void) modifiersChangedWhileInactive:(NSEvent*)event {
    // If we aren't activated by hotmodifiers, we don't want to be here
    // and if we are in the process of activating, we want to ignore the hotkey
    // so we don't try to process it twice.
    if (!hotModifiers_ || [NSApp keyWindow]) return;

    NSUInteger flags = [event qsbModifierFlags];
    NSLOG3(@"modifiersChangedWhileInactive: %@ %08x %08x", event, flags, hotModifiers_);
    if (flags != hotModifiers_) return;

    const useconds_t oneMilliSecond = 10000;
    UInt16 modifierKeys[] = {
        0,
        kVK_Shift,
        kVK_CapsLock,
        kVK_RightShift,
    };
    if (hotModifiers_ == NSControlKeyMask) {
        modifierKeys[0] = kVK_Control;
    } else if (hotModifiers_ == NSAlternateKeyMask) {
        modifierKeys[0] = kVK_Option;
    } else if (hotModifiers_ == NSCommandKeyMask) {
        modifierKeys[0] = kVK_Command;
    }
    QSBKeyMap* hotMap = [[[QSBKeyMap alloc] initWithKeys:modifierKeys count:1] autorelease];
    QSBKeyMap* invertedHotMap = [[[QSBKeyMap alloc] initWithKeys:modifierKeys count:sizeof(modifierKeys) / sizeof(UInt16)] autorelease];
    invertedHotMap = [invertedHotMap keyMapByInverting];
    NSTimeInterval startDate = [NSDate timeIntervalSinceReferenceDate];
    BOOL isGood = NO;
    while (([NSDate timeIntervalSinceReferenceDate] - startDate) < [self doubleClickTime]) {
        QSBKeyMap* currentKeyMap = [QSBKeyMap currentKeyMap];
        if ([currentKeyMap containsAnyKeyIn:invertedHotMap] || GetCurrentButtonState()) {
            return;
        }
        if (![currentKeyMap containsAnyKeyIn:hotMap]) {
            // Key released;
            isGood = YES;
            break;
        }
        usleep(oneMilliSecond);
    }
    if (!isGood) return;

    isGood = NO;
    startDate = [NSDate timeIntervalSinceReferenceDate];
    while (([NSDate timeIntervalSinceReferenceDate] - startDate) < [self doubleClickTime]) {
        QSBKeyMap* currentKeyMap = [QSBKeyMap currentKeyMap];
        if ([currentKeyMap containsAnyKeyIn:invertedHotMap] || GetCurrentButtonState()) {
            return;
        }
        if ([currentKeyMap containsAnyKeyIn:hotMap]) {
            // Key down
            isGood = YES;
            break;
        }
        usleep(oneMilliSecond);
    }
    if (!isGood) return;

    startDate = [NSDate timeIntervalSinceReferenceDate];
    while (([NSDate timeIntervalSinceReferenceDate] - startDate) < [self doubleClickTime]) {
        QSBKeyMap* currentKeyMap = [QSBKeyMap currentKeyMap];
        if ([currentKeyMap containsAnyKeyIn:invertedHotMap]) {
            return;
        }
        if (![currentKeyMap containsAnyKeyIn:hotMap]) {
            // Key Released
            isGood = YES;
            break;
        }
        usleep(oneMilliSecond);
    }
    if (isGood) {
        [self toggleVisor:self];
    }
}

-(BOOL) status {
    return !!window_;
}

-(BOOL) isVisorWindow:(id)win {
    return window_ == win;
}

static const EventTypeSpec kModifierEventTypeSpec[] = { {
                                                            kEventClassKeyboard, kEventRawKeyModifiersChanged
                                                        }
};
static const size_t kModifierEventTypeSpecSize = sizeof(kModifierEventTypeSpec) / sizeof(EventTypeSpec);

// Allows me to intercept the "control" double tap to activate QSB. There
// appears to be no way to do this from straight Cocoa.
-(void) startEventMonitoring {
    GTMCarbonEventMonitorHandler* handler = [GTMCarbonEventMonitorHandler sharedEventMonitorHandler];

    [handler registerForEvents:kModifierEventTypeSpec count:kModifierEventTypeSpecSize];
    [handler setDelegate:self];
}

-(void) stopEventMonitoring {
    GTMCarbonEventMonitorHandler* handler = [GTMCarbonEventMonitorHandler sharedEventMonitorHandler];

    [handler unregisterForEvents:kModifierEventTypeSpec count:kModifierEventTypeSpecSize];
    [handler setDelegate:nil];
}

-(OSStatus) gtm_eventHandler:(GTMCarbonEventHandler*)sender
               receivedEvent:(GTMCarbonEvent*)event
                     handler:(EventHandlerCallRef)handler {
    OSStatus status = eventNotHandledErr;

    if (([event eventClass] == kEventClassKeyboard) &&
        ([event eventKind] == kEventRawKeyModifiersChanged)) {
        UInt32 modifiers;
        if ([event getUInt32ParameterNamed:kEventParamKeyModifiers data:&modifiers]) {
            NSUInteger cocoaMods = GTMCarbonToCocoaKeyModifiers(modifiers);
            NSEvent* nsEvent = [NSEvent    keyEventWithType:NSFlagsChanged
                                                   location:[NSEvent mouseLocation]
                                              modifierFlags:cocoaMods
                                                  timestamp:[event time]
                                               windowNumber:0
                                                    context:nil
                                                 characters:nil
                                charactersIgnoringModifiers:nil
                                                  isARepeat:NO
                                                    keyCode:0];
            [self modifiersChangedWhileInactive:nsEvent];
        }
    }
    return status;
}

+(void) loadVisor {
    if (terminalVersion() < FIRST_MOUNTAIN_LION_VERSION) {
        SWIZZLE(TTWindowController, newTabWithProfile:);
        if (terminalVersion() < FIRST_LION_VERSION) {
            SWIZZLE(TTWindowController, newTabWithProfile: command: runAsShell:);
        } else {
            SWIZZLE(TTWindowController, newTabWithProfile: customFont: command: runAsShell: restorable: workingDirectory: sessionClass: restoreSession:);
        }
    } else {
        SWIZZLE(TTWindowController, makeTabWithProfile:);
        SWIZZLE(TTWindowController, makeTabWithProfile: customFont: command: runAsShell: restorable: workingDirectory: sessionClass: restoreSession:);
    }
    
    SWIZZLE(TTWindowController, setCloseDialogExpected:);
    SWIZZLE(TTWindowController, window: willPositionSheet: usingRect:);

    SWIZZLE(TTWindow, initWithContentRect: styleMask: backing: defer:);
    SWIZZLE(TTWindow, canBecomeKeyWindow);
    SWIZZLE(TTWindow, canBecomeMainWindow);
    SWIZZLE(TTWindow, performClose:);

    SWIZZLE(TTApplication, sendEvent:);
    SWIZZLE(TTApplication, applicationShouldHandleReopen: hasVisibleWindows:);

    LOG(@"Visor installed");
}

-(void) openVisor {
    // prevents showing misplaced visor window briefly
    ScopedNSDisableScreenUpdates disabler(__FUNCTION__);

    id visorProfile = [TotalTerminal getVisorProfile];
    id app = [NSClassFromString (@"TTApplication")sharedApplication];
    if (terminalVersion()<FIRST_MOUNTAIN_LION_VERSION) {
        id controller = [app newWindowControllerWithProfile:visorProfile]; // TODO: make static analyzer happy here, this is not a leak, controller goes away with window close
    } else {
        id controller = [app makeWindowControllerWithProfile:visorProfile]; // ah, Ben started following Cocoa naming conventions, good! :-)
    }

    [self resetWindowPlacement];
    [self updatePreferencesUI];
    [self updateStatusMenu];
    [self updateMainMenuState];
}

@end
