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
    BOOL typePickerShouldOpen;
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
@property (nonatomic, strong) NSArray *typeOptions;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *startLocation;
@property (strong, nonatomic) CLLocation *lastLocation;
@property (strong, nonatomic) CLLocation *endLocation;
@property (assign, nonatomic) CLLocationDistance distanceTraveled;
@property (strong, nonatomic) NSNumber *totalMileage;
@property (assign, nonatomic) float gpsStartOdometer;

@end

@implementation MTTripViewController

// Can't help myself. Still doing this...
@synthesize dateField, titleField, startOdometerField, endOdometerField;
@synthesize selectedDate;
@synthesize originalCenter, activeTextField;
@synthesize trip, numberFormatter, networkReachability;
@synthesize hud=_hud;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[MTViewUtils backGroundColor]];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    _typeOptions = kTripTypeOptions;
    self.tripTypePicker.dataSource = self;
    self.tripTypePicker.delegate = self;
    
    [_trackButton setImage:[UIImage imageNamed:@"gps_white.png"] forState:UIControlStateNormal];
    
    if ( !self.numberFormatter ) {
        self.numberFormatter = [[NSNumberFormatter alloc] init];
        [self.numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    }

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                               initWithTarget:self
                               action:@selector(dismissKeyboard)];

    [self.scrollView addGestureRecognizer:tap];
    [self.scrollView setMinimumZoomScale:0.1];
    shouldResetScroll = NO;
    
    self.titleField.delegate = self;
    self.dateField.delegate = self;
    self.startOdometerField.delegate = self;
    self.endOdometerField.delegate = self;
    
    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
    datePicker.datePickerMode = UIDatePickerModeDate;
    self.dateField.inputView = datePicker;
    [datePicker addTarget:self action:@selector(updateDate:) forControlEvents:UIControlEventValueChanged];
    
    self.networkReachability = [Reachability reachabilityForInternetConnection];
    
    if (nil == _locationManager)
        _locationManager = [[CLLocationManager alloc] init];
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locationManager.delegate = self;
    self.locationManager.distanceFilter = 10; // meters

    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [_locationManager requestWhenInUseAuthorization];
    }
    
    // if editing
    if (self.trip) {
        self.titleField.text = [self.trip objectForKey:@"title"];
        self.dateField.text = [self.trip tr_dateToString];
        self.startOdometerField.text = [self.trip tr_startOdometerToString];
        self.endOdometerField.text = [self.trip tr_endOdometerToString];
        self.distanceLabel.text = (![(NSNumber *)[self.trip objectForKey:@"distance"] isEqualToNumber:[NSNumber numberWithInt:-1]]) ? [NSString stringWithFormat:@"Distance: %@", [self.trip tr_totalDistanceString]] : @"";
        
        NSString *typeStr = [self.trip objectForKey:@"type"] ? [self.trip objectForKey:@"type"] : kTripTypeBusiness;
        [_typeButton setTitle:[NSString stringWithFormat:@"  %@", typeStr] forState:UIControlStateNormal];
        [_typeButton setImage:[self cellImageByType:typeStr] forState:UIControlStateNormal];
    } else {
        [_typeButton setTitle:[NSString stringWithFormat:@"  %@", kTripTypeBusiness] forState:UIControlStateNormal];
        [_typeButton setImage:[self cellImageByType:kTripTypeBusiness] forState:UIControlStateNormal];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self registerForKeyboardNotifications];
    
    self.originalCenter = self.view.center;
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

- (UIImage *)cellImageByType:(NSString *)type
{
    NSString *imageName;
    if ( !type || [type isEqualToString:kTripTypeBusiness] ) {
        imageName = @"briefcase.png";
    } else if ( [type isEqualToString:kTripTypeCharitable] ) {
        imageName = @"heart.png";
    } else if ( [type isEqualToString:kTripTypePersonal] ) {
        imageName = @"user.png";
    } else {
        return NULL;
    }
    
    return [UIImage imageNamed:imageName];
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
    self.selectedDate = [NSDate date];
}

