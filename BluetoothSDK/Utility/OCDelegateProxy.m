//
//  OCDelegateProxy.m
//  Sample-SwiftTests
//
//  Created by Peng on 2023/3/30.
//

#import "OCDelegateProxy.h"

static NSObject * invocation_get_argument_at_idx_with_objctype(NSInvocation *invocation, int idx, const char * type) {
    if ( strcmp(type, @encode(id)) == 0 ) {
        __unsafe_unretained NSObject * argument;
        [invocation getArgument:&argument atIndex:idx];
        return argument ? argument: NSNull.new;
    }
    else if ( strcmp(type, @encode(SEL)) == 0 ) {
        SEL argument;
        [invocation getArgument:&argument atIndex:idx];
        return [NSValue valueWithPointer:argument];
    }
    else if ( strcmp(type, @encode(int)) == 0 ) {
        int argument;
        [invocation getArgument:&argument atIndex:idx];
        return @(argument);
    }
#define ARGUMENT_VALUE(typename) \
    else if ( strcmp(type, @encode(typename)) == 0 ) {   \
        int argument;                               \
        [invocation getArgument:&argument atIndex:idx];   \
        return @(argument); \
    }
    ARGUMENT_VALUE(char)
    ARGUMENT_VALUE(short)
    ARGUMENT_VALUE(long)
    ARGUMENT_VALUE(long long)
    ARGUMENT_VALUE(float)
    ARGUMENT_VALUE(double)
    ARGUMENT_VALUE(bool)
    
    ARGUMENT_VALUE(unsigned int)
    ARGUMENT_VALUE(unsigned short)
    ARGUMENT_VALUE(unsigned long)
    ARGUMENT_VALUE(unsigned long long)
    else {
        NSValue * argument;
        [invocation getArgument:&argument atIndex:idx];
        return argument;
    }
}

static NSMutableArray * invovation_get_arguments(NSInvocation *invocation) {
    NSMutableArray * arguments = [NSMutableArray new];
    NSMethodSignature *ms = invocation.methodSignature;
    NSUInteger numberOfArguments = ms.numberOfArguments;
    for(int idx = 0; idx < numberOfArguments; idx+= 1) {
        const char * type = [ms getArgumentTypeAtIndex:idx];
        NSLog(@"%d type: %s", idx, type);
        [arguments addObject: invocation_get_argument_at_idx_with_objctype(invocation, idx, type) ];
    }
    return arguments;
}

@interface OCDelegateProxy()

@end

@implementation OCDelegateProxy


- (id)forwardingTargetForSelector:(SEL)aSelector {
    NSObject * target = [super forwardingTargetForSelector:aSelector];
    NSLog(@"%s %@", __func__, target.class);
    return target;
}
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSLog(@"methodSignatureForSelector: (%s)", sel_getName(aSelector));
    return [super methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSLog(@"forwardInvocation: ");
    
    SEL selector = anInvocation.selector;
    NSMutableArray * arguments = invovation_get_arguments(anInvocation);
    NSLog(@"%@", arguments);
    [self forwardSelector:selector arguments:arguments];
}

- (void)forwardSelector:(SEL)selector arguments:(NSArray *)arguments {
    
}

@end
