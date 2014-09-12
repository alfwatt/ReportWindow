#import <Cocoa/Cocoa.h>

#pragma mark NSUserDefaults keys

extern NSString* const ILReportWindowAutoSubmitKey; // if set the user's defaults is a BOOL, YES to send automatically, NO to prompt (default)
extern NSString* const ILReportWindowIgnoreKey; // if set the user's defaults is a BOOL, YES to suppress dialog, NO to prompt (default)

#pragma mark - Info.plist keys

// One of theses keys must be define for the window to be presented, you may provide both (email will be backup if POST to URL fails)
extern NSString* const ILReportWindowSubmitURLKey; // if set in the bundle's info dictionary the url to submit the crash report to, can be a mailto: url
extern NSString* const ILReportWindowSubmitEmailKey; // if set the backup email for submissions, if the primary URL is http and the user declines to upload

// ATTENTION! only set these keys if your log output and defaults contain no user identifiying information (account names, passwords, etc)
extern NSString* const ILReportWindowIncludeSyslogKey; // if set to YES in the bundles info dictionary then syslog messages with the applications bundle name in them are included
extern NSString* const ILReportWindowIncludeDefaultsKey; // if set to YES in the bundles info dictionary then the applications preferences are included in the report

#pragma mark - NSLocalizedStrings

extern NSString* const ILReportWindowInsecureConnectionString; // = @"Insecure Connection";
extern NSString* const ILReportWindowInsecureConnectionInformationString; // = @"%@ does not support secure crash reporting, your crash report will be sent in plaintext and may be observed while in transit."; // app name
extern NSString* const ILReportWindowInsecureConnectionEmailAlternateString; // = @"\n\nEmail may be more secure, depending on your provider.";
extern NSString* const ILReportWindowCancelString; // = @"Cancel";
extern NSString* const ILReportWindowSendString; // = @"Send";
extern NSString* const ILReportWindowEmailString; // = @"Email";
extern NSString* const ILReportWindowCrashReportString; // = @"Crash Report";
extern NSString* const ILReportWindowExceptionReportString; // = @"Exception Report";
extern NSString* const ILReportWindowErrorReportString; // = @"Error Report";
extern NSString* const ILReportWindowCrashedString; // = @"Crashed!";
extern NSString* const ILReportWindowRaisedExceptionString; // = @"Raised an Exception";
extern NSString* const ILReportWindowReportedErrorString; // = @"Reported an Error";
extern NSString* const ILReportWindowCrashDispositionString; // = @"Click Report to send the report to the devleoper, or Cancel to ignore it.";
extern NSString* const ILReportWindowErrorDispositionString; // = @"Click Restart to send the report to the devloper and restart the application, or Quit.";
extern NSString* const ILReportWindowReportString; // = @"Report";
extern NSString* const ILReportWindowRestartString; // = @"Restart";
extern NSString* const ILReportWindowQuitString; // = @"Quit";
extern NSString* const ILReportWindowCommentsString; // = @"please enter any comments here";
extern NSString* const ILReportWindowSubmitFailedString; // = @"Submitting Report Failed";
extern NSString* const ILReportWindowSubmitFailedInformationString; // = @"%@ was not able to submit the report to: %@\n\nyou can send the report by email"; // app name and submission url

@class PLCrashReport;
@class PLCrashReporter;

#pragma mark -

@interface ILReportWindow : NSWindowController <NSURLConnectionDelegate>
{
    NSError* error;
    NSException* exception;
    PLCrashReport* crashReport;
    PLCrashReporter* reporter;
    NSData* crashData;
    NSHTTPURLResponse* response;
    NSMutableData* responseBody;
    NSModalSession modalSession;
    NSTextField* headline;
    NSTextField* subhead;
    NSTextView* comments;
    NSButton* remember;
    NSTextField* status;
    NSProgressIndicator* progress;
    NSButton* cancel;
    NSButton* send;
}
@property(nonatomic,retain) NSError* error;
@property(nonatomic,retain) NSException* exception;
@property(nonatomic,retain) PLCrashReport* crashReport;
@property(nonatomic,retain) PLCrashReporter* reporter;
@property(nonatomic,retain) NSData* crashData;
@property(nonatomic,retain) NSHTTPURLResponse* response;
@property(nonatomic,retain) NSMutableData* responseBody;
@property(nonatomic,assign) NSModalSession modalSession;
@property(nonatomic,retain) IBOutlet NSTextField* headline;
@property(nonatomic,retain) IBOutlet NSTextField* subhead;
@property(nonatomic,retain) IBOutlet NSTextView* comments;
@property(nonatomic,retain) IBOutlet NSButton* remember;
@property(nonatomic,retain) IBOutlet NSTextField* status;
@property(nonatomic,retain) IBOutlet NSProgressIndicator* progress;
@property(nonatomic,retain) IBOutlet NSButton* cancel;
@property(nonatomic,retain) IBOutlet NSButton* send;

+ (instancetype) windowForReporter:(PLCrashReporter*) reporter;
+ (instancetype) windowForReporter:(PLCrashReporter*) reporter withError:(NSError*) error;
+ (instancetype) windowForReporter:(PLCrashReporter*) reporter withException:(NSException*) exception;

- (void) runModal;

#pragma mark - IBActions

- (IBAction)onCancel:(id)sender;
- (IBAction)onSend:(id)sender;

@end
