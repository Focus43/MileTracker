//
//  MTSignUpViewController.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 1/4/13.
//  Copyright (c) 2013 Focus43. All rights reserved.
//

#import "MTSignUpViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface MTSignUpViewController ()
@property (nonatomic, strong) UIImageView *fieldsBackground;
@end

@implementation MTSignUpViewController

@synthesize fieldsBackground = _fieldsBackground;

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
	
    [self.signUpView setBackgroundColor:[MTViewUtils backGroundColor]];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if ( orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight ) {
        [self.signUpView setLogo:nil];
    } else {
        [self.signUpView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo.png"]]];
    }
    
    _fieldsBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sign_up_bg.png"]];
    [self.signUpView addSubview:self.fieldsBackground];
    [self.signUpView sendSubviewToBack:self.fieldsBackground];
    
    self.signUpView.usernameField.textColor = [UIColor grayColor];
    self.signUpView.passwordField.textColor = [UIColor grayColor];
    self.signUpView.emailField.textColor = [UIColor grayColor];
    
    // Remove text shadow
    CALayer *layer = self.signUpView.usernameField.layer;
    layer.shadowOpacity = 0.0f;
    layer = self.signUpView.passwordField.layer;
    layer.shadowOpacity = 0.0f;
    layer = self.signUpView.emailField.layer;
    layer.shadowOpacity = 0.0f;
    

}

- (void)viewDidLayoutSubviews {
    // Set frame for elements
    //    [self.logInView.dismissButton setFrame:CGRectMake(10.0f, 10.0f, 87.5f, 45.5f)];
    //    [self.logInView.logo setFrame:CGRectMake(66.5f, 70.0f, 187.0f, 58.5f)];
    //    [self.logInView.facebookButton setFrame:CGRectMake(35.0f, 287.0f, 120.0f, 40.0f)];
    //    [self.logInView.twitterButton setFrame:CGRectMake(35.0f+130.0f, 287.0f, 120.0f, 40.0f)];
    //    [self.logInView.signUpButton setFrame:CGRectMake(35.0f, 385.0f, 250.0f, 40.0f)];
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if ( orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight ) {
        [self.fieldsBackground setFrame:CGRectMake(160.0f, 75.0f, 245.0f, 133.0f)];
    } else {
        [self.fieldsBackground setFrame:CGRectMake(37.0f, 205.0f, 245.0f, 133.0f)];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
