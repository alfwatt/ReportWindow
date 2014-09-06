ilreportwindow
==============

iStumbler Labs Report Window for Crashes, Exceptions and Errors

#import <ReportWindow/ReportWindow.h>
#import <ExceptionHandling/ExceptionHandling.h>

#pragma mark - NSApplicationDelegate

- (void) applicationDidFinishLaunching:(NSNotification*) aNotification
{
    PLCrashReporterConfig* config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeBSD symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll];
    PLCrashReporter* reporter = [[PLCrashReporter alloc] initWithConfiguration:config]
    ILReportWindow* reportWindow;
    NSError* reportError;
    
    // register as exception handler delegate
    [NSExceptionHandler defaultExceptionHandler].exceptionHandlingMask = NSLogAndHandleEveryExceptionMask;
    [NSExceptionHandler defaultExceptionHandler].delegate = self;
    
    if( [reporter hasPendingCrashReport])
    {
        // present UI to the user asking if we can report the crash
        reportWindow = [ILReportWindow windowForReporter:reporter];
        [reportWindow runModal];
    }
    
    
    if( ![reporter enableCrashReporterAndReturnError:&reportError])
    {
        reportWindow = [ILReportWindow windowForReporter:reporter withError:reportError];
        [reportWindow runModal];
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
        PLCrashReporterConfig* config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeBSD symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll];
        PLCrashReporter* reporter = [[PLCrashReporter alloc] initWithConfiguration:config]
        self.reportWindow = [ILReportWindow windowForReporter:reporter withError:error];
        [self.reportWindow runModal];
    }
}

#pragma mark - NSExceptionHandling

- (BOOL)exceptionHandler:(NSExceptionHandler *)exceptionHandler
   shouldHandleException:(NSException *)exception
                    mask:(NSUInteger)mask

{
    PLCrashReporterConfig* config = [[PLCrashReporterConfig alloc] initWithSignalHandlerType:PLCrashReporterSignalHandlerTypeBSD symbolicationStrategy:PLCrashReporterSymbolicationStrategyAll];
    PLCrashReporter* reporter = [[PLCrashReporter alloc] initWithConfiguration:config]
    self.reportWindow = [ILReportWindow windowForReporter:reporter withException:exception];
    [self.reportWindow runModal];
    return NO;
}
