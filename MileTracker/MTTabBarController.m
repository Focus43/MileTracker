//
//  MTTabBarControllerViewController.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 1/30/13.
//  Copyright (c) 2013 Focus43. All rights reserved.
//

#import "MTTabBarController.h"
#import "Reachability.h"
#import "MTSignUpViewController.h"
#import "MTLoginViewController.h"

@interface MTTabBarController ()

@property (nonatomic, strong)ADBannerView *banner;
@property (nonatomic,assign) BOOL bannerIsVisible;

@end

@implementation MTTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Add ad banner
    _banner = [[ADBannerView alloc] init];
    _banner.delegate = self;
    _banner.frame = CGRectMake(0.0, [UIScreen mainScreen].bounds.size.height - 49, _banner.frame.size.width, _banner.frame.size.height);
    _banner.requiredContentSizeIdentifiers = [NSSet setWithObjects: ADBannerContentSizeIdentifierPortrait, ADBannerContentSizeIdentifierLandscape, nil];
    [self.view insertSubview:_banner belowSubview:self.tabBar];
   
    self.bannerIsVisible = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
//    if (![PFUser currentUser]) { // No user logged in
//        
//        NSLog(@"not logged in");
//        NetworkStatus networkStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
//        
//        if ( networkStatus == NotReachable ) {
//            UIAlertView *cannotLoginAlert = [[UIAlertView alloc] initWithTitle:@"Uh oh..."
//                                                                       message:@"To sign up or log in, you have to be online, and it looks like you're not right now."
//                                                                      delegate:nil
//                                                             cancelButtonTitle:@"I'll try again later!"
//                                                             otherButtonTitles:nil];
//            [cannotLoginAlert show];
//            
//        }
//        
//        // Create the log in view controller
//        MTLoginViewController *logInViewController = [[MTLoginViewController alloc] init];
//        [logInViewController setDelegate:self]; // Set ourselves as the delegate
//        
//        // Create the sign up view controller
//        MTSignUpViewController *signUpViewController = [[MTSignUpViewController alloc] init];
//        [signUpViewController setDelegate:self]; // Set ourselves as the delegate
//        
//        // Assign our sign up controller to be displayed from the login controller
//        [logInViewController setSignUpController:signUpViewController];
//        
//        // Present the log in view controller
//        [self presentViewController:logInViewController animated:YES completion:NULL];
//        
//    }
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        _banner.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
        _banner.frame = CGRectOffset(_banner.frame, 0.0, -([UIScreen mainScreen].bounds.size.height - [UIScreen mainScreen].bounds.size.width - 18));
    } else {
        _banner.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
        _banner.frame = CGRectOffset(_banner.frame, 0.0, ([UIScreen mainScreen].bounds.size.height - [UIScreen mainScreen].bounds.size.width - 18));
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//# pragma mark - Login Delegate methods
//
//// Sent to the delegate to determine whether the log in request should be submitted to the server.
//- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
//    // Check if both fields are completed
//    if (username && password && username.length != 0 && password.length != 0) {
//        return YES; // Begin login process
//    }
//    
//    [[[UIAlertView alloc] initWithTitle:@"Missing Information"
//                                message:@"Make sure you fill out all of the information!"
//                               delegate:nil
//                      cancelButtonTitle:@"ok"
//                      otherButtonTitles:nil] show];
//    return NO; // Interrupt login process
//}
//
//// Sent to the delegate when a PFUser is logged in.
//- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
//    [self dismissViewControllerAnimated:YES completion:NULL];
//}
//
//// Sent to the delegate when the log in attempt fails.
//- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
//    NSLog(@"Failed to log in...");
//}
//
//// Sent to the delegate when the log in screen is dismissed.
//- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
//    [self.navigationController popViewControllerAnimated:YES];
//}
//
//# pragma mark - Sign Up Delegate methods
//
//// Sent to the delegate to determine whether the sign up request should be submitted to the server.
//- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
//    BOOL informationComplete = YES;
//    
//    // loop through all of the submitted data
//    for (id key in info) {
//        NSString *field = [info objectForKey:key];
//        if (!field || field.length == 0) { // check completion
//            informationComplete = NO;
//            break;
//        }
//    }
//    
//    // Display an alert if a field wasn't completed
//    if (!informationComplete) {
//        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
//                                    message:@"Make sure you fill out all of the information!"
//                                   delegate:nil
//                          cancelButtonTitle:@"ok"
//                          otherButtonTitles:nil] show];
//    }
//    
//    return informationComplete;
//}

#pragma mark -- Advertising Delegate

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    if (!self.bannerIsVisible) {
        [UIView beginAnimations:@"animateAdBannerOn" context:NULL];
        banner.frame = CGRectOffset(banner.frame, 0, -50);
        [UIView commitAnimations];
        self.bannerIsVisible = YES;
    }
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    if (self.bannerIsVisible) {
        [UIView beginAnimations:@"animateAdBannerOff" context:NULL];
        banner.frame = CGRectOffset(banner.frame, 0, 50);
        [UIView commitAnimations];
        self.bannerIsVisible = NO;
    }
}

@end
