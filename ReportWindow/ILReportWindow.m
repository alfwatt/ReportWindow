#import "ILReportWindow.h"

#import <execinfo.h>

#import <CrashReporter/CrashReporter.h>
#import <ExceptionHandling/ExceptionHandling.h>

// scripting bridge header for Mail.app
// https://developer.apple.com/library/mac/samplecode/SBSendEmail/Introduction/Intro.html

#import "Mail.h"


NSString* const ILReportWindowAutoSubmitKey = @"ILReportWindowAutoSubmitKey";
NSString* const ILReportWindowIgnoreKey = @"ILReportWindowIgnoreKey";

NSString* const ILReportWindowSubmitURLKey = @"ILReportWindowSubmitURLKey";
NSString* const ILReportWindowSubmitEmailKey = @"ILReportWindowSubmitEmailKey";

NSString* const ILReportWindowIncludeSyslogKey = @"ILReportWindowIncludeSyslogKey";
NSString* const ILReportWindowIncludeDefaultsKey = @"ILReportWindowIncludeDefaultsKey";

NSString* const ILReportWindowAutoRestartSecondsKey = @"ILReportWindowAutoRestartSecondsKey";

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
NSString* const ILReportWindowReportString = @"ILReportWindowReportString";
NSString* const ILReportWindowRestartString = @"ILReportWindowRestartString";
NSString* const ILReportWindowQuitString = @"ILReportWindowQuitString";
NSString* const ILReportWindowCommentsString = @"ILReportWindowCommentsString";
NSString* const ILReportWindowSubmitFailedString = @"ILReportWindowSubmitFailedString";
NSString* const ILReportWindowSubmitFailedInformationString = @"ILReportWindowSubmitFailedInformationString";
NSString* const ILReportWindowRestartInString = @"ILReportWindowRestartInString"; // = @"Restart in";
NSString* const ILReportWindowSecondsString = @"ILReportWindowSecondsString"; // = @"seconds";

#define ILLocalizedString(key) [[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:@"" table:[self className]]

#pragma mark -

@implementation ILReportWindow

+ (NSString*) exceptionReport:(NSException*) exception
{
    NSMutableString* report = [NSMutableString new];
    NSMutableArray *addresses = [NSMutableArray new];
    NSString *stackTrace = [[exception userInfo] objectForKey:NSStackTraceKey];
    NSScanner *scanner = [NSScanner scannerWithString:stackTrace];
    NSString *token;
    
    [report appendString:[NSString stringWithFormat:@"%@ %@\n\n%@\n\n", exception.name, exception.reason, exception.userInfo]];
    
    while ([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
                                   intoString:&token])
    {
        [addresses addObject:token];
    }
    
    NSUInteger numFrames = [addresses count];
    if (numFrames > 0)
    {
        void **frames = (void **)malloc(sizeof(void *) * numFrames);
        NSUInteger i, parsedFrames;
        
        for (i = 0, parsedFrames = 0; i < numFrames; i++)
        {
            NSString *address = [addresses objectAtIndex:i];
            NSScanner* addressScanner = [NSScanner scannerWithString:address];
            
            if (![addressScanner scanHexLongLong:(unsigned long long *)&frames[parsedFrames]])
            {
                NSLog(@"%@ failed to parse frame address '%@'", [self className], address);
                break;
            }
            
            parsedFrames++;
        }
        
        if (parsedFrames > 0) {
            char **frameStrings = backtrace_symbols(frames, (int)parsedFrames);
            if (frameStrings)
            {
                for (unsigned i = 0; i < numFrames && frameStrings[i] ; i++)
                {
                    [report appendString:[NSString stringWithUTF8String:(char *)frameStrings[i]]];
                    [report appendString:@"\n"];
                }
                free(frameStrings);
            }
        }
        
        free(frames);
    }
    return report;
}

