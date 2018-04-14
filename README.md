ReportWindow
==============

iStumbler Labs Report Window for Crashes, Exceptions and Errors

GitLab: https://gitlab.com/alfwatt/reportwindow

GitHub: https://github.com/alfwatt/ReportWindow

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

### ILReportingApplication

NSApplication subclass which encapsulates all the reporting behaviour.

## L10N

Spanish translation by Juan Pablo Atienza Martínez

## Release History

### 1.4 - ES Translation
### 1.3 - macOS 10.10 Support   
### 1.2 - Remove Email Reporting Method
### 1.1 - Add ILReportingApplication
### 1.0 - First!

## License

    The MIT License (MIT)

    Copyright (c) 2014-2018 Alf Watt

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
