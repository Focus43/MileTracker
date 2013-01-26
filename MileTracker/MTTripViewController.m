//
//  MTFirstViewController.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 12/14/12.
//  Copyright (c) 2012 Focus43. All rights reserved.
//

#import "MTTripViewController.h"
#import "NSDate+TCUtils.h"
#import "MTLoginViewController.h"
#import "MTSignUpViewController.h"
#import "UnsyncedTrip.h"
#import "Reachability.h"

@interface MTTripViewController ()

- (void)showCannotSaveAlert;
- (void)dateOrTimeFieldTouched:(UITextField *)touchedField;
- (void)registerForKeyboardNotifications;
- (void)dismissKeyboard;
- (void)saveLocalVersionTripData:(NSDictionary *)tripData withNewFlag:(BOOL)flag objectId:(NSString *)objectId;

@property (strong, nonatomic) UITextField *activeTextField;
@property CGPoint originalCenter;
@property (nonatomic, strong) Reachability *networkReachability;
@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation MTTripViewController

// Can't help myself. Still doing this...
@synthesize dateField, titleField, startOdometerField, endOdometerField;
@synthesize selectedDate;
@synthesize originalCenter, activeTextField, scrollView;
@synthesize trip, numberFormatter, networkReachability;
@synthesize actionSheetPicker = _actionSheetPicker;
@synthesize hud=_hud;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ( !self.numberFormatter ) {
        self.numberFormatter = [[NSNumberFormatter alloc] init];
        [self.numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    }

    [self registerForKeyboardNotifications];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                               initWithTarget:self
                               action:@selector(dismissKeyboard)];

    [self.scrollView addGestureRecognizer:tap];
    
    self.networkReachability = [Reachability reachabilityForInternetConnection];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.originalCenter = self.view.center;
    
    if (![PFUser currentUser]) { // No user logged in
        NetworkStatus networkStatus = [self.networkReachability currentReachabilityStatus];
        
        if ( networkStatus == NotReachable ) {
            UIAlertView *cannotLoginAlert = [[UIAlertView alloc] initWithTitle:@"Uh oh..."
                                                                       message:@"To sign up or log in, you have to be online, and it looks like you're not right now."
                                                                      delegate:nil
                                                             cancelButtonTitle:@"I'll try again later!"
                                                             otherButtonTitles:nil];
            [cannotLoginAlert show];
            
        }
    
        // Create the log in view controller
        MTLoginViewController *logInViewController = [[MTLoginViewController alloc] init];
        [logInViewController setDelegate:self]; // Set ourselves as the delegate
        
        // Create the sign up view controller
        MTSignUpViewController *signUpViewController = [[MTSignUpViewController alloc] init];
        [signUpViewController setDelegate:self]; // Set ourselves as the delegate
        
        // Assign our sign up controller to be displayed from the login controller
        [logInViewController setSignUpController:signUpViewController];
        
        // Present the log in view controller
        [self presentViewController:logInViewController animated:YES completion:NULL];
        
    }
    
    // if editing
    if (self.trip) {
        self.titleField.text = [self.trip objectForKey:@"title"];
        self.dateField.text = [self.trip tr_dateToString];
        self.startOdometerField.text = [self.trip tr_startOdometerToString];
        self.endOdometerField.text = [self.trip tr_endOdometerToString];
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showCannotSaveAlert
{
    UIAlertView *cannotSaveAlert = [[UIAlertView alloc] initWithTitle:@"Uh oh..." message:@"You must enter a date and destination" delegate:nil cancelButtonTitle:@"Duh!" otherButtonTitles:nil];
    [cannotSaveAlert show];
}

- (IBAction)saveButtonTouched:(id)sender
{
    // dismiss keyboard
    [self.titleField resignFirstResponder];
    [self.dateField resignFirstResponder];
    [self.startOdometerField resignFirstResponder];
    [self.endOdometerField resignFirstResponder];
    
    if ( !([self.dateField.text isEqualToString:@""] || [self.titleField.text isEqualToString:@""]) ) {
        
        NSNumber *start = [self.numberFormatter numberFromString:self.startOdometerField.text];
        if (!start) start = [NSNumber numberWithInt:0];
        
        NSNumber *end = [self.numberFormatter numberFromString:self.endOdometerField.text];
        if (!end) end = [NSNumber numberWithInt:0];
        
        PFUser *currentUser = [PFUser currentUser];
        NSDate *tripDate = self.selectedDate ? self.selectedDate : [self.trip objectForKey:@"date"];
        NSString *objectId = (self.trip) ? self.trip.objectId : @"";
        
        NSArray *data = [NSArray arrayWithObjects:self.titleField.text, tripDate, start, end, currentUser, nil];
        NSArray *keys = [NSArray arrayWithObjects:@"title", @"date", @"startOdometer", @"endOdometer", @"user", nil];
        NSMutableDictionary *tripData = [NSDictionary dictionaryWithObjects:data forKeys:keys];
        
        PFObject *tripToSave = [PFObject tr_objectWithData:tripData objectId:objectId];
        
        BOOL isNewTrip = YES;
        if (self.trip) {
            isNewTrip = NO;
        }
                
        NetworkStatus networkStatus = [self.networkReachability currentReachabilityStatus];
        
        if ( networkStatus == NotReachable ) {
            
            [self saveLocalVersionTripData:tripData withNewFlag:isNewTrip objectId:objectId];
            
        } else {
            
            if (!self.hud) {
                _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                self.hud.delegate = self;
            }
            
            self.hud.mode		= MBProgressHUDModeIndeterminate;
            self.hud.labelText	= @"Saving trip";
            self.hud.margin		= 30;
            self.hud.yOffset	= 30;
            [self.hud show:YES];
            
            [tripToSave saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Yessss!" message:@"Trip was saved" delegate:nil cancelButtonTitle:@"Sweet!" otherButtonTitles:nil];
                    [successAlert show];
                    
                    if (self.hud) {
                        [self.hud hide:YES afterDelay:0.5];
                    }
                    
                } else {
                    [self saveLocalVersionTripData:tripData withNewFlag:isNewTrip objectId:objectId];
                }
            }];
            
        }
        
        if ( !self.trip ) {
            self.titleField.text = @"";
            self.dateField.text = @"";
            self.startOdometerField.text = @"";
            self.endOdometerField.text = @"";
        }
        
    } else {
        [self showCannotSaveAlert];
    }
}