+ (NSString*) errorReport:(NSError*) error
{
    NSMutableString* report = [NSMutableString new];
    [report appendString:[NSString stringWithFormat:@"%@: %li\n\n%@", error.domain, (long)error.code, error.userInfo]];
    if( (error = [[error userInfo] objectForKey:NSUnderlyingErrorKey]) ) // we have to go deeper
    {
        [report appendString:[NSString stringWithFormat:@"\n\n- Underlying Error -\n\n"]];
        [report appendString:[self errorReport:error]];
    }
    return report;
}

+ (NSString*) grepSyslog // grep the syslog for any messages pertaining to us and return the messages
{
    NSString* appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
    NSTask* grep = 	[NSTask new];
    NSPipe* output = [NSPipe pipe];
    [grep setLaunchPath:@"/usr/bin/grep"];
    [grep setArguments:@[appName, @"/var/log/system.log"]];
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

+ (NSString*) byteSizeAsString:(NSInteger) fsSize
{
    static const int KILO = 1024;
    
    if (fsSize == 0)
        return NSLocalizedString( @"", @"File size, for empty files and directories");
    
    if (fsSize < KILO)
        return [NSString stringWithFormat:NSLocalizedString( @"%i Bytes", @"File size, for items that are less than 1 kilobyte"), fsSize];
    
    double numK = (double) fsSize / KILO;
    if (numK < KILO)
        return [NSString stringWithFormat:NSLocalizedString( @"%.1f KB", @"File size in Kilobytes"), numK];
    
    double numMB = numK / KILO;
    if (numMB < KILO)
        return [NSString stringWithFormat:NSLocalizedString(@"%.1f MB", @"File size in Megabytes"), numMB];
    
    double numGB = numMB / KILO;
    if (numGB < KILO)
        return [NSString stringWithFormat:NSLocalizedString( @"%.1f GB", @"File size in Gigabytes"), numGB];
    
    double numTB = numGB / KILO;
    if (numTB < KILO)
        return [NSString stringWithFormat:NSLocalizedString( @"%.1f TB", @"File size in Terrabytes"), numTB];
    
    double numPB = numTB / KILO;
    if (numPB < KILO)
        return [NSString stringWithFormat:NSLocalizedString( @"%.1f PB", @"File size in Petabytes"), numPB];
    
    double numEB = numPB / KILO;
    if (numEB < KILO)
        return [NSString stringWithFormat:NSLocalizedString( @"%.1f EB", @"File size in Exabytes"), numEB];
    
    return NSLocalizedString(@"Large",  @"File size, for really large files");
}


#pragma mark - Factory Methods

+ (instancetype) windowForCrashReporter:(PLCrashReporter*) reporter
{
    ILReportWindow* window = [[ILReportWindow alloc] initWithWindowNibName:[self className]];
    window.mode = ILReportWindowCrashMode;
    window.reporter = reporter;
    return window;
}

+ (instancetype) windowForError:(NSError*) error
{
    ILReportWindow* window = [[ILReportWindow alloc] initWithWindowNibName:[self className]];
    window.mode = ILReportWindowErrorMode;
    window.error = error;
    return window;
}

+ (instancetype) windowForException:(NSException*) exception
{
    ILReportWindow* window = [[ILReportWindow alloc] initWithWindowNibName:[self className]];
    window.mode = ILReportWindowExceptionMode;
    window.exception = exception;
    return window;
}

+ (instancetype) windowForBug
{
    ILReportWindow* window = [[ILReportWindow alloc] initWithWindowNibName:[self className]];
    window.mode = ILReportWindowBugMode;
    return window;
}

#pragma mark - 

- (BOOL) checkConfig // check for email or submit urls, one is enough
{
    NSArray* infoKeys = [[[NSBundle mainBundle] infoDictionary] allKeys];
    return ([infoKeys containsObject:ILReportWindowSubmitEmailKey] || [infoKeys containsObject:ILReportWindowSubmitURLKey]);
}

- (void) runModal
{
    if( [[NSUserDefaults standardUserDefaults] boolForKey:ILReportWindowIgnoreKey])
        return;
    
    if( [self checkConfig])
    {
        
        // clear the underlying exception handler
        self.exceptionHandler = NSGetUncaughtExceptionHandler();
        NSSetUncaughtExceptionHandler(nil);
        
        // clear the NSExceptionHandler
        self.exceptionDelegate = [[NSExceptionHandler defaultExceptionHandler] delegate];
        self.exceptionMask = [[NSExceptionHandler defaultExceptionHandler] exceptionHandlingMask];
        [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:0]; // can't have a throw in the middele
        [[NSExceptionHandler defaultExceptionHandler] setDelegate:nil]; // can't have a throw in the middele
        
        // now it's safe to show the window, any issues in our code will be treated as if there is no handling, preventing recursion
        [super showWindow:self];
        [self.window orderFrontRegardless];
        self.modalSession = [NSApp beginModalSessionForWindow:self.window];
    }
    else NSLog(@"%@ please configure a %@ or %@ in your apps Info.plist", [self className], ILReportWindowSubmitEmailKey, ILReportWindowSubmitURLKey);
}

- (void) prepareReportData
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    self.reportUUID = [NSString stringWithString:CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault,uuid))];
    if(uuid) CFRelease(uuid);

    if( self.reporter)
    {
        NSError* prepError = nil;
        // either pull the pending report of create a new one
        if( self.reporter.hasPendingCrashReport )
            self.crashData = [self.reporter loadPendingCrashReportDataAndReturnError:&prepError];
        else
            self.crashData = [self.reporter generateLiveReportAndReturnError:&prepError];
        
        if( !self.crashData)
            NSLog(@"%@ error when perparing report data: %@", [self className], prepError);
    }
}

