/*
  PFObject+Trip.m
  MileTracker

  Created by Stine Richvoldsen on 1/24/13.
  Copyright (c) 2013 Focus43. All rights reserved.
    
  Since PFObject can't be subclassed, I have created a category with a few utility methods 
  specific to trips. 
 
*/

#import "PFObject+Trip.h"

@implementation PFObject (Trip)

+ (PFObject *)tr_objectWithData:(id)data objectId:(NSString *)objectId
{
    PFObject *tripObj;
    
    if ( objectId && ![objectId isEqualToString:@""] ) {
        tripObj = [PFObject objectWithoutDataWithClassName:@"Trip" objectId:objectId];
    } else {
        tripObj = [PFObject objectWithClassName:@"Trip"];
    }
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithCapacity:0];
    
    if ( [data isKindOfClass:[PFObject class]]) {
        for (NSString * key in [data allKeys]) {
            [dataDict  setObject:data[key] forKey:key];
        }
    } else {
        [dataDict addEntriesFromDictionary:data];
    }
    
    [dataDict setObject:[PFUser currentUser] forKey:@"user"];
    
    return [tripObj tr_updateWithData:dataDict];
}


- (PFObject *)tr_updateWithData:(NSDictionary *)data
{
    if (data) {
        NSArray *keys = [data allKeys];
        for (NSString *key in keys) {
            [self setObject:[data objectForKey:key] forKey:key];
        }
    }
    
    return self;
}

- (void)syncWithCloudAndDeleteManagedObject:(NSManagedObject *)obj
{
    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSManagedObject *aManagedObject = obj;
            NSManagedObjectContext *context = [aManagedObject managedObjectContext];
            [context deleteObject:aManagedObject];
            NSError *error;
            if (![context save:&error]) {
                NSLog(@"can't delete the object- error : %@", error);
            } else {
                NSLog(@"deleted the object");
            }
        } else {
            NSLog(@"sync error = %@", error);
        }
    }];
}

- (void)deleteFromCloudAndDeleteManagedObject:(NSManagedObject *)obj
{
    [self deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSManagedObject *aManagedObject = obj;
            NSManagedObjectContext *context = [aManagedObject managedObjectContext];
            [context deleteObject:aManagedObject];
            NSError *error;
            if (![context save:&error]) {
                NSLog(@"can't delete the object- error : %@", error);
            } else {
                NSLog(@"deleted the object");
            }
        } else {
            NSLog(@"delete error = %@", error);
        }
    }];
}

- (NSString *)tr_decimalToString:(NSNumber *)aNumber
{
    return [[[MTFormatting sharedUtility] numberFormatter] stringFromNumber:aNumber];
}

- (NSString *)tr_dateToString
{
    return [[[MTFormatting sharedUtility] dateFormatter] stringFromDate:[self objectForKey:@"date"]];
}

- (NSString *)tr_endOdometerToString
{
    return [self tr_decimalToString:[self objectForKey:@"endOdometer"]];
}

- (NSString *)tr_startOdometerToString
{
    return [self tr_decimalToString:[self objectForKey:@"startOdometer"]];
}

- (NSNumber *)tr_totalTripDistance
{
    NSNumber *distance = [NSNumber numberWithFloat:([[self objectForKey:@"endOdometer"] floatValue] - [[self objectForKey:@"startOdometer"] floatValue])];
    if ( [distance doubleValue] > 0.0 ) {
        return distance;
    } else {
        return [NSDecimalNumber zero];
    }
}

- (NSString *)tr_totalDistanceString
{
    NSNumber *totalDistance = [self tr_totalTripDistance];
    
    if ( [totalDistance doubleValue] > 0.0 ) {
        return [NSString stringWithFormat:@"%@ mi", [self tr_decimalToString:totalDistance]];
    } else {
        return @"N/A";
    }
    
}

@end
