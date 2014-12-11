ReportWindow
==============

iStumbler Labs Report Window for Crashes, Exceptions and Errors

## Usage

Indlude ReportWindow.framework in your application.

## Example Code

    #import <ReportWindow/ReportWindow.h>
    #import <ExceptionHandling/ExceptionHandling.h>

    @property(nonatimic,retain) ILReportWindow* reportWindow;

    #pragma mark - IBAction

    - (IBAction) reportBug:(id) sender
    {
        // check for snag keys to see if we need to do something, excpetioal
        if( [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask
         && [[NSApp currentEvent] modifierFlags] & NSControlKeyMask)
        {
            /* Trigger a crash */
            ((char *)NULL)[1] = 0;
        }
        else if( [[NSApp currentEvent] modifierFlags] & NSControlKeyMask) // report the error
        {
            NSError* userReported = [NSError errorWithDomain:@"net.istumbler.labs" code:-1 userInfo:[[NSBundle mainBundle] infoDictionary]];
            [self reportError:userReported]; // triggers ReportWIndow
        }
        else if( [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) // report an exception
        {
            [[NSException exceptionWithName:@"net.istumbler.test" reason:@"Test Exception" userInfo:[[NSBundle mainBundle] infoDictionary]] raise];
            // exception handler will eventualy report the error
        }
        else // just a bug report
        {
            self.reportWindow = [ILReportWindow windowForBug];
            [self.reportWindow runModal];
        }
    }

    #pragma mark - NSApplicationDelegate

    - (void) applicationDidFinishLaunching:(NSNotification*) aNotification
    {
        NSError* reportError;
    
        // register as exception handler delegate
        [NSExceptionHandler defaultExceptionHandler].exceptionHandlingMask = NSLogAndHandleEveryExceptionMask;
        [NSExceptionHandler defaultExceptionHandler].delegate = self;
    
        if( [ILReportWindow hasPendingCrashReport])
        {
            // present UI to the user asking if we can report the crash
            self.reportWindow = [ILReportWindow windowForSystemCrashReport:[ILReportWindow lastPendingCrashReport]];
            [self.reportWindow runModal];
        }
    }

    - (void)reportError:(NSError *)error
    {
        if( [[error userInfo] objectForKey:NSRecoveryAttempterErrorKey])
        {
            if( [NSApp presentError:error]) // recovery was attempted
                return;
        }

        // we could not or did not recover, file a report
        self.reportWindow = [ILReportWindow windowForError:error];
        self.reportWindow.reporter = self.reporter;
        [self.reportWindow runModal];
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
        self.reportWindow.reporter = self.reporter;
        [self.reportWindow runModal];

        return NO;
    }