// http://tools.ietf.org/html/rfc1867

- (void) postReportToWebServer:(NSURL*) approvedURL
{
    // the user has apporved the url if it's not secure, go ahead and upload via http or https
    // setup to post the form, generate a UUID for the report, create the boundary and attache the file if needed
    NSMutableURLRequest* uploadRequest = [NSMutableURLRequest new];
    NSString *boundary = [NSString stringWithFormat:@"++%@", self.reportUUID];
    NSString *boundaryLine = [NSString stringWithFormat:@"--%@\r\n", boundary];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    NSString* crashFileName = [self.reportUUID stringByAppendingPathExtension:@"crashreport"];
    NSString* encodedComments = [self.comments.textStorage.string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSMutableString* requestBody = [NSMutableString new];
    
    // put the comments into the primary form-data field
    [uploadRequest setURL:approvedURL];
    [uploadRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
    [requestBody appendString:boundaryLine];
    [requestBody appendString:@"Content-Disposition: form-data; name=\"comments\"\r\n\r\n"];
    [requestBody appendString:encodedComments];
    [requestBody appendString:@"\r\n"];
    
    if( self.crashData) // send the crash report data as the next attachment
    {
        [requestBody appendString:boundaryLine];
        [requestBody appendString:[NSString stringWithFormat:@"Content-Disposition: attachment; name=\"report\"; filename=\"%@\"\r\n",crashFileName]];
        [requestBody appendString:@"Content-Transfer-Encoding: base64\r\n\r\n"];
        [requestBody appendString:[self.crashData base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength]];
        [requestBody appendString:@"\r\n"];
    }

    [requestBody appendString:boundaryLine];
    [requestBody appendString:@"\r\n"];

//    NSLog(@"request: \n\nContent-Type: %@\n%@", contentType, requestBody);
    
    uploadRequest.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    uploadRequest.HTTPShouldHandleCookies = NO;
    uploadRequest.timeoutInterval = 30;
    uploadRequest.HTTPMethod = @"POST";
    uploadRequest.HTTPBody = [requestBody dataUsingEncoding:NSUTF8StringEncoding]; // post data
    
    // add the comments, link the file and
    NSURLConnection* upload = [NSURLConnection connectionWithRequest:uploadRequest delegate:self];
    self.responseBody = [NSMutableData new];
    [upload scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSModalPanelRunLoopMode];
    [upload start];
}

- (void) emailReportTo:(NSURL*) mailtoURL
{
    /* set ourself as the delegate to receive any errors */
    // mail.delegate = self;
    NSError* emailError = nil;
    NSData* reportData = (self.reporter.hasPendingCrashReport
                         ?[self.reporter loadPendingCrashReportDataAndReturnError:&emailError]
                         :[self.reporter generateLiveReportAndReturnError:&emailError]);
    NSString* attachmentFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[self.reportUUID stringByAppendingPathExtension:@"ILCrashreport"]];
    [reportData writeToFile:attachmentFilePath atomically:NO];
    
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
    [self closeAfterReportComplete];
}

- (void) sendReport
{
    // get the submission url
    NSURL* url = [NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] objectForKey:ILReportWindowSubmitURLKey]];

    if( !url )
    {
        NSLog(@"%@ %@must be set to send a report!", [self className], ILReportWindowSubmitURLKey);
        [self close]; // developer error, immediate close
        return;
    }
    
    // cook up the report data if we have somewhere to send it
    [self prepareReportData];
    
    // if it's a mailto: create an email message with the support address
    if( [[url scheme] isEqualToString:@"mailto"])
    {
        [self emailReportTo:url];
    }
    else if( [[url scheme] isEqualToString:@"https"]) // if it's HTTPS post the crash report immediatly
    {
        [self postReportToWebServer:url];
    }
    else if( [[url scheme] isEqualToString:@"http"]) // // it it's *just* HTTP prompt the user for permission to send in the clear
    {
        NSString* appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
        NSURL* emailURL = [NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] objectForKey:ILReportWindowSubmitEmailKey]];
        NSAlert* plaintextAlert = [NSAlert new];
        plaintextAlert.alertStyle = NSCriticalAlertStyle;
        plaintextAlert.messageText = ILLocalizedString(ILReportWindowInsecureConnectionString);
        plaintextAlert.informativeText = [NSString stringWithFormat:ILLocalizedString(ILReportWindowInsecureConnectionInformationString), appName];
        [plaintextAlert addButtonWithTitle:ILLocalizedString(ILReportWindowCancelString)];
        [plaintextAlert addButtonWithTitle:ILLocalizedString(ILReportWindowSendString)];
        if( emailURL) // backup email key is specified
        {
            [plaintextAlert addButtonWithTitle:ILLocalizedString(ILReportWindowEmailString)];
            plaintextAlert.informativeText = [plaintextAlert.informativeText stringByAppendingString:ILLocalizedString(ILReportWindowInsecureConnectionEmailAlternateString)];
        }
        [plaintextAlert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode)
        {
            if( returnCode == NSAlertFirstButtonReturn)
            {
                [self close]; // this is a user cancel, immediate close
            }
            else if( returnCode == NSAlertSecondButtonReturn)
            {
                [self postReportToWebServer:url];
            }
            else if( returnCode == NSAlertThirdButtonReturn) // backup email key is specified
            {
                [self emailReportTo:emailURL];
            }
        }];
    }
    else
    {
        NSBeep();
        NSLog(@"%@ unkown scheme: %@ comments: %@", [self className], url, self.comments.textStorage.string);
        [self close]; // invalid scheme in config, developer error, immediate close
    }
}

