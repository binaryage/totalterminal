@class TTProfile;

@interface TTProfileManager : NSObject { }

+(TTProfileManager*)sharedProfileManager;
-(TTProfile*)profileWithName:(id)arg1;
-(void)setProfile:(id) arg1 forName:(id)arg2;
-(TTProfile*)defaultProfile;
-(TTProfile*)startupProfile;

@end
