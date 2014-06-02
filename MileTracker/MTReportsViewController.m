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
- (PFQuery *)queryFromReportTableSelection:(NSIndexPath *)indexPath;

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( ![PFUser currentUser].sessionToken ) {
        
        UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"You have to be logged in for access to this feature." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [problemAlert show];
        
    } else if ( [indexPath row] != 5 ) {
        
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
                    
                    // [self createEmailWithSubject:subject];
                    
                    // get file
                    NSData *exportFile =[NSURL fileURLWithPath:[self dataExportFilePath]];
                    NSArray *activityItems = [NSArray arrayWithObjects:exportFile, nil];
                    
                    // Open choice of action
                    UIActivityViewController *actViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
                    actViewController.excludedActivityTypes=@[UIActivityTypeAirDrop];
                    [actViewController setValue:[NSString stringWithFormat:@"TripTrax mileage export for %@", subject] forKey:@"subject"];
                    
//                    [actViewController setCompletionHandler:^(NSString *activityType, BOOL completed) {
//                        NSLog(@"completed dialog - activity: %@ - finished flag: %d", activityType, completed);
//                    }];
                    
                    [self presentViewController:actViewController animated:YES completion:nil];
                    
                } else {
                    
                    UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"No trips" message:@"No trips were recorded in the chosen time period" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [problemAlert show];
                    
                }
                
            }
            
            
        }];
    }    
}

#pragma mark -- UIActivityItemSource methods
//- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(NSString *)activityType
//{
//    return @"TripTrax export";
//}
//
//- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType {
//    if ([activityType isEqualToString:UIActivityTypeMail]) {
//        NSURL *exportFile = [NSURL fileURLWithPath:[self dataExportFilePath]];
//        NSArray *items = [NSArray arrayWithObjects:exportFile, nil];
////        NSArray *items = @[@"message mail", [NSURL fileURLWithPath:[self dataExportFilePath]]];
//        return items;
//    }
//    
//    NSArray *items = @[@"Not a proper Activity", [NSURL URLWithString:@"http://www.myUrlMail.com"]];
//    return items;
//}
//
//- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController {
//    return [NSURL fileURLWithPath:[self dataExportFilePath]];
//}

#pragma mark -- report file creation
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
    query.limit = 1000;
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

@end
