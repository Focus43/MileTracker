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

@interface MTTripViewController : UIViewController <UITextFieldDelegate, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>

@property (nonatomic, strong) PFObject *trip;

@property (strong, nonatomic) IBOutlet UITextField *titleField;
@property (strong, nonatomic) IBOutlet UITextField *dateField;
@property (strong, nonatomic) IBOutlet UITextField *startOdometerField;
@property (strong, nonatomic) IBOutlet UITextField *endOdometerField;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet ADBannerView *adView;

@property (nonatomic, retain) AbstractActionSheetPicker *actionSheetPicker;
@property (nonatomic, strong) NSDate *selectedDate;

@property (nonatomic, strong) NSNumberFormatter *numberFormatter;

- (IBAction)saveButtonTouched:(id)sender;

@end
