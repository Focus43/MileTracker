//
//  Trip.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 12/20/12.
//  Copyright (c) 2012 Focus43. All rights reserved.
//

#import "Trip.h"

@implementation Trip

@synthesize date, title, startOdometer, endOdometer;

+ (Trip *)tripWithData:(NSDictionary *)data
{
    // TODO: could use objectWithClassName:dictionary:
    // TODO: change to return PFObject
    Trip *trip = [[super alloc] initWithClassName:@"Trip"];
    
    if (data) {
        NSArray *keys = [data allKeys];
        for (NSString *key in keys) {
            [trip setObject:[data objectForKey:key] forKey:key];
        }
        
        trip.title = [data objectForKey:@"title"];
        trip.date = [data objectForKey:@"date"];
        trip.startOdometer = [data objectForKey:@"startOdometer"];
        trip.endOdometer = [data objectForKey:@"endOdometer"];
        trip.user = [data objectForKey:@"user"];
    }

    return trip;
}

+ (PFObject *)updateObj:(PFObject *)obj WithData:(NSDictionary *)data
{
    if (data) {
        NSArray *keys = [data allKeys];
        for (NSString *key in keys) {
            [obj setObject:[data objectForKey:key] forKey:key];
        }
    }
    
    return obj;
}

- (void)updateWithData:(NSDictionary *)dataDict
{
    if (dataDict) {
        NSArray *keys = [dataDict allKeys];
        for (NSString *key in keys) {
            [self setObject:[dataDict objectForKey:key] forKey:key];
        }
        
        self.title = [dataDict objectForKey:@"title"];
        self.date = [dataDict objectForKey:@"date"];
        self.startOdometer = [dataDict objectForKey:@"startOdometer"];
        self.endOdometer = [dataDict objectForKey:@"endOdometer"];
        self.user = [dataDict objectForKey:@"user"];
    }

}


- (NSString *)decimalToString:(NSNumber *)aNumber
{
    return [[[MTFormatting sharedUtility] numberFormatter] stringFromNumber:aNumber];
}  

- (NSString *)dateToString
{
//    return [[[MTFormatting sharedUtility] dateFormatter] stringFromDate:[self objectForKey:@"date"]];
    return [[[MTFormatting sharedUtility] dateFormatter] stringFromDate:self.date];
}

- (NSString *)endOdometerToString
{
//    return [self decimalToString:[self objectForKey:@"endOdometer"]];
    return [self decimalToString:self.endOdometer];
}

- (NSString *)startOdometerToString
{
//    return [self decimalToString:[self objectForKey:@"startOdometer"]];
    return [self decimalToString:self.startOdometer];
}

- (NSNumber *)totalTripDistance
{
    NSNumber *distance = [NSNumber numberWithFloat:([self.endOdometer floatValue] - [self.startOdometer floatValue])];
    if ( [distance doubleValue] > 0.0 ) {
        return distance;
    } else {
        return [NSDecimalNumber zero];
    }
}

- (NSString *)totalDistanceString
{
    NSNumber *totalDistance = [self totalTripDistance];
    
    if ( [totalDistance doubleValue] > 0.0 ) {
        return [NSString stringWithFormat:@"%@ mi", [self decimalToString:totalDistance]];
    } else {
        return @"N/A";
    }
    
}

@end
