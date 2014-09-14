ilreportwindow
==============

iStumbler Labs Report Window for Crashes, Exceptions and Errors

    #import <ReportWindow/ReportWindow.h>
    #import <CrashReporter/CrashReporter.h>
    #import <ExceptionHandling/ExceptionHandling.h>

    @property(nonatimic,retain) ILReportWindow* reportWindow;

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

    - (BOOL)exceptionHandler:(NSExceptionHandler *)exceptionHandler shouldHandleException:(NSException *)exception mask:(NSUInteger)mask
    {
        ILReportWindow* reportWindow = [ILReportWindow windowForException:exception];
        [reportWindow runModal];
        return NO;
    }
