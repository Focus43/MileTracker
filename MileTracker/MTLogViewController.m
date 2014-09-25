//
//  MTSecondViewController.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 12/14/12.
//  Copyright (c) 2012 Focus43. All rights reserved.
//

#import "MTLogViewController.h"
#import "MTTripViewController.h"
#import "Reachability.h"
#import "UnsyncedTrip.h"
#import "MTTotalMileage.h"

#define kDetailViewSegue @"ShowTripDetailViewSegue"
#define kTripCellIdentifier @"TripCell"
#define kLoadingCellIdentifier @"LoadingCell"
const int kLoadCellTag = 1234;
const int kNoTripsCellTag = 5678;

@interface MTLogViewController ()

@property (nonatomic, assign) BOOL reloadObjectsOnBackAction;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) NSArray *trips;
@property (nonatomic, strong) Reachability *networkReachability;
@property (nonatomic, assign) int objectsPerPage;
@property (nonatomic, assign) int currentPage;
@property (nonatomic, strong) NSIndexPath *loadMoreIdxPath;

- (void)loadTrips;
- (PFQuery *)queryForTable;
- (void)refreshTable;
- (void)syncWithUnsavedData;
- (UITableViewCell *)loadMoreTripsCell:(NSIndexPath *)indexPath;
- (UITableViewCell *)noTripsCell;

@end

@implementation MTLogViewController

@synthesize dateFormatter, reloadObjectsOnBackAction, networkReachability;
@synthesize trips = _trips;
@synthesize hud=_hud;
@synthesize objectsPerPage, currentPage = _currentPage, loadMoreIdxPath = _loadMoreIdxPath;

- (id)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];
    if (self) {
        
        // The className to query on
        self.className = kPFObjectClassName;
        
        self.objectsPerPage = 9;
        _currentPage = 1;
        
        self.networkReachability = [Reachability reachabilityForInternetConnection];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Whether the built-in pagination is enabled
    self.tableView.pagingEnabled = YES;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]
                                        init];
    self.refreshControl = refreshControl;
    [refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    
    _loadMoreIdxPath = [NSIndexPath indexPathForRow:10 inSection:0];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self loadTrips];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kDetailViewSegue]) {
        MTTripViewController *tripDetailViewController = segue.destinationViewController;
        
        NSIndexPath *indexPath;
        if ( [sender isKindOfClass:[UITableViewCell class]] ) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            indexPath = [self.tableView indexPathForCell:cell];
        } else {
            indexPath = (NSIndexPath *)sender; 
        }
        
        tripDetailViewController.trip = [self.trips objectAtIndex:indexPath.row];
        tripDetailViewController.navigationItem.title = @"Edit Trip Details";
        
        self.reloadObjectsOnBackAction = true;
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)loadTrips
{
    if (!self.hud) {
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.delegate = self;
    }
    
    self.hud.mode		= MBProgressHUDModeIndeterminate;
    self.hud.labelText	= @"Loading Trips";
    self.hud.margin		= 30;
    self.hud.yOffset = 0;
    [self.hud show:YES];

    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    if (![PFUser currentUser].sessionToken) {
        [self syncWithUnsavedData];
    } else {
        [self.queryForTable findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            
            self.trips = objects;
            if ( networkStatus == NotReachable || ![PFUser currentUser].sessionToken ) {
                [self syncWithUnsavedData];
            }
            
            if (!error) {
                [self.tableView reloadData];
                
//                if (self.trips.count > 0 ) {
//                    [self displayTallyTripsOffer];
//                } else {
//                    NSNumber *tallyDone = [NSNumber numberWithBool:TRUE];
//                    [[NSUserDefaults standardUserDefaults] setObject:tallyDone forKey:kUserDefaultsInitialTallyDoneKey];
//                }
                
                NSIndexPath *idxPath = [NSIndexPath indexPathForRow:[objects count]-9 inSection:0];
                [self.tableView scrollToRowAtIndexPath:idxPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
            
            if (self.hud) {
                [self.hud hide:YES afterDelay:0.5];
            }
            
        }];
    }
}

- (void)refreshTable
{
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    if ( networkStatus == NotReachable  || ![PFUser currentUser].sessionToken ) {
        UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Network problem" message:@"Seems like either your device is offline or you're not logged in, so only cached results can be displayed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [problemAlert show];
    } else {
        [self loadTrips];
        NSIndexPath *idxPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView scrollToRowAtIndexPath:idxPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    
    [self.refreshControl endRefreshing];
}


- (PFQuery *)queryForTable
{
    PFQuery *query = [PFQuery queryWithClassName:self.className];
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query orderByDescending:@"date"];
    query.limit = self.objectsPerPage * _currentPage;
        
    // Since Pull To Refresh is enabled, query against the network by default.
    if (self.tableView.pagingEnabled) {
        query.cachePolicy = kPFCachePolicyNetworkOnly;
    }
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network. Unless we're offline.
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];

    if (self.trips.count == 0) {
        if ( networkStatus != NotReachable && [PFUser currentUser].sessionToken ) {
            query.cachePolicy = kPFCachePolicyCacheThenNetwork;
        } else {
            query.cachePolicy = kPFCachePolicyCacheOnly;
        }
    } else {
        if ( networkStatus == NotReachable && ![PFUser currentUser].sessionToken ) {
            query.cachePolicy = kPFCachePolicyCacheOnly;
        } 
    }
    
    return query;
}

