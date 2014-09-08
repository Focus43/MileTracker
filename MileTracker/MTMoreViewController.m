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
#import "MTTotalMileage.h"

#define kFeedbackToAddress @"triptrax@focus-43.com"

@interface MTMoreViewController ()

@property (nonatomic, strong) UITextField *activeTextField;

- (void)showUpdatePasswordAlert;
- (void)updatePasswordWith:(NSString *)newPassword;
- (void)updateSavings;
- (void)sendFeedback;
- (void)doUserAction:(NSString *)action;

- (void)showEmailProblemAlert;
- (BOOL)validateEmail:(NSString *)candidate;
- (void)registerForKeyboardNotifications;
- (void)dismissKeyboard;
- (void)updateSavingsLabel;
- (void)updateLoginLabel;

@end

@implementation MTMoreViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[MTViewUtils backGroundColor]];
    
    // set defaults for unit settings and register actions for the switch events
    _kilometerSwitch.on = NO;
    _mileSwitch.on = YES;
    [[NSUserDefaults standardUserDefaults] setValue:kUserDefaultsLengthUnitMile forKey:kUserDefaultsLengthUnit];
    [_kilometerSwitch addTarget:self action:@selector(unitsChanged:) forControlEvents:UIControlEventValueChanged];
    [_mileSwitch addTarget:self action:@selector(unitsChanged:) forControlEvents:UIControlEventValueChanged];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Set the savings label depending on user defaults
    [self updateSavingsLabel:nil];
    // Set the login label depending on user status
    [self updateLoginLabel];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateLoginLabel
{
    NSString *labelStr = @"Log In / Register";
    
    if ( [PFUser currentUser].sessionToken ) {
        labelStr = @"Log Out";
    }
    
    [self.loginLabel setText:labelStr];
}

- (void)updateSavingsLabel:(NSNotification *)note
{
    NSString *labelStr;
    
    if (note) {
        labelStr = [NSString stringWithFormat:@"You can deduct %@ on your taxes!", note.object];
    } else {
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        NSString *stdStr = [prefs stringForKey:kUserDefaultsSavingsStringKey];
        
        if ( [PFUser currentUser] || stdStr ) {
            
            if ( [PFUser currentUser] ) {
                labelStr = (stdStr) ?
                    [NSString stringWithFormat:@"You can deduct %@ on your taxes!", stdStr] :
                    @"Tap to retrieve your total savings so far this year.";
            } else {
                labelStr = (stdStr) ?
                    [NSString stringWithFormat:@"You can deduct %@ on your taxes!", stdStr] :
                    @"Sign in to access this information.";
            }
            
        } else {
            labelStr = @"Sign in to access this information.";
        }
    }
    
    [self.savingsLabel setText:labelStr];
}

# pragma mark - action methods

- (void)doUserAction:(NSString *)action
{
    if ( [PFUser currentUser].sessionToken ) {
        [self logOut];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kLaunchLoginScreenNotification object:self];
    }
}

- (void)showUpdatePasswordAlert
{
    if ( [PFUser currentUser].sessionToken ) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Reset Password" message:@"Enter the email used for sign up, and we'll send you instructions:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField * alertTextField = [alert textFieldAtIndex:0];
        alertTextField.keyboardType = UIKeyboardTypeEmailAddress;
        alertTextField.placeholder = @"Email address";
        [alert show];
    } else {
        UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Log In" message:@"You have to be logged in to reset your password." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [problemAlert show];
    }
}

- (void)sendFeedback
{
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSString *model = [currentDevice model];
    NSString *systemVersion = [currentDevice systemVersion];
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    NSString *deviceSpecs = [NSString stringWithFormat:@"%@ - %@ - %@", model, systemVersion, appVersion];
    
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;
        [controller setToRecipients:[NSArray arrayWithObject:kFeedbackToAddress]];
        [controller setSubject:@"TripTrax feedback"];
        [controller setMessageBody:[@"\n\n\nIf you are reporting a bug, it would be great if you don't delete this device data: " stringByAppendingString:deviceSpecs] isHTML:NO];
        
        if (controller) [self presentViewController:controller animated:YES completion:NULL];
        
    } else {
        UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Looks like your device needs to be configured to send email. Update your settings and come back hrere and try again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [problemAlert show];
    }
}

