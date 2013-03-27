//
//  MTAppDelegate.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 12/14/12.
//  Copyright (c) 2012 Focus43. All rights reserved.
//

#import "MTAppDelegate.h"
#import "Reachability.h"
#import "UnsyncedTrip.h"
#import "MTUnsyncedTripValueTransformer.h"
#import "MTSignUpViewController.h"
#import "MTLoginViewController.h"

@interface MTAppDelegate ()

- (void)syncTrips;

@end

@implementation MTAppDelegate

static NSString * const kMTAFParseAPIApplicationId = @"Vd1Qs3EyW8r7JebCa7n9X6WXjvMxa711HJfKvWqJ";
static NSString * const kMTAFParseAPIKey = @"YRQphUyGjtoTh9uowBnaezq3LAaWFhKx0gysI546";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse setApplicationId:kMTAFParseAPIApplicationId clientKey:kMTAFParseAPIKey];
    
    // register transformer
    MTUnsyncedTripValueTransformer *transformer = [[MTUnsyncedTripValueTransformer alloc] init];
    [NSValueTransformer setValueTransformer:transformer forName:@"MTUnsyncedTripValueTransformer"];
    
    // reachability notifier
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
//	hostReach = [Reachability reachabilityWithHostName: @"api.parse.com"];
//	[hostReach startNotifier];
//	[self updateInterfaceWithReachability: hostReach];
	
    internetReach = [Reachability reachabilityForInternetConnection];
	[internetReach startNotifier];
	[self updateInterfaceWithReachability: internetReach];
    
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
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (![PFUser currentUser]) { // No user logged in
        [self launchLoginScreen];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void) updateInterfaceWithReachability: (Reachability*) curReach
{
    if(curReach == internetReach) {
        [self syncTrips];
    }
}

//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	[self updateInterfaceWithReachability: curReach];
}


- (void)syncTrips
{
    // TODO: move this into the Model
    NSManagedObjectContext *moc = [[MTCoreDataController sharedInstance] managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:kUnsyncedTripEntityName inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSError *error;
    NSArray *unsyncedArray = [moc executeFetchRequest:request error:&error];
    NSLog(@"fetch error = %@", error);
    if ( unsyncedArray != nil && [unsyncedArray count] > 0 ) {
                
        UIAlertView *syncAlert = [[UIAlertView alloc] initWithTitle:@"Just a sec" message:@"You had some trips that had not been synced with the cloud because you were offline. Those will be backed up now." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [syncAlert show];
        
        for ( UnsyncedTrip *obj in unsyncedArray ) {
            
            PFObject *unsyncedTrip;
            
            if ( obj.isNew == [NSNumber numberWithInt:1] ) {
                unsyncedTrip = [PFObject objectWithClassName:kPFObjectClassName];
                [unsyncedTrip tr_updateWithData:obj.unsyncedObjInfo];
            } else {
                unsyncedTrip = [PFObject objectWithoutDataWithClassName:kPFObjectClassName objectId:obj.objectId];
                [unsyncedTrip tr_updateWithData:obj.unsyncedObjInfo];
            }
            
            unsyncedTrip.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
            
            if (obj.unsyncedObjInfo) {
                [unsyncedTrip syncWithCloudAndDeleteManagedObject:obj];
            } else {
                [unsyncedTrip deleteFromCloudAndDeleteManagedObject:obj];
            }
            
        }
        
    }
}

- (void)launchLoginScreen
{
    NetworkStatus networkStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    
    if ( networkStatus == NotReachable ) {
        UIAlertView *cannotLoginAlert = [[UIAlertView alloc] initWithTitle:@"Uh oh..."
                                                                   message:@"To sign up or log in, you have to be online, and it looks like you're not right now."
                                                                  delegate:nil
                                                         cancelButtonTitle:@"I'll try again later!"
                                                         otherButtonTitles:nil];
        [cannotLoginAlert show];
        
    }
    
    // Create the log in view controller
    MTLoginViewController *logInViewController = [[MTLoginViewController alloc] init];
    [logInViewController setDelegate:self]; // Set ourselves as the delegate
    
    // Create the sign up view controller
    MTSignUpViewController *signUpViewController = [[MTSignUpViewController alloc] init];
    [signUpViewController setDelegate:self]; // Set ourselves as the delegate
    
    // Assign our sign up controller to be displayed from the login controller
    [logInViewController setSignUpController:signUpViewController];
    
    // Present the log in view controller
    [self.window.rootViewController presentViewController:logInViewController animated:YES completion:NULL];
}


# pragma mark - Login Delegate methods

// Sent to the delegate to determine whether the log in request should be submitted to the server.
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
    // Check if both fields are completed
    if (username && password && username.length != 0 && password.length != 0) {
        return YES; // Begin login process
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                message:@"Make sure you fill out all of the information!"
                               delegate:nil
                      cancelButtonTitle:@"ok"
                      otherButtonTitles:nil] show];
    return NO; // Interrupt login process
}

// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:NULL];
}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error
{
    NSLog(@"Failed to log in...");
}

// Sent to the delegate when the log in screen is dismissed.
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController
{
    [self.window.rootViewController dismissModalViewControllerAnimated:YES];
    
    NetworkStatus networkStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
    if (networkStatus != NotReachable) {
        [self syncTrips];
    }
}

# pragma mark - Sign Up Delegate methods

// Sent to the delegate to determine whether the sign up request should be submitted to the server.
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info
{
    BOOL informationComplete = YES;
    
    // loop through all of the submitted data
    for (id key in info) {
        NSString *field = [info objectForKey:key];
        if (!field || field.length == 0) { // check completion
            informationComplete = NO;
            break;
        }
    }
    
    // Display an alert if a field wasn't completed
    if (!informationComplete) {
        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                    message:@"Make sure you fill out all of the information!"
                                   delegate:nil
                          cancelButtonTitle:@"ok"
                          otherButtonTitles:nil] show];
    }
    
    return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user
{
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:NULL]; // Dismiss the PFSignUpViewController
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error
{
    NSLog(@"Failed to sign up...");
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController
{
    NSLog(@"User dismissed the signUpViewController");
}


@end
