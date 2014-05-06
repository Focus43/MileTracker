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
    
    [self.view setBackgroundColor:[MTViewUtils backGroundColor]];
    
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
    
//    if (![PFUser currentUser]) { // No user logged in
//        [[NSNotificationCenter defaultCenter] postNotificationName:kLaunchLoginScreenNotification object:self];
//    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.originalCenter = self.view.center;
        
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
//    if (![PFUser currentUser]) { // No user logged in
//        [[NSNotificationCenter defaultCenter] postNotificationName:kLaunchLoginScreenNotification object:self];
//    }
    
    // dismiss keyboard
    [self.titleField resignFirstResponder];
    [self.dateField resignFirstResponder];
    [self.startOdometerField resignFirstResponder];
    [self.endOdometerField resignFirstResponder];
    
    BOOL isNewTrip = YES;
    NSNumber *oldTotalMilesForTrip;
    float addedLastTime = 0.0;
    if (self.trip) {
        isNewTrip = NO;
        oldTotalMilesForTrip = [self.trip tr_totalTripDistance];
        // get what was added last time, but then delete the entry from dict to not save to Parse
        addedLastTime = [self.trip getAddedLastTime];
        [self.trip voidAddedLastTime];
    }
    
    if ( !([self.dateField.text isEqualToString:@""] || [self.titleField.text isEqualToString:@""]) ) {
        
        NSNumber *start = [self.numberFormatter numberFromString:self.startOdometerField.text];
        if (!start) start = [NSNumber numberWithInt:0];
        
        NSNumber *end = [self.numberFormatter numberFromString:self.endOdometerField.text];
        if (!end) end = [NSNumber numberWithInt:0];
        
        PFUser *currentUser = [PFUser currentUser];
        if (!currentUser)
            (NSString *)currentUser;
            currentUser = @"anonymous";
    
        NSDate *tripDate = self.selectedDate ? self.selectedDate : [self.trip objectForKey:@"date"];
        NSString *objectId = (self.trip) ? self.trip.objectId : @"";
        
        NSArray *data = [NSArray arrayWithObjects:self.titleField.text, tripDate, start, end, currentUser, nil];
        NSArray *keys = [NSArray arrayWithObjects:@"title", @"date", @"startOdometer", @"endOdometer", @"user", nil];
        NSMutableDictionary *tripData = [NSDictionary dictionaryWithObjects:data forKeys:keys];
        
        PFObject *tripToSave = [PFObject tr_objectWithData:tripData objectId:objectId];
        
        if ( [PFUser currentUser]) {
            tripToSave.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
        }
        
        NetworkStatus networkStatus = [self.networkReachability currentReachabilityStatus];
        
        if ( networkStatus == NotReachable || ![PFUser currentUser].sessionToken ) {
            
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
                    
                    float currentTripTotal, newTripTotal = 0.0;
                    NSNumber *newTotalSaved;
                    NSString *savingsStr;
                    NSString *savedStr;
                    
                    if ([end intValue] > 0) {
                        currentTripTotal = [end floatValue] - [start floatValue];
                        
                        if (currentTripTotal > 0 ) {
                        
                            if ( oldTotalMilesForTrip ) {
                                currentTripTotal -= [oldTotalMilesForTrip floatValue];
                            }
                            
                            newTripTotal = currentTripTotal + [[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsTotalMilesKey] floatValue] - addedLastTime;
                            // set the addedLastTime for the trip, to use in case it gets re-entered
                            [self.trip setAddedLastTime:currentTripTotal];
                          
                            newTotalSaved = [[NSNumber alloc] initWithFloat:newTripTotal * kDollarPerMileTaxDeduction];
                            
                            NSNumberFormatter *formatter = [[MTFormatting sharedUtility] currencyFormatter];
                            savedStr = [formatter stringFromNumber:newTotalSaved];
                            
                            if ( savedStr != NULL && ![savedStr isEqualToString:@""] ) {
                                savingsStr = [NSString stringWithFormat:@". So far this year, you have logged enough miles to deduct %@ on your taxes!", savedStr];
                            } else {
                                savingsStr = @".";
                            }
                            
                        } else {
                            savingsStr = @", but you just updated this trip to less than zero miles driven.";
                        }
                        
                        [[NSUserDefaults standardUserDefaults] setObject:savedStr forKey:kUserDefaultsSavingsStringKey];
                        [[NSUserDefaults standardUserDefaults] setObject:newTotalSaved forKey:kUserDefaultsSavingsKey];
                        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:newTripTotal] forKey:kUserDefaultsTotalMilesKey];
                        
                    } else if ([end intValue] == 0) {
                        savingsStr = @".";
                    } else {
                        savingsStr = @", but you entered a negative number for your odometer settings. So that's weird...";
                    }
                    
                    NSString *message = [NSString stringWithFormat:@"Trip was saved%@\n", savingsStr];
                    
                    UIAlertView *successAlert = [[UIAlertView alloc] initWithTitle:@"Yessss!" message:message delegate:nil cancelButtonTitle:@"Sweet!" otherButtonTitles:nil];
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
    UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Network problem" message:@"You're offline, so the trip will be saved locally and backed up in the cloud when you're back online." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [problemAlert show];
        
    if ( isNew ) {
        [UnsyncedTrip createTripForEntityDecriptionAndLoadWithData:tripData objectId:nil];
    } else {
        NSError *error = nil;
        NSArray *results = [UnsyncedTrip fetchTripsWithId:objectId error:error];
        
        if ( !error && results && [results count] > 0 ) {
            // record already exists
            [[results objectAtIndex:0] setValue:tripData forKey:@"unsyncedObjInfo"];
            [[[MTCoreDataController sharedInstance] managedObjectContext] save:&error];
            
        } else {
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
//                                                               action:@selector(dateWasSelected:element:)
                                                               action:@selector(dateWasSelected:)
                                                               origin:touchedField];
    
    [self.actionSheetPicker addCustomButtonWithTitle:@"Today" value:[NSDate date]];
    [self.actionSheetPicker addCustomButtonWithTitle:@"Yesterday" value:[[NSDate date] TC_dateByAddingCalendarUnits:NSDayCalendarUnit amount:-1]];
    self.actionSheetPicker.hideCancel = NO;
    [self.actionSheetPicker showActionSheetPicker];
}

//- (void)dateWasSelected:(NSDate *)selDate element:(id)element
//{
//    self.selectedDate = selDate;
//    UITextField *currentField = (UITextField *)element;
//    currentField.text = [[[MTFormatting sharedUtility] dateFormatter] stringFromDate:selDate];
//}

- (void)dateWasSelected:(NSDictionary *)selectionObj
{
    self.selectedDate = [selectionObj objectForKey:@"selectedDate"];
    UITextField *currentField = (UITextField *)[selectionObj objectForKey:@"origin"];
    currentField.text = [[[MTFormatting sharedUtility] dateFormatter] stringFromDate:self.selectedDate];
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

-(BOOL) textFieldShouldReturn: (UITextField *) textField
{
    [textField resignFirstResponder];
    return YES;
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
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad || ( [[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait || [[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown) ) {
        return;
    }
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGRect bkgndRect = self.activeTextField.superview.frame;
    bkgndRect.size.height += kbSize.height;
    [self.activeTextField.superview setFrame:bkgndRect];
    [scrollView setContentOffset:CGPointMake(0.0, self.activeTextField.frame.origin.y-50) animated:YES];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
        return;
    }
    
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    contentInsets.top += 50;
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    NSLog(@"didSelectViewController");
}

@end
