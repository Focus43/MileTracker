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
    
    // move dismiss button
    self.signUpView.dismissButton.frame = CGRectMake(self.signUpView.dismissButton.frame.origin.x, self.signUpView.dismissButton.frame.origin.y + 20, self.signUpView.dismissButton.frame.size.width, self.signUpView.dismissButton.frame.size.height + 20);
}

- (void)viewDidLayoutSubviews
{
    CGRect signupRect = CGRectMake( self.signUpView.usernameField.frame.origin.x, self.signUpView.usernameField.frame.origin.y, 245.0f, 133.0f);
    [self.fieldsBackground setFrame:signupRect];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
