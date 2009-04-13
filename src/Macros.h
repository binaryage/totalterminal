#ifdef _DEBUG_MODE
#  define LOG(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#  define LOG(format, ...)
#endif

#define DEBUG_LOG_PATH "/Users/darwin/code/visor/debug.log"
