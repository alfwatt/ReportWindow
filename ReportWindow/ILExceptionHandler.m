//
//  ILExceptionHandler.m
//  ReportWindow
//
//  Created by alf on 10/5/14.
//
//

#import "ILExceptionHandler.h"
#import <AppKit/AppKit.h>

NSString* const ILUnderlyingException = @"ILUnderlyingException";

@implementation ILExceptionHandler

+ (ILExceptionHandler*) handlerForException:(NSString*) exceptionName
                                    pattern:(NSString*) messagePattern
                                  generator:(ILExceptionErrorGenerator) errorGenerator
                                   recovery:(ILExceptionRecoveryAttempt) recoveryAttempt
{
    ILExceptionHandler* handler = [ILExceptionHandler new];
    handler.exceptionName = exceptionName;
    handler.exceptionReasonPattern = messagePattern;
    handler.exceptionErrorGenerator = errorGenerator;
    handler.exceptionRecoveryAttempt = recoveryAttempt;
    return handler;
}


+ (BOOL)isCommonSystemException:(NSException *)exception
{
    return ([exception.name isEqualTo:NSAccessibilityException]); // autolayout probably worth reporting for now
}

#pragma mark -

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

#pragma mark -

static NSMutableDictionary* ILHandlerRegistry;

@implementation ILExceptionHandlerRegistry

+ (void) registerHandlers:(NSArray*) handlers
{
    ILHandlerRegistry = [NSMutableDictionary new];
    
    for ( ILExceptionHandler* handler in handlers)
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

+ (ILExceptionHandler*) registeredHandlerForException:(NSException*) exception
{
    ILExceptionHandler* matchedHandler = nil;
    for( ILExceptionHandler* candidateHandler in [self registeredHandlersForExceptionName:[exception name]])
    {
        if ( [candidateHandler canHandleException:exception]) // take the first match
        {
            matchedHandler = candidateHandler;
            break;
        }
    }
    return matchedHandler;
}

@end
