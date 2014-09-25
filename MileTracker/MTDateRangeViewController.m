//
//  MTDateRangeViewController.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 3/17/14.
//  Copyright (c) 2014 Focus43. All rights reserved.
//

#import "MTDateRangeViewController.h"

@interface MTDateRangeViewController ()

@property (strong, nonatomic) UITextField *activeTextField;
@property (nonatomic, strong) MBProgressHUD *hud;

- (void)dateOrTimeFieldTouched:(UITextField *)touchedField;
- (NSString *)dataExportFilePath;

@end

@implementation MTDateRangeViewController

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
    // Do any additional setup after loading the view.
    [self.view setBackgroundColor:[MTViewUtils backGroundColor]];
    float deviceVersion   = [[[UIDevice currentDevice] systemVersion] intValue];
    if ( deviceVersion < 7.0 ) {
        self.exportBtn.titleLabel.textColor = [UIColor blackColor];
    }
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    UIDatePicker *startDatePicker = [[UIDatePicker alloc] init];
    startDatePicker.datePickerMode = UIDatePickerModeDate;
    self.startDateField.inputView = startDatePicker;
    UIDatePicker *endDatePicker = [[UIDatePicker alloc] init];
    endDatePicker.datePickerMode = UIDatePickerModeDate;
    self.endDateField.inputView = endDatePicker;
    [startDatePicker addTarget:self action:@selector(updateDate:) forControlEvents:UIControlEventValueChanged];
    [endDatePicker addTarget:self action:@selector(updateDate:) forControlEvents:UIControlEventValueChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)exportButtonTouched:(id)sender
{
    if ( [self.startDateField.text isEqualToString:@""] || [self.endDateField.text isEqualToString:@""] || !self.startDate || !self.endDate) {
        UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Missing dates" message:@"Please, enter start and end dates." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [problemAlert show];
        return;
    }
    
    NSArray *keys = [NSArray arrayWithObjects:@"userid", @"start", @"end", nil];
    NSArray *paramObjs = [NSArray arrayWithObjects:[PFUser currentUser].objectId, self.startDate, self.endDate, nil];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:paramObjs forKeys:keys];
    
    if (!self.hud) {
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.delegate = self;
    }
    
    self.hud.mode		= MBProgressHUDModeIndeterminate;
    self.hud.labelText	= @"Collecting Trips";
    self.hud.margin		= 30;
    self.hud.yOffset = 0;
    [self.hud show:YES];

    
    [PFCloud callFunctionInBackground:@"exportDataByDateRange" withParameters:parameters block:^(id result, NSError *error) {
        if (error) {
            NSLog(@"error! %@", error);
        } else {
            if ( result ) {
                if( error ) {
                    NSLog(@"%@", [error localizedDescription]);
                } else {
                    NSMutableString *writeString = [result objectForKey:@"data"];
                    NSLog(@"result = %@", writeString);
                    [self writeToDataFile:writeString];
                }
                
                
                NSString *subject = @"custom date range";
                
                // get file
                NSData *exportFile =[NSURL fileURLWithPath:[self dataExportFilePath]];
                NSArray *activityItems = [NSArray arrayWithObjects:exportFile, nil];
                // close hud
                if (self.hud) {
                    [self.hud hide:YES afterDelay:0.5];
                }
                // Open choice of action
                UIActivityViewController *actViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
                actViewController.excludedActivityTypes=[NSArray arrayWithObject:@"UIActivityTypeAirDrop"];
                [actViewController setValue:[NSString stringWithFormat:@"TripTrax mileage export for %@", subject] forKey:@"subject"];                [self presentViewController:actViewController animated:YES completion:nil];
                
            } else {
                
                UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"No trips" message:@"No trips were recorded in the chosen time period" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [problemAlert show];
                
            }
            
        }
        
        
    }];
}

- (IBAction)updateDate:(id)sender
{
    UIDatePicker *dp = (UIDatePicker *)sender;
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
	df.dateStyle = NSDateFormatterMediumStyle;
	self.activeTextField.text = [NSString stringWithFormat:@"%@", [df stringFromDate:dp.date]];
    
    if ( self.activeTextField == self.startDateField ) {
        self.startDate = dp.date;
    } else if ( self.activeTextField == self.endDateField ) {
        self.endDate = dp.date;
    }
}

- (IBAction)dateFieldTouched:(id)sender;
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
	df.dateStyle = NSDateFormatterMediumStyle;
    
    if ( self.activeTextField == self.startDateField ) {
        self.startDate = [NSDate date];
        self.startDateField.text = [NSString stringWithFormat:@"%@", [df stringFromDate:self.startDate]];
    } else if ( self.activeTextField == self.endDateField ) {
        self.endDate = self.startDate ? [self.startDate dateByAddingTimeInterval:60*60*24] : [[NSDate date] dateByAddingTimeInterval:60*60*24];
        self.endDateField.text = [NSString stringWithFormat:@"%@", [df stringFromDate:self.endDate]];
    }
    
    // hack to fix font bug
    self.activeTextField.font = [UIFont fontWithName:@"Helvetica Neue" size:17];
}

- (void)dismissKeyboard
{
    [self.activeTextField resignFirstResponder];
}

# pragma mark - Text Field Delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
    
    return true;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
}

//- (void)textFieldDidEndEditing:(UITextField *)textField
//{
//    self.activeTextField = nil;
//}

-(BOOL) textFieldShouldReturn: (UITextField *) textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -- report file creation
- (NSString *)dataExportFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"trips_export.csv"];
}

- (NSString *)reportStringFromTrips:(NSArray *)trips
{
    NSMutableString *writeString = [NSMutableString stringWithCapacity:0];
    [writeString appendString:@"title, date, startOdometer, endOdometer, trip distance (mi)\n"];
    
    for (int i=0; i<[trips count]; i++) {
        PFObject *trip = [trips objectAtIndex:i];
        [writeString appendString:[NSString stringWithFormat:@"\"%@\", %@, %@, %@, %@\n", [trip objectForKey:@"title"] , [trip tr_dateToString], [trip objectForKey:@"startOdometer" ], [trip objectForKey:@"endOdometer"], [trip tr_totalTripDistance]]];
    }
    
    return writeString;
}

- (void)writeToDataFile:(NSString *)tripExportString
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self dataExportFilePath]]) {
        [[NSFileManager defaultManager] removeItemAtPath:[self dataExportFilePath] error:nil];
    }
    
    [[NSFileManager defaultManager] createFileAtPath:[self dataExportFilePath] contents:nil attributes:nil];
    
    NSFileHandle *handle;
    handle = [NSFileHandle fileHandleForWritingAtPath: [self dataExportFilePath] ];
    [handle truncateFileAtOffset:[handle seekToEndOfFile]];
    [handle writeData:[tripExportString dataUsingEncoding:NSUTF8StringEncoding]];
}


@end
