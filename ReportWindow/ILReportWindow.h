#import <KitBridge/KitBridge.h>

#pragma mark - NSUserDefaults keys

/* @const ILReportWindowAutoSubmitKey BOOL value, YES to send automatically, NO to prompt (default) */
extern NSString* const ILReportWindowAutoSubmitKey;

/* @const ILReportWindowIgnoreKey BOOL value, YES to suppress dialog, NO to prompt (default) */
extern NSString* const ILReportWindowIgnoreKey;

/* @const ILReportWindowUserFullNameKey the users full name as a single string */
extern NSString* const ILReportWindowUserFullNameKey;

/* @const ILReportWindowUserEmailKey if set the users default email address to include in reports */
extern NSString* const ILReportWindowUserEmailKey;

/* @const ILReportWindowSuppressDuplicatesKey BOOL: if set NO report all errors, YES suppress duplicates (default) */
extern NSString* const ILReportWindowSuppressDuplicatesKey;

/* @const ILReportWindowReportedSignaturesKey set of exception, error and crash signatures which we have already reported */
extern NSString* const ILReportWindowReportedSignaturesKey;

/* @const ILReportWindowDeleteSubmittedKey BOOL: if set YES will delete crash reports when sucessfully submitted or emailed */
extern NSString* const ILReportWindowDeleteSubmittedKey;

#pragma mark - Info.plist keys

// One of theses keys must be define for the window to be presented
// you may provide both (email will be backup if POST to URL fails)

/* @const ILReportWindowSubmitURLKey if set in the bundle's info dictionary
 the url to submit the crash report to, can be a mailto: url */
extern NSString* const ILReportWindowSubmitURLKey;

/* @const ILReportWindowSubmitEmailKey if set the backup email for submissions,
 if the primary URL is http and the user declines to upload */
extern NSString* const ILReportWindowSubmitEmailKey;

/*
    !! ATTENTION !!

    Only set the following keys if your log output, defaults and windows contain no
    user identifiying information (account names, passwords, etc).
     
    These keys can be set either in the Apps Info.plist or the NSUserDefaults, which
    will override the info plist entry.
*/

/* @const ILReportWindowIncludeSyslogKey if set to YES then syslog messages with the applications bundle name in them are included */
extern NSString* const ILReportWindowIncludeSyslogKey;

/* @const ILReportWindowIncludeDefaultsKey if set to YES then the applications preferences are included in the report */
extern NSString* const ILReportWindowIncludeDefaultsKey;

/* @const ILReportWindowIncludeWindowScreenshotsKey if set to YES then screenshots of all open windows are included in exception and error reports */
extern NSString* const ILReportWindowIncludeWindowScreenshotsKey;

/* @const ILReportWindowAutoRestartSecondsKey if set overrades default of 60 before an automatic crash report will be submitted, and the window dismissed */
extern NSString* const ILReportWindowAutoRestartSecondsKey;

#pragma mark - NSError User Info Dictionary Keys

/* @const ILReportWindowTreatErrorAsBugKey set in the info dictionry of an NSError and ILReport window will present it as a bug report */
extern NSString* const ILReportWindowTreatErrorAsBugKey;

#pragma mark - Screen Shot Dictionary Keys

extern NSString* const ILReportWindowTitle; // window title
extern NSString* const ILReportWindowFrame; // window frame for screenshot
extern NSString* const ILReportWindowInfo; // window identifier for screenshot
extern NSString* const ILReportWindowImage; // window image for screenshot

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
extern NSString* const ILReportWindowErrorDispositionString; // = "Click Restart to send the report to the devloper and restart the application, or Ingore it.";
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

#if IL_APP_KIT
@interface ILReportWindow : NSWindowController <NSURLConnectionDelegate>
@property(nonatomic,assign) NSModalSession modalSession;
@property(nonatomic,retain) IBOutlet NSButton* screenshots;
@property(nonatomic,retain) IBOutlet NSButton* remember;
#elif IL_UI_KIT
@interface ILReportWindow : UIViewController <NSURLConnectionDelegate>
@property(nonatomic,retain) IBOutlet UIWindow* window;
#endif
@property(nonatomic,retain) IBOutlet ILProgressView* progress;
@property(nonatomic,retain) IBOutlet ILLabel* headline;
@property(nonatomic,retain) IBOutlet ILLabel* subhead;
@property(nonatomic,retain) IBOutlet ILTextField* fullname;
@property(nonatomic,retain) IBOutlet ILTextField* emailaddress;
@property(nonatomic,retain) IBOutlet ILTextView* comments;
@property(nonatomic,retain) IBOutlet ILLabel* status;
@property(nonatomic,retain) IBOutlet ILButton* cancel;
@property(nonatomic,retain) IBOutlet ILButton* send;
@property(nonatomic,assign) ILReportWindowMode mode;
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

#pragma mark - Exceptions

/** @param exception to build a report from
    @returns NSString* report of the provided exception with stack trace, and all avalaible details */
+ (NSString*) exceptionReport:(NSException*) exception;

/** @param exception to build a signature for
    @returns unique signature for an exception */
+ (NSString*) exceptionSignature:(NSException*) exception;

#pragma mark - Errors

/** @param error to build a report from
    @returns report of the provided error with all nested errors and available details */
+ (NSString*) errorReport:(NSError*) error;

/** @param error to build a signature for
    @returns unique signature for a particular error */
+ (NSString*) errorSignature:(NSError*) error;

#pragma mark - System Crash Reports

+ (NSArray*) systemCrashReports;
+ (NSString*) latestSystemCrashReport;
+ (NSString*) systemCrashReportSignature:(NSString*) filename;
+ (BOOL) clearSystemCrashReports;

#if IL_APP_KIT
#pragma mark - Screenshots

/** @param window -- the NSWindow* to make a screenshot of
    @returns NSImage* -- the screenshot
*/
+ (NSImage*) screenshotWindow:(NSWindow*) window;

/** @returns an array of dictionaries containing window identifers, window frames and screenshots as PDF data using the following keys:
 
    ILReportWindowIdentifier - [window identifier] of the window
    ILReportWindowFrame - NNStringFromRect([window frame]) of the window
    ILReportPDFData - [window dataWithPDFInsideRect:[window frame]] of the window
*/
+ (NSArray*) windowScreenshots;

#endif

#pragma mark - Utilities
#if IL_APP_KIT
/** @returns contents of the system log which inlcude our application's name
    @brief NB that this can block for some time as the system `log` tool is slow
*/
+ (NSString*) fetchSyslog;

/** clears terminal signal handlers and restarts the app */
+ (void) restartApp;
#endif

#pragma mark - Factory Methods

+ (instancetype) windowForSystemCrashReport:(NSString*) crashReportPath;
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

/* Copyright 2014-2017, Alf Watt (alf@istumbler.net) Avaliale under MIT Style license in README.md */
