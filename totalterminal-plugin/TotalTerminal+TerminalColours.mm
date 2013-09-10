// taken from http://github.com/evanphx/terminalcolours/commit/20eb738a5c81349a3b0189ee7eb25de589abf987

#undef PROJECT
#define PROJECT TerminalColours
#import "TotalTerminal+TerminalColours.h"

#import "TTAppPrefsController.h"

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

@implementation NSView (TotalTerminal)
-(id) SMETHOD (TTView, colorForANSIColor):(unsigned int)index;
{
  id colour = nil;

  if (index > 0) {
    colour = [[self performSelector:@selector(profile)] valueForKey:colourKeys[index]];
  }

  return colour ? : [self SMETHOD (TTView, colorForANSIColor):index];
}

-(id) SMETHOD (TTView, colorForANSIColor):(unsigned int)index adjustedRelativeToColor:(id)arg2;
{
  id colour = nil;

  if (index > 0) {
    colour = [[self performSelector:@selector(profile)] valueForKey:colourKeys[index]];
  }

  return colour ? : [self SMETHOD (TTView, colorForANSIColor):index adjustedRelativeToColor:arg2];
}
@end

@implementation NSObject (TotalTerminal)
// ===========================
// = Setting/getting colours =
// ===========================

-(void) setColour:(id)value forKey:(NSString*)key {
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

-(id) colourForKey:(NSString*)key {
  NSMutableDictionary* values = [self valueForKey:@"values"];
  id colour = [values objectForKey:key];

  if ([colour isKindOfClass:[NSData class]]) {
    // We can’t swizzle initWithPropertyListRepresentation before the settings are loaded
    // so we need to check and unarchive data here
    [self setColour:[NSUnarchiver unarchiveObjectWithData:colour] forKey:key];
    colour = [self colourForKey:key];
  }
  if ((colour == nil) && ![key isEqualToString:@"noColour"]) {
    // redColor → vtRedColour – these are NSColor category methods
    // added by Terminal which return the default colours
    NSString* valueKey = [NSString stringWithFormat:@"vt%c%@Color",
                          [key characterAtIndex:0] + ('A' - 'a'),
                          [key substringWithRange:NSMakeRange(1, [key length] - 7)]];
    colour = [NSColor valueForKey:valueKey];
  }
  return colour;
}

// These two are swizzled so that we can use bindings to set the colour values from the nib
-(id) SMETHOD (TTProfile, valueForKey):(NSString*)key {
  if ([key hasSuffix:@"Colour"])
    return [self colourForKey:key];
  else return [self SMETHOD (TTProfile, valueForKey):key];
}

-(void) SMETHOD (TTProfile, setValue):(id)value forKey:(NSString*)key {
  if ([key hasSuffix:@"Colour"])
    [self setColour:value forKey:key];
  else [self SMETHOD (TTProfile, setValue):value forKey:key];
}

// ==================
// = Profile saving =
// ==================

// Save our custom colours into the profile plist
-(id) SMETHOD (TTProfile, propertyListRepresentation) {
  NSMutableDictionary* plist = [[self SMETHOD (TTProfile, propertyListRepresentation)] mutableCopy];
  size_t index;

  for (index = 0; index < sizeof(colourKeys) / sizeof(colourKeys[0]); index++) {
    NSString* colourKey = colourKeys[index];
    if ([self colourForKey:colourKey]) [plist setObject:[NSArchiver archivedDataWithRootObject:[self colourForKey:colourKey]] forKey:colourKey];
  }

  return plist;
}

@end

@implementation NSWindowController (TotalTerminal)

// Add the “More…” button to the text preferences section
-(void) SMETHOD (TTAppPrefsController, windowDidLoad) {
  [self SMETHOD (TTAppPrefsController, windowDidLoad)];

  TTAppPrefsController* prefsController = (TTAppPrefsController*)[NSClassFromString (@"TTAppPrefsController")sharedPreferencesController];
  NSView* windowSettingsView = [[[prefsController valueForKey:@"tabView"] tabViewItemAtIndex:1] view];
  NSTabView* tabView = [[windowSettingsView subviews] objectAtIndex:0];
  NSView* textPrefsView = [[tabView tabViewItemAtIndex:0] view];

  NSButton* configureButton = [[NSButton alloc] init];
  [configureButton setBezelStyle:NSRoundedBezelStyle];
  [[configureButton cell] setControlSize:NSSmallControlSize];
  [configureButton setTitle:@"More…"];
  [configureButton sizeToFit];
  [configureButton setTarget:[TotalTerminal sharedInstance]];
  [configureButton setAction:@selector(orderFrontColourConfiguration:)];
  [configureButton setFrameOrigin:NSMakePoint(233, 128)];
  [textPrefsView addSubview:configureButton];
}

@end

@implementation TotalTerminal (TotalTerminal)

+(void) loadTerminalColours {
  AUTO_LOGGER();

  SWIZZLE(TTProfile, valueForKey:);
  SWIZZLE(TTProfile, setValue: forKey:);
  SWIZZLE(TTProfile, propertyListRepresentation);

  SWIZZLE(TTView, colorForANSIColor:);
  SWIZZLE(TTView, colorForANSIColor: adjustedRelativeToColor:);

  SWIZZLE(TTAppPrefsController, windowDidLoad);
  LOG(@"TerminalColours installed");
}

-(IBAction) orderFrontColourConfiguration:(id)sender {
  if (!colorsWindow_) {
    [NSBundle loadNibNamed:@"Configuration" owner:self];
  }
  [NSApp beginSheet:colorsWindow_ modalForWindow:[sender window] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

-(IBAction) orderOutConfiguration:(id)sender;
{
  [NSApp endSheet:[sender window]];
  [[sender window] orderOut:self];
}

// For binding in the nib
-(TTAppPrefsController*) profilesController {
  return [[NSClassFromString (@"TTAppPrefsController")sharedPreferencesController] performSelector:@selector(profilesController)];
}

@end
