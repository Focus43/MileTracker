//
//  MTReportsViewController.h
//  MileTracker
//
//  Created by Stine Richvoldsen on 1/2/13.
//  Copyright (c) 2013 Focus43. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface MTReportsViewController : UITableViewController <MFMailComposeViewControllerDelegate, UIActivityItemSource>

@property (nonatomic, strong) IBOutlet UILabel *label1;
@property (nonatomic, strong) IBOutlet UILabel *label2;
@property (nonatomic, strong) IBOutlet UILabel *label3;
@property (nonatomic, strong) IBOutlet UILabel *label4;
@property (nonatomic, strong) IBOutlet UILabel *label5;
@property (nonatomic, strong) IBOutlet UILabel *label6;

@end
