//
//  MTAppDelegate.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 12/14/12.
//  Copyright (c) 2012 Focus43. All rights reserved.
//

#import "MTAppDelegate.h"
#import "Reachability.h"
#import "Trip.h"
#import "UnsyncedTrip.h"
#import "MTUnsyncedTripValueTransformer.h"

@interface MTAppDelegate ()

- (void)syncTrips;

@end

@implementation MTAppDelegate

static NSString * const kMTAFParseAPIApplicationId = @"Vd1Qs3EyW8r7JebCa7n9X6WXjvMxa711HJfKvWqJ";
static NSString * const kMTAFParseAPIKey = @"YRQphUyGjtoTh9uowBnaezq3LAaWFhKx0gysI546";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse setApplicationId:kMTAFParseAPIApplicationId clientKey:kMTAFParseAPIKey];
    
    MTUnsyncedTripValueTransformer *transformer = [[MTUnsyncedTripValueTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"MTUnsyncedTripValueTransformer"];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"applicationWillEnterForeground");
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    if (networkStatus != NotReachable) {
        [self syncTrips];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
//    NSLog(@"applicationDidBecomeActive");
//    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
//    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
//    
//    if (networkStatus != NotReachable) {
//        [self syncTrips];
//    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)syncTrips
{
    NSLog(@"syncTrips");
    // TODO: move this into the Model
    NSManagedObjectContext *moc = [[MTCoreDataController sharedInstance] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"UnsyncedTrip" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSError *error;
    NSArray *unsyncedArray = [moc executeFetchRequest:request error:&error];
    NSLog(@"fetch error = %@", error);
    if ( unsyncedArray != nil && [unsyncedArray count] > 0 ) {
        NSLog(@"unsaved array = %@", unsyncedArray);
        
        // show HUD?
        
        UIAlertView *syncAlert = [[UIAlertView alloc] initWithTitle:@"Just a sec" message:@"You had some trips that had not been synced with the cloud because you were offline. Give me a sec to update those." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [syncAlert show];
        
        for ( UnsyncedTrip *obj in unsyncedArray ) {
            
            PFObject *unsyncedTrip;
            
            if ( [obj.isNew boolValue] ) {
                unsyncedTrip = [Trip tripWithData:obj.unsyncedObjInfo];
            } else {
                unsyncedTrip = [PFObject objectWithoutDataWithClassName:@"Trip" objectId:obj.objectId];
                [Trip updateObj:unsyncedTrip WithData:obj.unsyncedObjInfo];
            }
            
            unsyncedTrip.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
            
            // TODO: change to saveAllInBackground:block: after creating array of unsyncedObjs?
            [unsyncedTrip saveInBackgroundWithBlock: ^(BOOL succeeded, NSError *error) {
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
                    // TODO: handle error
//                    UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Network problem" message:@"The server cannot be contacted at this time, and the trip will be saved at a later time, when the connection is back up." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                    [problemAlert show];
                }
            }];
        }
        
        // hide HUD
    }
}

@end
