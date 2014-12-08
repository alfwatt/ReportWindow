
#import "ILExceptionRecovery.h"
#import <AppKit/AppKit.h>

NSString* const ILUnderlyingException = @"ILUnderlyingException";

static NSMutableDictionary* ILHandlerRegistry;

@implementation ILExceptionRecovery

#pragma mark - ILExceptionRecovery Registry

+ (void) registerHandlers:(NSArray*) handlers
{
    ILHandlerRegistry = [NSMutableDictionary new];
    
    for ( ILExceptionRecovery* handler in handlers)
    {
        if( ![[ILHandlerRegistry allKeys] containsObject:handler.exceptionName])
            [ILHandlerRegistry setObject:[NSMutableArray new] forKey:handler.exceptionName];
        
        [[ILHandlerRegistry objectForKey:handler.exceptionName] addObject:handler];
    }
}

+ (NSArray*) registeredHandlersForExceptionName:(NSString*) exceptionName
{
    return [ILHandlerRegistry objectForKey:exceptionName];
}

+ (ILExceptionRecovery*) registeredHandlerForException:(NSException*) exception
{
    ILExceptionRecovery* matchedHandler = nil;
    for( ILExceptionRecovery* candidateHandler in [self registeredHandlersForExceptionName:[exception name]])
    {
        if ( [candidateHandler canHandleException:exception]) // take the first match
        {
            matchedHandler = candidateHandler;
            break;
        }
    }
    return matchedHandler;
}

#pragma mark - System Exception Identification

+ (BOOL)isCommonSystemException:(NSException *)exception
{
    return ([exception.name isEqualTo:NSAccessibilityException]); // autolayout probably worth reporting for now
}

#pragma mark - Factory Method

+ (ILExceptionRecovery*) handlerForException:(NSString*) exceptionName
                                     pattern:(NSString*) messagePattern
                                   generator:(ILExceptionErrorGenerator) errorGenerator
                                    recovery:(ILExceptionRecoveryAttempt) recoveryAttempt
{
    ILExceptionRecovery* handler = [ILExceptionRecovery new];
    handler.exceptionName = exceptionName;
    handler.exceptionReasonPattern = messagePattern;
    handler.exceptionErrorGenerator = errorGenerator;
    handler.exceptionRecoveryAttempt = recoveryAttempt;
    return handler;
}

#pragma mark - Recovery Handling

- (BOOL) canHandleException:(NSException*) exception
{
    BOOL canYouHandleIt = NO;
    NSError* error = nil;
    if( [[exception name] isEqualToString:self.exceptionName])
    {
        NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:self.exceptionReasonPattern
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        if( regex)
        {
            if( [regex numberOfMatchesInString:exception.reason
                                       options:NSMatchingAnchored
                                         range:NSMakeRange(0, exception.reason.length)])
            {
                canYouHandleIt = YES;
            }
        }
        else NSLog(@"error compiling regex for: %@ %@", self.exceptionName, self.exceptionReasonPattern);
    }
    
    return canYouHandleIt;
}

- (NSError*) recoverableErrorForException:(NSException*) exception
{
    return self.exceptionErrorGenerator(exception,self);
}

#pragma mark - NSErrorRecovery

- (BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex
{
    return self.exceptionRecoveryAttempt(error,recoveryOptionIndex);
}

@end

/* Copyright 2014, Alf Watt (alf@istumbler.net) Avaliale under BSD Style license in license.txt. */
