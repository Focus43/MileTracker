//
//  UnsyncedTrip.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 1/11/13.
//  Copyright (c) 2013 Focus43. All rights reserved.
//

#import "UnsyncedTrip.h"

@implementation UnsyncedTrip

@dynamic unsyncedObjInfo;
@dynamic isNew;
@dynamic savedTime;
@dynamic objectId;


+ (UnsyncedTrip *)createTripForEntityDecriptionAndLoadWithData:(NSDictionary *)tripData objectId:(NSString *)objectId
{
    UnsyncedTrip *unsyncedTrip = (UnsyncedTrip *)[NSEntityDescription insertNewObjectForEntityForName:kUnsyncedTripEntityName
                                                                               inManagedObjectContext:[[MTCoreDataController sharedInstance] managedObjectContext]];
    
    BOOL isNew = (objectId) ? NO : YES;
    
    if (tripData) {
        NSMutableDictionary *tripDict = [NSMutableDictionary dictionaryWithDictionary:tripData];
        [tripDict removeObjectForKey:@"user"];
        
        [unsyncedTrip setValue:tripDict forKey:@"unsyncedObjInfo"];
        [unsyncedTrip setValue:[tripDict objectForKey:@"date"] forKey:@"savedTime"];
        [unsyncedTrip setValue:[PFUser currentUser].objectId forKey:@"userId"];
        
    } else {
        [unsyncedTrip setValue:nil forKey:@"unsyncedObjInfo"];
    }
    
    [unsyncedTrip setValue:[NSNumber numberWithBool:isNew] forKey:@"isNew"];
    [unsyncedTrip setValue:objectId forKey:@"objectId"];
    [unsyncedTrip setValue:[PFUser currentUser].objectId forKey:@"userId"];
    
    NSLog(@"createTripForEntityDecriptionAndLoadWithData unsyncedTrip = %@", unsyncedTrip);
    return unsyncedTrip;
}

+ (NSArray *)fetchTripsMatching:(NSDate *)creationDate error:(NSError *)error
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *trips = [NSEntityDescription entityForName:kUnsyncedTripEntityName inManagedObjectContext:[[MTCoreDataController sharedInstance] managedObjectContext]];
    [request setEntity:trips];
    
    // All this is to account for dictionary making slight changes in the timestamp (really?? anyway:)
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSUInteger unitFlags = NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDateComponents *searchDateComps = [calendar components:unitFlags fromDate:creationDate];
    NSDateComponents *startComps = [searchDateComps copy];
    NSDateComponents *endComps = [searchDateComps copy];
    [startComps setSecond:searchDateComps.second - 2];
    [endComps setSecond:searchDateComps.second + 2];
    NSDate *startDate = [calendar dateFromComponents:startComps];
    NSDate *endDate = [calendar dateFromComponents:endComps];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((savedTime >= %@) AND (savedTime <= %@))",startDate,endDate];
    [request setPredicate:predicate];
    
    return [[[MTCoreDataController sharedInstance] managedObjectContext] executeFetchRequest:request error:&error];
}

+ (NSArray *)fetchTripsWithId:(NSString *)objectId error:(NSError *)error
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *trips = [NSEntityDescription entityForName:kUnsyncedTripEntityName inManagedObjectContext:[[MTCoreDataController sharedInstance] managedObjectContext]];
    [request setEntity:trips];
    
    NSPredicate *objectPredicate = [NSPredicate predicateWithFormat:@"(objectId == %@)",objectId];
    NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"(userId == %@)",[PFUser currentUser].objectId];
    
    NSArray *searchPredicatesArray = [NSArray arrayWithObjects:objectPredicate, userPredicate, nil];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:searchPredicatesArray];
    [request setPredicate:predicate];
    
    return [[[MTCoreDataController sharedInstance] managedObjectContext] executeFetchRequest:request error:&error];
}

@end
