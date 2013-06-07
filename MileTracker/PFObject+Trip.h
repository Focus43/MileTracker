/*
 PFObject+Trip.m
 MileTracker
 
 Created by Stine Richvoldsen on 1/24/13.
 Copyright (c) 2013 Focus43. All rights reserved.
 
 Since PFObject can't be subclassed, I have created a category with a few utility methods
 specific to trips.
 
 */

#import <Parse/Parse.h>

@interface PFObject (Trip)

//+ (PFObject *)tr_objectWithData:(NSDictionary *)data objectId:(NSString *)objectId;
+ (PFObject *)tr_objectWithData:(id)data objectId:(NSString *)objectId;

- (PFObject *)tr_updateWithData:(NSDictionary *)data;
- (void)deleteFromCloudAndDeleteManagedObject:(NSManagedObject *)obj;
- (void)syncWithCloudAndDeleteManagedObject:(NSManagedObject *)obj;

- (NSString *)tr_decimalToString:(NSNumber *)aNumber;
- (NSString *)tr_dateToString;
- (NSString *)tr_endOdometerToString;
- (NSString *)tr_startOdometerToString;
- (NSNumber *)tr_totalTripDistance;
- (NSString *)tr_totalDistanceString;

- (void)setAddedLastTime:(float)added;
- (float)getAddedLastTime;
- (void)voidAddedLastTime;


@end
