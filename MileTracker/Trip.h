//
//  Trip.h
//  MileTracker
//
//  Created by Stine Richvoldsen on 12/20/12.
//  Copyright (c) 2012 Focus43. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <Parse/Parse.h>


@interface Trip : PFObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDecimalNumber * startOdometer;
@property (nonatomic, retain) NSDecimalNumber * endOdometer;

+ (Trip *)tripWithData:(NSDictionary *)data;

- (void)updateWithData:(NSDictionary *)data;

- (NSString *)decimalToString:(NSDecimalNumber *)aNumber;
- (NSString *)dateToString;
- (NSString *)endOdometerToString;
- (NSString *)startOdometerToString;
- (NSDecimalNumber *)totaTriplDistance;
- (NSString *)totalDistanceString;

@end
