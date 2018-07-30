#import "ILReportWindow.h"

#import <execinfo.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

#if IL_APP_KIT
#import <ExceptionHandling/ExceptionHandling.h>
#endif

#pragma mark - NSUserDefaults keys

NSString* const ILReportWindowAutoSubmitKey = @"ILReportWindowAutoSubmitKey";
NSString* const ILReportWindowIgnoreKey = @"ILReportWindowIgnoreKey";
NSString* const ILReportWindowUserFullNameKey = @"ILReportWindowUserFullNameKey";
NSString* const ILReportWindowUserEmailKey = @"ILReportWindowUserEmailKey";
NSString* const ILReportWindowReportedSignaturesKey = @"ILReportWindowReportedSignaturesKey";
NSString* const ILReportWindowDeleteSubmittedKey = @"ILReportWindowDeleteSubmittedKey";

#pragma mark - Info.plist keys

NSString* const ILReportWindowSubmitURLKey = @"ILReportWindowSubmitURLKey";
NSString* const ILReportWindowSubmitEmailKey = @"ILReportWindowSubmitEmailKey";

NSString* const ILReportWindowSuppressDuplicatesKey = @"ILReportWindowSuppressDuplicatesKey";

NSString* const ILReportWindowIncludeSyslogKey = @"ILReportWindowIncludeSyslogKey";
NSString* const ILReportWindowIncludeDefaultsKey = @"ILReportWindowIncludeDefaultsKey";
NSString* const ILReportWindowIncludeWindowScreenshotsKey = @"ILReportWindowIncludeWindowScreenshotsKey";

NSString* const ILReportWindowAutoRestartSecondsKey = @"ILReportWindowAutoRestartSecondsKey";
NSString* const ILReportWindowTreatErrorAsBugKey = @"ILReportWindowTreatErrorAsBugKey";

NSString* const ILReportWindowTitle = @"ILReportWindowTitle";
NSString* const ILReportWindowFrame = @"ILReportWindowFrame";
NSString* const ILReportWindowInfo = @"ILReportWindowInfo";
NSString* const ILReportWindowImage = @"ILReportWindowImage";

#pragma mark - NSLocalizedStrings

NSString* const ILReportWindowInsecureConnectionString = @"ILReportWindowInsecureConnectionString";
NSString* const ILReportWindowInsecureConnectionInformationString = @"ILReportWindowInsecureConnectionInformationString";
NSString* const ILReportWindowInsecureConnectionEmailAlternateString = @"ILReportWindowInsecureConnectionEmailAlternateString";
NSString* const ILReportWindowCancelString = @"ILReportWindowCancelString";
NSString* const ILReportWindowSendString = @"ILReportWindowSendString";
NSString* const ILReportWindowEmailString = @"ILReportWindowEmailString";
NSString* const ILReportWindowCrashReportString = @"ILReportWindowCrashReportString";
NSString* const ILReportWindowBugReportString = @"ILReportWindowBugReportString";
NSString* const ILReportWindowExceptionReportString = @"ILReportWindowExceptionReportString";
NSString* const ILReportWindowErrorReportString = @"ILReportWindowErrorReportString";
NSString* const ILReportWindowCrashedString = @"ILReportWindowCrashedString";
NSString* const ILReportWindowRaisedExceptionString = @"ILReportWindowRaisedExceptionString";
NSString* const ILReportWindowReportedErrorString = @"ILReportWindowReportedErrorString";
NSString* const ILReportWindowReportingBugString = @"ILReportWindowReportingBugString";
NSString* const ILReportWindowReportDispositionString = @"ILReportWindowCrashDispositionString";
NSString* const ILReportWindowErrorDispositionString = @"ILReportWindowErrorDispositionString";
NSString* const ILReportWindowBugDispositionString = @"ILReportWindowBugDispositionString";
NSString* const ILReportWindowReportString = @"ILReportWindowReportString";
NSString* const ILReportWindowRestartString = @"ILReportWindowRestartString";
NSString* const ILReportWindowQuitString = @"ILReportWindowQuitString";
NSString* const ILReportWindowIgnoreString = @"ILReportWindowIgnoreString";
NSString* const ILReportWindowCommentsString = @"ILReportWindowCommentsString";
NSString* const ILReportWindowSubmitFailedString = @"ILReportWindowSubmitFailedString";
NSString* const ILReportWindowSubmitFailedInformationString = @"ILReportWindowSubmitFailedInformationString";
NSString* const ILReportWindowRestartInString = @"ILReportWindowRestartInString";
NSString* const ILReportWindowSecondsString = @"ILReportWindowSecondsString";

#define ILLocalizedString(key) [[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:@"" table:@"ReportWindow"]

#pragma mark - Sparkle Updater Support

NSString* const ILReportWindowSparkleUpdaterClass = @"SUUpdater";
NSString* const ILReportWIndowSparkleUpdaterURLKey = @"SUFeedURL";

@interface NSObject (ILReportWindowSparkleMethods)

+ (instancetype) sharedUpdater;
- (NSURL*) feedURL;
- (IBAction) checkForUpdates:(id)sender;

@end

#pragma mark - Private

@interface ILReportWindow ()
@property(nonatomic, retain) NSOperationQueue* gatherQueue;

@end

#pragma mark -

@implementation ILReportWindow

+ (BOOL) isFeatureExplicitlyDisabled:(NSString*) key
{
    BOOL explicit = NO;

    if( [[NSUserDefaults standardUserDefaults] objectForKey:key]) { // the key exists
        explicit = ![[NSUserDefaults standardUserDefaults] boolForKey:key]; // if set to 'NO' it's explicit
    }

    return explicit;
}

+ (BOOL) isFeatureEnabled:(NSString*) key
{
    BOOL enabled = NO;
    
    if( [[[[NSBundle mainBundle] infoDictionary] objectForKey:key] boolValue]) {
        enabled = YES;
    }
    
    // if the feature is turned on in the info dictionary, and the user has set a default as NO, disable it
    if( enabled && [self isFeatureExplicitlyDisabled:key]) {
        enabled = NO;
    }
    
    return enabled;
}

#pragma mark - Exceptions

