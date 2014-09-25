//
//  MTTripViewController.h
//  MileTracker
//
//  Created by Stine Richvoldsen on 12/14/12.
//  Copyright (c) 2012 Focus43. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface MTTripViewController : UIViewController <UITextFieldDelegate, CLLocationManagerDelegate, UIPickerViewDelegate>

@property (nonatomic, strong) PFObject *trip;

@property (strong, nonatomic) IBOutlet UITextField *titleField;
@property (strong, nonatomic) IBOutlet UITextField *dateField;
@property (strong, nonatomic) IBOutlet UITextField *startOdometerField;
@property (strong, nonatomic) IBOutlet UITextField *endOdometerField;
@property (strong, nonatomic) IBOutlet UILabel *distanceLabel;
@property (strong, nonatomic) IBOutlet MTButton *trackButton;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) NSDate *selectedDate;

@property (nonatomic, strong) NSNumberFormatter *numberFormatter;

- (IBAction)dateFieldTouched:(id)sender;
- (IBAction)saveButtonTouched:(id)sender;
- (IBAction)trackButtonTouched:(id)sender;

@end
