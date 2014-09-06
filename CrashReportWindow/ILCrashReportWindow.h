#import <Cocoa/Cocoa.h>

extern NSString* const ILCrashWindowAutoSubmitKey; // if set the user's defaults is a BOOL, YES to send NO to cancel
extern NSString* const ILCrashWindowSubmitURLKey; // if set in the bundle's info dictionary the url to submit the crash report to, can be a mailto: url
extern NSString* const ILCrashWindowSubmitEmailKey; // if set the backup email for submissions, if the primary URL is http and the user declines to upload
extern NSString* const ILCrashWindowIncludeSyslogKey; // if set to YES then syslog messages with the applications bundle name in them are included
extern NSString* const ILCrashWindowIncludeDefaultsKey; // if set to YES then the applications preferences are included in the report

extern NSString* const ILCrashWindowInsecureConnectionString; // = @"Insecure Connection";
extern NSString* const ILCrashWIndowInsecureConnectionInformationString; // = @"%@ does not support secure crash reporting, your crash report will be sent in plaintext and may be observed while in transit."; // app name
extern NSString* const ILCrashWindowInsecureConnectionEmailAlternateString; // = @"\n\nEmail may be a more secure option, depending on your provider.";
extern NSString* const ILCrashWindowCancelString; // = @"Cancel";
extern NSString* const ILCrashWindowSendString; // = @"Send";
extern NSString* const ILCrashWindowEmailString; // = @"Email";
extern NSString* const ILCrashWindowCrashReportString; // = @"Crash Report";
extern NSString* const ILCrashWindowExceptionReportString; // = @"Exception Report";
extern NSString* const ILCrashWindowErrorReportString; // = @"Error Report";
extern NSString* const ILCrashWindowCrashedString; // = @"Crashed!";
extern NSString* const ILCrashWindowRaisedExceptionString; // = @"Raised an Exception";
extern NSString* const ILCrashWindowReportedErrorString; // = @"Reported an Error";
extern NSString* const ILCrashWindowCrashDispositionString; // = @"Click Report to send the report to the devleoper, or Cancel to ignore it.";
extern NSString* const ILCrashWindowErrorDispositionString; // = @"Click Restart to send the report to the devloper and restart the application, or Quit.";
extern NSString* const ILCrashWindowReportString; // = @"Report";
extern NSString* const ILCrashWindowRestartString; // = @"Restart";
extern NSString* const ILCrashWindowQuitString; // = @"Quit";
extern NSString* const ILCrashWindowCommentsString; // = @"please enter any comments here";
extern NSString* const ILCrashWindowSubmitFailedString; // = @"Submitting Report Failed";
extern NSString* const ILCrashWindowSubmitFailedInformationString; // = @"%@ was not able to submit the report to: %@\n\nyou can send the report by email"; // app name and submission url

@class PLCrashReport;
@class PLCrashReporter;

@interface ILCrashReportWindow : NSWindowController <NSURLConnectionDelegate>
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
