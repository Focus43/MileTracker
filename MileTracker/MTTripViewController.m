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

@interface MTTripViewController ()

- (void)showCannotSaveAlert;
- (void)dateOrTimeFieldTouched:(UITextField *)touchedField;
- (void)registerForKeyboardNotifications;
- (void)dismissKeyboard;

@property (strong, nonatomic) UITextField *activeTextField;
@property CGPoint originalCenter;

@end

@implementation MTTripViewController

@synthesize dateField, titleField, startOdometerField, endOdometerField;
@synthesize selectedDate;
@synthesize originalCenter, activeTextField, scrollView;
@synthesize trip, numberFormatter;
@synthesize actionSheetPicker = _actionSheetPicker;

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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.originalCenter = self.view.center;
    
    if (![PFUser currentUser]) { // No user logged in
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
        self.titleField.text = self.trip.title;
        self.dateField.text = [self.trip dateToString];
        self.startOdometerField.text = [self.trip startOdometerToString];
        self.endOdometerField.text = [self.trip endOdometerToString];
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showCannotSaveAlert
{
    UIAlertView *cannotSaveAlert = [[UIAlertView alloc] initWithTitle:@"Uh oh..." message:@"You must at least enter a date" delegate:nil cancelButtonTitle:@"Duh!" otherButtonTitles:nil];
    [cannotSaveAlert show];
}

- (IBAction)saveButtonTouched:(id)sender
{
    // dismiss keyboard
    [self.titleField resignFirstResponder];
    [self.dateField resignFirstResponder];
    [self.startOdometerField resignFirstResponder];
    [self.endOdometerField resignFirstResponder];
    
    if (![self.dateField.text isEqualToString:@""]) {
        
        NSNumber *start = [self.numberFormatter numberFromString:self.startOdometerField.text];
        if (!start) start = [NSNumber numberWithInt:0];
        
        NSNumber *end = [self.numberFormatter numberFromString:self.endOdometerField.text];
        if (!end) end = [NSNumber numberWithInt:0];
        
        PFUser *currentUser = [PFUser currentUser];
        NSDate *tripDate = self.selectedDate ? self.selectedDate : [[[MTFormatting sharedUtility] dateFormatter] dateFromString:self.dateField.text];
        
        NSArray *data = [NSArray arrayWithObjects:self.titleField.text, tripDate, start, end, currentUser, nil];
        NSArray *keys = [NSArray arrayWithObjects:@"title", @"date", @"startOdometer", @"endOdometer", @"user", nil];
        NSDictionary *tripData = [NSDictionary dictionaryWithObjects:data forKeys:keys];
        
        Trip *tripToSave = [Trip tripWithData:tripData];
        // if editing, make sure we update the trip object AND trip
        // this is a bit of a cluster, but I can't find other way to handle it....
        // TODO: use trip to update the list view w/o reloading table when gong back
        if (self.trip) {
            [self.trip updateWithData:tripData];
            tripToSave = self.tripObj;
            [tripToSave setObject:self.titleField.text forKey:@"title"];
            [tripToSave setObject:tripDate forKey:@"date"];
            [tripToSave setObject:start forKey:@"startOdometer"];
            [tripToSave setObject:end forKey:@"endOdometer"];
            [tripToSave setObject:currentUser forKey:@"user"];
        }
        
        // set access limitation
        tripToSave.ACL = [PFACL ACLWithUser:currentUser];
        
        [tripToSave saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Yessss!" message:@"Trip was saved" delegate:nil cancelButtonTitle:@"Sweet!" otherButtonTitles:nil];
                [successAlert show];
                
                if (!self.trip) {
                    self.titleField.text = @"";
                    self.dateField.text = @"";
                    self.startOdometerField.text = @"";
                    self.endOdometerField.text = @"";
                }
                
            } else {
                UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Network problem" message:@"The server cannot be contacted at this time, and the trip will be saved at a later time, when the connection is back up." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [problemAlert show];
                [tripToSave saveEventually];
            }
        }];
        
    } else {
        [self showCannotSaveAlert];
    }
}

- (void)dateOrTimeFieldTouched:(UITextField *)touchedField
{
    [self.titleField resignFirstResponder];
    [self.startOdometerField resignFirstResponder];
    [self.endOdometerField resignFirstResponder];
    
    NSDate *pickerDate = self.trip ? self.trip.date : [NSDate date];
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
