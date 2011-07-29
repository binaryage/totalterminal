#import "TotalTerminal.h"

@interface TotalTerminal (Features)
+(BOOL) shouldLoadFeature:(NSString*)feature;
+(void) loadFeatures;
@end
