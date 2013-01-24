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

+ (PFObject *)tr_objectWithData:(NSDictionary *)data className:(NSString *)objectId
{
    PFObject *tripObj = [PFObject objectWithoutDataWithClassName:@"Trip" objectId:[data objectForKey:@"objectId"]];
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithDictionary:data];
    
    [dataDict removeObjectForKey:@"objectId"];
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
