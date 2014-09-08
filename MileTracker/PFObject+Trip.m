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
        tripObj = [PFObject objectWithoutDataWithClassName:kPFObjectClassName objectId:objectId];
    } else {
        tripObj = [PFObject objectWithClassName:kPFObjectClassName];
    }
    
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithCapacity:0];
    
    if ( [data isKindOfClass:[PFObject class]]) {
        for (NSString * key in [data allKeys]) {
            [dataDict  setObject:data[key] forKey:key];
        }
    } else {
        [dataDict addEntriesFromDictionary:data];
    }
    
    if ([PFUser currentUser])
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
    self.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
    [self setObject:[PFUser currentUser] forKey:@"user"];
    
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

// TODO: add isEqual method

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
//    NSDateFormatter *df = [[NSDateFormatter alloc] init];
//    [df setTimeZone:[NSTimeZone systemTimeZone]];
//    [df setTimeStyle:NSDateFormatterMediumStyle];
//    [df setDateStyle:NSDateFormatterMediumStyle];
//    NSString *date = [df stringFromDate:[self objectForKey:@"date"]];
//    
//    return date;
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
    if ( [self objectForKey:@"distance"] ) {
        return [self objectForKey:@"distance"];
    } else {
        NSNumber *distance = [NSNumber numberWithFloat:([[self objectForKey:@"endOdometer"] floatValue] - [[self objectForKey:@"startOdometer"] floatValue])];
        return distance;
    }
}

- (NSString *)tr_totalDistanceString
{
    NSString *distString = @"";
    
    if ( [self objectForKey:@"distance"] ) {
        
        float divisor = ( [[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsLengthUnit]  isEqual: kUserDefaultsLengthUnitMile] ) ? 1609.344 : 1000.00;
        
        distString = [NSString stringWithFormat:@"%d %@", (int)roundf(([[self objectForKey:@"distance"] floatValue] / divisor)), [[NSUserDefaults standardUserDefaults] stringForKey:kUserDefaultsLengthUnit]];
    } else {
        NSNumber *distance = [NSNumber numberWithFloat:([[self objectForKey:@"endOdometer"] floatValue] - [[self objectForKey:@"startOdometer"] floatValue])];
        if ( [distance doubleValue] > 0.0 ) {
            distString = [NSString stringWithFormat:@"%d %@", [distance intValue], [[NSUserDefaults standardUserDefaults] stringForKey:kUserDefaultsLengthUnit]];
        } else {
            distString = [NSString stringWithFormat:@"%d %@", 0, [[NSUserDefaults standardUserDefaults] stringForKey:kUserDefaultsLengthUnit]];
        }
    }
    
    return distString;
}

- (void)setAddedLastTime:(float)added
{

    [self setObject:[NSNumber numberWithFloat:added] forKey:@"addedLastTime"];
}

- (float)getAddedLastTime
{
    if ([self objectForKey:@"addedLastTime"]) {
       return [[self objectForKey:@"addedLastTime"] floatValue]; 
    } else {
        return 0.0;
    }
    
}

- (void)voidAddedLastTime 
{
    [self removeObjectForKey:@"addedLastTime"];
}

@end
