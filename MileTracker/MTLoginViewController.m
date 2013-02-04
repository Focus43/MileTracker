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

- (void)viewDidLayoutSubviews
{
    CGRect loginRect = CGRectMake( self.logInView.usernameField.frame.origin.x, self.logInView.usernameField.frame.origin.y, 245.0f, 90.0f);
    [self.fieldsBackground setFrame:loginRect];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if ( (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) && [[UIDevice currentDevice].model isEqualToString:@"iPad"] ) {
        [self.logInView setLogo:nil];
    } else {
        [self.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo.png"]]];
    }
}


@end
