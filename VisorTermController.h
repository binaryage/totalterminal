//
//  VisorTermController.h
//  Visor
//
//  Created by Nicholas Jitkoff on 6/11/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
 
@class TermView,Splitter,Shell,TermEmulator,vt52,vt100,TermDefaults,TermStorage;
@interface TermController : NSWindowController
{
    TermView *termView;
    Splitter *splitter;
    BOOL scrolling;
    Shell *shell;
    TermEmulator *emulator;
    vt52 *vt52emulator;
    vt100 *vt100emulator;
    TermDefaults *defaults;
    TermStorage *storage;
    NSString *filename;
    int windowsMenuNumber;
    int oldTitleBits;
    int originalRows;
    int originalColumns;
    BOOL ignoreResize;
    BOOL liveResize;
    double updateContentsDelay;
    BOOL pendingUpdateContents;
    BOOL pendingUpdateScroller;
    BOOL bellCanceled;
    NSSound *bellSound;
    int bellRepeats;
    NSView *accessoryView;
    NSCell *printSelectedRangeMatrixCell;
    NSTextView *printTextView;
    NSImage *termBackground;
    NSImage *originalImage;
}

- (id)init;
- (id)initWithDefaults:(id)fp8;
- (id)initWithFactoryDefaults;
- (void)windowDidLoad;
- (void)dealloc;
- (id)defaults;
- (id)filename;
- (void)setFilename:(id)fp8;
- (BOOL)scrolling;
- (id)termView;
- (id)termBackground;
- (void)resetTermBackground;
- (id)shell;
- (void)shell:(id)fp8 childDidExitWithStatus:(int)fp12;
- (void)sendBreak:(id)fp8;
- (void)sendReset:(id)fp8;
- (void)sendHardReset:(id)fp8;
- (id)emulator;
- (void)emulateVt52AtRow:(unsigned int)fp8 column:(unsigned int)fp12 withString:(id)fp16;
- (void)emulateVt102AtRow:(unsigned int)fp8 column:(unsigned int)fp12 withString:(id)fp16;
- (id)storage;
- (void)clearScrollback:(id)fp8;
- (void)pageLayout:(id)fp8;
- (void)printDocument:(id)fp8;
- (void)printOperationDidRun:(id)fp8 success:(BOOL)fp12 contextInfo:(void *)fp16;
- (void)printVisibleRange:(id)fp8;
- (void)printSelectedRange:(id)fp8;
- (void)printScrollbackBuffer:(id)fp8;
- (void)savePanelDidEnd:(id)fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (void)saveTextAs:(id)fp8;
- (void)saveSelectedTextAs:(id)fp8;
- (void)inspector:(id)fp8;
- (void)quickTitle:(id)fp8;
- (void)useAsDefaults:(id)fp8;
- (void)find:(id)fp8;
- (void)findNext:(id)fp8;
- (void)findPrevious:(id)fp8;
- (void)enterSelection:(id)fp8;
- (void)windowDidMove:(id)fp8;
- (struct _NSSize)windowWillResize:(id)fp8 toSize:(struct _NSSize)fp12;
- (void)_endResize;
- (void)windowDidResize:(id)fp8;
- (void)windowDidResignKey:(id)fp8;
- (void)windowDidBecomeKey:(id)fp8;
- (void)windowWillMiniaturize:(id)fp8;
- (void)windowDidDeminiaturize:(id)fp8;
- (BOOL)windowShouldClose:(id)fp8;
- (void)windowWillClose:(id)fp8;
- (void)closeSheetDidEnd:(id)fp8 returnCode:(int)fp12 contextInfo:(void *)fp16;
- (int)windowsMenuNumber;
- (void)setWindowsMenuNumber:(int)fp8;
- (void)fontChanged;
- (void)setNeedsDisplay;
- (void)setNeedsDisplayFromLine:(unsigned int)fp8 toLine:(unsigned int)fp12;
- (void)scrollAndSetNeedsDisplayForLines:(unsigned int)fp8;
- (void)_blinkNotification:(id)fp8;
- (void)updateScroller;
- (void)opacityChanged;
- (void)delayedUpdateScroller;
- (void)updateTitle;
- (void)returnToDefaultSize:(id)fp8;
- (void)updateSize;
- (void)updateSizeForRows:(unsigned int)fp8 columns:(unsigned int)fp12;
- (void)_updateContents;
- (void)delayedUpdateContents;
- (void)updateContents;
- (void)ringBell;
- (void)cancelBell;
- (void)sound:(id)fp8 didFinishPlaying:(BOOL)fp12;
- (void)setWindowContentSizeManually:(struct _NSSize)fp8;
- (void)terminalWillStartLiveResize;
- (void)terminalDidEndLiveResize;
- (void)selectAll:(id)fp8;

@end

@interface VisorTermController : TermController {
	id delegate;
}
- (id) delegate;
- (void) setDelegate: (id) newDelegate;
@end
