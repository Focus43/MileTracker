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
@property (nonatomic, strong) NSLayoutConstraint *stickToBottom;
@property (nonatomic, assign) float constraintConstant;
@property (nonatomic, assign) float bannerHeight;

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
    
    if ( floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1 ) {
        self.tabBar.barStyle = UIBarStyleBlack;
        self.tabBar.translucent = NO;
        self.tabBar.tintColor = [UIColor whiteColor];
    }
    
	// Add ad banner
    _banner = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
    [_banner setTranslatesAutoresizingMaskIntoConstraints:NO];
    _banner.delegate = self;
    
    [_banner setBackgroundColor:[UIColor clearColor]];
    
    [self.view insertSubview:_banner belowSubview:self.tabBar];
    
//    NSOperatingSystemVersion ios8_0_0 = (NSOperatingSystemVersion){8, 0, 0};
//    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:ios8_0_0]) {
    if ( [[[UIDevice currentDevice] systemVersion] intValue] < 8 ) {
        _constraintConstant = -1 * (self.tabBar.frame.size.height);
    } else {
        _constraintConstant = _banner.frame.size.height - self.tabBar.frame.size.height;
    }
    
    // pin sides to superview
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[_banner]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_banner)]];
    // pin to bottom
    _stickToBottom = [NSLayoutConstraint constraintWithItem:_banner
                                                  attribute:NSLayoutAttributeBottom
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:self.tabBar
                                                  attribute:NSLayoutAttributeBottom
                                                 multiplier:1.0
                                                   constant:_constraintConstant];
    [self.view addConstraint:_stickToBottom];
    [self.view layoutIfNeeded];
    self.bannerIsVisible = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Hack to deal w ad changing size in ios7 and not ios8
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    _bannerHeight = _banner.frame.size.height;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if ( _banner.frame.size.height != _bannerHeight ) {
        
        _stickToBottom.constant += _bannerHeight - _banner.frame.size.height;
        
        [UIView animateWithDuration:0.25 animations:^{
            [self.view layoutIfNeeded];
        }];
    }
}


#pragma mark -- Advertising Delegate

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    if (!self.bannerIsVisible) {
        _stickToBottom.constant = _constraintConstant - _banner.frame.size.height;
        
        [UIView animateWithDuration:1 animations:^{
            [self.view layoutIfNeeded];
        }];
        self.bannerIsVisible = YES;
    }
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    if (self.bannerIsVisible) {
        _stickToBottom.constant = _constraintConstant;
        
        [UIView animateWithDuration:1 animations:^{
            [self.view layoutIfNeeded];
        }];
        self.bannerIsVisible = NO;
    }
}

@end
