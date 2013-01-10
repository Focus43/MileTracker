//
//  MTLogTableViewCell.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 12/27/12.
//  Copyright (c) 2012 Focus43. All rights reserved.
//

#import "MTLogTableViewCell.h"

@implementation MTLogTableViewCell

@synthesize dateLabel, titleLabel, distanceLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
