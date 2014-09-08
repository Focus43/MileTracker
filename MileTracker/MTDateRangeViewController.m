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

- (void)dateOrTimeFieldTouched:(UITextField *)touchedField
{
    NSDate *pickerDate = [NSDate date];
    
    _actionSheetPicker = [[ActionSheetDatePicker alloc] initWithTitle:@""
                                                       datePickerMode:UIDatePickerModeDate
                                                         selectedDate:pickerDate
                                                               target:self
                                                               action:@selector(dateWasSelected:)
                                                               origin:touchedField];

    [self.actionSheetPicker addCustomButtonWithTitle:@"Today" value:[NSDate date]];
    self.actionSheetPicker.hideCancel = NO;
    [self.actionSheetPicker showActionSheetPicker];
}


- (void)dateWasSelected:(NSDictionary *)selectionObj
{
    UITextField *currentField = (UITextField *)[selectionObj objectForKey:@"origin"];
    
    if ( currentField == self.startDateField ) {
        self.startDate = [selectionObj objectForKey:@"selectedDate"];
        self.startDateField.text = [[[MTFormatting sharedUtility] dateFormatter] stringFromDate:self.startDate];
    } else if ( currentField == self.endDateField ) {
        self.endDate = [selectionObj objectForKey:@"selectedDate"];
        self.endDateField.text = [[[MTFormatting sharedUtility] dateFormatter] stringFromDate:self.endDate];
    }
}

# pragma mark - Text Field Delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if ( textField == self.startDateField || textField == self.endDateField ) {
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
