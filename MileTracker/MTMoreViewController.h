//
//  MTMoreViewController.h
//  MileTracker
//
//  Created by Stine Richvoldsen on 1/4/13.
//  Copyright (c) 2013 Focus43. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTMoreViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) UIButton *logOutButton;
@property (nonatomic, strong) UIButton *resetPasswordButton;

@property (nonatomic, strong) IBOutlet UIButton *feedbackButton;
@property (strong, nonatomic) IBOutlet UITextField *emailField;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

- (IBAction)logOutAction:(id)sender;
- (IBAction)resetPasswordAction:(id)sender;
- (IBAction)sendFeedbackAction:(id)sender;

@end