- (void)syncWithUnsavedData
{
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    if ( networkStatus == NotReachable || ![PFUser currentUser].sessionToken ) {
        // Compare w unsynced objects
        // TODO: move fetch into the Model - getAll
        NSManagedObjectContext *moc = [[MTCoreDataController sharedInstance] managedObjectContext];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:kUnsyncedTripEntityName inManagedObjectContext:moc];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDescription];
        
        NSError *error;
        NSArray *unsyncedFetchArray = [moc executeFetchRequest:request error:&error];
        
        NSMutableArray *unsyncedNewArray = [NSMutableArray arrayWithCapacity:0];
        NSMutableArray *unsyncedExistingArray = [NSMutableArray arrayWithCapacity:0];
        NSMutableArray *unsyncedDeletedArray = [NSMutableArray arrayWithCapacity:0];
        NSMutableArray *newObjectsArray = [NSMutableArray arrayWithCapacity:0];
       
        if ( [unsyncedFetchArray count] > 0 ) {
            
            for ( UnsyncedTrip *obj in unsyncedFetchArray ) {
                if ( obj.unsyncedObjInfo ) {
                    PFObject *trip = [PFObject tr_objectWithData:obj.unsyncedObjInfo objectId:obj.objectId];
                    if ( ![obj.isNew boolValue] ) {
                        [unsyncedExistingArray addObject:trip];
                    } else {
                        [unsyncedNewArray addObject:trip];
                    }
                } else {
                    [unsyncedDeletedArray addObject:obj.objectId];
                }
            }
            
            // Set up the new object array
            [newObjectsArray addObjectsFromArray:unsyncedNewArray];
            
            if ( [PFUser currentUser].sessionToken ) {
                [newObjectsArray addObjectsFromArray:self.trips];
            }
            
                        
            if ( [unsyncedExistingArray count] > 0 ) {
                // compare trips and update self.objects with the latest data
                for ( PFObject *obj in unsyncedExistingArray ) {
                    NSPredicate *shouldUpdatePred = [NSPredicate predicateWithFormat:@"(objectId == %@)",obj.objectId];
                    
                    NSUInteger index = [newObjectsArray indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                        return [shouldUpdatePred evaluateWithObject:obj];
                    }];
                    
                    if ( index != NSNotFound ) {
                        [newObjectsArray replaceObjectAtIndex:index withObject:obj];
                    }
                }
            }
            
            if ( [unsyncedDeletedArray count] > 0 ) {
                
                for ( NSString *objId in unsyncedDeletedArray ) {
                    NSPredicate *shouldDeletePred = [NSPredicate predicateWithFormat:@"(objectId == %@)",objId];
                    
                    NSUInteger index = [newObjectsArray indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                        return [shouldDeletePred evaluateWithObject:obj];
                    }];
                    
                    if ( index != NSNotFound ) {
                        [newObjectsArray removeObjectAtIndex:index];
                    }
                }
            }
            
            self.trips = newObjectsArray;
            NSLog(@"self.trips =  %@", self.trips);
            if ( ![PFUser currentUser].sessionToken ) {
                [self.tableView reloadData];
            }
        }
        
    }

    if (self.hud) {
        [self.hud hide:YES afterDelay:0.5];
    }
}

- (UITableViewCell *)loadMoreTripsCell:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    
    UILabel* loadMore =[[UILabel alloc]initWithFrame: cell.frame];
    loadMore.backgroundColor = [UIColor clearColor];
    loadMore.textAlignment = NSTextAlignmentCenter;
    loadMore.font = [UIFont boldSystemFontOfSize:18];
    
    if ( indexPath.row == [self.trips count] ) {
        loadMore.text = @"Load more trips...";
        cell.tag = kLoadCellTag;
        cell.userInteractionEnabled = YES;
        self.loadMoreIdxPath = indexPath;
    } else {
        loadMore.text = @"";
        cell.tag = kLoadCellTag + 1;
        cell.userInteractionEnabled = NO;
    }
    
    [cell addSubview:loadMore];
    
    return cell;
}

