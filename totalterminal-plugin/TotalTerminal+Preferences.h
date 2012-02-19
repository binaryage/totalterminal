#import "TTAppPrefsController.h"

#import "TotalTerminal.h"

@interface TTAppPrefsController (TotalTerminal)
-(void)SMETHOD(TTAppPrefsController, selectVisorPane);
@end

@interface ModifierButtonImageView : NSImageView { }
-(void)mouseDown:(NSEvent*)event;
@end

@interface TotalTerminal (Preferences)

-(NSSize)originalPreferencesSize;
-(void)setOriginalPreferencesSize:(NSSize)size;
-(NSSize)prefPaneSize;
-(NSToolbarItem*)getVisorToolbarItem;

-(void)rotateModifierHotKey;
-(void)updatePreferencesUI;
-(void)storePreferencesPaneSize;

@end
