// taken from http://github.com/evanphx/terminalcolours/commit/20eb738a5c81349a3b0189ee7eb25de589abf987

#import "TerminalColours.h"
#import "Versions.h"
#import "JRSwizzle.h"

static NSString* colourKeys[] = {
    @"noColour",
    @"blackColour",
    @"redColour",
    @"greenColour",
    @"yellowColour",
    @"blueColour",
    @"magentaColour",
    @"cyanColour",
    @"whiteColour",
    @"brightBlackColour",
    @"brightRedColour",
    @"brightGreenColour",
    @"brightYellowColour",
    @"brightBlueColour",
    @"brightMagentaColour",
    @"brightCyanColour",
    @"brightWhiteColour",
};

@interface NSObject (TTAppPrefsController_Methods)
+ (id)sharedPreferencesController;
@end

@implementation NSView (TerminalColours)
- (id)TerminalColours_colorForANSIColor:(unsigned int)index;
{
    id colour = nil;

    if(index > 0) {
        colour = [[self performSelector:@selector(profile)] valueForKey:colourKeys[index]];
    }

    return colour ?: [self TerminalColours_colorForANSIColor:index];
}

- (id)TerminalColours_colorForANSIColor:(unsigned int)index adjustedRelativeToColor:(id)arg2;
{
    id colour = nil;

    if(index > 0) {
        colour = [[self performSelector:@selector(profile)] valueForKey:colourKeys[index]];
    }

    return colour ?: [self TerminalColours_colorForANSIColor:index adjustedRelativeToColor:arg2];
}
@end

@implementation NSObject (TTProfile_TerminalColours)
// ===========================
// = Setting/getting colours =
// ===========================

- (void)setColour:(id)value forKey:(NSString*)key
{
    NSMutableDictionary* values = [self valueForKey:@"values"];
    [values setObject:value forKey:key];

    // I can’t see what I need to do to notify that a setting has changed and refresh the display
    // It’s probably done by something observing key paths, so this does the job
    [self performSelector:@selector(setScriptCursorColor:) withObject:[self performSelector:@selector(scriptCursorColor)]];
    
    // Saves the value
    id cursorType = [values objectForKey:@"CursorType"];
    [self setValue:[NSNumber numberWithInt:-1] forKey:@"CursorType"];
    [self setValue:cursorType forKey:@"CursorType"];
}

- (id)colourForKey:(NSString*)key
{
    NSMutableDictionary* values = [self valueForKey:@"values"];
    id colour = [values objectForKey:key];
    if([colour isKindOfClass:[NSData class]])
    {
        // We can’t swizzle initWithPropertyListRepresentation before the settings are loaded
        // so we need to check and unarchive data here
        [self setColour:[NSUnarchiver unarchiveObjectWithData:colour] forKey:key];
        colour = [self colourForKey:key];
    }
    if(colour == nil && ![key isEqualToString:@"noColour"])
    {
        // redColor → vtRedColour – these are NSColor category methods
        // added by Terminal which return the default colours
        NSString* valueKey = [NSString stringWithFormat:@"vt%c%@Color",
            [key characterAtIndex:0] + ('A' - 'a'),
            [key substringWithRange:NSMakeRange(1, [key length] - 7)]];
        colour = [NSColor valueForKey:valueKey];
    }
    return colour;
}

/*
    These two are swizzled so that we can use bindings to set the colour values
    from the nib
*/
- (id)TerminalColours_TTProfile_valueForKey:(NSString*)key;
{
    if([key hasSuffix:@"Colour"])
        return [self colourForKey:key];
    else
        return [self TerminalColours_TTProfile_valueForKey:key];
}

- (void)TerminalColours_TTProfile_setValue:(id)value forKey:(NSString*)key;
{
    if([key hasSuffix:@"Colour"])
        [self setColour:value forKey:key];
    else
        [self TerminalColours_TTProfile_setValue:value forKey:key];
}

// ==================
// = Profile saving =
// ==================