+ (NSString*) exceptionReport:(NSException*) exception
{
    // report the exception, name, reason and user info
    NSMutableString* report = [NSMutableString new];
    [report appendString:[NSString stringWithFormat:@"signature: %@\n\n%@ %@\n\n%@\n\n",
                          [self exceptionSignature:exception],
                          exception.name, exception.reason, exception.userInfo]];

#if IL_APP_KIT
    // symbolicate the stack trace using backtrace_symbols
    NSString *stackTrace = [[exception userInfo] objectForKey:NSStackTraceKey];
    NSScanner *scanner = [NSScanner scannerWithString:stackTrace];
    NSMutableArray *addresses = [NSMutableArray new];
    NSString *token;
    while ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&token]) {
        [addresses addObject:token];
    }
    
    NSUInteger numFrames = [addresses count];
    if (numFrames > 0) {
        void **frames = (void **)malloc(sizeof(void *) * numFrames);
        NSUInteger i, parsedFrames;
        
        for (i = 0, parsedFrames = 0; i < numFrames; i++) {
            NSString *address = [addresses objectAtIndex:i];
            NSScanner* addressScanner = [NSScanner scannerWithString:address];
            
            if (![addressScanner scanHexLongLong:(unsigned long long *)&frames[parsedFrames]]) {
                NSLog(@"%@ failed to parse frame address '%@'", [self className], address);
                break;
            }
            
            parsedFrames++;
        }
        
        if (parsedFrames > 0) {
            char **frameStrings = backtrace_symbols(frames, (int)parsedFrames);
            if (frameStrings) {
                for (unsigned i = 0; i < numFrames && frameStrings[i] ; i++) {
                    [report appendString:[NSString stringWithUTF8String:(char *)frameStrings[i]]];
                    [report appendString:@"\n"];
                }
                free(frameStrings);
            }
        }
        
        free(frames);
    }
#endif
    return report;
}

+ (NSString*) exceptionSignature:(NSException*) exception
{
    // if the addresses inside of our app are reported consistently (i.e. not aslrd out into hyperspace) we can use them
    // as entry/exit markers for the exception and base the signature on those addresses, the exeption class and name
    return [NSString stringWithFormat:@"%@-%@-%@", exception.class, exception.name, exception.reason];
}

#pragma mark - Errors

+ (NSString*) errorReport:(NSError*) error
{
    NSMutableString* report = [NSMutableString new];
    [report appendString:[NSString stringWithFormat:@"%@: %li\n\n%@", error.domain, (long)error.code, error.userInfo]];
    if ((error = [[error userInfo] objectForKey:NSUnderlyingErrorKey]) ) { // we have to go deeper
        [report appendString:[NSString stringWithFormat:@"\n\n- Underlying Error -\n\n"]];
        [report appendString:[self errorReport:error]];
    }
    return report;
}

+ (NSString*) errorSignature:(NSError*) error
{
    return [NSString stringWithFormat:@"%@++%@++%li", error.class, error.domain, (long)error.code];
}

#pragma mark - System Crash Reports

+ (NSArray*) systemCrashReports
{
    NSMutableArray* reports = [NSMutableArray array];
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleExecutableKey];
    NSError* error = nil;

    // find the report directory in the users's library folder
    for (NSString* libraryDirectory in NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES)) {
        NSString* reportsPath = [libraryDirectory stringByAppendingPathComponent:@"Logs/DiagnosticReports"];
        
        // iStumbler_2014-12-07-130612_galaxy.crash for .e.g.
        for (NSString* fileName in [fm contentsOfDirectoryAtPath:reportsPath error:&error]) {
            if ([fileName rangeOfString:appName].location == 0) {
                [reports addObject:[reportsPath stringByAppendingPathComponent:fileName]];
            }
        }
    }
    
    // get a list of the filenames
    return reports;
}

+ (NSString*) latestSystemCrashReport
{
    // process the list of filenames, from systemCrashReports, finde the most recent
    // iStumbler_2014-12-07-130612_galaxy.crash for .e.g.
    NSString* latest = nil;
    NSDate* latestDate = nil;
    for (NSString* filename in [ILReportWindow systemCrashReports]) { // when in doubt
        NSArray* components = [[filename lastPathComponent] componentsSeparatedByString:@"_"];
        NSString* reportDateString = [components objectAtIndex:1];
        NSDateFormatter* dateFormatter = [NSDateFormatter new];
        NSDate* reportDate = [dateFormatter dateFromString:reportDateString];
        
        if (!latestDate || [latestDate timeIntervalSinceDate:reportDate] > 0) {
            latestDate = reportDate;
            latest = filename;
        }
    }

    // check to see if it's aleaday been reported, though
    if ([ILReportWindow isFeatureEnabled:ILReportWindowSuppressDuplicatesKey]) {
        NSArray* signatures = [[NSUserDefaults standardUserDefaults] arrayForKey:ILReportWindowReportedSignaturesKey];
        if (signatures && [signatures containsObject:latest]) {
            NSLog(@"%@ suppressing: %@", self.class, latest);
            latest = nil;
        }
    }

    return latest;
}

+ (NSString*) systemCrashReportSignature:(NSString*) filename
{
    return filename; // make each crash unique by it's filename
}

+ (BOOL) clearSystemCrashReports
{
    BOOL allClear = YES;
    for (NSString* reportPath in [ILReportWindow systemCrashReports]) {
        allClear = [[NSFileManager defaultManager] trashItemAtURL:[NSURL fileURLWithPath:reportPath] resultingItemURL:nil error:nil];
        if (!allClear) {
            break; // for
        }
    }
    return allClear;
}

#pragma mark - Screenshots
#if IL_APP_KIT

+ (NSImage*) screenshotWindow:(NSWindow*) window
{
    CGWindowID windowID = (CGWindowID)[window windowNumber];
    CGWindowImageOption imageOptions = kCGWindowImageDefault;
    CGWindowListOption singleWindowListOptions = kCGWindowListOptionIncludingWindow;
    CGRect imageBounds = CGRectNull;
    CGImageRef windowImageRef = CGWindowListCreateImage(imageBounds, singleWindowListOptions, windowID, imageOptions);
    NSImage * windowImage = [[NSImage alloc] initWithCGImage:windowImageRef size:[window frame].size];
    [windowImage setCacheMode:NSImageCacheNever];

exit:
    CFRelease( windowImageRef);
    return windowImage;
}

+ (NSArray*) windowScreenshots
{
    NSMutableArray* screenShots = [NSMutableArray new];
    for (NSWindow* window in [NSApp windows]) {
        if (![window isKindOfClass:NSClassFromString(@"NSCarbonMenuWindow")] // don't screenshot the menus
        &&  ![[window windowController] isKindOfClass:[ILReportWindow class]] // or this error report itself
        &&  [window isVisible]) { // ignore offscreen windows
            NSDictionary* windowInfo = @{
                ILReportWindowTitle: [window title],
                ILReportWindowFrame: NSStringFromRect([window frame]),
                ILReportWindowImage: [ILReportWindow screenshotWindow:window]
            };
            [screenShots addObject:windowInfo];
        }
    }
    return screenShots;
}

#endif

#pragma mark - Utilities
#if IL_APP_KIT

