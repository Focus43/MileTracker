//
//  MTReportsViewController.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 1/2/13.
//  Copyright (c) 2013 Focus43. All rights reserved.
//

#import "MTReportsViewController.h"
#import <Parse/Parse.h>
#import <Foundation/Foundation.h>

@interface MTReportsViewController ()

@property (nonatomic, strong) MBProgressHUD *hud;

- (NSDate *)dateSetToMidnightUsingComponents:(NSDateComponents *)components;
- (NSString *)dataExportFilePath;
- (void)writeToDataFile:(NSString *)tripExportString;
- (void)createEmailWithSubject:(NSString *)subject;

@end

@implementation MTReportsViewController

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
    
    // Hack to fix the layout on iPad
    if ([[UIDevice currentDevice].model isEqualToString:@"iPad"] ) {
        self.label1.text = [NSString stringWithFormat:@"              %@", self.label1.text];
        self.label2.text = [NSString stringWithFormat:@"              %@", self.label2.text];
        self.label3.text = [NSString stringWithFormat:@"              %@", self.label3.text];
        self.label4.text = [NSString stringWithFormat:@"              %@", self.label4.text];
        self.label5.text = [NSString stringWithFormat:@"              %@", self.label5.text];
        self.label6.text = [NSString stringWithFormat:@"              %@", self.label6.text];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source

- (NSString *)dataExportFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"trips_export.csv"];
}

- (NSDate *)dateSetToMidnightUsingComponents:(NSDateComponents *)components
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [gregorian setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    
    return [gregorian dateFromComponents: components];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor whiteColor]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( ![PFUser currentUser].sessionToken ) {
        
        UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You have to be logged in for access to this feature." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [problemAlert show];
        
    } else if ( [indexPath row] != 5 ) {
        
        NSDictionary *params = [self getReportParamsFromTableSelection:indexPath];
        
        if (!self.hud) {
            _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.hud.delegate = self;
        }
        
        self.hud.mode		= MBProgressHUDModeIndeterminate;
        self.hud.labelText	= @"Collecting Trips";
        self.hud.margin		= 30;
        self.hud.yOffset = 0;
        [self.hud show:YES];
        
        // data selection logic
        [PFCloud callFunctionInBackground:@"exportDataByDateRange" withParameters:params block:^(id result, NSError *error) {
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
                    
                    
                    NSString *subject = @"";
                    switch ([indexPath row]) {
                        case 0:
                            subject = [subject stringByAppendingString:@"1st quarter"];
                            break;
                        case 1:
                            subject = [subject stringByAppendingString:@"2nd quarter"];
                            break;
                        case 2:
                            subject = [subject stringByAppendingString:@"3rd quarter"];
                            break;
                        case 3:
                            subject = [subject stringByAppendingString:@"4th quarter"];
                            break;
                        case 4:
                            subject = [subject stringByAppendingString:@"last year"];
                            break;
                    }
                    
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
                    [actViewController setValue:[NSString stringWithFormat:@"TripTrax mileage export for %@", subject] forKey:@"subject"];
                    [self presentViewController:actViewController animated:YES completion:nil];
                    
                } else {
                    
                    UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"No trips" message:@"No trips were recorded in the chosen time period" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [problemAlert show];
                    
                }
                
            }
            
            
        }];
    }    
}

- (NSDictionary *)getReportParamsFromTableSelection:(NSIndexPath *) indexPath
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *componentsForToday = [gregorian components:NSUIntegerMax fromDate:[NSDate date]];
    
    NSDateComponents *startComponents = [[NSDateComponents alloc] init];
    [startComponents setHour:0];
    [startComponents setMinute:0];
    [startComponents setSecond:0];
    NSDateComponents *endComponents = [[NSDateComponents alloc] init];
    [endComponents setHour:0];
    [endComponents setMinute:0];
    [endComponents setSecond:0];
    
    switch ([indexPath row]) {
        case 0: // 1st quarter
            [startComponents setYear:([componentsForToday year] - 1)];
            [startComponents setMonth:12];
            [startComponents setDay:31];
            [endComponents setYear:[componentsForToday year]];
            [endComponents setMonth:3];
            [endComponents setDay:31];
            break;
        case 1: // 2nd quarter
            [startComponents setYear:[componentsForToday year]];
            [startComponents setMonth:3];
            [startComponents setDay:31];
            [endComponents setYear:[componentsForToday year]];
            [endComponents setMonth:6];
            [endComponents setDay:30];
            break;
        case 2: // 3rd quarter
            [startComponents setYear:[componentsForToday year]];
            [startComponents setMonth:6];
            [startComponents setDay:30];
            [endComponents setYear:[componentsForToday year]];
            [endComponents setMonth:9];
            [endComponents setDay:30];
            break;
        case 3: // 4th quarter
            [startComponents setYear:[componentsForToday year]];
            [startComponents setMonth:9];
            [startComponents setDay:30];
            [endComponents setYear:[componentsForToday year]];
            [endComponents setMonth:12];
            [endComponents setDay:31];
            break;
        case 4: //last year
            [startComponents setYear:([componentsForToday year] - 2)];
            [startComponents setMonth:12];
            [startComponents setDay:31];
            [endComponents setYear:([componentsForToday year] - 1)];
            [endComponents setMonth:12];
            [endComponents setDay:31];
            break;
        default:
            break;
    }
    
    NSArray *keys = [NSArray arrayWithObjects:@"userid", @"start", @"end", nil];
    NSArray *paramObjs = [NSArray arrayWithObjects:[PFUser currentUser].objectId, [self dateSetToMidnightUsingComponents:startComponents], [self dateSetToMidnightUsingComponents:endComponents], nil];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjects:paramObjs forKeys:keys];
    
    return parameters;
    
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
