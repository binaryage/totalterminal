// this is just a wrapper header to exclude compiling logger in release mode

#ifdef DEBUG
#include "LoggerClient.h"
#endif