// log show --info --debug --predicate 'process == "AppName" and senderImagePath endswith "AppName"' --last 12h --style syslog
+ (NSString*) fetchSyslog // grep the syslog for any messages pertaining to us and return the messages
{
    NSString* appName = [[[NSBundle mainBundle] executablePath] lastPathComponent];
    NSTask* grep = 	[NSTask new];
    NSPipe* output = [NSPipe pipe];
    NSString* predicate = [NSString stringWithFormat:@"process == \"%@\" and senderImagePath endswith \"%@\"", appName, appName];
    [grep setLaunchPath:@"/usr/bin/log"];
    [grep setArguments:@[@"show", @"--predicate", predicate, @"--last", @"1d", @"--info", @"--debug", @"--style", @"syslog"]];
    [grep setStandardInput:[NSPipe pipe]];
    [grep setStandardOutput:output];
    [grep launch];
    NSString* logLines = [[NSString alloc] initWithData:[[output fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    return logLines;
}

+ (void) restartApp
{
    static int fatal_signals[] = {SIGABRT, SIGBUS, SIGFPE, SIGILL, SIGSEGV, SIGTRAP};
    static int fatal_signals_count = (sizeof(fatal_signals) / sizeof(fatal_signals[0]));
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    
    // clear out all the fatal signal handlers, so we don't end up crashing all the way down
    for (int i = 0; i < fatal_signals_count; i++) {
        struct sigaction sa;
        
        memset(&sa, 0, sizeof(sa));
        sa.sa_handler = SIG_DFL;
        sigemptyset(&sa.sa_mask);
        
        sigaction(fatal_signals[i], &sa, NULL);
    }
    
    NSString* shellEscapedAppPath = [NSString stringWithFormat:@"'%@'", [[[NSBundle mainBundle] bundlePath] stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"]];
    NSString *script = [NSString stringWithFormat:@"(while /bin/kill -0 %d >&/dev/null; do /bin/sleep 0.1; done; /usr/bin/open %@) &", pid, shellEscapedAppPath];
    [[NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:@[@"-c", script]] waitUntilExit];
    exit(1);
}
#endif

#pragma mark -

+ (NSString*) byteSizeAsString:(NSInteger) fsSize {
    static const int KILO = 1024;
    
    if (fsSize == 0) {
        return NSLocalizedStringFromTableInBundle( @"", nil, [NSBundle bundleForClass:[self class]], @"File size, for empty files and directories");
    }
    
    if (fsSize < KILO) {
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle( @"%i Bytes", nil, [NSBundle bundleForClass:[self class]], @"File size, for items that are less than 1 kilobyte"), fsSize];
    }
    
    double numK = (double) fsSize / KILO;
    if (numK < KILO) {
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle( @"%.1f KB", nil, [NSBundle bundleForClass:[self class]], @"File size in Kilobytes"), numK];
    }
    
    double numMB = numK / KILO;
    if (numMB < KILO) {
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"%.1f MB", nil, [NSBundle bundleForClass:[self class]], @"File size in Megabytes"), numMB];
    }
    
    double numGB = numMB / KILO;
    if (numGB < KILO) {
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle( @"%.1f GB", nil, [NSBundle bundleForClass:[self class]], @"File size in Gigabytes"), numGB];
    }
    
    double numTB = numGB / KILO;
    if (numTB < KILO) {
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle( @"%.1f TB", nil, [NSBundle bundleForClass:[self class]], @"File size in Terrabytes"), numTB];
    }
    
    double numPB = numTB / KILO;
    if (numPB < KILO) {
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle( @"%.1f PB", nil, [NSBundle bundleForClass:[self class]], @"File size in Petabytes"), numPB];
    }
    
    double numEB = numPB / KILO;
    if (numEB < KILO) {
        return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle( @"%.1f EB", nil, [NSBundle bundleForClass:[self class]], @"File size in Exabytes"), numEB];
    }
    
    return NSLocalizedStringFromTableInBundle(@"Large", nil, [NSBundle bundleForClass:[self class]],  @"File size, for really large files");
}
/*
 @param array of plist entries (String, Number, Array, Dictionary, Data)
 @return array of plist entries but with all Data elements replaced with "%lu bytes"
 */
+ (NSArray*) filterDataFromArray:(NSArray*) array
{
    NSMutableArray* filtered = [NSMutableArray new];

    for (id item in array) {
        if ([item isKindOfClass:[NSData class]]) {
            [filtered addObject:[NSString stringWithFormat:@"<%@ data>", [self byteSizeAsString:[item length]]]];
        }
        else if ([item isKindOfClass:[NSDictionary class]]) {
            [filtered addObject:[self filterDataFromDictionary:item]];
        }
        else if ([item isKindOfClass:[NSArray class]]) {
            [filtered addObject:[self filterDataFromArray:item]];
        }
        else {
            [filtered addObject:item];
        }
    }
    return filtered;
}

/*
 @param plist an NSDictionary contianing plist entries (String, Number, Array, Dictionary, Data)
 @returns an NSDictionary with any NSData elements replaced with: "%lu bytes"
 */
+ (NSDictionary*) filterDataFromDictionary:(NSDictionary*) dictionary
{
    NSMutableDictionary* filtered = [NSMutableDictionary new];

    for (NSString* key in [dictionary allKeys]) {
        id value = [dictionary objectForKey:key];
        if ([value isKindOfClass:[NSData class]]) {
            value = [NSString stringWithFormat:@"<%@ data>", [self byteSizeAsString:[value length]]];
        }
        else if ([value isKindOfClass:[NSDictionary class]]) {
            value = [self filterDataFromDictionary:value];
        }
        else if ([value isKindOfClass:[NSArray class]]) {
            value = [self filterDataFromArray:value];
        }
        [filtered setObject:value forKey:key];
    }

    return filtered;
}

#pragma mark - Factory Methods

+ (instancetype) windowForSystemCrashReport:(NSString*) crashReportPath
{
#if IL_APP_KIT
    ILReportWindow* window = [[ILReportWindow alloc] initWithWindowNibName:[self className]];
    window.mode = ILReportWindowCrashMode;
    return window;
#else
    return nil; // TODO
#endif
}

+ (instancetype) windowForError:(NSError*) error
{
#if IL_APP_KIT
    ILReportWindow* window = [[ILReportWindow alloc] initWithWindowNibName:[self className]];
    
    if ([[[error userInfo] objectForKey:ILReportWindowTreatErrorAsBugKey] boolValue]) {
        window.mode = ILReportWindowBugMode;
    }
    else {
        window.mode = ILReportWindowErrorMode;
    }

    window.error = error;

    return window;
#else
    return nil; // TODO
#endif
}

+ (instancetype) windowForException:(NSException*) exception
{
#if IL_APP_KIT
    ILReportWindow* window = [[ILReportWindow alloc] initWithWindowNibName:[self className]];
    window.mode = ILReportWindowExceptionMode;
    window.exception = exception;
    return window;
#else
    return nil; /// TODO
#endif
}