- (void) reportConnectionError
{
    NSURL* emailURL = [NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] objectForKey:ILReportWindowSubmitEmailKey]];
    if( emailURL) // backup email key is specified
    {
        NSString* appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
        NSAlert* alert = [NSAlert new];
        alert.alertStyle = NSCriticalAlertStyle;
        alert.messageText = ILLocalizedString(ILReportWindowSubmitFailedString);
        alert.informativeText = [NSString stringWithFormat:ILLocalizedString(ILReportWindowSubmitFailedInformationString), appName, emailURL];
        [alert addButtonWithTitle:ILLocalizedString(ILReportWindowEmailString)];
        [alert addButtonWithTitle:ILLocalizedString(ILReportWindowCancelString)];
        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode)
         {
             if( returnCode == NSAlertFirstButtonReturn)
             {
                 [self emailReportTo:emailURL];
             }
             else if( returnCode == NSAlertSecondButtonReturn)
             {
                 [self close]; // user cancel, immediate close
             }
         }];
    }
}

- (void) closeAfterReportComplete
{
    // if we want to auto-submit an error or exception, then start a timer before restarting the app
    if( [[NSUserDefaults standardUserDefaults] boolForKey:ILReportWindowAutoSubmitKey]
     && (self.mode == ILReportWindowErrorMode || self.mode == ILReportWindowExceptionMode))
    {
        NSDictionary* info = [[NSBundle mainBundle] infoDictionary];
        self.autoRestartSeconds = ([[info allKeys] containsObject:ILReportWindowAutoRestartSecondsKey]
                               ? [[info objectForKey:ILReportWindowAutoRestartSecondsKey] unsignedIntegerValue]
                               : 60);

        self.autoRestartTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(autoRestartTimer:) userInfo:nil repeats:YES];
        self.send.enabled = YES; // enabled so the user can skip the timer
        self.remember.enabled = YES; // enabled so the user can skip the timer
    }
    else if( self.mode == ILReportWindowErrorMode || self.mode == ILReportWindowExceptionMode) // user prompted hit submit button
    {
#ifdef DEBUG
        exit(-1);
#else
        [ILReportWindow restartApp];
#endif
    }
    else
    {
        [self close]; // just close in the case of an exception or bug report
    }
}

