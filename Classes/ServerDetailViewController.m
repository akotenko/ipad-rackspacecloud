//
//  ServerDetailViewController.m
//  RackspaceCloud
//
//  Created by Michael Mayo on 1/27/10.
//  Copyright Apple Inc 2010. All rights reserved.
//

// TODO: default view for when there are no servers
// TODO: correct off-black in login screen background graphic

// TODO: ping server:
// http://just-ping.com/index.php?vh=173.203.226.198&s=ping
// TODO: also for IP: open in safari, copy in clipboard, email IP address

#import "ServerDetailViewController.h"
#import "MasterViewController.h"
#import "ASICloudServersServer.h"
#import "ASICloudServersImage.h"
#import "ASICloudServersImageRequest.h"
#import "ASICloudServersFlavor.h"
#import "ASICloudServersFlavorRequest.h"
#import "AddServerViewController.h"
#import "RenameServerViewController.h"
#import "ResetServerAdminPasswordViewController.h"
#import "RebootServerViewController.h"
#import "ResizeServerViewController.h"
#import "CreateServerSnapshotViewController.h"
#import "ManageBackupSchedulesViewController.h"
#import "RebuildServerViewController.h"
#import "UIViewController+SpinnerView.h"
#import "ASICloudServersServerRequest.h"


#import "ServersListViewController.h"


#define kNameSection 0
#define kDetailsSection 1
#define kPublicIPSection 2
#define kPrivateIPSection 3
#define kMetadataSection 4
#define kActionSection 5


@implementation ServerDetailViewController

@synthesize navigationBar, popoverController, detailItem;
@synthesize tableView;
@synthesize server;
@synthesize logoImageView, backgroundImageView;

#pragma mark -
#pragma mark HTTP Response Handlers

- (void)listBackupScheduleFinished:(ASICloudServersServerRequest *)request {
	NSLog(@"Rename Response: %i - %@", [request responseStatusCode], [request responseString]);
	[self hideSpinnerView];
	
	if ([request responseStatusCode] == 204) {
		//self.serverDetailViewController.server.name = textField.text;
		//[self.serverDetailViewController.tableView reloadData];
		//[self dismissModalViewControllerAnimated:YES];
	} else {
		NSString *title = @"Error";
		NSString *errorMessage = @"There was a problem renaming your server.";
		switch ([request responseStatusCode]) {
			case 400: // cloudServersFault
				break;
			case 500: // cloudServersFault
				break;
			case 503:
				errorMessage = @"Your server was not renamed because the service is currently unavailable.  Please try again later.";
				break;				
			case 401:
				title = @"Authentication Failure";
				errorMessage = @"Please check your User Name and API Key.";
				break;
			case 409:
				errorMessage = @"Your server cannot be renamed at the moment because it is currently building.";
				break;
			case 413:
				errorMessage = @"Your server cannot be renamed at the moment because you have exceeded your API rate limit.  Please try again later or contact support for a rate limit increase.";
				break;
			default:
				break;
		}
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

#pragma mark -
#pragma mark Managing the popover controller

/*
 When setting the detail item, update the view and dismiss the popover controller if it's showing.
 */
- (void)setDetailItem:(id)newDetailItem {
    if (detailItem != newDetailItem) {
        [detailItem release];
        detailItem = [newDetailItem retain];
        
        // Update the view.
        navigationBar.topItem.title = [detailItem description];
    }
	
    if (popoverController != nil) {
        [popoverController dismissPopoverAnimated:YES];
    }        
}

#pragma mark -
#pragma mark Table View Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 6;
}

// TODO: metadata CRUD

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == kActionSection) {
		return 8;
	} else if (section == kNameSection) {
		return 3;
	} else if (section == kDetailsSection) {
		return 3;
	} else if (section == kPublicIPSection) {
		return [server.publicIpAddresses count];
	} else if (section == kPrivateIPSection) {
		return [server.privateIpAddresses count];
	} else if (section == kMetadataSection) {
		return [[server.metadata allKeys] count];
	} else {
		return 0;
	}
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section {
	if (section == kNameSection) {
		return @"Overview";
	} else if (section == kDetailsSection) {
		return @"Technical Details";
	} else if (section == kPublicIPSection) {
		return @"Public IP Addresses";
	} else if (section == kPrivateIPSection) {
		return @"Private IP Addresses";
	} else if (section == kMetadataSection) {
		if ([[server.metadata allKeys] count] > 0) {
			return @"Server Metadata";
		} else {
			return @"";
		}
	}
	
	return @"Actions";
}


- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	// TODO: move this to initWithNibName
	self.logoImageView.image = [ASICloudServersImage logoForImageId:server.imageId];
	self.backgroundImageView.image = [ASICloudServersImage backgroundForImageId:server.imageId];
	
	
	self.tableView.backgroundView = nil; // makes it clear
	self.detailItem = @"Server Details";
	self.navigationItem.title = @"Server Details";
	
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = (UITableViewCell *) [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier] autorelease];
		//cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.accessoryType = UITableViewCellAccessoryNone;
	}

	UITableViewCell *actionCell = (UITableViewCell *) [aTableView dequeueReusableCellWithIdentifier:@"ActionCell"];
	if (actionCell == nil) {
		actionCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ActionCell"] autorelease];
		//cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		actionCell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	
	if (indexPath.section == kNameSection) {
		if (indexPath.row == 0) {
			cell.textLabel.text = @"Server Name";
			cell.detailTextLabel.text = server.name;
		} else if (indexPath.row == 1) {
			cell.textLabel.text = @"Status";
			cell.detailTextLabel.text = server.status;
		} else if (indexPath.row == 2) {
			cell.textLabel.text = @"Host ID";
			cell.detailTextLabel.text = server.hostId;
		} else {
		}
	} else if (indexPath.section == kDetailsSection) {
		ASICloudServersFlavor *flavor = [ASICloudServersFlavorRequest flavorForId:server.flavorId];
		if (indexPath.row == 0) {
			cell.textLabel.text = @"Operating System";			
			cell.detailTextLabel.text = [ASICloudServersImageRequest imageForId:server.imageId].name;
		} else if (indexPath.row == 1) {
			cell.textLabel.text = @"Memory";
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%i MB", flavor.ram];
		} else if (indexPath.row == 2) {
			cell.textLabel.text = @"Disk";
			cell.detailTextLabel.text = [NSString stringWithFormat:@"%i GB", flavor.disk];
		}
	} else if (indexPath.section == kActionSection) {
		if (indexPath.row == 0) {
			actionCell.textLabel.text = @"Reboot This Server";
		} else if (indexPath.row == 1) {
			actionCell.textLabel.text = @"Rename This Server";
		} else if (indexPath.row == 2) {
			actionCell.textLabel.text = @"Change the Size of RAM and Disk on This Server";
		} else if (indexPath.row == 3) {
			actionCell.textLabel.text = @"Change the Root Password";
		} else if (indexPath.row == 4) {
			// POST /images
			// TODO: clone this server?  (create snapshot + create new server)
			actionCell.textLabel.text = @"Create a Snapshot Backup Image of This Server";
		} else if (indexPath.row == 5) {
			actionCell.textLabel.text = @"Manage Backup Schedules";
		} else if (indexPath.row == 6) {
			actionCell.textLabel.text = @"Rebuild This Server"; // From Scratch" ?
		} else if (indexPath.row == 7) {
			actionCell.textLabel.text = @"Delete This Server";
		}
		return actionCell;
	} else if (indexPath.section == kPublicIPSection) {
		cell.textLabel.text = @"";
		cell.detailTextLabel.text = [[server publicIpAddresses] objectAtIndex:indexPath.row];
	} else if (indexPath.section == kPrivateIPSection) {
		cell.textLabel.text = @"";
		cell.detailTextLabel.text = [[server privateIpAddresses] objectAtIndex:indexPath.row];
	} else if (indexPath.section == kMetadataSection) {
		NSString *key = [[server.metadata allKeys] objectAtIndex:indexPath.row];
		cell.textLabel.text = key;
		cell.detailTextLabel.text = [server.metadata objectForKey:key];
	} else {
		cell.textLabel.text = @"";
		cell.detailTextLabel.text = @"";
	}
	
	return cell;
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {	
	if (indexPath.section == kActionSection) {
		
		NSString *className = nil;
		
		switch (indexPath.row) {
			case 0:
				className = @"RebootServerViewController";
				break;
			case 1:
				className = @"RenameServerViewController";
				break;
			case 2:
				className = @"ResizeServerViewController";
				break;
			case 3:
				className = @"ResetServerAdminPasswordViewController";
				break;
			case 4:
				className = @"CreateServerSnapshotViewController";
				break;
			case 5:
				className = @"ManageBackupSchedulesViewController";
				break;
			case 6:
				className = @"RebuildServerViewController";
				break;
			default:
				break;
		}

		if (className != nil) {
			// it's a modal view controller, so show it
			Class class = NSClassFromString(className);
			UIViewController *vc = [[class alloc] initWithNibName:className bundle:nil];
			vc.modalPresentationStyle = UIModalPresentationFormSheet;
			SEL method = NSSelectorFromString(@"setServerDetailViewController:");
			if ([vc respondsToSelector:method]) {
				[vc performSelector:method withObject:self];
			}
			
			[self presentModalViewController:vc animated:YES];
		} else {
			if (indexPath.row == 7) {
				NSString *title = @"Are you sure you want to delete this server?  This operation cannot be undone and you will lose all backup images.";
				//NSString *deleteTitle = [NSString stringWithFormat:@"Permanently Delete Server %@", self.server.name];
				NSString *deleteTitle = @"Delete This Server";
				UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:deleteTitle otherButtonTitles:nil];
				actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
				//UITableViewCell *cell = [self tableView:self.tableView cellForRowAtIndexPath:indexPath];
				[actionSheet showInView:self.view];
				[actionSheet release];
			}			
		}
		
	} else if (indexPath.section == kPublicIPSection) {
		// TODO: popover with ping, copy, and email
		//ServersListViewController *vc = [[ServersListViewController alloc] initWithNibName:@"ServersListViewController" bundle:nil];
		MasterViewController *vc = [[MasterViewController alloc] init];
		UIPopoverController *pc = [[UIPopoverController alloc] initWithContentViewController:vc];
		//- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
		
		UITableViewCell *cell = [self tableView:self.tableView cellForRowAtIndexPath:indexPath];		
		[pc presentPopoverFromRect:cell.contentView.frame inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		
		[pc release];
		[vc release];
		
	} else if (indexPath.section == kPrivateIPSection) {
		// TODO: popover with copy, and email
	}
}

#pragma mark -
#pragma mark Button Handlers

-(void)addButtonPressed:(id)sender {
	AddServerViewController *vc = [[AddServerViewController alloc] initWithNibName:@"AddServerViewController" bundle:nil];
	vc.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentModalViewController:vc animated:YES];
}


