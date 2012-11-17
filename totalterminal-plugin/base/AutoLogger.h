#if defined(DEBUG)

// may be redefined later
# define TAG STR_PROJECT_NAME(PROJECT) // => "CutAndPaste"

# ifdef __cplusplus

extern void IndentingLoggerF(const char* filename, int lineNumber, const char* functionName, NSString* domain, int level, NSString* format, ...) NS_FORMAT_FUNCTION(6, 7);

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

extern void IndentingFunctionLoggerF(const char* file, int line, const char* fn, NSString* tag, NSString* format, ...) NS_FORMAT_FUNCTION(5, 6);

class AutoFunctionIndenter {
public:
  AutoFunctionIndenter() {
    NSMutableDictionary* ts = [[NSThread currentThread] threadDictionary];
    NSNumber* indent = [ts objectForKey:@ "indent"];

    if (!indent) {
      indent = [NSNumber numberWithInt:0];
    }
    indent = [NSNumber numberWithInt:[indent intValue] + 1];
    [ts setObject : indent forKey : @ "indent"];
  }

  ~AutoFunctionIndenter() {
    NSMutableDictionary* ts = [[NSThread currentThread] threadDictionary];
    NSNumber* indent = [ts objectForKey:@ "indent"];

    indent = [NSNumber numberWithInt:[indent intValue] - 1];
    [ts setObject : indent forKey : @ "indent"];
  }
};

#  define AUTO_LOGGER() IndentingFunctionLoggerF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, @ ""); AutoFunctionIndenter autoFunctionIndent
#  define AUTO_LOGGERF(format, ...) IndentingFunctionLoggerF(__FILE__, __LINE__, __PRETTY_FUNCTION__, @ TAG, format, __VA_ARGS__); AutoFunctionIndenter autoFunctionIndent

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