#pragma mark - NSWindowController

- (void) awakeFromNib
{
    // setup the headline from the app name and event message
    NSString* appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
 
    // setup the window depending on the report mode
    if( self.mode == ILReportWindowCrashMode)
    {
        self.window.title = ILLocalizedString(ILReportWindowCrashReportString);
        self.headline.stringValue = [NSString stringWithFormat:@"%@ %@", appName, ILLocalizedString(ILReportWindowCrashedString)];
        self.subhead.stringValue = ILLocalizedString(ILReportWindowReportDispositionString);
        self.send.title = ILLocalizedString(ILReportWindowReportString);
    }
    else if( self.mode == ILReportWindowErrorMode)
    {
        self.window.title = ILLocalizedString(ILReportWindowErrorReportString);
        self.headline.stringValue = [NSString stringWithFormat:@"%@ %@", appName, ILLocalizedString(ILReportWindowReportedErrorString)];
        self.subhead.stringValue = ILLocalizedString(ILReportWindowErrorDispositionString);
        self.send.title = ILLocalizedString(ILReportWindowRestartString);
        self.cancel.title = ILLocalizedString(ILReportWindowQuitString);
    }
    else if( self.mode == ILReportWindowExceptionMode)
    {
        self.window.title = ILLocalizedString(ILReportWindowExceptionReportString);
        self.headline.stringValue = [NSString stringWithFormat:@"%@ %@", appName, ILLocalizedString(ILReportWindowRaisedExceptionString)];
        self.subhead.stringValue = ILLocalizedString(ILReportWindowErrorDispositionString);
        self.send.title = ILLocalizedString(ILReportWindowRestartString);
        self.cancel.title = ILLocalizedString(ILReportWindowQuitString);
    }
    else // assume it's ILReportWindowBugMode
    {
        self.window.title = ILLocalizedString(ILReportWindowBugReportString);
        self.headline.stringValue = [NSString stringWithFormat:@"%@ %@", ILLocalizedString(ILReportWindowReportingBugString), appName];
        self.subhead.stringValue = ILLocalizedString(ILReportWindowErrorDispositionString);
        self.send.title = ILLocalizedString(ILReportWindowReportString);
    }
    
    [self.progress startAnimation:self];
    self.status.stringValue = @"";
    self.comments.editable = NO;
    self.remember.enabled = NO;
    self.send.enabled = NO;

    // fill in the comments section
    NSDictionary* commentsAttributes = @{NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:9]};
    [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:ILLocalizedString(ILReportWindowCommentsString) attributes:commentsAttributes]];

    // if the error wasn't explicity set, grab the last one
    if( self.error )
    {
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n- Error -\n\n" attributes:commentsAttributes]];
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:[ILReportWindow errorReport:self.error] attributes:commentsAttributes]];
    }
    
    if( self.exception)
    {
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n- Exception -\n\n" attributes:commentsAttributes]];
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:[ILReportWindow exceptionReport:self.exception] attributes:commentsAttributes]];
    }
    
    // if the keys are set in the main bundle info keys, include the syslog and user defaults
    if( [[[[NSBundle mainBundle] infoDictionary] objectForKey:ILReportWindowIncludeSyslogKey] boolValue])
    {
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n- System Log -\n\n" attributes:commentsAttributes]];
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:[ILReportWindow grepSyslog] attributes:commentsAttributes]];
    }
       
    if( [[[[NSBundle mainBundle] infoDictionary] objectForKey:ILReportWindowIncludeDefaultsKey] boolValue])
    {
        NSString* defaultsString = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]] description];
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n- Application Defaults -\n\n" attributes:commentsAttributes]];
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:defaultsString attributes:commentsAttributes]];
    }
    
    // select the 'please enter any notes' line for replacment
    [self.comments setSelectedRange:NSMakeRange(0,[self.comments.textStorage.string rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location)];
    
    self.comments.editable = YES;
    self.remember.enabled = YES;
    self.send.enabled = YES;
    [self.progress stopAnimation:self];
    
    if( [[NSUserDefaults standardUserDefaults] boolForKey:ILReportWindowAutoSubmitKey])
    {
        self.remember.state = NSOnState;
        if(self.mode != ILReportWindowBugMode) // present the window and send the report, showing them that we're doing it, they can canel and add comments
        {
            [self performSelector:@selector(onSend:) withObject:self afterDelay:0];
        }
    }
    else self.remember.state = NSOffState;
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    if( self.modalSession)
    {
        [NSApp endModalSession:self.modalSession];
        [[NSExceptionHandler defaultExceptionHandler] setDelegate:self.exceptionDelegate];
        [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:self.exceptionMask];
        NSSetUncaughtExceptionHandler(self.exceptionHandler);
        self.exceptionDelegate = nil;
    }
}

