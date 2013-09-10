#ifndef MACROS_H
#define MACROS_H

#import "JRSwizzle.h"
#import "LoggerClientDebug.h"
#import "ScreenUpdates.h"

#define PROJECT Core

// http://stackoverflow.com/questions/195975/how-to-make-a-char-string-from-a-c-macros-value
// PROJECT macro holds current Feature name, in case of Cut&Paste plugin it is symbol CutAndPaste
#define QUOTE_PROJECT_NAME(name) # name
#define STR_PROJECT_NAME(macro) QUOTE_PROJECT_NAME(macro)
#define PROJECT_STR STR_PROJECT_NAME(PROJECT) // => "CutAndPaste"

#define QUOTE_PROJECT_CLASS(name) name ## Plugin
#define STR_PROJECT_CLASS(macro) QUOTE_PROJECT_CLASS(macro)
#define PROJECT_CLASS STR_PROJECT_CLASS(PROJECT) // => CutAndPastePlugin

#define QUOTE_PROJECT_CLASS_STR(name) # name
#define STR_PROJECT_CLASS_STR(macro) QUOTE_PROJECT_CLASS_STR(macro)
#define PROJECT_CLASS_STR(...) STR_PROJECT_CLASS_STR(PROJECT_CLASS(__VA_ARGS__)) // => "CutAndPastePlugin"

#define QUOTE_SMETHOD(name, cn, __VA_ARGS__) TotalTerminal_ ## name ## _ ## cn ## _ ## __VA_ARGS__
#define STR_SMETHOD(macro, cn, __VA_ARGS__) QUOTE_SMETHOD(macro, cn, __VA_ARGS__)
#define SMETHOD(cn, ...) STR_SMETHOD(PROJECT, cn, __VA_ARGS__) // => TotalTerminal_CutAndPaste_ClassName_Selector

#define QUOTE_METHOD_NAME(name) # name
#define STR_METHOD_NAME(macro) QUOTE_METHOD_NAME(macro)
#define SMETHOD_STR(...) STR_METHOD_NAME(SMETHOD(__VA_ARGS__)) // => "TotalTerminal_CutAndPaste_Something"

// swizzling support
#define SWIZZLE(cn, sel) [NSClassFromString(@ # cn) TotalTerminal_jr_swizzleMethod : @selector(sel) withMethod : @selector(SMETHOD(cn,sel))error : NULL];
#define CWIZZLE(cn, sel) [NSClassFromString(@ # cn) TotalTerminal_jr_swizzleClassMethod : @selector(sel) withClassMethod : @selector(SMETHOD(cn,sel))error : NULL];

// http://stackoverflow.com/questions/2459390/localizing-concatenated-or-dynamic-strings
#define $(x) NSLocalizedStringWithDefaultValue(x, @ PROJECT_STR, [[PROJECT_CLASS class ] mainBundle], x, nil)
#define $$(x) NSString stringWithFormat : $(x)

#if defined(DEBUG)
# define ERROR(format, ...) NSBeep(), NSLog(format, ## __VA_ARGS__)
#else
# define ERROR(format, ...) NSLog(format, ## __VA_ARGS__)
#endif
#define INFO(format, ...) NSLog(format, ## __VA_ARGS__)

#if defined(DEBUG)
# define DCHECK(condition) (((condition)) ? (void)0 : (NSBeep(), NSLog(@ "Check failed: %s (%s:%d) [%@ %s]", # condition, __FILE__, __LINE__, @ TAG, __PRETTY_FUNCTION__)))
#else
# define DCHECK(condition)
#endif

#import "AutoLogger.h"

#endif // MACROS_H
