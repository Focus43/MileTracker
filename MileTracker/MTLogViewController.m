//
//  MTSecondViewController.m
//  MileTracker
//
//  Created by Stine Richvoldsen on 12/14/12.
//  Copyright (c) 2012 Focus43. All rights reserved.
//

#import "MTLogViewController.h"
#import "MTLogTableViewCell.h"
#import "MTTripViewController.h"
#import "Reachability.h"
#import "UnsyncedTrip.h"

@interface MTLogViewController ()

@property (nonatomic, assign) BOOL reloadObjectsOnBackAction;
@property (nonatomic, strong) MBProgressHUD *hud;
@property (nonatomic, strong) NSArray *trips;
@property (nonatomic, strong) Reachability *networkReachability;

- (void)loadTrips;
- (PFQuery *)queryForTable;
- (void)refreshTable;
- (void)syncWithUnsavedData;

@end

@implementation MTLogViewController

@synthesize dateFormatter, reloadObjectsOnBackAction, networkReachability;
@synthesize trips = _trips;
@synthesize hud=_hud;

- (id)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];
    if (self) {
        
        // The className to query on
        self.className = @"Trip";
        
        // The number of objects to show per page
//        self.objectsPerPage = 9;
        
        self.networkReachability = [Reachability reachabilityForInternetConnection];
        
    }
    return self;
}

- (void)viewDidLoad
{
    NSLog(@"viewDidLoad");
    [super viewDidLoad];
    
    // Whether the built-in pagination is enabled
    self.tableView.pagingEnabled = YES;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]
                                        init];
    self.refreshControl = refreshControl;
    [refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    
//    [self loadTrips];
}

- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"viewDidAppear");
    [super viewDidAppear:animated];
    
    [self loadTrips];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"prepareForSegue : %@", segue.identifier);
    if ([segue.identifier isEqualToString:@"ShowTripDetailViewSegue"]) {
        MTTripViewController *tripDetailViewController = segue.destinationViewController;
        MTLogTableViewCell *cell = (MTLogTableViewCell *)sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
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
    self.hud.labelText	= @"Loading Trips.";
    self.hud.margin		= 30;
    self.hud.yOffset	= 30;
    [self.hud show:YES];

    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
   
    [self.queryForTable findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSLog(@"objects from Parse: %@", objects);
        self.trips = objects;
        if ( networkStatus == NotReachable ) {
            [self syncWithUnsavedData];
        }

        if (!error) {
            [self.tableView reloadData];
        }
        
        if (self.hud) {
            [self.hud hide:YES afterDelay:0.5];
        }
    }];
}

- (void)refreshTable
{
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    if ( networkStatus == NotReachable ) {
        UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Network problem" message:@"Seems like your device is offline, so only cached results can be displayed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [problemAlert show];
    } else {
        [self loadTrips];
    }
    
    [self.refreshControl endRefreshing];
}


- (PFQuery *)queryForTable
{
    NSLog(@"queryForTable");
    PFQuery *query = [PFQuery queryWithClassName:self.className];
    
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query orderByDescending:@"date"];
        
    // Since Pull To Refresh is enabled, query against the network by default.
    if (self.tableView.pagingEnabled) {
        query.cachePolicy = kPFCachePolicyNetworkOnly;
    }
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network. Unless we're offline.
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];

    if (self.trips.count == 0) {
        if ( networkStatus != NotReachable ) {
            query.cachePolicy = kPFCachePolicyCacheThenNetwork;
        } else {
            query.cachePolicy = kPFCachePolicyCacheOnly;
        }
    } else {
        if ( networkStatus == NotReachable ) {
            query.cachePolicy = kPFCachePolicyCacheOnly;
        }
    }
    
    return query;
}

- (void)syncWithUnsavedData
{
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    if (networkStatus == NotReachable) {
        // Compare w unsynced objects
        // TODO: move fetch into the Model - getAll
        NSManagedObjectContext *moc = [[MTCoreDataController sharedInstance] managedObjectContext];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"UnsyncedTrip" inManagedObjectContext:moc];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDescription];
        
        NSError *error;
        NSArray *unsyncedFetchArray = [moc executeFetchRequest:request error:&error];
        NSMutableArray *unsyncedNewArray = [NSMutableArray arrayWithCapacity:0];
        NSMutableArray *unsyncedExistingArray = [NSMutableArray arrayWithCapacity:0];
        NSMutableArray *newObjectsArray = [NSMutableArray arrayWithCapacity:0];
       
        if ( [unsyncedFetchArray count] > 0 ) {
            
            for ( UnsyncedTrip *obj in unsyncedFetchArray ) {
                PFObject *trip = [PFObject tr_objectWithData:obj.unsyncedObjInfo className:self.className];
                if ( ![obj.isNew boolValue] ) {
                    [unsyncedExistingArray addObject:trip];
                } else {
                    [unsyncedNewArray addObject:trip];
                }
            }
            
            // Set up the new object array
            [newObjectsArray addObjectsFromArray:unsyncedNewArray];
            [newObjectsArray addObjectsFromArray:self.trips];
                        
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
            
            self.trips = newObjectsArray;
        }
        
    }
//    else {
//        NSLog(@"There IS internet connection");
//    }

    if (self.hud) {
        [self.hud hide:YES afterDelay:0.5];
    }
    NSLog(@"trips at END of syncWithUnsavedData = %@",self.trips);
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MTLogTableViewCell *cell = nil;
    static NSString *CellIdentifier = @"TripCell";
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[MTLogTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    PFObject *trip = [self.trips objectAtIndex:indexPath.row];
    cell.titleLabel.text = [trip objectForKey:@"title"];
    cell.dateLabel.text = [trip tr_dateToString];
    cell.distanceLabel.text = [trip tr_totalDistanceString];
    return cell;

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

/*
 // Override if you need to change the ordering of objects in the table.
 - (PFObject *)objectAtIndex:(NSIndexPath *)indexPath {
 return [objects objectAtIndex:indexPath.row];
 }
 */

/*
 // Override to customize the look of the cell that allows the user to load the next page of objects.
 // The default implementation is a UITableViewCellStyleDefault cell with simple labels.
 - (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath 
 {
 static NSString *CellIdentifier = @"NextPage";
 
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
 
 if (cell == nil) {
 cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
 }
 
 cell.selectionStyle = UITableViewCellSelectionStyleNone;
 cell.textLabel.text = @"Load more...";
 
 return cell;
 }
 */


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.trips count];
}

 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
     if (editingStyle == UITableViewCellEditingStyleDelete) {
         
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
        


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"ShowTripDetailViewSegue" sender:self];
}


@end