- (void)saveLocalVersionTripData:(NSDictionary *)tripData withNewFlag:(BOOL)isNew objectId:(NSString*)objectId
{
    NSLog(@"saveLocalVersionTripData tripData = %@", tripData);
    UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Network problem" message:@"You're offline, so the trip will be saved locally and backed up in the cloud when you're back online." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [problemAlert show];
        
    if ( isNew ) {
        NSLog(@"it's a new trip");
        [UnsyncedTrip createTripForEntityDecriptionAndLoadWithData:tripData objectId:nil];
        
    } else {
        NSLog(@"not a new trip");
        
        NSError *error = nil;
        NSArray *results = [UnsyncedTrip fetchTripsWithId:objectId error:error];
        
        if ( !error && results && [results count] > 0 ) {
            NSLog(@"already in unsynced data : %@", [results objectAtIndex:0]);
            // record already exists
            [[results objectAtIndex:0] setValue:tripData forKey:@"unsyncedObjInfo"];
            [[[MTCoreDataController sharedInstance] managedObjectContext] save:&error];
            
        } else {
            NSLog(@"first time added to unsynced data");
            [UnsyncedTrip createTripForEntityDecriptionAndLoadWithData:tripData objectId:objectId];
            
        }
        
    }
    
    // Save object right away, to have access to it in the log
    [[MTCoreDataController sharedInstance] saveContext];
    
    if (self.hud) {
        [self.hud hide:YES afterDelay:0.5];
    }
}

- (void)dateOrTimeFieldTouched:(UITextField *)touchedField
{
    [self.titleField resignFirstResponder];
    [self.startOdometerField resignFirstResponder];
    [self.endOdometerField resignFirstResponder];
    
    NSDate *pickerDate = self.trip ? [self.trip objectForKey:@"date"] : [NSDate date];
    _actionSheetPicker = [[ActionSheetDatePicker alloc] initWithTitle:@""
                                                       datePickerMode:UIDatePickerModeDate
                                                         selectedDate:pickerDate
                                                               target:self
                                                               action:@selector(dateWasSelected:element:)
                                                               origin:touchedField];
    
    [self.actionSheetPicker addCustomButtonWithTitle:@"Today" value:[NSDate date]];
    [self.actionSheetPicker addCustomButtonWithTitle:@"Yesterday" value:[[NSDate date] TC_dateByAddingCalendarUnits:NSDayCalendarUnit amount:-1]];
    self.actionSheetPicker.hideCancel = NO;
    [self.actionSheetPicker showActionSheetPicker];
}

- (void)dateWasSelected:(NSDate *)selDate element:(id)element
{
    self.selectedDate = selDate;
    UITextField *currentField = (UITextField *)element;
    currentField.text = [[[MTFormatting sharedUtility] dateFormatter] stringFromDate:selDate];
}

- (NSDate *)dateSetToMidnightUsingDate:(NSDate *)aDate
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:NSUIntegerMax fromDate:aDate];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    
    return [gregorian dateFromComponents: components];
}

# pragma mark - Login Delegate methods

// Sent to the delegate to determine whether the log in request should be submitted to the server.
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
    // Check if both fields are completed
    if (username && password && username.length != 0 && password.length != 0) {
        return YES; // Begin login process
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                message:@"Make sure you fill out all of the information!"
                               delegate:nil
                      cancelButtonTitle:@"ok"
                      otherButtonTitles:nil] show];
    return NO; // Interrupt login process
}

// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    NSLog(@"Failed to log in...");
}

// Sent to the delegate when the log in screen is dismissed.
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    [self.navigationController popViewControllerAnimated:YES];
}

# pragma mark - Sign Up Delegate methods

// Sent to the delegate to determine whether the sign up request should be submitted to the server.
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
    BOOL informationComplete = YES;
    
    // loop through all of the submitted data
    for (id key in info) {
        NSString *field = [info objectForKey:key];
        if (!field || field.length == 0) { // check completion
            informationComplete = NO;
            break;
        }
    }
    
    // Display an alert if a field wasn't completed
    if (!informationComplete) {
        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                    message:@"Make sure you fill out all of the information!"
                                   delegate:nil
                          cancelButtonTitle:@"ok"
                          otherButtonTitles:nil] show];
    }
    
    return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
    [self dismissModalViewControllerAnimated:YES]; // Dismiss the PFSignUpViewController
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
    NSLog(@"Failed to sign up...");
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
    NSLog(@"User dismissed the signUpViewController");
}

# pragma mark - Text Field Delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if ( textField == self.dateField ) {
        [self dateOrTimeFieldTouched:textField];
        
        return false;
    }
    
    return true;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeTextField = nil;
}

# pragma mark - keyboard notification handlers 

- (void)dismissKeyboard
{
    [self.activeTextField resignFirstResponder];
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
        CGPoint scrollPoint = CGPointMake(0.0, self.activeTextField.frame.origin.y - 25);
        [scrollView setContentOffset:scrollPoint animated:YES];
    }
}

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
