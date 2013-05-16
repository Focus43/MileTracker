//
//  MTTotalMileage.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 5/15/13.
//  Copyright (c) 2013 Focus43. All rights reserved.
//

#import "MTTotalMileage.h"
#import <Parse/Parse.h>

@interface MTTotalMileage()

@property float totalMilesForYear;

- (PFQuery *)queryForTripsMadeThisYear;
- (void)setCurrentTotalMileage;

@end


@implementation MTTotalMileage

- (PFQuery *)queryForTripsMadeThisYear
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *componentsForNow = [gregorian components:NSUIntegerMax fromDate:[NSDate date]];
    
    NSDateComponents *startComponents = [[NSDateComponents alloc] init];
    [startComponents setYear:([componentsForNow year] - 1)];
    [startComponents setMonth:12];
    [startComponents setDay:31];
    [startComponents setHour:23];
    [startComponents setMinute:59];
    [startComponents setSecond:59];
    
    PFQuery *query = [PFQuery queryWithClassName:kPFObjectClassName];
    [query whereKey:@"date" lessThanOrEqualTo:[gregorian dateFromComponents: componentsForNow]];
    [query whereKey:@"date" greaterThan:[gregorian dateFromComponents: startComponents]];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    NSLog(@"queryForTripsMadeThisYear = %@", query);
    return query;
}

- (void)setCurrentTotalSavings
{
    PFQuery *query = [self queryForTripsMadeThisYear];
    self.totalMilesForYear = 0;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (error) {
            NSLog(@"error! %@", error);
        } else {
            float totalMiles = 0;
            
            if ( [objects count] > 0 ) {
                for (int i=0; i<[objects count]; i++) {
                    PFObject *trip = [objects objectAtIndex:i];
                    float totalMilesForTrip = [[trip objectForKey:@"endOdometer"] floatValue]- [[trip objectForKey:@"startOdometer"] floatValue];
                    totalMiles = totalMiles + totalMilesForTrip;
                }
                
                self.totalMilesForYear = totalMiles;
                NSLog(@"self.totalMilesForYear = %f", self.totalMilesForYear);
                
                NSNumber *totalSaved = [[NSNumber alloc] initWithFloat:totalMiles * kDollarPerMileTaxDeduction];
        
                NSNumberFormatter *formatter = [[MTFormatting sharedUtility]currencyFormatter];
                NSString *savedStr = [formatter stringFromNumber:totalSaved];
                [[NSNotificationCenter defaultCenter] postNotificationName:kMileageTotalFoundNotification object:savedStr];
                [[NSUserDefaults standardUserDefaults] setObject:savedStr forKey:kUserDefaultsSavingsKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
        
    }];
}

- (NSNumber *)getCurrentTotalSavings
{
    if ( !self.totalMilesForYear || self.totalMilesForYear == 0 ) {
        [self setCurrentTotalSavings];
    }
    
    return [[NSNumber alloc] initWithInt:self.totalMilesForYear];
}

+ (NSString *)dollarsSavedUntilNow
{
    // TODO: get rid of this one
    MTTotalMileage *totalMileage = [[self alloc] init];
    NSNumber *totalMiles = [totalMileage getCurrentTotalMileage];
    NSNumber *totalSaved = [[NSNumber alloc] initWithFloat:[totalMiles floatValue] * kDollarPerMileTaxDeduction];
    
    NSNumberFormatter *formatter = [[MTFormatting sharedUtility] currencyFormatter];    
    NSString *savedStr = [formatter stringFromNumber:totalSaved];
    [[NSNotificationCenter defaultCenter] postNotificationName:kMileageTotalFoundNotification object:savedStr];
    [[NSUserDefaults standardUserDefaults] setObject:savedStr forKey:kUserDefaultsSavingsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    return savedStr;
}
            
+ (void)initiateSavingsUntilNowCalc
{
    MTTotalMileage *totalMileage = [[self alloc] init];
    [totalMileage setCurrentTotalSavings];
}

@end
