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
    if ([value integerValue]==0) {
        return @"Main Screen";
    }
    return [NSString stringWithFormat: @"Screen %d", [value integerValue]-1];
}

- (id)reverseTransformedValue:(id)value {
    LOG(@"reverseTransformedValue %@", value);
    if ([value hasPrefix:@"Screen"]) {
        return [NSNumber numberWithInteger:[[value substringFromIndex:6] integerValue]+1];
    }
    return [NSNumber numberWithInteger:0];
}

@end