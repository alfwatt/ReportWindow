
#import <Foundation/Foundation.h>

typedef NSError*(^ILExceptionErrorGenerator)(NSException* exception,id recoveryAttemptor);
typedef BOOL(^ILExceptionRecoveryAttempt)(NSError* error, NSUInteger recoveryIndex);

extern NSString* const ILUnderlyingException;

/** @class An exception handler manages an exception by creating a recoverable NSError, which can then be presented to the user */
@interface ILExceptionHandler : NSObject
@property(nonatomic,retain) NSString* exceptionName;
@property(nonatomic,retain) NSString* exceptionReasonPattern;
@property(copy) ILExceptionErrorGenerator exceptionErrorGenerator; // this block takes your exception and generates the recoverable error
@property(copy) ILExceptionRecoveryAttempt exceptionRecoveryAttempt; // passes in the integer that we picked

/** @param exceptionName name to match for this handler
    @param reasonPattern regular expression to match against the reasonString for this handler
    @param errorGenerator block to generate an NSError with recovery options
    @param recoveryAttempt block to attemp recovery from the NSError with specified recovery options
    @returns a handler initilized with the specified parameters */
+ (ILExceptionHandler*) handlerForException:(NSString*) exceptionName
                                    pattern:(NSString*) reasonPattern
                                  generator:(ILExceptionErrorGenerator) errorGenerator
                                   recovery:(ILExceptionRecoveryAttempt) recoveryAttempt;

/** @returns YES if this is a common system exception which should not be reported, e.g. NSAccessibilityException */
+ (BOOL) isCommonSystemException:(NSException*) exception;

/** @param exception
    @returns true if the handler can generate a recoverable error for the exception */
- (BOOL) canHandleException:(NSException*) exception;

/** @param exception
    @returns a recoverable NSError object for the exception */
- (NSError*) recoverableErrorForException:(NSException*) exception;

@end

#pragma mark -

/** The exception handler registry performs matching for exception names and reason string patterns */
@interface ILExceptionHandlerRegistry : NSObject

/** @param handlers to be registered for later lookup. replaces all existin handlers */
+ (void) registerHandlers:(NSArray*) handlers;

/** @param exceptionName the name of th exception to lookup in the registry 
    @returns an array or handlers (or nil) */
+ (NSArray*) registeredHandlersForExceptionName:(NSString*) exceptionName;

/** @param exception the exception to lookup a hander for *
    @return the first matched hanlder (or nil) */
+ (ILExceptionHandler*) registeredHandlerForException:(NSException*) exception;

@end

/* Copyright 2014, Alf Watt (alf@istumbler.net) Avaliale under BSD Style license in license.txt. */