+ (instancetype) windowForBug
{
#if IL_APP_KIT
    ILReportWindow* window = [[ILReportWindow alloc] initWithWindowNibName:[self className]];
    window.mode = ILReportWindowBugMode;
    return window;
#else
    return nil; /// TODO
#endif
}

#pragma mark - 

- (void) takeScreenshots
{
#if IL_APP_KIT
    NSArray* screenshots = [ILReportWindow windowScreenshots]; // TODO process these for size, maybe 8-bit greyscale?
    for (NSDictionary* screenshot in screenshots) {
        NSDictionary* commentsAttributes = @{NSFontAttributeName: [ILFont fontWithName:@"Menlo" size:9]};
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n- Window Screenshot -\n\n" attributes:commentsAttributes]];

        for( NSString* key in @[ILReportWindowTitle, ILReportWindowFrame]) {
            [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@\t%@\n", ILLocalizedString(key), [screenshot objectForKey:key]] attributes:commentsAttributes]];
        }

        NSImage* screenshotImage = [screenshot objectForKey:ILReportWindowImage];
        NSTextAttachmentCell* screenshotCell = [[NSTextAttachmentCell alloc] initImageCell:screenshotImage];
        NSTextAttachment* attachment = [NSTextAttachment new];
        [attachment setAttachmentCell:screenshotCell];
        [self.comments.textStorage appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    }
#endif
}
- (NSString*) reportSignature
{
    NSString* reportSignature = nil;

    if (self.mode == ILReportWindowCrashMode) {
        reportSignature = [ILReportWindow latestSystemCrashReport];
    }
    else if (self.mode == ILReportWindowExceptionMode) {
        reportSignature = [ILReportWindow exceptionSignature:self.exception];
    }
    else if (self.mode == ILReportWindowErrorMode) {
        reportSignature = [ILReportWindow errorSignature:self.error];
    }
    // else generate a a UUID or timestamp for a bug report?
    
    return reportSignature;
}

- (BOOL) checkConfig // check for email or submit urls, one is enough
{
    NSArray* infoKeys = [[[NSBundle mainBundle] infoDictionary] allKeys];
    return [infoKeys containsObject:ILReportWindowSubmitURLKey];
}

- (void) runModal
{
    NSString* reportSignature = [self reportSignature];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:ILReportWindowIgnoreKey] && self.mode != ILReportWindowErrorMode) {
        return; // quietly ignore reports if the user doesn't care
    }
    else if (reportSignature && [ILReportWindow isFeatureEnabled:ILReportWindowSuppressDuplicatesKey]
      && [[[NSUserDefaults standardUserDefaults] arrayForKey:ILReportWindowReportedSignaturesKey] containsObject:reportSignature]) {
        NSLog(@"%@ suppressing: %@", self.class, reportSignature);
        return;
    }
    
    if ([self checkConfig]) {
        // clear the underlying exception handler
        self.exceptionHandler = NSGetUncaughtExceptionHandler();
        NSSetUncaughtExceptionHandler(nil);
        
#if IL_APP_KIT
        // reset the NSExceptionHandler delegate and mask
        self.exceptionDelegate = [[NSExceptionHandler defaultExceptionHandler] delegate];
        self.exceptionMask = [[NSExceptionHandler defaultExceptionHandler] exceptionHandlingMask];
        [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:0]; // can't have a throw in the middle
        [[NSExceptionHandler defaultExceptionHandler] setDelegate:nil]; // can't have a throw in the middle
        
        // now it's safe to show the window, any issues in our code will be treated as if there is no handling, preventing recursion
        [super showWindow:self];
        [self.window orderFrontRegardless];
        self.modalSession = [NSApp beginModalSessionForWindow:self.window];
#endif
    }
    else NSLog(@"%@ please configure a %@ in your apps Info.plist", self.class, ILReportWindowSubmitURLKey);
}

// TODO run modal for window with parameters 

- (void) prepareReportData
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    self.reportUUID = [NSString stringWithString:CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault,uuid))];
    if(uuid) CFRelease(uuid);

#ifdef PL_CRASH_COMPATABLE
    if (self.reporter) {
        NSError* prepError = nil;
        // either pull the pending report of create a new one
        if (self.reporter.hasPendingCrashReport ) {
            self.crashData = [self.reporter loadPendingCrashReportDataAndReturnError:&prepError];
        }
        else {
            self.crashData = [self.reporter generateLiveReportAndReturnError:&prepError];
        }
        
        if (!self.crashData) {
            NSLog(@"%@ error when perparing report data: %@", self.class, prepError);
        }
    }
#endif
}

