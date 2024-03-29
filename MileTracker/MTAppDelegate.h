//
//  MTAppDelegate.h
//  MileTracker
//
//  Created by Stine Richvoldsen on 12/14/12.
//  Copyright (c) 2012 Focus43. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Reachability;

@interface MTAppDelegate : UIResponder <UIApplicationDelegate,UIAlertViewDelegate, PFSignUpViewControllerDelegate, PFLogInViewControllerDelegate> {
    Reachability* hostReach;
    Reachability* internetReach;
}

@property (strong, nonatomic) UIWindow *window;

- (void)launchLoginScreen;

@end
