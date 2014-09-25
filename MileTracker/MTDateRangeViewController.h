//
//  MTDateRangeViewController.h
//  MileTracker
//
//  Created by Stine Richvoldsen on 3/17/14.
//  Copyright (c) 2014 Focus43. All rights reserved.
//

#import "MTReportsViewController.h"

@interface MTDateRangeViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *startDateField;
@property (strong, nonatomic) IBOutlet UITextField *endDateField;
@property (strong, nonatomic) IBOutlet MTButton *exportBtn;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSDate *endDate;

- (IBAction)exportButtonTouched:(id)sender;
- (IBAction)dateFieldTouched:(id)sender;

@end
