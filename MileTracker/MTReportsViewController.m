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

- (NSDate *)dateSetToMidnightUsingComponents:(NSDateComponents *)components;
- (NSString *)dataExportFilePath;
- (NSString *)reportStringFromTrips:(NSArray *)trips;
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
    
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setColor:[UIColor blackColor]];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setShadowOffset:CGSizeMake(0.0, 0.0)];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setFont:[UIFont systemFontOfSize:17.0]];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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

// TODO: move next 3 methods to the Trip model?

- (PFQuery *)queryFromReportTableSelection:(NSIndexPath *)indexPath
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
    
    PFQuery *query = [PFQuery queryWithClassName:kPFObjectClassName];
    [query whereKey:@"date" lessThanOrEqualTo:[self dateSetToMidnightUsingComponents:endComponents]];
    [query whereKey:@"date" greaterThan:[self dateSetToMidnightUsingComponents:startComponents]];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    
    return query;
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

- (void)createEmailWithSubject:(NSString *)subject
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;
        [controller setSubject:[@"Mileage for " stringByAppendingString:subject]];
        [controller setMessageBody:[@"Attached is a tab delimited file with a list of business related trips from " stringByAppendingString:subject] isHTML:NO];
        
        NSData *exportData = [NSData dataWithContentsOfFile:[self dataExportFilePath]];
        [controller addAttachmentData:exportData mimeType:@"application/octet-stream" fileName:[[subject stringByReplacingOccurrencesOfString:@" " withString:@"_"] stringByAppendingString:@".csv"]];
        
        if (controller) [self presentModalViewController:controller animated:YES];
        
    } else {
        UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Looks like your device needs to be configured to send email. Update your settings and come back hrere and try again!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [problemAlert show];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // data selection logic
    PFQuery *query = [self queryFromReportTableSelection:indexPath];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (error) {
            NSLog(@"error! %@", error);
        } else {
            
            if ( [objects count] > 0 ) {
                
                NSMutableString *writeString = [self reportStringFromTrips:objects];
                
                [self writeToDataFile:writeString];
                
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
                
                [self createEmailWithSubject:subject];
                
            } else {
                
                UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"No trips" message:@"No trips were recorded in the chosen time period" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [problemAlert show];
                
            }
            
        }
         
        
    }];

}
#pragma mark - Mail Compose View Controller delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        NSLog(@"It's away!");
    }
    [self dismissModalViewControllerAnimated:YES];
}

@end