- (void)updateSavings
{
    if ( [PFUser currentUser].sessionToken ) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSavingsLabel:) name:kMileageTotalFoundNotification object:nil];
        [MTTotalMileage initiateSavingsUntilNowCalc];
    } else {
        UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Sign Up!" message:@"This feature is available if you sign up and log in." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [problemAlert show];
    }
    
}

# pragma mark - action support methods

- (void)unitsChanged:(UISwitch *)changedSwitch
{
    if ( changedSwitch == _mileSwitch ) {
        if ( [_mileSwitch isOn] ) {
            [_kilometerSwitch setOn:NO animated:YES];
            [[NSUserDefaults standardUserDefaults] setValue:kUserDefaultsLengthUnitMile forKey:kUserDefaultsLengthUnit];
        } else {
            [_kilometerSwitch setOn:YES animated:YES];
            [[NSUserDefaults standardUserDefaults] setValue:kUserDefaultsLengthUnitKilometer forKey:kUserDefaultsLengthUnit];
        }
    } else if ( changedSwitch == _kilometerSwitch ) {
        if ( [_kilometerSwitch isOn] ) {
            [_mileSwitch setOn:NO animated:YES];
            [[NSUserDefaults standardUserDefaults] setValue:kUserDefaultsLengthUnitKilometer forKey:kUserDefaultsLengthUnit];
        } else {
            [_mileSwitch setOn:YES animated:YES];
            [[NSUserDefaults standardUserDefaults] setValue:kUserDefaultsLengthUnitMile forKey:kUserDefaultsLengthUnit];
        }
    }
    PFUser *user = [PFUser currentUser];
    user[@"lengthUnit"] = [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsLengthUnit];
    [user saveInBackground];
}

- (void)logOut
{
    NSString *messageString;
    
    UIAlertView *youSureAlert = [[UIAlertView alloc] initWithTitle:@"You sure?" message:messageString delegate:self cancelButtonTitle:@"Never mind..." otherButtonTitles:@"Sign me out!", nil];
    [youSureAlert show];
}

- (void)updatePasswordWith:(NSString *)newPassword
{
    if ( newPassword ) {
        if ( [self validateEmail:newPassword] ) {
            [PFUser requestPasswordResetForEmailInBackground:newPassword block:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Password Updated" message:@"Your password has been updated. Check your email!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [successAlert show];
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
    UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Invalid email" message:@"You must enter a valid email address." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [problemAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( alertView.alertViewStyle == UIAlertViewStylePlainTextInput ) {
        if ( buttonIndex == 1 ) {
            [self updatePasswordWith: [[alertView textFieldAtIndex:0] text]];
        }
    } else {
        if ( buttonIndex == 1 ) {
//            NSLog(@"logging out");
            [PFUser logOut];
            UITabBarController *tabBarController = self.view.window.rootViewController;
            [tabBarController setSelectedIndex:0];
            MTAppDelegate *appDelegate = (MTAppDelegate *)([UIApplication sharedApplication].delegate);
            [appDelegate launchLoginScreen];
            [PFQuery clearAllCachedResults];
        }
    }
}

# pragma mark - table view methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( [indexPath section] == 0 ) {
        if ( [indexPath row] == 0 ) {
            [self doUserAction: [tableView cellForRowAtIndexPath:indexPath].textLabel.text];
        } else if ( [indexPath row] == 1 ) {
            [self showUpdatePasswordAlert];
        }
    } else if ( [indexPath section] == 1 ) {
        if ( [indexPath row] == 0 ) {
            [self updateSavings];
        }
    } else if ( [indexPath section] == 2 ) {
        if ( [indexPath row] == 0 ) {
            [self sendFeedback];
        }
    }
    
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.textColor = [UIColor whiteColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0){
        return 35;
    }
    return 25;
}

#pragma mark - Mail Compose View Controller delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        UIAlertView *thanksAlert = [[UIAlertView alloc] initWithTitle:@"Thank you!" message:@"We appreciate you taking the time to let us know what you think!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [thanksAlert show];
    }
    [self dismissModalViewControllerAnimated:YES];
}

@end
