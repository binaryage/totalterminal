#import "TotalTerminal.h"

@interface TotalTerminal (Observers)
+(BOOL) automaticallyNotifiesObserversForKey:(NSString*)theKey;
-(void) registerObservers;
-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
@end
