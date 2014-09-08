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
#import "PFObject+Trip.h"

@interface MTTripViewController () {
    float totalDistance;
    float totalDistanceDisplay;
    BOOL shouldResetScroll;
}

- (void)showCannotSaveAlert;
- (void)dateOrTimeFieldTouched:(UITextField *)touchedField;
- (void)registerForKeyboardNotifications;
- (void)dismissKeyboard;
- (void)saveLocalVersionTripData:(NSDictionary *)tripData withNewFlag:(BOOL)flag objectId:(NSString *)objectId;

@property (strong, nonatomic) UITextField *activeTextField;
@property CGPoint originalCenter;
@property (nonatomic, strong) Reachability *networkReachability;
@property (nonatomic, strong) MBProgressHUD *hud;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *startLocation;
@property (strong, nonatomic) CLLocation *endLocation;
@property (strong, nonatomic) NSNumber *totalMileage;
@property (assign, nonatomic) float gpsStartOdometer;

@end

@implementation MTTripViewController

// Can't help myself. Still doing this...
@synthesize dateField, titleField, startOdometerField, endOdometerField;
@synthesize selectedDate;
@synthesize originalCenter, activeTextField, scrollView;
@synthesize trip, numberFormatter, networkReachability;
@synthesize hud=_hud;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[MTViewUtils backGroundColor]];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    [_trackButton setImage:[UIImage imageNamed:@"gps_white.png"] forState:UIControlStateNormal];
//    [_trackButton setImageEdgeInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    
    if ( !self.numberFormatter ) {
        self.numberFormatter = [[NSNumberFormatter alloc] init];
        [self.numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    }

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                               initWithTarget:self
                               action:@selector(dismissKeyboard)];

    [self.scrollView addGestureRecognizer:tap];
    shouldResetScroll = NO;
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
    self.dateField.inputView = datePicker;
    [datePicker addTarget:self action:@selector(updateDate:) forControlEvents:UIControlEventValueChanged];
    
    self.networkReachability = [Reachability reachabilityForInternetConnection];
    
    if (nil == _locationManager)
        _locationManager = [[CLLocationManager alloc] init];
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locationManager.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self registerForKeyboardNotifications];
    
    self.originalCenter = self.view.center;
    
    // if editing
    if (self.trip) {
        self.titleField.text = [self.trip objectForKey:@"title"];
        self.dateField.text = [self.trip tr_dateToString];
        self.startOdometerField.text = [self.trip tr_startOdometerToString];
        self.endOdometerField.text = [self.trip tr_endOdometerToString];
        self.distanceLabel.text = [self.trip tr_totalDistanceString];
    }

}

- (void)viewWillDisappear:(BOOL)animated {
    
    [self deregisterFromKeyboardNotifications];
    
    [super viewWillDisappear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showCannotSaveAlert
{
    UIAlertView *cannotSaveAlert = [[UIAlertView alloc] initWithTitle:@"Uh oh..." message:@"You must enter a date or destination" delegate:nil cancelButtonTitle:@"Duh!" otherButtonTitles:nil];
    [cannotSaveAlert show];
}

- (IBAction)dateFieldTouched:(id)sender
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
	df.dateStyle = NSDateFormatterMediumStyle;
	self.dateField.text = [NSString stringWithFormat:@"%@", [df stringFromDate:[NSDate date]]];
}

- (IBAction)updateDate:(id)sender
{
    UIDatePicker *dp = (UIDatePicker *)sender;
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
	df.dateStyle = NSDateFormatterMediumStyle;
	self.dateField.text = [NSString stringWithFormat:@"%@", [df stringFromDate:dp.date]];
}

- (IBAction)trackButtonTouched:(id)sender
{
    if ( [_trackButton.currentTitle isEqualToString:@"  Start Tracking"] ) {
        
//        UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"GPS not available"
//                                                               message:@"GPS tracking is turned off. If you would like, you can turn it back on again in settings."
//                                                              delegate:nil
//                                                     cancelButtonTitle:@"OK"
//                                                     otherButtonTitles:nil];
//        [problemAlert show];
        
        
        self.startOdometerField.text = @"";
        self.endOdometerField.text = @"";
        
        [_trackButton setTitle:@"  Stop Tracking" forState:UIControlStateNormal];
        // start tracking
        [_trackButton startFlashing];
        _startLocation = nil;
        [_locationManager startUpdatingLocation];
        
    } else {
        [_locationManager stopUpdatingLocation];
        TFLog(@"stop updating. total dist = %f", totalDistance);
        [_trackButton setTitle:@"  Start Tracking" forState:UIControlStateNormal];
        [_trackButton stopFlashing];
    }
}

- (IBAction)saveButtonTouched:(id)sender
{
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
    
    if ( ![self.dateField.text isEqualToString:@""] || ![self.titleField.text isEqualToString:@""] ) {
        
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
        
        NSArray *data = [NSArray arrayWithObjects:self.titleField.text, tripDate, start, end, currentUser, [NSNumber numberWithFloat:totalDistance], nil];
        NSArray *keys = [NSArray arrayWithObjects:@"title", @"date", @"startOdometer", @"endOdometer", @"user", @"distance", nil];
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
            self.hud.yOffset = 0;
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

# pragma mark - Location Manager Delegate methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    TFLog(@"didUpdateLocations - locations: %@", locations);
    
    if (_startLocation == nil)
        _startLocation = [locations lastObject];
    
    _gpsStartOdometer = [self.startOdometerField.text integerValue];
    
    CLLocationDistance distanceBetween = [[locations lastObject] distanceFromLocation:_startLocation];

    float divisor = ( [[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsLengthUnit]  isEqual: kUserDefaultsLengthUnitMile] ) ? 1609.344 : 1000.00;
    NSString *endString = [NSString stringWithFormat:@"Total Distance: %d %@", (int)roundf(_gpsStartOdometer + (distanceBetween / divisor)), [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsLengthUnit]];
    
    self.distanceLabel.text = endString;
    totalDistanceDisplay = distanceBetween / divisor;
    totalDistance = distanceBetween;
    
    if ( [CLLocationManager deferredLocationUpdatesAvailable] )
        [_locationManager allowDeferredLocationUpdatesUntilTraveled:CLLocationDistanceMax timeout:CLTimeIntervalMax];
}

-(void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error
{
    NSString *stringError = [NSString stringWithFormat:@"error: %@",[error description]];
    TFLog(@"didFinishDeferredUpdatesWithError: %@", stringError);
}

# pragma mark - Text Field Delegate methods

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

- (void)deregisterFromKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
}

- (void)keyboardWasShown:(NSNotification*)notification
{
    NSDictionary* info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    CGRect visibleRect = self.view.frame;
    visibleRect.size.height -= keyboardSize.height;

    if ( !CGRectContainsPoint(visibleRect, self.activeTextField.frame.origin) ){
        CGPoint scrollPoint = CGPointMake(0.0, self.activeTextField.frame.origin.y - self.activeTextField.frame.size.height);
        [scrollView setContentOffset:scrollPoint animated:YES];
        shouldResetScroll = YES;
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    if ( shouldResetScroll ) {
        [self.scrollView setContentOffset:CGPointZero animated:YES];
        shouldResetScroll = NO;
    }
}


@end