#pragma mark -
#pragma mark Split view support

- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc {
    
    barButtonItem.title = @"Servers";
    [navigationBar.topItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.popoverController = pc;
}


// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    
    [navigationBar.topItem setLeftBarButtonItem:nil animated:YES];
    self.popoverController = nil;
}


#pragma mark -
#pragma mark Rotation support

// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


#pragma mark -
#pragma mark View lifecycle

/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad {
 [super viewDidLoad];
 }
 */


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

/*
 - (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 }
 */
/*
 - (void)viewWillDisappear:(BOOL)animated {
 [super viewWillDisappear:animated];
 }
 */
/*
 - (void)viewDidDisappear:(BOOL)animated {
 [super viewDidDisappear:animated];
 }
 */

- (void)viewDidUnload {
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    self.popoverController = nil;
}


#pragma mark -
#pragma mark Memory management

/*
 - (void)didReceiveMemoryWarning {
 // Releases the view if it doesn't have a superview.
 [super didReceiveMemoryWarning];
 
 // Release any cached data, images, etc that aren't in use.
 }
 */

- (void)dealloc {
    [popoverController release];
    [navigationBar release];
    
    [detailItem release];
	
	[tableView release];
	[server release];
	
	[logoImageView release];
	[backgroundImageView release];
	
    [super dealloc];
}

@end
