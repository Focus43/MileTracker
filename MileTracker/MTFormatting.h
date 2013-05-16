//
//  MTFormattingUtilitites.h
//  MileTracker
//
//  Created by Stine Richvoldsen on 1/9/13.
//  Copyright (c) 2013 Focus43. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTFormatting : NSObject

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;
@property (strong, nonatomic) NSNumberFormatter *currencyFormatter;

+ (MTFormatting *)sharedUtility;
- (id)init;

@end
