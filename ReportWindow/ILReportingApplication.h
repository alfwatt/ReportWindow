#import <Cocoa/Cocoa.h>

@class ILReportWindow;

/** @class ILReportingApplicaiton 
    @description NSApplication sublcass which overrides willPresentError: and sets up error reporting 

 */
@interface ILReportingApplication : NSApplication
@property(nonatomic,retain) ILReportWindow* reportWindow;

#pragma mark - IBActions

- (IBAction) reportBug:(id) sender;

@end