// http://tools.ietf.org/html/rfc1867
// the user has apporved the url if it's not secure, go ahead and upload via http or https
// setup to post the form, generate a UUID for the report, create the boundary and attache the file if needed
- (void) postReportToWebServer:(NSURL*) approvedURL
{
    BOOL multipart = NO;
    NSMutableURLRequest* uploadRequest = [NSMutableURLRequest new];
    [uploadRequest setURL:approvedURL];
    NSString* encodedComments = [self.comments.textStorage.string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSMutableString* requestBody = [NSMutableString new];

    if (multipart) {
        NSString *boundary = [NSString stringWithFormat:@"++%@", self.reportUUID];
        NSString *boundaryLine = [NSString stringWithFormat:@"--%@\r\n", boundary];
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        
        // put the comments into the primary form-data field
        [uploadRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
        [requestBody appendString:boundaryLine];
        [requestBody appendString:@"Content-Disposition: form-data; name=\"comments\"\r\n\r\n"];
        [requestBody appendString:encodedComments];
        [requestBody appendString:@"\r\n"];

#ifdef PL_CRASH_COMPATABLE
        if (self.crashData) { // send the crash report data as the next attachment
            NSString* crashFileName = [self.reportUUID stringByAppendingPathExtension:@"crashreport"];

            [requestBody appendString:boundaryLine];
            [requestBody appendString:[NSString stringWithFormat:@"Content-Disposition: attachment; name=\"report\"; filename=\"%@\"\r\n",crashFileName]];
            [requestBody appendString:@"Content-Transfer-Encoding: base64\r\n\r\n"];
            [requestBody appendString:[self.crashData base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength]];
            [requestBody appendString:@"\r\n"];
        }
#endif
    
        // TODO send any text attachments in the report

        [requestBody appendString:boundaryLine];
        [requestBody appendString:@"\r\n"];
    }
    else {
        [uploadRequest addValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
        [requestBody appendString:encodedComments];
    }
    
    uploadRequest.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    uploadRequest.HTTPShouldHandleCookies = NO;
    uploadRequest.timeoutInterval = 30;
    uploadRequest.HTTPMethod = @"POST";
    uploadRequest.HTTPBody = [requestBody dataUsingEncoding:NSUTF8StringEncoding]; // post data
    
    // TODO move over to NSURLSession
    // NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]]; // no cookies for us, thanks
    // NSURLSessionUploadTask* upload = [session uploadTaskWithRequest:uploadRequest fromData:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLConnection* upload = [NSURLConnection connectionWithRequest:uploadRequest delegate:self];
    
    self.responseBody = [NSMutableData new];
#if IL_APP_KIT
    [upload scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSModalPanelRunLoopMode];
#else
    [upload scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
#endif
    [upload start];
}

- (void) emailReportTo:(NSURL*) mailtoURL
{
#ifdef PL_CRASH_COMPATABLE
    NSError* emailError = nil;
    NSData* reportData = (self.reporter.hasPendingCrashReport
                         ?[self.reporter loadPendingCrashReportDataAndReturnError:&emailError]
                         :[self.reporter generateLiveReportAndReturnError:&emailError]);
    attachmentFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[self.reportUUID stringByAppendingPathExtension:@"ILCrashreport"]];
    [reportData writeToFile:attachmentFilePath atomically:NO];
#endif
    
#ifdef SCRIPTING_SUPPORT
    /* set ourself as the delegate to receive any errors */
    // TODO extract text attachments and make them email attachments
    // mail.delegate = self;
    NSString* attachmentFilePath = nil;

    /* create a Scripting Bridge object for talking to the Mail application */
    MailApplication *mail = [SBApplication applicationWithBundleIdentifier:@"com.apple.Mail"];
    
    /* create a new outgoing message object */
    MailOutgoingMessage *emailMessage = [[[mail classForScriptingClass:@"outgoing message"] alloc] initWithProperties:
                                         [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSString stringWithFormat:@"Crash Report: %@", self.reportUUID], @"subject",
                                          self.comments.textStorage.string, @"content",
                                          nil]];
    
    /* add the object to the mail app  */
    [[mail outgoingMessages] addObject: emailMessage];
    
    /* set the sender, show the message */
    emailMessage.visible = YES;
    
    /* Test for errors */
    if ( [mail lastError] != nil )
        return;
    
    /* create a new recipient and add it to the recipients list */
    MailToRecipient *theRecipient = [[[mail classForScriptingClass:@"to recipient"] alloc] initWithProperties:
                                     [NSDictionary dictionaryWithObjectsAndKeys:
                                      mailtoURL.resourceSpecifier, @"address",
                                      nil]];
    [emailMessage.toRecipients addObject: theRecipient];
    
    /* Test for errors */
    if ( [mail lastError] != nil )
        return;
    
    /* add an attachment, if one was specified */
    
    if ( [attachmentFilePath length] > 0 ) {
        MailAttachment *theAttachment;
        
        theAttachment = [[[mail classForScriptingClass:@"attachment"] alloc] initWithProperties:
                         [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSURL URLWithString:attachmentFilePath], @"fileName",
                          nil]];
        
        /* add it to the list of attachments */
        [[emailMessage.content attachments] addObject: theAttachment];
        
        /* Test for errors */
        if ( [mail lastError] != nil )
            return;
    }
    /* send the message */
    [emailMessage send];
#endif
    [self closeAfterReportComplete];
}

- (void) sendReport
{
    // get the submission url
    NSURL* url = [NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] objectForKey:ILReportWindowSubmitURLKey]];

    if( !url ) {
        NSLog(@"%@ %@must be set to send a report!", self.class, ILReportWindowSubmitURLKey);
#if IL_APP_KIT
        [self close]; // developer error, immediate close
#endif
        return;
    }
    
    // create the UUID for the report
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    self.reportUUID = [NSString stringWithString:CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault,uuid))];
    if(uuid) CFRelease(uuid);
    
    /* if it's a mailto: create an email message with the support address
    if ([[url scheme] isEqualToString:@"mailto"]) {
        [self emailReportTo:url];
    }
    else */
    if ([[url scheme] isEqualToString:@"https"]) { // if it's HTTPS post the crash report immediatly
        [self postReportToWebServer:url];
    }
    else if ([[url scheme] isEqualToString:@"http"]) { // it it's *just* HTTP prompt the user for permission to send in the clear
#if IL_APP_KIT
        NSString* appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
        NSAlert* plaintextAlert = [NSAlert new];
        plaintextAlert.alertStyle = NSCriticalAlertStyle;
        plaintextAlert.messageText = ILLocalizedString(ILReportWindowInsecureConnectionString);
        plaintextAlert.informativeText = [NSString stringWithFormat:ILLocalizedString(ILReportWindowInsecureConnectionInformationString), appName];
        [plaintextAlert addButtonWithTitle:ILLocalizedString(ILReportWindowSendString)];
        [plaintextAlert addButtonWithTitle:ILLocalizedString(ILReportWindowCancelString)];

        [plaintextAlert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            if( returnCode == NSAlertFirstButtonReturn) {
                [self close]; // this is a user cancel, immediate close
            }
            else if( returnCode == NSAlertSecondButtonReturn) {
                [self postReportToWebServer:url];
            }
        }];
#endif
    }
    else {
#if IL_APP_KIT
        NSBeep();
        NSLog(@"%@ unkown scheme: %@ comments:\n\n%@", self.class, url, self.comments.textStorage.string);
        [self close]; // invalid scheme in config, developer error, immediate close
#endif
    }
}

- (void) closeAfterReportComplete
{
    // record the signature
    NSString* reportSignature = [self reportSignature];
    if( reportSignature)
    {
        NSArray* reported = [[NSUserDefaults standardUserDefaults] arrayForKey:ILReportWindowReportedSignaturesKey];
        if( reported) {
            if( ![reported containsObject:reportSignature]) {
                reported = [reported arrayByAddingObject:reportSignature];
            }
        }
        else {
            reported = @[reportSignature];
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:reported forKey:ILReportWindowReportedSignaturesKey];
        [[NSUserDefaults standardUserDefaults] synchronize]; // imporant cause we might quit the app next
    }

    // assuming everything went well, trash the latest system crash report
    NSString* lastCrashReport = [ILReportWindow latestSystemCrashReport];
    if( lastCrashReport) {
        NSFileManager* fm = [NSFileManager defaultManager];
        NSError* error = nil;
        NSURL* trashed = nil;
        if(![fm trashItemAtURL:[NSURL fileURLWithPath:lastCrashReport] resultingItemURL:&trashed error:&error]) {
            NSLog(@"%@ error %@ moving %@ to trash %@", self.class, error, lastCrashReport, trashed);
        }
    }

    // if we want to auto-submit an error or exception, then start a timer before restarting the app
    if( [[NSUserDefaults standardUserDefaults] boolForKey:ILReportWindowAutoSubmitKey]
     && (self.mode == ILReportWindowErrorMode || self.mode == ILReportWindowExceptionMode)) {
        NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
        self.autoRestartSeconds = ([[info allKeys] containsObject:ILReportWindowAutoRestartSecondsKey]
                               ? [[info objectForKey:ILReportWindowAutoRestartSecondsKey] unsignedIntegerValue]
                               : 60);

        self.autoRestartTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(autoRestartTimer:) userInfo:nil repeats:YES];
        self.send.enabled = YES; // enabled so the user can skip the timer
#if IL_APP_KIT
        self.remember.enabled = YES; // enabled so the user can skip the timer
#endif
    }
    else if( self.mode == ILReportWindowErrorMode || self.mode == ILReportWindowExceptionMode) { // user prompted hit submit button
#ifdef DEBUG
        exit(-1);
#else
        [ILReportWindow restartApp];
#endif
    }