- (IBAction)updateDate:(id)sender
{
    UIDatePicker *dp = (UIDatePicker *)sender;
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
	df.dateStyle = NSDateFormatterMediumStyle;
	self.dateField.text = [NSString stringWithFormat:@"%@", [df stringFromDate:dp.date]];
    self.selectedDate = dp.date;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 3) { // this is my picker cell
        if (typePickerShouldOpen) {
            return 219;
        } else {
            return 0;
        }
    } else {
        return self.tableView.rowHeight;
    }
}

- (IBAction)typeButtonTouched:(id)sender
{
    [self dismissKeyboard];
    typePickerShouldOpen = !typePickerShouldOpen;

    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:3 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadData];
    self.tripTypePicker.hidden = NO;

    [self.tripTypePicker selectRow:[_typeOptions indexOfObject:[_typeButton.titleLabel.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]] inComponent:0 animated:YES];
}

- (IBAction)trackButtonTouched:(id)sender
{
    if ( [_trackButton.currentTitle isEqualToString:@"  Start Tracking"] ) {
        
        
        if ( ![CLLocationManager locationServicesEnabled] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ) {
            UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"GPS not available"
                                                                   message:@"GPS tracking is turned off. If you would like, you can turn it back on again in settings."
                                                                  delegate:nil
                                                         cancelButtonTitle:@"OK"
                                                         otherButtonTitles:nil];
            [problemAlert show];

        } else {
            _distanceTraveled = 0;
            
            self.startOdometerField.text = @"";
            self.startOdometerField.enabled = NO;
            self.startOdometerField.borderStyle = UITextBorderStyleBezel;
            self.startOdometerField.backgroundColor = [UIColor lightGrayColor];
            self.endOdometerField.text = @"";
            self.endOdometerField.enabled = NO;
            self.endOdometerField.borderStyle = UITextBorderStyleBezel;
            self.endOdometerField.backgroundColor = [UIColor lightGrayColor];
            
            [_trackButton setTitle:@"  Stop Tracking" forState:UIControlStateNormal];
            // start tracking
            [_trackButton startFlashing];
            _startLocation = nil;
            [_locationManager startUpdatingLocation];
        }
        
    } else {
        [_locationManager stopUpdatingLocation];
        [_trackButton setTitle:@"  Start Tracking" forState:UIControlStateNormal];
        [_trackButton stopFlashing];
    }
}

- (IBAction)saveButtonTouched:(id)sender
{
    // stop tracking
    [_locationManager stopUpdatingLocation];
    [_trackButton setTitle:@"  Start Tracking" forState:UIControlStateNormal];
    [_trackButton stopFlashing];
    
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
        
        if ( [self.trip objectForKey:@"distance"] && (![self.startOdometerField.text isEqualToString:@""] || ![self.endOdometerField.text  isEqualToString:@""]) ) {
            [self.trip setObject:[NSNumber numberWithInt:-1] forKey:@"distance"];
            totalDistance = -1;
        } else if ( [self.trip objectForKey:@"distance"] ) {
            totalDistance = [[self.trip objectForKey:@"distance"] floatValue];
        }
    }
    
    if ( ![self.dateField.text isEqualToString:@""] || ![self.titleField.text isEqualToString:@""] ) {
        
        NSNumber *start = [self.numberFormatter numberFromString:self.startOdometerField.text];
        if (!start) start = [NSNumber numberWithInt:0];
        
        NSNumber *end = [self.numberFormatter numberFromString:self.endOdometerField.text];
        if (!end) end = [NSNumber numberWithInt:0];
        
        PFUser *currentUser = [PFUser currentUser];
        if (!currentUser) {
            (NSString *)currentUser;
            currentUser = @"anonymous";
        }
        
        NSDate *tripDate = self.selectedDate ? self.selectedDate : [self.trip objectForKey:@"date"];
        NSString *objectId = (self.trip) ? self.trip.objectId : @"";
        
        totalDistance = (totalDistance == 0) ? -1 : totalDistance;
        
        NSArray *data = [NSArray arrayWithObjects:self.titleField.text, tripDate, [_typeButton.titleLabel.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]], start, end, currentUser, [NSNumber numberWithFloat:totalDistance], nil];
        NSArray *keys = [NSArray arrayWithObjects:@"title", @"date", @"type", @"startOdometer", @"endOdometer", @"user", @"distance", nil];
        NSMutableDictionary *tripData = [NSDictionary dictionaryWithObjects:data forKeys:keys];
        
        // reset distance traveled back to 0
        _distanceTraveled = 0;
        
        PFObject *tripToSave = [PFObject tr_objectWithData:tripData objectId:objectId];
        
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
                            
