ReportWindow
==============

iStumbler Labs Report Window for Crashes, Exceptions and Errors

## Usage

Indlude ReportWindow.framework and ExceptionHandling.framework in your application project.

## Configuration

By adding specific keys to your Application's Info.plist file you can control the behavoiur of the ReportWindow.

    extern NSString* const ILReportWindowSubmitURLKey; // if set in the bundle's info dictionary the url to submit the crash report to, can be a mailto: url
    extern NSString* const ILReportWindowSubmitEmailKey; // if set the backup email for submissions, if the primary URL is http and the user declines to upload

    /* !ATTENTION! only set these keys if your log output, defaults and windows contain
    no user identifiying information (account names, passwords, etc)!

    These keys can be set either in the bundle info dictionary or the NSUserDefaults
    allowing users to override them */
    extern NSString* const ILReportWindowIncludeSyslogKey; // if set to YES then syslog messages with the applications bundle name in them are included
    extern NSString* const ILReportWindowIncludeDefaultsKey; // if set to YES then the applications preferences are included in the report

Once those keys are set, either change your Applications base class from NSApplication to ILReportingApplication or specifcy
ILReprtingApplication as the NSPrincipalClass in your apps Info.plist.

## Classes

### ILReportWindow

Provides the controller for the report window interface and uploads the report to the URL you specify.

### ILExceptionRecovery

Provides an exception recovery mechanisim by converting recognized NSExceptions into NSErrors with recovery options.

## ILReportingApplication

NSApplication subclass which encapsulates all the reporting behaviour.