#if IL_APP_KIT
    else {
        [self close]; // just close in the case of an exception or bug report
    }
#endif
}

#pragma mark - NSNibAwakening

- (void) awakeFromNib
{
    // setup the headline from the app name and event message
    NSString* appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
 
    // setup the username and email fields for uesrs we know them from
    NSString* defaultsUsername = [[NSUserDefaults standardUserDefaults] stringForKey:ILReportWindowUserFullNameKey];
    NSString* defaultsEmail = [[NSUserDefaults standardUserDefaults] stringForKey:ILReportWindowUserEmailKey];

    if (defaultsUsername) {
#if IL_APP_KIT
        self.fullname.stringValue = defaultsUsername;
#elif IL_UI_KIT
        self.fullname.text = defaultsUsername;
#endif
    }
    
    if (defaultsEmail) {
#if IL_APP_KIT
        self.emailaddress.stringValue = defaultsEmail;
#elif IL_UI_KIT
        self.emailaddress.text = defaultsEmail;
#endif
    }
    
    // setup the window depending on the report mode
    if (self.mode == ILReportWindowCrashMode) {
#if IL_APP_KIT
        self.window.title = ILLocalizedString(ILReportWindowCrashReportString);
        self.screenshots.state = NSOffState;
        self.screenshots.enabled = NO;
#endif
        self.send.title = ILLocalizedString(ILReportWindowSendString);
        self.headline.text = [NSString stringWithFormat:@"%@ %@", appName, ILLocalizedString(ILReportWindowCrashedString)];
        self.subhead.text = ILLocalizedString(ILReportWindowReportDispositionString);
    }
    else if (self.mode == ILReportWindowErrorMode) {
#if IL_APP_KIT
        self.window.title = ILLocalizedString(ILReportWindowErrorReportString);
#endif

        if (self.error && self.error.localizedDescription) { // add the description to the headline
            self.headline.text = [NSString stringWithFormat:@"%@ %@: %@",
                appName, ILLocalizedString(ILReportWindowReportedErrorString), self.error.localizedDescription];
        }
        else {
            self.headline.text = [NSString stringWithFormat:@"%@ %@", appName, ILLocalizedString(ILReportWindowReportedErrorString)];
        }

        if (self.error && self.error.localizedFailureReason) { // add the failure reason to the disposition
            self.subhead.text = [NSString stringWithFormat:@"%@\n%@",
                self.error.localizedFailureReason, ILLocalizedString(ILReportWindowErrorDispositionString)];
        }
        else {
            self.subhead.text = ILLocalizedString(ILReportWindowErrorDispositionString);
        }

        self.send.title = ILLocalizedString(ILReportWindowRestartString);
        self.cancel.title = ILLocalizedString(ILReportWindowIgnoreString);
#if IL_APP_KIT
        self.screenshots.state = NSOnState;
        self.screenshots.enabled = YES;
#endif
    }
    else if (self.mode == ILReportWindowExceptionMode) {
#if IL_APP_KIT
        self.window.title = ILLocalizedString(ILReportWindowExceptionReportString);
#endif
        self.headline.text = [NSString stringWithFormat:@"%@ %@", appName, ILLocalizedString(ILReportWindowRaisedExceptionString)];
        self.subhead.text = ILLocalizedString(ILReportWindowErrorDispositionString);
        self.send.title = ILLocalizedString(ILReportWindowRestartString);
        self.cancel.title = ILLocalizedString(ILReportWindowIgnoreString);
#if IL_APP_KIT
        self.screenshots.state = NSOnState;
        self.screenshots.enabled = YES;
#endif
    }
    else { // assume it's ILReportWindowBugMode
#if IL_APP_KIT
        self.window.title = ILLocalizedString(ILReportWindowBugReportString);
#endif
        self.headline.text = [NSString stringWithFormat:@"%@ %@", ILLocalizedString(ILReportWindowReportingBugString), appName];
        self.subhead.text = ILLocalizedString(ILReportWindowBugDispositionString);
        self.send.title = ILLocalizedString(ILReportWindowReportString);
#if IL_APP_KIT
        self.remember.hidden = YES; // automatic bug reporting *would* be an amazing feature though
        self.screenshots.state = NSOffState;
        self.screenshots.enabled = YES;
#endif
    }

#if IL_APP_KIT
    // set the screenshots enabled based on app plist and user preference, show it as enabled
    if ([ILReportWindow isFeatureEnabled:ILReportWindowIncludeWindowScreenshotsKey]) {
        self.screenshots.enabled = YES;
        self.screenshots.state = NSOnState;
    }

    [self.progress startAnimation:self];
#endif

    self.status.text = NSLocalizedStringFromTableInBundle(@"Building Report…", nil, [NSBundle bundleForClass:[self class]], @"Building Report… Status");
    self.comments.editable = NO;
    self.send.enabled = NO;
#if IL_APP_KIT
    self.remember.enabled = NO;
#endif

    // fill in the comments section
    NSDictionary* commentsAttributes = @{NSFontAttributeName: [ILFont fontWithName:@"Menlo" size:9]};
    [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:ILLocalizedString(ILReportWindowCommentsString) attributes:commentsAttributes]];
    
    // if the error wasn't explicity set, grab the last one
    if (self.error) {
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n- Error -\n\n" attributes:commentsAttributes]];
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:[ILReportWindow errorReport:self.error] attributes:commentsAttributes]];
    }
    
    if (self.exception) {
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n- Exception -\n\n" attributes:commentsAttributes]];
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:[ILReportWindow exceptionReport:self.exception] attributes:commentsAttributes]];
    }

    if ([ILReportWindow isFeatureEnabled:ILReportWindowIncludeDefaultsKey]) {
        NSDictionary* defaultsDictionary = [[NSUserDefaults standardUserDefaults] persistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
        defaultsDictionary = [[self class] filterDataFromDictionary:defaultsDictionary];
        NSString* defaultsString = [defaultsDictionary description];
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n- Application Defaults -\n\n" attributes:commentsAttributes]];
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:defaultsString attributes:commentsAttributes]];
    }
    
    // following report segments might take some time to gather, create a serial queue

    self.gatherQueue = [NSOperationQueue new];
    self.gatherQueue.maxConcurrentOperationCount = 1;

    // gather crash reports
    [self.gatherQueue addOperationWithBlock:^{
        NSString* reportPath = [ILReportWindow latestSystemCrashReport];
        if (reportPath) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n- Latest Crash Report -\n\n" attributes:commentsAttributes]];

                [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@\n",reportPath] attributes:commentsAttributes]];

                NSString* reportContents = [NSString stringWithContentsOfFile:reportPath encoding:NSUTF8StringEncoding error:nil];
                [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n%@\n",reportContents] attributes:commentsAttributes]];
            }];
        }
    }];
    
    // list of system crash reports
    [self.gatherQueue addOperationWithBlock:^{
        NSArray* crashReports = [ILReportWindow systemCrashReports];
        
        if (crashReports && crashReports.count > 0) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n- Crash Reports -\n\n" attributes:commentsAttributes]];

                for (NSString* reportPath in crashReports) {
                    [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"\t%@\n",reportPath] attributes:commentsAttributes]];
                }
            }];
        }
    }];

    if ([ILReportWindow isFeatureEnabled:ILReportWindowIncludeWindowScreenshotsKey]) {
        [self.gatherQueue addOperationWithBlock:^{
            [self takeScreenshots];
        }];
    }

