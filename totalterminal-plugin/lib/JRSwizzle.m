/*******************************************************************************
   JRSwizzle.m
   Copyright (c) 2007 Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
   Some rights reserved: <http://opensource.org/licenses/mit-license.php>

 ***************************************************************************/

#import "JRSwizzle.h"
#import <objc/objc-class.h>

#define SetNSError(ERROR_VAR, FORMAT, ...) \
  NSString * errStr = [@"+[NSObject(JRSwizzle) jr_swizzleMethod:withMethod:error:]: " stringByAppendingFormat:FORMAT, ## __VA_ARGS__]; \
  NSLog(@"Swizzle error: %@", errStr); \
  NSBeep(); \
  if (ERROR_VAR) { \
    *ERROR_VAR = [NSError errorWithDomain:@"NSCocoaErrorDomain" \
                                     code:-1 \
                                 userInfo:[NSDictionary dictionaryWithObject:errStr forKey:NSLocalizedDescriptionKey]]; \
  }

@implementation NSObject (TotalTerminal_Swizzling)

+(BOOL) TotalTerminal_jr_swizzleInClass:(Class)class_ method:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError**)error_;
{
#if OBJC_API_VERSION >= 2
  Method origMethod = class_getInstanceMethod(class_, origSel_);
  if (!origMethod) {
    SetNSError(error_, @"original method %@ not found for class %@", NSStringFromSelector(origSel_), NSStringFromClass(class_));
    return NO;
  }

  Method altMethod = class_getInstanceMethod(class_, altSel_);
  if (!altMethod) {
    SetNSError(error_, @"alternate method %@ not found for class %@", NSStringFromSelector(altSel_), NSStringFromClass(class_));
    return NO;
  }

  class_addMethod(class_,
      origSel_,
      class_getMethodImplementation(class_, origSel_),
      method_getTypeEncoding(origMethod));
  class_addMethod(class_,
      altSel_,
      class_getMethodImplementation(class_, altSel_),
      method_getTypeEncoding(altMethod));

  method_exchangeImplementations(class_getInstanceMethod(class_, origSel_), class_getInstanceMethod(class_, altSel_));
  return YES;

#else
  // Scan for non-inherited methods.
  Method directOriginalMethod = NULL, directAlternateMethod = NULL;

  void* iterator = NULL;
  struct objc_method_list* mlist = class_nextMethodList(class_, &iterator);
  while (mlist) {
    int method_index;
    for (method_index = 0; method_index < mlist->method_count; ++method_index) {
      SEL sel = mlist->method_list[method_index].method_name;
      if (sel == origSel_) {
        assert(!directOriginalMethod);
        directOriginalMethod = &mlist->method_list[method_index];
      }
      if (sel == altSel_) {
        assert(!directAlternateMethod);
        directAlternateMethod = &mlist->method_list[method_index];
      }
    }
    mlist = class_nextMethodList(class_, &iterator);
  }

  // If either method is inherited, copy it up to the target class to make it non-inherited.
  if (!directOriginalMethod || !directAlternateMethod) {
    Method inheritedOriginalMethod = NULL, inheritedAlternateMethod = NULL;
    if (!directOriginalMethod) {
      inheritedOriginalMethod = class_getInstanceMethod(class_, origSel_);
      if (!inheritedOriginalMethod) {
        SetNSError(error_, @"original method %@ not found for class %@", NSStringFromSelector(origSel_), NSStringFromClass(class_));
        return NO;
      }
    }
    if (!directAlternateMethod) {
      inheritedAlternateMethod = class_getInstanceMethod(class_, altSel_);
      if (!inheritedAlternateMethod) {
        SetNSError(error_, @"alternate method %@ not found for class %@", NSStringFromSelector(altSel_), NSStringFromClass(class_));
        return NO;
      }
    }

    int hoisted_method_count = !directOriginalMethod && !directAlternateMethod ? 2 : 1;
    struct objc_method_list* hoisted_method_list = (struct objc_method_list*)malloc(
        sizeof(struct objc_method_list) + (sizeof(struct objc_method) * (hoisted_method_count - 1)));
    hoisted_method_list->obsolete = NULL;         // soothe valgrind - apparently ObjC runtime accesses this value and it shows as uninitialized in valgrind
    hoisted_method_list->method_count = hoisted_method_count;
    Method hoisted_method = hoisted_method_list->method_list;

    if (!directOriginalMethod) {
      bcopy(inheritedOriginalMethod, hoisted_method, sizeof(struct objc_method));
      directOriginalMethod = hoisted_method++;
    }
    if (!directAlternateMethod) {
      bcopy(inheritedAlternateMethod, hoisted_method, sizeof(struct objc_method));
      directAlternateMethod = hoisted_method;
    }
    class_addMethods(class_, hoisted_method_list);
  }

  // Swizzle.
  IMP temp = directOriginalMethod->method_imp;
  directOriginalMethod->method_imp = directAlternateMethod->method_imp;
  directAlternateMethod->method_imp = temp;

  return YES;

#endif
}       // _jr_swizzleInClass:method:withMethod:error:

+(BOOL) TotalTerminal_jr_swizzleMethod:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError**)error_ {
  return [self TotalTerminal_jr_swizzleInClass:[self class] method:origSel_ withMethod:altSel_ error:error_];
}

+(BOOL) TotalTerminal_jr_swizzleClassMethod:(SEL)origSel_ withClassMethod:(SEL)altSel_ error:(NSError**)error_ {
  // pass metaclass to -_jr_swizzleInClass so that a class method get swizzled (and not an instance method)
  return [self TotalTerminal_jr_swizzleInClass:object_getClass([self class]) method:origSel_ withMethod:altSel_ error:error_];
}

@end
