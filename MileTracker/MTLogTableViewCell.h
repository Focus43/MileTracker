//
//  MTLogTableViewCell.h
//  MileTracker
//
//  Created by Stine Richvoldsen on 12/27/12.
//  Copyright (c) 2012 Focus43. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTLogTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UILabel *distanceLabel;

@end