#if IL_APP_KIT
    // if the keys are set in the main bundle info keys, include the syslog and user defaults
    if ([ILReportWindow isFeatureEnabled:ILReportWindowIncludeSyslogKey]) {
        [self.gatherQueue addOperationWithBlock:^{
            NSString* logString = [ILReportWindow fetchSyslog];
            if (logString && logString.length > 0) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n- System Log -\n\n" attributes:commentsAttributes]];
                    [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:logString attributes:commentsAttributes]];
                }];
            }
        }];
    }
#endif

    // add this to the end of the gather queue, so that the UI will enable when other opations are complete
    [self.gatherQueue addOperationWithBlock:^{
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.status.text = @"";
            self.comments.editable = YES;
#if IL_APP_KIT
            self.remember.enabled = YES;
#endif
            self.send.enabled = YES;
            [self.progress stopAnimating];
            // select the 'please enter any notes' line for replacment
            [self.comments setSelectedRange:NSMakeRange(0, [self.comments.textStorage.string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location)];

            // automatically submit if configured to do so
            if ([[NSUserDefaults standardUserDefaults] boolForKey:ILReportWindowAutoSubmitKey]) {
#if IL_APP_KIT
                self.remember.state = NSOnState;
#endif
                if (self.mode != ILReportWindowBugMode) { // present the window and send the report, showing them that we're doing it, they can canel and add comments
                    [self performSelector:@selector(onSend:) withObject:self afterDelay:0];
                }
            }
#if IL_APP_KIT
            else self.remember.state = NSOffState;
#endif
        }];
    }];
    
    [super awakeFromNib];
}

#pragma mark - NSWindowDelegate
#if IL_APP_KIT
- (void)windowWillClose:(NSNotification *)notification
{
    if (self.gatherQueue) {
        [self.gatherQueue waitUntilAllOperationsAreFinished];
    }

    if (self.modalSession) {
        [NSApp endModalSession:self.modalSession];
        [[NSExceptionHandler defaultExceptionHandler] setDelegate:self.exceptionDelegate];
        [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:self.exceptionMask];
        NSSetUncaughtExceptionHandler(self.exceptionHandler);
        self.exceptionDelegate = nil;
    }
}
#endif

#pragma mark - IBActions

- (IBAction)onCancel:(id)sender
{
#if IL_APP_KIT
    if (self.remember.state ) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:ILReportWindowAutoSubmitKey];
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:ILReportWindowAutoSubmitKey];
    }
#endif

    // are we currently sending? stop that
    self.comments.editable = YES;
#if IL_APP_KIT
    self.remember.enabled = YES;
#endif
    self.send.enabled = YES;
    self.status.text = @"";
    [self.progress stopAnimating];
    
#if IL_APP_KIT
    [self close]; // user canceled or ignored, immediate close
#endif
}

- (IBAction)onSend:(id)sender
{
#if IL_APP_KIT
    if (self.remember.state ) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:ILReportWindowAutoSubmitKey];
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:ILReportWindowAutoSubmitKey];
    }
#endif

    // update the provided name and email if they differ from the defualts
    NSString* providedName = self.fullname.text;
    NSString* providedEmail = self.emailaddress.text;

    if (![providedName isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:ILReportWindowUserFullNameKey]]) {
        [[NSUserDefaults standardUserDefaults] setObject:providedName forKey:ILReportWindowUserFullNameKey];
    }
    
    if (![providedEmail isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:ILReportWindowUserEmailKey]]) {
        [[NSUserDefaults standardUserDefaults] setObject:providedEmail forKey:ILReportWindowUserEmailKey];
    }
    
    // if the auto-restart timer is counting down, we've already submitted the report
    if (self.autoRestartTimer) { // advance it to the end and fire it
        self.autoRestartSeconds = 1;
        [self autoRestartTimer:self.autoRestartTimer];
    }
    else { // user want's us to submit
        // start the progress indicator and disable various controls
        [self.progress startAnimating];
        self.comments.editable = NO;
#if IL_APP_KIT
        self.remember.enabled = NO;
#endif
        self.send.enabled = NO;

        // perform the upload
        [self sendReport];
    }
}

#pragma mark - NSTimer

- (void) autoRestartTimer:(NSTimer*) timer
{
    if( --self.autoRestartSeconds == 0 ) { // decrement and check
        [timer invalidate];
        self.autoRestartTimer = nil;
#ifdef DEBUG
        exit(-1);
#elif IL_APP_KIT
        [ILReportWindow restartApp];
#endif
    }
    else {
        self.status.text = [NSString stringWithFormat:@"%@ %lu %@",
            ILLocalizedString(ILReportWindowRestartInString),
            self.autoRestartSeconds,
            ILLocalizedString(ILReportWindowSecondsString)];
    }
}

#pragma mark - NSURLSessionTaskDelegate

- (void) URLSession:(NSURLSession*)session
    task:(NSURLSessionTask*)task
    willPerformHTTPRedirection:(NSHTTPURLResponse*)redirect
    newRequest:(NSURLRequest*)request
    completionHandler:(void (^)(NSURLRequest* _Nullable))completionHandler
{
    if (redirect && (redirect.statusCode == 302)) { // we got redirected
        Class sparkeUpdater = NSClassFromString(ILReportWindowSparkleUpdaterClass); // check to see if the updater is present
        if (sparkeUpdater && [[[sparkeUpdater sharedUpdater] feedURL] isEqual:redirect.URL]) { // we were redirected to the update page
            [[sparkeUpdater sharedUpdater] checkForUpdates:self];
        }
        else { //  display the page to the user
            NSLog(@"%@ error submitting a report: %li redirect: %@", self.class, (long)self.response.statusCode, redirect.URL);
#if IL_APP_KIT
            [[NSWorkspace sharedWorkspace] openURL:redirect.URL];
#elif IL_UI_KIT
            [[UIApplication sharedApplication] openURL:redirect.URL options:@{} completionHandler:nil];
#endif
        }
    }
}

