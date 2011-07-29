/*******************************************************************************
 JRSwizzle.h
 Copyright (c) 2007 Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
 Some rights reserved: <http://opensource.org/licenses/mit-license.php>
 
 ***************************************************************************/

#import <Foundation/Foundation.h>

@interface NSObject (TotalTerminal_Swizzling)
+(BOOL)TotalTerminal_jr_swizzleMethod:(SEL) origSel_ withMethod:(SEL) altSel_ error:(NSError**)error_;
+(BOOL)TotalTerminal_jr_swizzleClassMethod:(SEL) origSel_ withClassMethod:(SEL) altSel_ error:(NSError**)error_;
@end
