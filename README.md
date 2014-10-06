ilreportwindow
==============

iStumbler Labs Report Window for Crashes, Exceptions and Errors

    #import <ReportWindow/ReportWindow.h>
    #import <CrashReporter/CrashReporter.h>
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
            NSError* userReported = [NSError errorWithDomain:@"net.istumbler" code:-1 userInfo:[[NSBundle mainBundle] infoDictionary]];
            [self reportError:userReported]; // triggers ReportWIndow
        }
        else if( [[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) // report an exception
        {
            [[NSException exceptionWithName:@"net.istumbler.test" reason:@"Test Exceptoin" userInfo:[[NSBundle mainBundle] infoDictionary]] raise];
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
        PLCrashReporterConfig* config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeBSD symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll];
        PLCrashReporter* reporter = [[PLCrashReporter alloc] initWithConfiguration:config]

        // you'll have to add a crash calback, if you want to intercept crashes in the app, otherwise you get them on the next launch

        NSError* reportError;
    
        // register as exception handler delegate
        [NSExceptionHandler defaultExceptionHandler].exceptionHandlingMask = NSLogAndHandleEveryExceptionMask;
        [NSExceptionHandler defaultExceptionHandler].delegate = self;
    
        if( [reporter hasPendingCrashReport])
        {
            // present UI to the user asking if we can report the crash
            self.reportWindow = [ILReportWindow windowForCrashReporter:reporter];
            [self.reportWindow runModal];
        }
    
        if( ![reporter enableCrashReporterAndReturnError:&reportError])
        {
            [self reportError:reportError];
        }
    }

    - (void)reportError:(NSError *)error
    {
        if( [[error userInfo] objectForKey:NSRecoveryAttempterErrorKey])
        {
            [(id<PluginApplicationDelegate>)[NSApp delegate] reportError:error];
        }
        else // non-recoverable errors should be reported
        {
            self.reportWindow = [ILReportWindow windowForReporter:reporter withError:error];
            [self.reportWindow runModal];
        }
    }

    #pragma mark - NSExceptionHandling

    - (BOOL)exceptionHandler:(NSExceptionHandler *)exceptionHandler
       shouldHandleException:(NSException *)exception
                        mask:(NSUInteger)mask
    {
        if( ![ILExceptionHandler isCommonSystemException:exception])
        {
            ILExceptionHandler* handler = [ILExceptionHandlerRegistry registeredHandlerForException:exception];
            if( handler)
            {
                NSError* recoverableError = [handler recoverableErrorForException:exception];
                [NSApp presentError:recoverableError];
            }
            else // we have to report the exception
            {
                self.reportWindow = [ILReportWindow windowForException:exception];
                self.reportWindow.reporter = self.reporter;
                [self.reportWindow runModal];
            }
            return NO;
        }
        return YES;
    }

    - (BOOL)exceptionHandler:(NSExceptionHandler *)exceptionHandler shouldHandleException:(NSException *)exception mask:(NSUInteger)mask
    {
        ILReportWindow* reportWindow = [ILReportWindow windowForException:exception];
        [reportWindow runModal];
        return NO;
    }
