//
//  MTUnsyncedTripValueTransformer.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 1/15/13.
//  Copyright (c) 2013 Focus43. All rights reserved.
//

#import "MTUnsyncedTripValueTransformer.h"
//#import "Trip.h"

@implementation MTUnsyncedTripValueTransformer

+ (Class)transformedValueClass
{
	return [NSData class];
}

+ (BOOL)allowsReverseTransformation
{
	return YES;
}

- (id)transformedValue:(id)value
{
    NSString * error;
   
    return [NSPropertyListSerialization dataFromPropertyList:value format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
     
}

- (id)reverseTransformedValue:(id)value
{
    NSError *error;
    NSMutableDictionary *tripData = [NSPropertyListSerialization propertyListWithData:value options:NSPropertyListMutableContainersAndLeaves format:nil error:&error];
    
//    PFObject *tripObj = [PFObject objectWithoutDataWithClassName:@"Trip" objectId:[tripData objectForKey:@"objectId"]];
//    
//    [tripData removeObjectForKey:@"objectId"];
//    [tripData setObject:[PFUser currentUser] forKey:@"user"];
//    
//    return [Trip updateObj:tripObj WithData:tripData];    

    return [PFObject tr_objectWithData:tripData className:@"Trip"];
}

@end

