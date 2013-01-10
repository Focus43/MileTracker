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
    Trip *trip = [[super alloc] initWithClassName:@"Trip"];
    
    if (data) {
        // TODO: change to set title, date etc 
        NSArray *keys = [data allKeys];
        for (NSString *key in keys) {
            [trip setObject:[data objectForKey:key] forKey:key];
        }
        
        trip.title = [data objectForKey:@"title"];
        trip.date = [data objectForKey:@"date"];
        trip.startOdometer = [data objectForKey:@"startOdometer"];
        trip.endOdometer = [data objectForKey:@"endOdometer"];
        
    }

    return trip;
}

- (void)updateWithData:(NSDictionary *)data
{
    if (data) {
        // TODO: change to set title, date etc
        NSArray *keys = [data allKeys];
        for (NSString *key in keys) {
            [self setObject:[data objectForKey:key] forKey:key];
        }
        
        self.title = [data objectForKey:@"title"];
        self.date = [data objectForKey:@"date"];
        self.startOdometer = [data objectForKey:@"startOdometer"];
        self.endOdometer = [data objectForKey:@"endOdometer"];
    }

}

- (NSString *)decimalToString:(NSDecimalNumber *)aNumber
{
    return [[[MTFormatting sharedUtility] numberFormatter] stringFromNumber:aNumber];
} 

- (NSString *)dateToString
{
    return [[[MTFormatting sharedUtility] dateFormatter] stringFromDate:[self objectForKey:@"date"]];
}

- (NSString *)endOdometerToString
{
    return [self decimalToString:[self objectForKey:@"endOdometer"]];
}

- (NSString *)startOdometerToString
{
    return [self decimalToString:[self objectForKey:@"startOdometer"]];
}

- (NSDecimalNumber *)totaTriplDistance
{
    NSDecimalNumber *distance = [[self objectForKey:@"endOdometer"] decimalNumberBySubtracting:[self objectForKey:@"startOdometer"]];
    if ( [distance doubleValue] > 0.0 ) {
        return distance;
    } else {
        return [NSDecimalNumber zero];
    }
}

- (NSString *)totalDistanceString
{
    NSDecimalNumber *distance = [[self objectForKey:@"endOdometer"] decimalNumberBySubtracting:[self objectForKey:@"startOdometer"]];
    
    if ( [distance doubleValue] > 0.0 ) {
        return [NSString stringWithFormat:@"%@ mi", [self decimalToString:distance]];
    } else {
        return @"N/A";
    }
    
}

@end