// Save our custom colours into the profile plist
- (id)TerminalColours_propertyListRepresentation;
{
    NSMutableDictionary* plist = [[self TerminalColours_propertyListRepresentation] mutableCopy];
	size_t index;

    for(index = 0; index < sizeof(colourKeys) / sizeof(colourKeys[0]); index++)
    {
        NSString* colourKey = colourKeys[index];
        if([self colourForKey:colourKey])
            [plist setObject:[NSArchiver archivedDataWithRootObject:[self colourForKey:colourKey]] forKey:colourKey];
    }

    return [plist autorelease];
}
@end

@implementation NSWindowController (PrefsWindowDidLoad)
// Add the “More…” button to the text preferences section
- (void)TerminalColours_TTAppPrefsController_windowDidLoad;
{
    [self TerminalColours_TTAppPrefsController_windowDidLoad];

    id prefsController         = [NSClassFromString(@"TTAppPrefsController") sharedPreferencesController];
    NSView* windowSettingsView = [[[prefsController valueForKey:@"tabView"] tabViewItemAtIndex:1] view];
    NSTabView* tabView         = [[windowSettingsView subviews] objectAtIndex:0];
    NSView* textPrefsView      = [[tabView tabViewItemAtIndex:0] view];

    NSButton* configureButton = [[NSButton alloc] init];
    {
        [configureButton setBezelStyle:NSRoundedBezelStyle];
        [[configureButton cell] setControlSize:NSSmallControlSize];
        [configureButton setTitle:@"More…"];
        [configureButton sizeToFit];
        [configureButton setTarget:[TerminalColours sharedInstance]];
        [configureButton setAction:@selector(orderFrontColourConfiguration:)];
        [configureButton setFrameOrigin:NSMakePoint(233, 128)];
        [textPrefsView addSubview:configureButton];
    }
    [configureButton release];
}
@end

@implementation TerminalColours
+ (void)load
{
    if (terminalVersion()>=FIRST_LION_VERSION) {
        // TerminalColours is not needed anymore under Lion, Apple has implemented 256 color support
        return;
    }
    
    [NSClassFromString(@"TTProfile") jr_swizzleMethod:@selector(valueForKey:) withMethod:@selector(TerminalColours_TTProfile_valueForKey:) error:NULL];
    [NSClassFromString(@"TTProfile") jr_swizzleMethod:@selector(setValue:forKey:) withMethod:@selector(TerminalColours_TTProfile_setValue:forKey:) error:NULL];
    
    [NSClassFromString(@"TTView") jr_swizzleMethod:@selector(colorForANSIColor:) withMethod:@selector(TerminalColours_colorForANSIColor:) error:NULL];
    [NSClassFromString(@"TTView") jr_swizzleMethod:@selector(colorForANSIColor:adjustedRelativeToColor:) withMethod:@selector(TerminalColours_colorForANSIColor:adjustedRelativeToColor:) error:NULL];
    [NSClassFromString(@"TTAppPrefsController") jr_swizzleMethod:@selector(windowDidLoad) withMethod:@selector(TerminalColours_TTAppPrefsController_windowDidLoad) error:NULL];
    [NSClassFromString(@"TTProfile") jr_swizzleMethod:@selector(propertyListRepresentation) withMethod:@selector(TerminalColours_propertyListRepresentation) error:NULL];
}

+ (TerminalColours*)sharedInstance
{
    static TerminalColours* plugin = nil;

    if(plugin == nil)
        plugin = [[TerminalColours alloc] init];

    return plugin;
}

- (void)orderFrontColourConfiguration:(id)sender
{
    if(![self window])
        [NSBundle loadNibNamed:@"Configuration" owner:self];
    [NSApp beginSheet:[self window] modalForWindow:[sender window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)orderOutConfiguration:(id)sender;
{
    [NSApp endSheet:[sender window]];
    [[sender window] orderOut:self];
}

// For binding in the nib
- (id)profilesController
{
    return [[NSClassFromString(@"TTAppPrefsController") sharedPreferencesController] performSelector:@selector(profilesController)];
}
@end
