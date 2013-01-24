//
//  MTTripViewController.h
//  MileTracker
//
//  Created by Stine Richvoldsen on 12/14/12.
//  Copyright (c) 2012 Focus43. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

#import "ActionSheetPicker.h"
//#import "Trip.h"

@interface MTTripViewController : UIViewController <UITextFieldDelegate, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>

// TODO: combine these two
@property (nonatomic, strong) PFObject *trip;
@property (nonatomic, strong) PFObject *tripObj;

@property (strong, nonatomic) IBOutlet UITextField *titleField;
@property (strong, nonatomic) IBOutlet UITextField *dateField;
@property (strong, nonatomic) IBOutlet UITextField *startOdometerField;
@property (strong, nonatomic) IBOutlet UITextField *endOdometerField;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic, retain) AbstractActionSheetPicker *actionSheetPicker;
@property (nonatomic, strong) NSDate *selectedDate;

@property (nonatomic, strong) NSNumberFormatter *numberFormatter;

- (IBAction)saveButtonTouched:(id)sender;

@end