- (void) URLSession:(NSURLSession*)session
    task:(NSURLSessionTask*)task
    didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
    totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    self.status.text = [NSString stringWithFormat:@"%@/%@ %C",
        [ILReportWindow byteSizeAsString:totalBytesSent],
        [ILReportWindow byteSizeAsString:totalBytesExpectedToSend],
        0x2191]; // UPWARDS ARROW Unicode: U+2191, UTF-8: E2 86 91
#if DEBUG
    NSLog(@"%@ post: %li/%li bytes", self.class, (long)totalBytesSent,(long)totalBytesExpectedToSend);
#endif
}

- (void) URLSession:(NSURLSession*)session task:(NSURLSessionTask*)task didCompleteWithError:(NSError*)error
{
    if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)task.response;
        
        if (httpResponse.statusCode == 200) { // OK!
            self.status.text = [NSString stringWithFormat:@"%C", 0x2713]; // CHECK MARK Unicode: U+2713, UTF-8: E2 9C 93
            [self closeAfterReportComplete];
        }
        else { // not ok, present error
            [self.progress stopAnimating];
            self.status.text = [NSString stringWithFormat:@"%li %C", (long)httpResponse.statusCode, 0x274C]; // CROSS MARK Unicode: U+274C
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:ILReportWindowAutoSubmitKey]; // disable auto-submit
        }
    }
}

#pragma mark - NSURLSessionDataDelegate


- (void) URLSession:(NSURLSession*)session dataTask:(NSURLSessionDataTask*)dataTask didReceiveData:(NSData*)data
{
    [self.responseBody appendData:data];
    self.status.text = [NSString stringWithFormat:@"%@ %C",
        [ILReportWindow byteSizeAsString:self.responseBody.length],
        0x2193]; //↓ DOWNWARDS ARROW Unicode: U+2193, UTF-8: E2 86 93
#if DEBUG
    NSLog(@"%@ read: %li bytes from: %@", self.class, (unsigned long)self.responseBody.length, dataTask.currentRequest.URL);
#endif
}

#pragma mark - DEPRICATED
#pragma mark - NSURLConnectionDataDelegate

//
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)URLresponse
{
    if( [URLresponse isKindOfClass:[NSHTTPURLResponse class]]) {
        self.response = (NSHTTPURLResponse*)URLresponse;
    }
}

//
- (void) connection:(NSURLConnection *)connection
    didSendBodyData:(NSInteger)bytesWritten
    totalBytesWritten:(NSInteger)totalBytesWritten
    totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    self.status.text = [NSString stringWithFormat:@"%@/%@ %C",
        [ILReportWindow byteSizeAsString:totalBytesWritten],
        [ILReportWindow byteSizeAsString:totalBytesExpectedToWrite],
        0x2191]; // UPWARDS ARROW Unicode: U+2191, UTF-8: E2 86 91
#if DEBUG
    NSLog(@"%@ post: %li/%li bytes", self.class, (long)totalBytesWritten,(long)totalBytesExpectedToWrite);
#endif
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseBody appendData:data];
    self.status.text = [NSString stringWithFormat:@"%@ %C",
        [ILReportWindow byteSizeAsString:self.responseBody.length],
        0x2193]; //↓ DOWNWARDS ARROW Unicode: U+2193, UTF-8: E2 86 93
#if DEBUG
    NSLog(@"%@ read: %li bytes from: %@", self.class, (unsigned long)self.responseBody.length, connection.currentRequest.URL);
#endif
}

/* intercept redirects (we don't need to load the resulting page ourselves), if there was an error ask the workspace to open the URL */
- (NSURLRequest*) connection:(NSURLConnection*) connection willSendRequest:(NSURLRequest*) request redirectResponse:(NSURLResponse*) redirect
{
    if( redirect && self.response.statusCode == 302 ) { // we got redirected
        Class sparkeUpdater = NSClassFromString(ILReportWindowSparkleUpdaterClass); // check to see if the updater is present
        if( sparkeUpdater && [[[sparkeUpdater sharedUpdater] feedURL] isEqual:redirect.URL]) { // we were redirected to the update page
            [[sparkeUpdater sharedUpdater] checkForUpdates:self];
            return nil;
        }
        else { //  display the page to the user
            NSLog(@"%@ error submitting a report: %li redirect: %@", self.class, (long)self.response.statusCode, redirect.URL);
#if IL_APP_KIT
            [[NSWorkspace sharedWorkspace] openURL:redirect.URL];
#endif
            return nil;
        }
    }
    
    return request; // just return the request, either everything is OK or the web browser is showing the error
}

- (void)connectionDidFinishLoading:(NSURLConnection *) connection
{
#if DEBUG
    NSLog(@"%@ report submitted status: %li from: %@", self.class, (long)self.response.statusCode, connection.currentRequest.URL);
#endif
    //    NSString* bodyString = [[NSString alloc] initWithData:self.responseBody encoding:NSUTF8StringEncoding];
    //    NSLog(@"%@ response body: %@", bodyString);
    
    if (self.response.statusCode == 200 ) { // OK!
        self.status.text = [NSString stringWithFormat:@"%C", 0x2713]; // CHECK MARK Unicode: U+2713, UTF-8: E2 9C 93
        [self closeAfterReportComplete];
    }
    else { // not ok, present error
        [self.progress stopAnimating];
        self.status.text = [NSString stringWithFormat:@"%li %C", (long)self.response.statusCode, 0x274C]; // CROSS MARK Unicode: U+274C
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:ILReportWindowAutoSubmitKey]; // disable auto-submit
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)connectionError
{
#if IL_APP_KIT
    NSBeep();
#endif
    self.status.text = [NSString stringWithFormat:@"%C", 0x274C]; // CROSS MARK Unicode: U+274C
    
    if (connectionError) { // log it to the console
        NSLog(@"%@ connection to: %@ failed: %@", self.class, connection.currentRequest.URL, [ILReportWindow errorReport:connectionError]);
        NSDictionary* commentsAttributes = @{NSFontAttributeName: [ILFont fontWithName:@"Menlo" size:9]};
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n- Error -\n\n" attributes:commentsAttributes]];
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:[ILReportWindow errorReport:connectionError] attributes:commentsAttributes]];
    }
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return NO;
}

@end

/* Copyright 2014-2018, Alf Watt (alf@istumbler.net) Avaliale under MIT Style license in README.md */
