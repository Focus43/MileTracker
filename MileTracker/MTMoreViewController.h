//
//  MTMoreViewController.h
//  MileTracker
//
//  Created by Stine Richvoldsen on 1/4/13.
//  Copyright (c) 2013 Focus43. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface MTMoreViewController : UITableViewController <UITextFieldDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UILabel *savingsLabel;
@property (strong, nonatomic) IBOutlet UILabel *loginLabel;

@end
