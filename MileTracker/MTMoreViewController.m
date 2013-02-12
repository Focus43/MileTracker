//
//  MTMoreViewController.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 1/4/13.
//  Copyright (c) 2013 Focus43. All rights reserved.
//

#import "MTMoreViewController.h"
#import "MTAppDelegate.h"
#import <Parse/Parse.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface MTMoreViewController ()

@property (nonatomic, strong) UITextField *activeTextField;

- (void)showEmailProblemAlert;
- (BOOL) validateEmail:(NSString *)candidate;
- (void)registerForKeyboardNotifications;
- (void)dismissKeyboard;

@end

@implementation MTMoreViewController

@synthesize emailField, scrollView, activeTextField;

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
    
    [self.view setBackgroundColor:[MTViewUtils backGroundColor]];
	
    [self registerForKeyboardNotifications];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.scrollView addGestureRecognizer:tap];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)sendFeedbackAction:(id)sender
{
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSString *model = [currentDevice model];
    NSString *systemVersion = [currentDevice systemVersion];
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    NSString *deviceSpecs = [NSString stringWithFormat:@"%@ - %@ - %@", model, systemVersion, appVersion];
    
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;
        [controller setSubject:@"TripTrax feedback"];
        [controller setMessageBody:[@"If you are reporting a bug, it would be great if you don't delete this device data:\n" stringByAppendingString:deviceSpecs] isHTML:NO];
        
        if (controller) [self presentModalViewController:controller animated:YES];
        
    } else {
        UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Looks like your device needs to be configured to send email. Update your settings and come back hrere and try again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [problemAlert show];
    }
}

- (IBAction)logOutAction:(id)sender
{  
    NSString *messageString;
    
    UIAlertView *youSureAlert = [[UIAlertView alloc] initWithTitle:@"You sure?" message:messageString delegate:self cancelButtonTitle:@"Never mind then" otherButtonTitles:@"Sign me out!", nil];
    [youSureAlert show];
}

- (IBAction)resetPasswordAction:(id)sender
{
    if ( self.emailField.text ) {
        if ( [self validateEmail:self.emailField.text] ) {
            [PFUser requestPasswordResetForEmailInBackground:self.emailField.text block:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Password Updated" message:@"Your password has been updated. Check your email!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [successAlert show];
                    self.emailField.text = @"";
                    [self.emailField resignFirstResponder];
                } else {
                    UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:[[error userInfo] objectForKey:@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [problemAlert show];
                }
            }]; 
        } else {
            [self showEmailProblemAlert]; 
        }
    } else {
        [self showEmailProblemAlert];
    }
}

- (BOOL)validateEmail:(NSString *)candidate
{
    NSString *emailRegex =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:candidate];
}

- (void)showEmailProblemAlert
{
    UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Invalid email" message:@"You must enter a valid emil address." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [problemAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex == 1 ) {
        NSLog(@"logging out");
        [PFUser logOut];
        UITabBarController *tabBarController = self.view.window.rootViewController;
        [tabBarController setSelectedIndex:0];
        MTAppDelegate *appDelegate = (MTAppDelegate *)([UIApplication sharedApplication].delegate);
        [appDelegate launchLoginScreen];
        [PFQuery clearAllCachedResults];
    }
}

# pragma mark - move view around on showing keyboard
// move to a UIVIewController category

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeTextField = nil;
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    if ( !scrollView.contentInset.bottom == contentInsets.bottom ) {
        scrollView.contentInset = contentInsets;
        scrollView.scrollIndicatorInsets = contentInsets;
    }
    
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.activeTextField.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, self.activeTextField.frame.origin.y - 20);
        [scrollView setContentOffset:scrollPoint animated:YES];
    }
}

- (void)dismissKeyboard
{
    [self.activeTextField resignFirstResponder];
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
    
    // This scrolls the screen back to the top. Not sure I like it....
    CGPoint scrollPoint = CGPointMake(0.0, 0.0);
    [scrollView setContentOffset:scrollPoint animated:YES];
}

@end
