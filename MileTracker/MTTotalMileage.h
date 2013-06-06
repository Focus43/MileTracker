//
//  MTTotalMileage.h
//  MileTracker
//
//  Created by Stine Richvoldsen on 5/15/13.
//  Copyright (c) 2013 Focus43. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTTotalMileage : NSObject

- (NSNumber *)getCurrentTotalMileage;
//+ (NSString *)dollarsSavedUntilNow;
+ (void)initiateSavingsUntilNowCalc;

@end
