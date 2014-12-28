#import "ILReportingApplication.h"
#import "ILExceptionRecovery.h"
#import "ILReportWindow.h"

#import <ExceptionHandling/ExceptionHandling.h>

@implementation ILReportingApplication

#pragma mark - NSApplication Overrides

- (void) finishLaunching
{
    // TODO present UI to the user asking if we can report a previous crash
    //        self.reportWindow = [ILReportWindow windowForCrashReporter:self.reporter];
    //        [self.reportWindow runModal];

    // register as exception handler delegate
    [NSExceptionHandler defaultExceptionHandler].exceptionHandlingMask = NSLogAndHandleEveryExceptionMask;
    [NSExceptionHandler defaultExceptionHandler].delegate = self;

    [super finishLaunching];
}

#pragma mark - NSResponder Overrides

/*
- (NSError *)willPresentError:(NSError *)error
{
    if( [[error userInfo] objectForKey:NSRecoveryAttempterErrorKey])
    {
        return error;
    }
    else
    {
        self.reportWindow = [ILReportWindow windowForError:error];
        [self.reportWindow runModal];
        return nil;
    }
}
*/

- (BOOL) presentError:(NSError *)error
{
    if( [[error userInfo] objectForKey:NSRecoveryAttempterErrorKey])
    {
        return [super presentError:error];
    }
    else
    {
        self.reportWindow = [ILReportWindow windowForError:error];
        [self.reportWindow runModal];
        return YES;
    }
}

- (void)presentError:(NSError *)error modalForWindow:(NSWindow *)window delegate:(id)delegate didPresentSelector:(SEL)didPresentSelector contextInfo:(void *)contextInfo
{
    if( [[error userInfo] objectForKey:NSRecoveryAttempterErrorKey]
     || ([[error domain] isEqualToString:NSCocoaErrorDomain] && [error code]==NSUserCancelledError))
    {
        [super presentError:error modalForWindow:window delegate:delegate didPresentSelector:didPresentSelector contextInfo:contextInfo];
    }
    else // TODO do this attached to a window and inform the delegate of the success or failure
    {
        self.reportWindow = [ILReportWindow windowForError:error];
        [self.reportWindow runModal];
    }
}

#pragma mark - NSExceptionHandling

- (BOOL)exceptionHandler:(NSExceptionHandler *)exceptionHandler
   shouldHandleException:(NSException *)exception
                    mask:(NSUInteger)mask

{
    if( [ILExceptionRecovery isCommonSystemException:exception])
        return YES;

    ILExceptionRecovery* handler = [ILExceptionRecovery registeredHandlerForException:exception];
    if( handler)
    {
        NSError* recoverableError = [handler recoverableErrorForException:exception];
        if( [NSApp presentError:recoverableError])
            return NO;
    }

    // could not or did not recover, report the exception
    self.reportWindow = [ILReportWindow windowForException:exception];
    [self.reportWindow runModal];

    return NO;
}

#pragma mark - NSErrorRecoveryAttempting

- (BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex;
{
    NSLog(@"attemptRecoveryFromError: %@ optionIndex: %li", error, recoveryOptionIndex);
    return NO;
}

#pragma mark - IBActions

- (void) reportBug:(id) sender
{
    // check for snag keys to see if we need to do something, excpetioal
    if( [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask
       && [[NSApp currentEvent] modifierFlags] & NSControlKeyMask)
    {
        /* Trigger a crash */
        ((char *)NULL)[1] = 0;
    }
    else if( [[NSApp currentEvent] modifierFlags] & NSShiftKeyMask
            && [[NSApp currentEvent] modifierFlags] & NSControlKeyMask) // report a handled error (tests reportError:)
    {
        NSDictionary* handler = @{
                                  NSRecoveryAttempterErrorKey: self,
                                  NSLocalizedDescriptionKey: @"Can you handle this error, man!?",
                                  NSLocalizedFailureReasonErrorKey: @"There's no Reason Here.",
                                  NSLocalizedRecoverySuggestionErrorKey: @"You're gonna wanna freak out.",
                                  NSLocalizedRecoveryOptionsErrorKey: @[@"Freak", @"Report"]
                                  };
        NSError* handled = [NSError errorWithDomain:@"net.istumbler.labs" code:-2 userInfo:handler];
        [NSApp presentError:handled];
    }
    else if( [[NSApp currentEvent] modifierFlags] & NSControlKeyMask) // report the error
    {
        NSError* userReported = [NSError errorWithDomain:@"net.istumbler.labs" code:-1 userInfo:[[NSBundle mainBundle] infoDictionary]];
        [NSApp presentError:userReported];
    }
    else if( [[NSApp currentEvent] modifierFlags] & NSShiftKeyMask
            && [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) // report a handled exception (tests ILExceptionHandler)
    {
        [[NSException exceptionWithName:@"net.istumbler.labs.handled" reason:@"Handled Exception" userInfo:[[NSBundle mainBundle] infoDictionary]] raise];
    }
    else if( [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) // report an exception
    {
        [[NSException exceptionWithName:@"net.istumbler.labs.test" reason:@"Test Exception" userInfo:[[NSBundle mainBundle] infoDictionary]] raise];
        // exception handler will eventualy report the error
    }
    else // just a bug report
    {
        self.reportWindow = [ILReportWindow windowForBug];
        [self.reportWindow runModal];
    }
}

@end
