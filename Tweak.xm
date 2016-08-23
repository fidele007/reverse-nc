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

// Re-create swipe gestures for swapping Notifications and Today views
- (void)handleModeChange:(id)sender {
  if (![sender isKindOfClass:%c(UISwipeGestureRecognizer)]) {
    return %orig;
  }

  UISwipeGestureRecognizer *gesture = (UISwipeGestureRecognizer *)sender;
  SBModeControlManager *modeControl = MSHookIvar<SBModeControlManager *>(self, "_modeControl");
  if (gesture.direction == UISwipeGestureRecognizerDirectionRight) {
    if ([self.selectedViewController isKindOfClass:%c(SBTodayViewController)]) {

      /* Set |selectedSegmentIndex| to 0 because setSelectedViewController method is hooked to
         show Notifications view only if |selectedSegmentIndex| = 0 */
      modeControl.selectedSegmentIndex = 0;

      /* Passing self.viewControllers[1] as the argument is only for consistency's sake
         since the view controller will always be of Notifications if |selectedSegmentIndex| = 0 */
      [self setSelectedViewController:self.viewControllers[1] animated:YES];

    } else {
      // If not in Today view, just do your stuff
      return %orig;
    }
  // Same reasoning for the gesture in the other direction
  } else if (gesture.direction == UISwipeGestureRecognizerDirectionLeft) {
    if ([self.selectedViewController isKindOfClass:%c(SBNotificationsViewController)]) {
      modeControl.selectedSegmentIndex = 1;
      [self setSelectedViewController:self.viewControllers[0] animated:YES];
    } else {
      return %orig;
    }
  }
}
%end