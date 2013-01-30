//
//  MTLoginViewController.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 1/4/13.
//  Copyright (c) 2013 Focus43. All rights reserved.
//

#import "MTLoginViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface MTLoginViewController ()

@property (nonatomic, strong) UIImageView *fieldsBackground;

@end

@implementation MTLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.logInView setBackgroundColor:[MTViewUtils backGroundColor]];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if ( orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight ) {
        [self.logInView setLogo:nil];
    } else {
        [self.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo.png"]]];
    }
        
      // Add login field background
    _fieldsBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"login_bg.png"]];
    [self.logInView addSubview:self.fieldsBackground];
    [self.logInView sendSubviewToBack:self.fieldsBackground];
    
    self.logInView.usernameField.textColor = [UIColor grayColor];
    self.logInView.passwordField.textColor = [UIColor grayColor];

    // Remove text shadow
    CALayer *layer = self.logInView.usernameField.layer;
    layer.shadowOpacity = 0.0f;
    layer = self.logInView.passwordField.layer;
    layer.shadowOpacity = 0.0f;
        
}

- (void)viewDidLayoutSubviews {
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if ( orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight ) {
        [self.fieldsBackground setFrame:CGRectMake(160.0f, 50.0f, 245.0f, 90.0f)];
    } else {
        [self.fieldsBackground setFrame:CGRectMake(37.0f, 190.0f, 245.0f, 90.0f)];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if ( orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight ) {
        [self.logInView setLogo:nil];
    } else {
        [self.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo.png"]]];
    }
}


@end
