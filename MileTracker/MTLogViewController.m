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
#import "Trip.h"

@interface MTLogViewController ()

@property (nonatomic, assign)BOOL reloadObjectsOnBackAction;

@end

@implementation MTLogViewController

@synthesize dateFormatter, reloadObjectsOnBackAction;

- (id)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];
    if (self) {
        
        // The className to query on
        self.className = @"Trip";
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 9;

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.reloadObjectsOnBackAction) {
        [self loadObjects];
        self.reloadObjectsOnBackAction = false;
    }
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowTripDetailViewSegue"]) {
        MTTripViewController *tripDetailViewController = segue.destinationViewController;
        MTLogTableViewCell *cell = (MTLogTableViewCell *)sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        tripDetailViewController.tripObj = [self.objects objectAtIndex:indexPath.row];
        tripDetailViewController.trip = [Trip tripWithData:[self.objects objectAtIndex:indexPath.row]];
        
        tripDetailViewController.navigationItem.title = @"Edit Trip Details";
        
        self.reloadObjectsOnBackAction = true;
        
    }
    //    else if ([segue.identifier isEqualToString:@"ShowAddTripViewSegue"]) {
    //        MTTripViewController *addTripViewController = segue.destinationViewController;
    //    }
}

#pragma mark - Table view data source

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Parse

- (void)objectsDidLoad:(NSError *)error
{
    [super objectsDidLoad:error];
    
    // This method is called every time objects are loaded from Parse via the PFQuery
}

- (void)objectsWillLoad
{
    [super objectsWillLoad];
    
    // This method is called before a PFQuery is fired to get more objects
}

- (void)loadObjects
{
    [super loadObjects];
}


// Override to customize what kind of query to perform on the class. The default is to query for
// all objects ordered by createdAt descending.
- (PFQuery *)queryForTable
{
    PFQuery *query = [PFQuery queryWithClassName:self.className];
    
    [query whereKey:@"user" equalTo:[PFUser currentUser]];
    [query orderByDescending:@"date"];
    
//    query.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    // Since Pull To Refresh is enabled, query against the network by default.
    if (self.pullToRefreshEnabled) {
        query.cachePolicy = kPFCachePolicyNetworkOnly;
    }
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if (self.objects.count == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    return query;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object
{    
    MTLogTableViewCell *cell = nil;
    static NSString *CellIdentifier = @"TripCell";
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[MTLogTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    Trip *trip = [Trip tripWithData:object];
    cell.titleLabel.text = trip.title;
    cell.dateLabel.text = [trip dateToString];
    cell.distanceLabel.text = [trip totalDistanceString];
    
    return cell;

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

#pragma mark - Table view data source

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
     if (editingStyle == UITableViewCellEditingStyleDelete) {
         
         [[self.objects objectAtIndex:indexPath.row] deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
             if (!succeeded) {
                 if ([error code] == kPFErrorConnectionFailed ) {
                     UIAlertView *problemAlert = [[UIAlertView alloc] initWithTitle:@"Oops!" message:@"Can't connect to the cloud, so try this later, when we're back online." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                     [problemAlert show];
                     
//                      [[self.objects objectAtIndex:indexPath.row] deleteEventually];
                     
                 } else {
                     NSLog(@"error when deleting: %@", error);
                 }
                 
             } else {
                 // Delete the row 
                 [self loadObjects];
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
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}


@end
