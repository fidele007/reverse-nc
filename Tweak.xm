@interface SBModeControlManager : NSObject
@property(readonly, retain, nonatomic) NSArray *views;
@property(nonatomic) long long selectedSegmentIndex;
- (void)insertSegmentWithTitle:(id)title atIndex:(unsigned long long)index animated:(BOOL)animated;
@end

@interface SBModeViewController : UIViewController {
  SBModeControlManager *_modeControl;
}
@property(retain, nonatomic) NSArray *viewControllers;
@property(retain, nonatomic) UIViewController *selectedViewController;
@property(retain, nonatomic) UIViewController *deselectedViewController;
- (void)setSelectedViewController:(UIViewController *)viewController animated:(BOOL)animated; 
- (void)_setSelectedSegmentIndex:(long long)arg1;
@end

// This swaps Notifications and Today titles, but it doesn't swap their views
%hook SBModeControlManager
- (void)insertSegmentWithTitle:(id)title atIndex:(unsigned long long)index animated:(BOOL)animated {
  if (index == 0) {
    index = 1;
  } else if (index == 1) {
    index = 0;
  }
  %orig;
}
%end

%hook SBModeViewController
- (void)setSelectedViewController:(UIViewController *)viewController animated:(BOOL)animated {
  // This check prevents crash on SpringBoard startup because 
  // self.viewControllers does not store all view controllers (Today & Notifications) until NC is open
  if (!self.viewControllers || [self.viewControllers count] < 2) {
    return %orig;
  }

  // Swap view controllers for Today view and Notifications view
  SBModeControlManager *modeControl = MSHookIvar<SBModeControlManager *>(self, "_modeControl");
  NSInteger selectedIndex = modeControl.selectedSegmentIndex;
  if (selectedIndex == 0) {
    viewController = self.viewControllers[1];
  } else if (selectedIndex == 1) {
    viewController = self.viewControllers[0];
  }

  %orig;
}

- (void)_setSelectedSegmentIndex:(long long)selectedSegmentIndex {
  // Swap indexes for Today view and Notifications view
  if ([self.selectedViewController isKindOfClass:%c(SBTodayViewController)]) {
    selectedSegmentIndex = 1;
  } else if ([self.selectedViewController isKindOfClass:%c(SBNotificationsViewController)]) {
    selectedSegmentIndex = 0;
  }

  %orig;
}
%end