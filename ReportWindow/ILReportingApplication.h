#import <KitBridge/KitBridge.h>

@class ILReportWindow;

/** @class ILReportingApplicaiton 
    @description NSApplication sublcass which overrides willPresentError: and sets up error reporting
 */
@interface ILReportingApplication : ILApplication
@property(nonatomic,retain) ILReportWindow* reportWindow;

#pragma mark - IBActions

- (IBAction) reportBug:(id) sender;

@end

/* Copyright © 2014-2018, Alf Watt (alf@istumbler.net) Avaliale under MIT Style license in README.md */