- (UITableViewCell *)noTripsCell
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    
    UILabel* noTrips =[[UILabel alloc]initWithFrame: cell.frame];
    noTrips.backgroundColor = [UIColor clearColor];
    noTrips.textAlignment = NSTextAlignmentCenter;
    noTrips.font = [UIFont boldSystemFontOfSize:18];
    noTrips.text = @"You don't have any trips saved yet...";
    [cell addSubview:noTrips];
    
    cell.userInteractionEnabled = NO;
    cell.tag = kNoTripsCellTag;
    
    return cell;
}

//- (void)displayTallyTripsOffer
//{
//    if ( ![[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsInitialTallyDoneKey] boolValue] ) {
//        [[[UIAlertView alloc] initWithTitle:@"New Feature!"
//                                    message:@"The app now tracks your total tax deduction for the year. To get you up to date, your trips need to be tallied up. That can be done now, or you can go to 'More', and take care of it later"
//                                   delegate: self
//                          cancelButtonTitle:@"I'll do it later"
//                          otherButtonTitles:@"Do it now!", nil] show];
//        
//        NSNumber *tallyDone = [NSNumber numberWithBool:TRUE];
//        [[NSUserDefaults standardUserDefaults] setObject:tallyDone forKey:kUserDefaultsInitialTallyDoneKey];
//    }
//}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int number;
    int count = [self.trips count];

    if ( count >= 9 ) {
        number = count + 2;
    } else if ( count == 0 ) {
        number = 1;
    } else {
        number = count;
    }
    return number;
    // if count is more than 9: adding one for see more cell and one for empty cell that brings table up above ads
    // unless there are zero entries, then we only need one for the no trips message
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( [self.trips count] == 0 ) {
        return [self noTripsCell];
    }
    
    if ( indexPath.row < [self.trips count] ) {
        
        UITableViewCell *cell = nil;
        static NSString *CellIdentifier = kTripCellIdentifier;
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        }
        
        PFObject *trip = [self.trips objectAtIndex:indexPath.row];
        cell.textLabel.text = ( ![[trip objectForKey:@"title"] isEqualToString:@""] ) ? [trip objectForKey:@"title"] : @"< no description >";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@   %@", [trip tr_dateToString], [trip tr_totalDistanceString]];
        return cell;
        
    } else {
        return [self loadMoreTripsCell:indexPath];
    }
}

 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
     if (editingStyle == UITableViewCellEditingStyleDelete) {
         
         NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
         
         if ( networkStatus == NotReachable || ![PFUser currentUser].sessionToken ) {
             PFObject *objectToDelete = [self.trips objectAtIndex:indexPath.row];
             
             NSError *error = nil;
             NSArray *results = [UnsyncedTrip fetchTripsWithId:objectToDelete.objectId error:error];
             
             if ( !error && results && [results count] > 0 ) {
                 // record already exists => just delete it!delete from Core Data
                 [[[MTCoreDataController sharedInstance] managedObjectContext] deleteObject:[results objectAtIndex:0]];
             } else {
                 [UnsyncedTrip createTripForEntityDecriptionAndLoadWithData:nil objectId:objectToDelete.objectId];
             }
             
             [[[MTCoreDataController sharedInstance] managedObjectContext] save:&error];
             if (error) {
                 NSLog(@"can't save");
             } else {
                 // Delete the row
                 [self loadTrips];
             }
             
         } else {
             
             [[self.trips objectAtIndex:indexPath.row] deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                 
                 if (!succeeded) {
                     if ([error code] == kPFErrorConnectionFailed ) {
                         UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Can't connect to the cloud, so try this later, when we're back online." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                         [problemAlert show];
                     } else {
                         NSLog(@"error when deleting: %@", error);
                     }
                     
                 } else {
                     // Delete the row
                     [self loadTrips];
                 }
             }];
         }
         
     } 
 }

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( indexPath.row == self.loadMoreIdxPath.row ) {
        _currentPage ++;
        [self loadTrips];
    } else {
//        [self performSegueWithIdentifier:kDetailViewSegue sender:self];
        [self performSegueWithIdentifier:kDetailViewSegue sender:indexPath];
    }
}

# pragma mark - Alert View Delegate methods

//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    if ( buttonIndex == 1 ) {
//        [MTTotalMileage initiateSavingsUntilNowCalc];
//    }
//}



@end
