#import "AutoLogger.h"

void IndentingLoggerF(const char* filename, int lineNumber, const char* functionName, NSString* domain, int level, NSString* format, ...) {
  va_list ap;

  va_start(ap, format);
  NSString* print = [[NSString alloc] initWithFormat:format arguments:ap];
  va_end(ap);

  NSMutableDictionary* ts = [[NSThread currentThread] threadDictionary];
  NSNumber* indent = [ts objectForKey:@ "indent"];

  if (!indent) {
    indent = [NSNumber numberWithInt:0];
  }

  LogMessageF(filename, lineNumber, functionName, domain, level, @ "%*s%@", [indent intValue] * 3, "", print);
}

void IndentingFunctionLoggerF(const char* file, int line, const char* fn, NSString* tag, NSString* format, ...) {
  va_list ap;

  va_start(ap, format);
  NSString* print = [[NSString alloc] initWithFormat:format arguments:ap];
  va_end(ap);

  IndentingLoggerF(file, line, fn, tag, 4, @ "--> %s %@", fn, print);
}
