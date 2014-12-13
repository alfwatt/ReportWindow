ReportWindow
==============

iStumbler Labs Report Window for Crashes, Exceptions and Errors

## Usage

Indlude ReportWindow.framework and ExceptionHandling.framework in your application project.

## Configuration

By adding specific keys to your Application's Info.plist file you can control the behavoiur of the ReportWindow.

    extern NSString* const ILReportWindowSubmitURLKey; // if set in the bundle's info dictionary the url to submit the crash report to, can be a mailto: url
    extern NSString* const ILReportWindowSubmitEmailKey; // if set the backup email for submissions, if the primary URL is http and the user declines to upload

    // ATTENTION! only set these keys if your log output, defaults and windows contain no user identifiying information (account names, passwords, etc)
    // thse keys can be set either in the bundle info dictionary or the NSUserDefaults
    extern NSString* const ILReportWindowIncludeSyslogKey; // if set to YES then syslog messages with the applications bundle name in them are included
    extern NSString* const ILReportWindowIncludeDefaultsKey; // if set to YES then the applications preferences are included in the report

Once those keys are set, you can use the Example Code below to intergrate the ReportWindow into your application.

## Classes

### ILReportWindow

Provides the controller for the report window interface and uploads the report to the URL you specify.

### ILExceptionRecovery

Provides an exception recovery mechanisim by converting recognized NSExceptions into NSErrors with recovery options.

## Example Code

    #import <ReportWindow/ReportWindow.h>
    #import <ExceptionHandling/ExceptionHandling.h>

    #pragma mark - NSApplicationDelegate Header

    @property(nonatimic,retain) ILReportWindow* reportWindow;

    #pragma mark - NSApplicationDelegate Implmentation

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

    #pragma mark - IBActions

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
            [[NSException exceptionWithName:@"net.istumbler.labs.test" reason:@"Test Exception" userInfo:[[NSBundle mainBundle] infoDictionary]] raise];
            // exception handler will eventualy report the error
        }
        else // just a bug report
        {
            self.reportWindow = [ILReportWindow windowForBug];
            [self.reportWindow runModal];
        }
    }
