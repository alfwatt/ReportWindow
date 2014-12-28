ReportWindow
==============

iStumbler Labs Report Window for Crashes, Exceptions and Errors

## Usage

Indlude ReportWindow.framework and ExceptionHandling.framework in your application project.

## Configuration

By adding specific keys to your Application's Info.plist file you can control the behavoiur of the ReportWindow.
The two critical keys give the URL and Email address to submit reports to, at least one must be set.

    /* @const ILReportWindowSubmitURLKey if set in the bundle's info dictionary
    the url to submit the crash report to, can be a mailto: url */
    extern NSString* const ILReportWindowSubmitURLKey;

    /* @const ILReportWindowSubmitEmailKey if set the backup email for submissions,
    if the primary URL is http and the user declines to upload */
    extern NSString* const ILReportWindowSubmitEmailKey;

Once one of both of those keys are set, either change your Applications base class from NSApplication to
ILReportingApplication or specifcy ILReportingApplication as the NSPrincipalClass in your apps Info.plist.

You should also hook up a menu item titled 'Report Bug..' to the IBOutlet on ILReportingApplication:

    - (IBAction) reportBug:(id) sender;

You can then test the framework and your CGI installation by holding down the following keys when calling
reportBug:

- Option - Raise a Test Exception
- Option + Shift - Raise a Handled Test Exception
- Control - Report a Test Error
- Control + Shift - Report a Test Error with Recovery Options
- Control + Option - Immediatly Crash the App

## Classes

### ILReportWindow

Provides the controller for the report window interface and uploads the report to the URL you specify.

### ILExceptionRecovery

Provides an exception recovery mechanisim by converting recognized NSExceptions into NSErrors with recovery options.

## ILReportingApplication

NSApplication subclass which encapsulates all the reporting behaviour.

