#ifndef MACROS_H
#define MACROS_H

#import "JRSwizzle.h"
#import "LoggerClient.h"
#import "Notifications.h"
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

#ifdef _DEBUG_MODE
# define ERROR(format, ...) NSBeep(), NSLog(format, ## __VA_ARGS__)
#else
# define ERROR(format, ...) NSLog(format, ## __VA_ARGS__)
#endif
#define INFO(format, ...) NSLog(format, ## __VA_ARGS__)

#ifdef _DEBUG_MODE
# define DCHECK(condition) (condition) ? ((void)0) : (NSLOG(@"Check failed: %s", # condition), ERROR(@ "Check failed: %s [%s:%d]", # condition, __FILE__, __LINE__))
#else
# define DCHECK(condition)
#endif

#ifdef _DEBUG_MODE

// may be redefined later
# define TAG STR_PROJECT_NAME(PROJECT) // => "CutAndPaste"

# ifdef __cplusplus

class IndentingLoggerF {
public:
    IndentingLoggerF(const char* filename, int lineNumber, const char* functionName, NSString* domain, int l, NSString* format, ...) {
        va_list ap;
        
        va_start(ap, format);
        NSString* print = [[NSString alloc] initWithFormat : format arguments:ap];
        va_end(ap);
        
        NSMutableDictionary* ts = [[NSThread currentThread] threadDictionary];
        NSNumber* indent = [ts objectForKey:@ "indent"];
        
        if (!indent) {
            indent = [NSNumber numberWithInt:0];
        }
        
        LogMessageF(filename, lineNumber, functionName, domain, l, @ "%*s%@", [indent intValue] * 3, "", print);
    }
};

#  define NSLOG(...) IndentingLoggerF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, 0, __VA_ARGS__)
#  define NSLOG1(...) IndentingLoggerF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, 1, __VA_ARGS__)
#  define NSLOG2(...) IndentingLoggerF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, 2, __VA_ARGS__)
#  define NSLOG3(...) IndentingLoggerF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, 3, __VA_ARGS__)
#  define NSLOG4(...) IndentingLoggerF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, 4, __VA_ARGS__)
#  define XLOG(...) IndentingLoggerF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, 1, __VA_ARGS__)
#  ifdef YDEBUG
#   define YLOG(...) IndentingLoggerF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, 2, __VA_ARGS__)
#  else
#   define YLOG(...)
#  endif
#  ifdef ZDEBUG
#   define ZLOG(...) IndentingLoggerF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, 3, __VA_ARGS__)
#  else
#   define ZLOG(...)
#  endif

#  define TLOG(tag, level, ...) IndentingLoggerF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ # tag, level, __VA_ARGS__)

# else

#  define NSLOG(...) LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, 0, __VA_ARGS__)
#  define NSLOG1(...) LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, 1, __VA_ARGS__)
#  define NSLOG2(...) LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, 2, __VA_ARGS__)
#  define NSLOG3(...) LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, 3, __VA_ARGS__)
#  define NSLOG4(...) LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, 4, __VA_ARGS__)
#  define XLOG(...) LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, 1, __VA_ARGS__)
#  ifdef YDEBUG
#   define YLOG(...) LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, 2, __VA_ARGS__)
#  else
#   define YLOG(...)
#  endif
#  ifdef ZDEBUG
#   define ZLOG(...) LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, 3, __VA_ARGS__)
#  else
#   define ZLOG(...)
#  endif

#  define TLOG(tag, level, ...) LogMessageF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ # tag, level, __VA_ARGS__)

# endif

# ifdef __cplusplus

class AutoFunctionLogger {
public:
    AutoFunctionLogger(const char* file, int line, const char* fn, NSString* tag, NSString* format, ...) {
        va_list ap;
        
        va_start(ap, format);
        NSString* print = [[NSString alloc] initWithFormat : format arguments:ap];
        va_end(ap);
        init(file, line, fn, tag, print);
    }
    
    AutoFunctionLogger(const char* file, int line, const char* fn, NSString* tag) {
        init(file, line, fn, tag, nil);
    }
    
    void init(const char* file, int line, const char* fn, NSString* tag, NSString* print) {
        NSMutableDictionary* ts = [[NSThread currentThread] threadDictionary];
        NSNumber* indent = [ts objectForKey:@ "indent"];
        
        if (!indent) {
            indent = [NSNumber numberWithInt:0];
        }
        
        print_ = print;
        file_ = file;
        line_ = line;
        fn_ = fn;
        if (print_) {
            LogMessageF(file_, line_, fn_, tag, 4, @ "%*s--> %s %@", [indent intValue] * 3, "", fn_, print_);
        } else {
            LogMessageF(file_, line_, fn_, tag, 4, @ "%*s--> %s", [indent intValue] * 3, "", fn_);
        }
        indent = [NSNumber numberWithInt:[indent intValue] + 1];
        [ts setObject : indent forKey : @ "indent"];
    }
    
    ~AutoFunctionLogger() {
        NSMutableDictionary* ts = [[NSThread currentThread] threadDictionary];
        NSNumber* indent = [ts objectForKey:@ "indent"];
        
        indent = [NSNumber numberWithInt:[indent intValue] - 1];
        [ts setObject : indent forKey : @ "indent"];
        if (print_) {
            [print_ release];
        }
    }
    
    NSString* print_;
    const char* file_;
    int line_;
    const char* fn_;
};

#  define AUTO_LOGGER() AutoFunctionLogger autoFunctionLogger(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG)
#  define AUTO_LOGGERF(format, ...) AutoFunctionLogger autoFunctionLogger(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, format, ## __VA_ARGS__)

# endif

#else

# define NSLOG(...)
# define NSLOG1(...)
# define NSLOG2(...)
# define NSLOG3(...)
# define NSLOG4(...)
# define TLOG(tag, level, ...)
# define AUTO_LOGGER()
# define AUTO_LOGGERF(format, ...)
# define XLOG(...)
# define YLOG(...)
# define ZLOG(...)

#endif

#define LOG NSLOG

#endif // MACROS_H
