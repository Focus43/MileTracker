//
//  MTAFParseAPIClient.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 12/21/12.
//  Copyright (c) 2012 Focus43. All rights reserved.
//

#import "MTParseAPIClient.h"

@implementation MTParseAPIClient

static NSString * const kMTAFParseAPIApplicationId = @"Vd1Qs3EyW8r7JebCa7n9X6WXjvMxa711HJfKvWqJ";
static NSString * const kMTAFParseAPIKey = @"YRQphUyGjtoTh9uowBnaezq3LAaWFhKx0gysI546";

+ (MTParseAPIClient *)sharedClient {
    static MTParseAPIClient *sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // register w Parse
        [Parse setApplicationId:kMTAFParseAPIApplicationId clientKey:kMTAFParseAPIKey];
        
        sharedClient = [[MTParseAPIClient alloc] init];
    });
    
    return sharedClient;
}


@end
