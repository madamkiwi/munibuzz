//
//  StopsTableViewController.m
//  munibuzz2
//
//  Created by Kalai Wei on 10/12/13.
//  Copyright (c) 2013 Kalai Wei. All rights reserved.
//

#import "StopsTableViewController.h"
#import "Stops.h"
#import "RoutesViewController.h"
#import "AppDelegate.h"
#import "RoutesDatabase.h"

@interface StopsTableViewController ()

@end

@implementation StopsTableViewController
@synthesize stopsSearchBar;
@synthesize operation;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {

    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView reloadData];
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [filteredStopsArray removeAllObjects];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.title contains[c] %@",searchText];
    filteredStopsArray = [NSMutableArray arrayWithArray:[stopsArray filteredArrayUsingPredicate:predicate]];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    // Tells the table data source to reload when scope bar selection changes
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [filteredStopsArray count];
    } else {
        return [stopsArray count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    Stops *stop = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        stop = [filteredStopsArray objectAtIndex:indexPath.row];
    } else {
        stop = [stopsArray objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.text = stop.title;
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    return cell;
}

/* this function saves the user selected stop info which will be displayed in routes view */
- (void)tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *__strong)indexPath
{
    Stops *stop;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        stop = [filteredStopsArray objectAtIndex:indexPath.row];
    } else {
        stop = [stopsArray objectAtIndex:indexPath.row];
    }
    
    if ([self.operation  isEqual: @"Start"]) {
        [data.startLabel setString:stop.title];

        NSString *que = [NSString stringWithFormat:@"SELECT * FROM stops group by direction,stopid having title=\"%@\"",stop.title];
        [rarray1 setArray:[[RoutesDatabase database] RoutesInfo:[que UTF8String]]];

/*        [filteredStopsArray removeAllObjects];
        
        filteredStopsArray = [NSMutableArray arrayWithArray:[stopsArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.dTag contains[c] %@",stop.dTag]]];
        

        if (![data.destLabel isEqualToString:@"location"]) {
            //destination has already been selected, so now use the dTag and route from
            // the start stop, and get the stop tag and stop id.
            filteredStopsArray = [NSMutableArray arrayWithArray:[stopsArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.title contains[c] %@",data.startLabel]]];
            [data.startStopTag setString:[[filteredStopsArray objectAtIndex:0] sTag]];
            [data.startStopId setString:[[filteredStopsArray objectAtIndex:0] sId]];
            [data.routeLabel setString:[[filteredStopsArray objectAtIndex:0] rId]];
        }

        NSString *query = [NSString stringWithFormat:@"SELECT * FROM stops having title=\"%@\" or title=\"%@\"",data.startLabel, data.destLabel];
        stopsArray = [[RoutesDatabase database] RoutesInfo:[query UTF8String]];
*/
    } else if ([self.operation  isEqual: @"End"]) {
        [data.destLabel setString:stop.title];
//        [data.routeId setString:stop.rId];

/*        [filteredStopsArray removeAllObjects];
        
        filteredStopsArray = [NSMutableArray arrayWithArray:[stopsArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.dTag contains[c] %@",stop.dTag]]];
*/
        if (![data.startLabel isEqualToString:@"location"] && ![data.destLabel isEqualToString:data.startLabel]) {
            //rarray1 contains all possible route directions for start stop
            //rarray2 contains all possible route directions for end stop
            NSMutableString *queryStr = [NSMutableString stringWithFormat:@"SELECT * FROM stops group by direction,stopid having title=\"%@\"", data.destLabel];
            
            [rarray2 setArray:[[RoutesDatabase database] RoutesInfo:[queryStr UTF8String]]];

//            NSLog(@"rarray 1 has %ld items rarray 2 has %ld items", [rarray1 count], [rarray2 count]);
            
            //find routes that contain both start and end stops, and put into NSArray routes
            NSUInteger length = ([rarray1 count] > [rarray2 count]) ? [rarray2 count] : [rarray1 count];
            NSMutableArray *routes = [[NSMutableArray alloc] initWithCapacity:length];
            NSMutableArray *tmp1 = [[NSMutableArray alloc] init];
            NSMutableArray *tmp2 = [[NSMutableArray alloc] init];
            for (NSInteger ii=0; ii < [rarray1 count]; ii++) {
                Stops *stop1 = [rarray1 objectAtIndex:ii];
                for (NSInteger jj=0; jj < [rarray2 count]; jj++) {
                    Stops *stop2 = [rarray2 objectAtIndex:jj];
                    if ([stop1.dTag isEqual:stop2.dTag]) {
                        [queryStr setString:[NSString stringWithFormat:@"SELECT * FROM route_%@ group by key,tag having title=\"%@\"", stop1.dTag, stop1.title]];
                        [tmp1 setArray:[[RoutesDatabase database] DirectionsInfo:[queryStr UTF8String] direction:stop1.dTag route:stop1.rId]];
                        [queryStr setString:[NSString stringWithFormat:@"SELECT * FROM route_%@ group by key,tag having title=\"%@\"", stop2.dTag, stop2.title]];
                        [tmp2 setArray:[[RoutesDatabase database] DirectionsInfo:[queryStr UTF8String] direction:stop2.dTag route:stop2.rId]];
                        if ([tmp1 count] > 0 && [tmp2 count] > 0) {
                            stop1 = [tmp1 objectAtIndex:0];
                            stop2 = [tmp2 objectAtIndex:0];
                            if (stop1 < stop2) {
                                [directionArray addObject:stop1.dTag];
                            }
                        }

                        NSArray *tmpRoute = [[NSArray alloc] initWithObjects:[rarray1 objectAtIndex:ii],[rarray2 objectAtIndex:jj],nil];
                        [routes addObject:tmpRoute];
                    }
                }
            }
            
            if ([rarray1 count] > 0) {
                [data.startStopTag setString:[[rarray1 objectAtIndex:0] sTag]];
                [data.startStopId setString:[[rarray1 objectAtIndex:0] sId]];
                [data.routeLabel setString:[directionArray objectAtIndex:0]];
            }
        }
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
