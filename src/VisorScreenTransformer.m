#import "Macros.h"
#import "VisorScreenTransformer.h"

@implementation VisorScreenTransformer

+ (Class)transformedValueClass {
    LOG(@"transformedValueClass");
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    LOG(@"allowsReverseTransformation");
    return YES;
}

- (id)transformedValue:(id)value {
    LOG(@"transformedValue %@", value);
    return [NSString stringWithFormat: @"Screen %d", [value integerValue]];
}

- (id)reverseTransformedValue:(id)value {
    LOG(@"reverseTransformedValue %@", value);
    return [NSNumber numberWithInteger:[[value substringFromIndex:6] integerValue]];
}

@end