#pragma mark - IBActions

- (IBAction)onCancel:(id)sender
{
    if( self.remember.state ) [[NSUserDefaults standardUserDefaults] setBool:YES forKey:ILReportWindowAutoSubmitKey];
    else [[NSUserDefaults standardUserDefaults] removeObjectForKey:ILReportWindowAutoSubmitKey];

    // are we currently sending? stop that
    self.comments.editable = YES;
    self.remember.enabled = YES;
    self.send.enabled = YES;
    self.status.stringValue = @"";
    [self.progress stopAnimation:self];
    
    if( self.mode == ILReportWindowExceptionMode || self.mode == ILReportWindowErrorMode)
        [NSApp terminate:self];
    else
        [self close]; // user canceled, immediate close
}

- (IBAction)onSend:(id)sender
{
    if( self.remember.state ) [[NSUserDefaults standardUserDefaults] setBool:YES forKey:ILReportWindowAutoSubmitKey];
    else [[NSUserDefaults standardUserDefaults] removeObjectForKey:ILReportWindowAutoSubmitKey];

    if( self.autoRestartTimer) // advance it to the end and fire it
    {
        self.autoRestartSeconds = 1;
        [self autoRestartTimer:self.autoRestartTimer];
    }
    else // user wan't us to submit
    {
        // start the progress indicator and disable various controls
        [self.progress startAnimation:self];
        self.comments.editable = NO;
        self.remember.enabled = NO;
        self.send.enabled = NO;

        // perform the upload
        [self sendReport];
    }
}

#pragma mark - NSTimer