//                            if ( savedStr != NULL && ![savedStr isEqualToString:@""] ) {
//                                savingsStr = [NSString stringWithFormat:@". So far this year, you have logged enough miles to deduct %@ on your taxes!", savedStr];
//                            } else {
                                savingsStr = @".";
//                            }
                            
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
                                        
                    if (self.hud) {
                        [self.hud hide:YES afterDelay:1.5];
                    }

                    if (!self.hud) {
                        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                        self.hud.delegate = self;
                    }
                    
                    self.hud.mode		= MBProgressHUDModeText;
                    self.hud.labelText	= message;
                    self.hud.margin		= 30;
                    self.hud.yOffset = 0;
                    [self.hud show:YES];
                    
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
            self.distanceLabel.text = @"";
        }
        
        _startLocation = nil;
    
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
    CLLocation *newLocation = [locations lastObject];
    if (newLocation.horizontalAccuracy < 20) {
    
        if (_startLocation == nil) {
            _startLocation = [locations lastObject];
            _lastLocation = [locations lastObject];
        }
        
        _distanceTraveled += [[locations lastObject] distanceFromLocation:_lastLocation];
        // keep this location for next update
        _lastLocation = [locations lastObject];


        float divisor = ( [[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsLengthUnit]  isEqual: kUserDefaultsLengthUnitMile] ) ? 1609.344 : 1000.00;
        NSString *endString = [NSString stringWithFormat:@"Distance: %d %@", (int)roundf((_distanceTraveled / divisor)), [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsLengthUnit]];
        
        self.distanceLabel.text = endString;
        totalDistanceDisplay = _distanceTraveled / divisor;
        totalDistance = _distanceTraveled;
        
        if ( [CLLocationManager deferredLocationUpdatesAvailable] )
            [_locationManager allowDeferredLocationUpdatesUntilTraveled:CLLocationDistanceMax timeout:CLTimeIntervalMax];
    }
}

-(void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error
{
//    NSString *stringError = [NSString stringWithFormat:@"error: %@",[error description]];
//    TFLog(@"didFinishDeferredUpdatesWithError: %@", stringError);
//    NSLog(@"didFinishDeferredUpdatesWithError: %@", stringError);
}

# pragma mark - Text Field Delegate methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
    if ( self.trip && !([[self.trip objectForKey:@"distance"] floatValue] <= 0.0) && (textField == self.startOdometerField || textField == self.endOdometerField) ) {
        UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"" message:@"Adding odometer reading will delete the distance previously tracked with GPS." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [problemAlert show];
    }
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

#pragma mark - picker view delegate

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString *typeStr = [_typeOptions objectAtIndex:row];
    [_typeButton setTitle:[NSString stringWithFormat:@"  %@", typeStr] forState:UIControlStateNormal];
    [_typeButton setImage:[self cellImageByType:typeStr] forState:UIControlStateNormal];
}

# pragma mark - picker view data source

- (int)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (int)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return _typeOptions.count;
}

- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return _typeOptions[row];
}

# pragma mark - table view

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.textColor = [UIColor whiteColor];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 35;
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
        [_scrollView setContentOffset:scrollPoint animated:YES];
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
