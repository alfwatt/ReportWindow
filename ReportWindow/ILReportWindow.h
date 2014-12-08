#import <Cocoa/Cocoa.h>

// #define PL_CRASH_COMPATABLE

#pragma mark - NSUserDefaults keys

extern NSString* const ILReportWindowAutoSubmitKey; // if set the user's defaults is a BOOL, YES to send automatically, NO to prompt (default)
extern NSString* const ILReportWindowIgnoreKey; // if set the user's defaults is a BOOL, YES to suppress dialog, NO to prompt (default)
extern NSString* const ILReportWindowUserFullNameKey; // if set the users full name as a single string
extern NSString* const ILReportWindowUserEmailKey; // if set the users default email address to include in reports
extern NSString* const ILReportWindowSuppressDuplicatesKey; // if set 
extern NSString* const ILReportWindowReportedSignaturesKey; // set of exception, error and crash signatures which we have already reported

#pragma mark - Info.plist keys

// One of theses keys must be define for the window to be presented, you may provide both (email will be backup if POST to URL fails)
extern NSString* const ILReportWindowSubmitURLKey; // if set in the bundle's info dictionary the url to submit the crash report to, can be a mailto: url
extern NSString* const ILReportWindowSubmitEmailKey; // if set the backup email for submissions, if the primary URL is http and the user declines to upload

// ATTENTION! only set these keys if your log output, defaults and windows contain no user identifiying information (account names, passwords, etc)
// thse keys can be set either in the bundle info dictionary or the NSUserDefaults
extern NSString* const ILReportWindowIncludeSyslogKey; // if set to YES then syslog messages with the applications bundle name in them are included
extern NSString* const ILReportWindowIncludeDefaultsKey; // if set to YES then the applications preferences are included in the report
extern NSString* const ILReportWindowIncludeWindowScreenshotsKey; // if set to YES then screenshots of all open windows are included in exception and error reports

extern NSString* const ILReportWindowAutoRestartSecondsKey; // if set overrades default of 60 before an automatic crash report will be submitted, and the window dismissed
extern NSString* const ILReportWindowTreatErrorAsBugKey; // set in the info dictionry of an NSError and ILReport window will present it as a bug report

extern NSString* const ILReportWindowTitle; // window title
extern NSString* const ILReportWindowFrame; // window frame for screenshot
extern NSString* const ILReportWindowInfo; // window identifier for screenshot
extern NSString* const ILReportWindowImage; // window PDF data for screenshot


#pragma mark - NSLocalizedStrings

extern NSString* const ILReportWindowCancelString; // = "Cancel";
extern NSString* const ILReportWindowSendString; // = "Send";
extern NSString* const ILReportWindowEmailString; // = "Email";
extern NSString* const ILReportWindowCrashReportString; // = "Crash Report";
extern NSString* const ILReportWindowExceptionReportString; // = "Exception Report";
extern NSString* const ILReportWindowErrorReportString; // = "Error Report";
extern NSString* const ILReportWindowBugReportString; // = "Bug Report";
extern NSString* const ILReportWindowCrashedString; // = "Crashed!";
extern NSString* const ILReportWindowRaisedExceptionString; // = AppName + "Raised an Exception";
extern NSString* const ILReportWindowReportedErrorString; // = AppName + "Reported an Error";
extern NSString* const ILReportWindowReportingBugString; // = "Bug Report for" + AppName;
extern NSString* const ILReportWindowReportDispositionString; // = "Click Send to send the report to the devleoper, or Cancel to ignore it.";
extern NSString* const ILReportWindowErrorDispositionString; // = "Click Restart to send the report to the devloper and restart the application, or Quit.";
extern NSString* const ILReportWindowBugDispositionString; // = "Click Send to send the report to the devleoper, or Cancel to delete it.";

extern NSString* const ILReportWindowReportString; // = @"Report";
extern NSString* const ILReportWindowRestartString; // = @"Restart";
extern NSString* const ILReportWindowQuitString; // = @"Quit";
extern NSString* const ILReportWindowIgnoreString; // = @"Ignore";
extern NSString* const ILReportWindowCommentsString; // = @"please enter any comments here";
extern NSString* const ILReportWindowSubmitFailedString; // = @"Submitting Report Failed";
extern NSString* const ILReportWindowSubmitFailedInformationString; // = @"%@ was not able to submit the report to: %@\n\nyou can send the report by email"; // app name and submission url
extern NSString* const ILReportWindowInsecureConnectionString; // = @"Insecure Connection";
extern NSString* const ILReportWindowInsecureConnectionInformationString; // = @"%@ does not support secure crash reporting, your crash report will be sent in plaintext and may be observed while in transit."; // app name
extern NSString* const ILReportWindowInsecureConnectionEmailAlternateString; // = @"\n\nEmail may be more secure, depending on your provider.";

