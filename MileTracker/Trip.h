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

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSNumber *startOdometer;
@property (nonatomic, retain) NSNumber *endOdometer;
@property (nonatomic, retain) PFUser *user;

+ (Trip *)tripWithData:(NSDictionary *)data;
+ (PFObject *)updateObj:(PFObject *)obj WithData:(NSDictionary *)data;

- (void)updateWithData:(NSDictionary *)data;

- (NSString *)decimalToString:(NSNumber *)aNumber;
- (NSString *)dateToString;
- (NSString *)endOdometerToString;
- (NSString *)startOdometerToString;
- (NSNumber *)totalTripDistance;
- (NSString *)totalDistanceString;

@end