- (void) autoRestartTimer:(NSTimer*) timer
{
    if( --self.autoRestartSeconds == 0 ) // decrement and check
    {
        [timer invalidate];
        self.autoRestartTimer = nil;
#ifdef DEBUG
        exit(-1);
#else
        [ILReportWindow restartApp];
#endif
    }
    else
    {
        self.status.stringValue = [NSString stringWithFormat:@"%@ %lu %@",
                                   ILLocalizedString(ILReportWindowRestartInString),
                                   self.autoRestartSeconds,
                                   ILLocalizedString(ILReportWindowSecondsString)];
    }
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)URLresponse
{
    if( [URLresponse isKindOfClass:[NSHTTPURLResponse class]])
    {
        self.response = (NSHTTPURLResponse*)URLresponse;
    }
}

- (void)connection:(NSURLConnection *)connection
   didSendBodyData:(NSInteger)bytesWritten
 totalBytesWritten:(NSInteger)totalBytesWritten
totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    self.status.stringValue = [NSString stringWithFormat:@"%@/%@ %C",
                               [ILReportWindow byteSizeAsString:totalBytesWritten],
                               [ILReportWindow byteSizeAsString:totalBytesExpectedToWrite],
                               0x2191]; // UPWARDS ARROW Unicode: U+2191, UTF-8: E2 86 91
    NSLog(@"%@ post: %li/%li bytes", [self className], (long)totalBytesWritten,(long)totalBytesExpectedToWrite);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseBody appendData:data];
    self.status.stringValue = [NSString stringWithFormat:@"%@ %C",[ILReportWindow byteSizeAsString:self.responseBody.length], 0x2193]; //↓ DOWNWARDS ARROW Unicode: U+2193, UTF-8: E2 86 93
    NSLog(@"%@ read: %li bytes", self.className, (unsigned long)self.responseBody.length);
}

/* intercept redirects (we don't need to load the resulting page ourselves), if there was an error ask the workspace to open the URL */
- (NSURLRequest*) connection:(NSURLConnection*) connection willSendRequest:(NSURLRequest*) request redirectResponse:(NSURLResponse*) redirect
{
    if( redirect && self.response.statusCode == 302 ) // we got redirected, display the page to the user
    {
        NSLog(@"%@ error submitting a report: %li redirect: %@", [self className], (long)self.response.statusCode, redirect.URL);
        [[NSWorkspace sharedWorkspace] openURL:redirect.URL];
        return nil;
    }
    
    return request; // just return the request, either everything is OK or the web browser is showing the error
}

- (void)connectionDidFinishLoading:(NSURLConnection *) connection
{
    NSLog(@"%@ report submitted status: %li", [self className], (long)self.response.statusCode);
    
    //    NSString* bodyString = [[NSString alloc] initWithData:self.responseBody encoding:NSUTF8StringEncoding];
    //    NSLog(@"%@ response body: %@", bodyString);
    
    if( self.response.statusCode == 200 ) // OK!
    {
        self.status.stringValue = [NSString stringWithFormat:@"%C", 0x2713]; // CHECK MARK Unicode: U+2713, UTF-8: E2 9C 93
        [self.reporter purgePendingCrashReport];
        [self closeAfterReportComplete];
    }
    else // not ok, present error
    {
        self.status.stringValue = [NSString stringWithFormat:@"%li %C", (long)self.response.statusCode, 0x274C];// CROSS MARK Unicode: U+274C, UTF-8: E2 9D 8C
        [self reportConnectionError]; // offer to email or cancel
    }
}

#pragma mark - NSURlConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)connectionError
{
    NSBeep();
    self.status.stringValue = [NSString stringWithFormat:@"%C", 0x29F1];// ERROR-BARRED BLACK DIAMOND Unicode: U+29F1, UTF-8: E2 A7 B1
    
    if( connectionError ) // log it to the comments
    {
        NSDictionary* commentsAttributes = @{NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:9]};
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n- Error -\n\n" attributes:commentsAttributes]];
        [self.comments.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:[ILReportWindow errorReport:connectionError] attributes:commentsAttributes]];
    }

    [self reportConnectionError]; // offer to email or cancel
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
    return NO;
}

@end