extern NSString* const ILReportWindowRestartInString; // = @"Restart in";
extern NSString* const ILReportWindowSecondsString; // = @"seconds";

#ifdef PL_CRASH_COMPATABLE
@class PLCrashReport;
@class PLCrashReporter;
#endif

#pragma mark -

/** window mode */
typedef enum
{
    ILReportWindowCrashMode,
    ILReportWindowErrorMode,
    ILReportWindowExceptionMode,
    ILReportWindowBugMode
}
ILReportWindowMode;

@interface ILReportWindow : NSWindowController <NSURLConnectionDelegate>
@property(nonatomic,assign) ILReportWindowMode mode;
@property(nonatomic,assign) NSModalSession modalSession;
@property(nonatomic,retain) NSString* reportUUID;
@property(nonatomic,retain) NSError* error;
@property(nonatomic,retain) NSException* exception;
@property(nonatomic,retain) NSHTTPURLResponse* response;
@property(nonatomic,retain) NSMutableData* responseBody;
@property(nonatomic,assign) id exceptionDelegate;
@property(nonatomic,assign) NSUInteger exceptionMask;
@property(nonatomic,assign) NSUncaughtExceptionHandler* exceptionHandler;
@property(nonatomic,assign) NSUInteger autoRestartSeconds;
@property(nonatomic,assign) NSTimer* autoRestartTimer;
@property(nonatomic,retain) IBOutlet NSTextField* headline;
@property(nonatomic,retain) IBOutlet NSTextField* subhead;
@property(nonatomic,retain) IBOutlet NSTextField* fullname;
@property(nonatomic,retain) IBOutlet NSTextField* emailaddress;
@property(nonatomic,retain) IBOutlet NSTextView* comments;
@property(nonatomic,retain) IBOutlet NSButton* remember;
@property(nonatomic,retain) IBOutlet NSTextField* status;
@property(nonatomic,retain) IBOutlet NSProgressIndicator* progress;
@property(nonatomic,retain) IBOutlet NSButton* cancel;
@property(nonatomic,retain) IBOutlet NSButton* send;
#ifdef PL_CRASH_COMPATABLE
@property(nonatomic,retain) PLCrashReport* crashReport;
@property(nonatomic,retain) PLCrashReporter* reporter;
@property(nonatomic,retain) NSData* crashData;
#endif

#pragma mark - Exceptions

/** @param NSException* exception
    @returns NSString* report of the provided exception with stack trace, and all avalaible details */
+ (NSString*) exceptionReport:(NSException*) exception;

/** @param exception
    @returns unique signature for an exception */
+ (NSString*) exceptionSignature:(NSException*) exception;

#pragma mark - Errors

/** @param error
    @returns report of the provided error with all nested errors and available details */
+ (NSString*) errorReport:(NSError*) error;

/** @param error
    @returns unique signature for a particular error */
+ (NSString*) errorSignature:(NSError*) error;

#pragma mark - System Crash Reports

+ (NSArray*) systemCrashReports;
+ (NSString*) latestSystemCrashReport;
+ (NSString*) systemCrashReportSignature:(NSString*) filename;

#ifdef PL_CRASH_COMPATABLE
#pragma mark - PLCrashReport
+ (NSString*) crashReportSignature:(PLCrashReport*) report;
+ (instancetype) windowForCrashReporter:(PLCrashReporter*) reporter;
#endif

#pragma mark - Screenshots

+ (NSImage*) screenshotWindow:(NSWindow*) window withConstraints:(NSArray*) constraints;

/** @returns an array of dictionaries containing window identifers, window frames and screenshots as PDF data using the following keys:
 
    ILReportWindowIdentifier - [window identifier] of the window
    ILReportWindowFrame - NNStringFromRect([window frame]) of the window
    ILReportPDFData - [window dataWithPDFInsideRect:[window frame]] of the window
*/
+ (NSArray*) windowScreenshots;

#pragma mark - Utilities

/** @returns contents of the system log which inlcude our application's name */
+ (NSString*) grepSyslog;

/** clears terminal signal handlers and restarts the app */
+ (void) restartApp;

#pragma mark - Factory Methods

+ (instancetype) windowForError:(NSError*) error;
+ (instancetype) windowForException:(NSException*) exception;
+ (instancetype) windowForBug;

#pragma mark - Modal Reporting

/** unregisters exception delegate, runs dialog in modal session */
- (void) runModal;

#pragma mark - IBActions

- (IBAction)onCancel:(id)sender;
- (IBAction)onSend:(id)sender;

@end

/* Copyright 2014, Alf Watt (alf@istumbler.net) Avaliale under BSD Style license in license.txt. */
