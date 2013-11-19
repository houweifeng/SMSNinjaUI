#import "SNWhitelistViewController.h"
#import "SNNumberViewController.h"
#import "SNContentViewController.h"
#import "SNSystemMessageHistoryViewController.h"
#import "SNSystemCallHistoryViewController.h"
#import "SNMainViewController.h"
#import <sqlite3.h>

#define SETTINGS @"/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/var/mobile/Library/SMSNinja/smsninja.db"

@implementation SNWhitelistViewController
- (void)dealloc
{
	[keywordArray release];
	keywordArray = nil;
    
	[typeArray release];
	typeArray = nil;
    
	[nameArray release];
	nameArray = nil;
    
	[chosenName release];
	chosenName = nil;
    
	[chosenKeyword release];
	chosenKeyword = nil;
    
	[super dealloc];
}

- (void)loadDatabaseSegment
{
	sqlite3 *database;
	sqlite3_stmt *statement;
	int openResult = sqlite3_open([DATABASE UTF8String], &database);
	if (openResult == SQLITE_OK)
	{
		NSString *sql = @"select keyword, type, name from whitelist";
		int prepareResult = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
		if (prepareResult == SQLITE_OK)
		{
			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				char *keyword = (char *)sqlite3_column_text(statement, 0);
				[keywordArray addObject:keyword ? [NSString stringWithUTF8String:keyword] : @""];
                
				char *type = (char *)sqlite3_column_text(statement, 1);
				[typeArray addObject:type ? [NSString stringWithUTF8String:type] : @""];
                
				char *name = (char *)sqlite3_column_text(statement, 2);
				[nameArray addObject:name ? [NSString stringWithUTF8String:name] : @""];
			}
			sqlite3_finalize(statement);
		}
		else NSLog(@"SMSNinja: Failed to prepare %@, error %d", DATABASE, prepareResult);
		sqlite3_close(database);
	}
	else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
}

- (void)gotoMainView
{
	for (UIViewController *viewController in self.navigationController.viewControllers)
		if ([viewController isKindOfClass:[SNMainViewController class]])
			[self.navigationController popToViewController:viewController animated:YES];
}

- (SNWhitelistViewController *)init
{
	if ((self = [super initWithStyle:UITableViewStylePlain]))
	{
		UIButton* backButton = [UIButton buttonWithType:(UIButtonType)101];
		[backButton addTarget:self action:@selector(gotoMainView) forControlEvents:UIControlEventTouchUpInside];
		[backButton setTitle:NSLocalizedString(@"SMSNinja", @"SMSNinja") forState:UIControlStateNormal];
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:backButton] autorelease];
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
        
		keywordArray = [[NSMutableArray alloc] initWithCapacity:600];
		typeArray = [[NSMutableArray alloc] initWithCapacity:600];
		nameArray = [[NSMutableArray alloc] initWithCapacity:600];
		chosenName = [[NSString alloc] initWithFormat:@""];
		chosenKeyword = [[NSString alloc] initWithFormat:@""];
        
		[self loadDatabaseSegment];
	}
	return self;
}

- (void)segmentAction:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 1)
    {
        SNBlacklistViewController *blacklistViewController = [[SNBlacklistViewController alloc] init];
        [self.navigationController pushViewController:blacklistViewController animated:NO];
        [blacklistViewController release];
    }
}

- (void)viewDidLoad
{
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"White", @"White"), NSLocalizedString(@"Black", @"Black"), nil]];
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.frame = CGRectMake(0.0f, 0.0f, 100.0f, 30.0f);
	[segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	self.navigationItem.titleView = segmentedControl;
	[segmentedControl release];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([[typeArray objectAtIndex:indexPath.row] isEqualToString:@"0"]) // NumberViewController
	{
		SNNumberViewController *numberViewController = [[SNNumberViewController alloc] init];
		numberViewController.flag = @"white";
		numberViewController.nameString = [nameArray objectAtIndex:indexPath.row];
		numberViewController.keywordString = [keywordArray objectAtIndex:indexPath.row];
		numberViewController.phoneString = @"1";
		numberViewController.smsString = @"1";
		numberViewController.replyString = @"0";
		numberViewController.messageString = @"";
		numberViewController.forwardString = @"0";
		numberViewController.numberString = @"";
		numberViewController.soundString = @"0";
		[self.navigationController pushViewController:numberViewController animated:YES];
		[numberViewController release];
	}
	else if ([[typeArray objectAtIndex:indexPath.row] isEqualToString:@"1"]) // ContentViewController
	{
		SNContentViewController *contentViewController = [[SNContentViewController alloc] init];
		contentViewController.flag = @"white";
		contentViewController.nameString = [nameArray objectAtIndex:indexPath.row];
		contentViewController.keywordString = [keywordArray objectAtIndex:indexPath.row];
		contentViewController.replyString = @"0";
		contentViewController.messageString = @"";
		contentViewController.forwardString = @"0";
		contentViewController.numberString = @"";
		contentViewController.soundString = @"0";
		[self.navigationController pushViewController:contentViewController animated:YES];
		[contentViewController release];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [keywordArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"any-cell"];
	if (cell == nil) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"any-cell"] autorelease];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
	UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 2.0f, cell.contentView.bounds.size.width - 20.0f, (cell.contentView.bounds.size.height - 4.0f) / 2.0f)];
	nameLabel.text = [nameArray objectAtIndex:indexPath.row];
	[cell.contentView addSubview:nameLabel];
	[nameLabel release];
    
	UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabel.frame.origin.x, nameLabel.frame.origin.y + nameLabel.frame.size.height, nameLabel.bounds.size.width, nameLabel.bounds.size.height)];
	contentLabel.text = [keywordArray objectAtIndex:indexPath.row];
	[cell.contentView addSubview:contentLabel];
	[contentLabel release];
    
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return NSLocalizedString(@"Whitelist", @"Whitelist");
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block NSSet *deleteSet = [NSSet setWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
    __block SNBlacklistViewController *weakSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                   {
                       sqlite3 *database;
                       int openResult = sqlite3_open([DATABASE UTF8String], &database);
                       if (openResult == SQLITE_OK)
                       {
                           for (NSIndexPath *chosenRowIndexPath in deleteSet)
                           {
                               NSString *sql = [NSString stringWithFormat:@"delete from whitelist where keyword = '%@' and type = '%@' and name = '%@'", [weakSelf->keywordArray objectAtIndex:chosenRowIndexPath.row], [weakSelf->typeArray objectAtIndex:chosenRowIndexPath.row], [[weakSelf->nameArray objectAtIndex:chosenRowIndexPath.row] stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
                               int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
                               if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
                               
                               [weakSelf->keywordArray removeObjectAtIndex:chosenRowIndexPath.row];
                               [weakSelf->typeArray removeObjectAtIndex:chosenRowIndexPath.row];
                               [weakSelf->nameArray removeObjectAtIndex:chosenRowIndexPath.row];
                           }
                           sqlite3_close(database);
                       }
                       else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
                   });
	[tableView beginUpdates];
	[tableView deleteRowsAtIndexPaths:[deleteSet allObjects] withRowAnimation:UITableViewRowAnimationFade];
	[tableView endUpdates];
}

- (void)gotoNumberView
{
	SNNumberViewController *numberViewController = [[SNNumberViewController alloc] init];
	numberViewController.flag = @"white";
	numberViewController.nameString = @"";
	numberViewController.keywordString = @"";
	numberViewController.phoneString = @"1";
	numberViewController.smsString = @"1";
	numberViewController.replyString = @"0";
	numberViewController.messageString = @"";
	numberViewController.forwardString = @"0";
	numberViewController.numberString = @"";
	numberViewController.soundString = @"0";
	[self.navigationController pushViewController:numberViewController animated:YES];
	[numberViewController release];
}

- (void)gotoContentView
{
	SNContentViewController *contentViewController = [[SNContentViewController alloc] init];
	contentViewController.flag = @"white";
	contentViewController.nameString = @"";
	contentViewController.keywordString = @"";
	contentViewController.replyString = @"0";
	contentViewController.messageString = @"";
	contentViewController.forwardString = @"0";
	contentViewController.numberString = @"";
	contentViewController.soundString = @"0";
	[self.navigationController pushViewController:contentViewController animated:YES];
	[contentViewController release];
}

- (void)gotoSystemCallHistoryView
{
	SNSystemCallHistoryViewController *systemCallHistoryViewController = [[SNSystemCallHistoryViewController alloc] init];
	systemCallHistoryViewController.flag = @"white";
	[self.navigationController pushViewController:systemCallHistoryViewController animated:YES];
	[systemCallHistoryViewController release];
}

- (void)gotoSystemMessageHistoryView
{
	SNSystemMessageHistoryViewController *systemMessageHistoryViewController = [[SNSystemMessageHistoryViewController alloc] init];
	systemMessageHistoryViewController.flag = @"white";
	[self.navigationController pushViewController:systemMessageHistoryViewController animated:YES];
	[systemMessageHistoryViewController release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex)
	{
		case 0:
			[self gotoAddressbook];
			break;
		case 1:
			[self gotoSystemCallHistoryView];
			break;
		case 2:
			[self gotoSystemMessageHistoryView];
			break;
		case 3:
			[self gotoNumberView];
			break;
		case 4:
			[self gotoContentView];
			break;
	}
}

- (void)addRecord
{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"From addressbook", @"From addressbook"), NSLocalizedString(@"From call history", @"From call history"), NSLocalizedString(@"From message history", @"From message history"), NSLocalizedString(@"Enter numbers", @"Enter numbers"), NSLocalizedString(@"Enter keywords", @"Enter keywords"), nil];
	[actionSheet showFromToolbar:self.navigationController.toolbar];
	[actionSheet release];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	if (editing)
	{
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", @"Add") style:UIBarButtonItemStyleBordered target:self action:@selector(chooseSource)] autorelease];
	}
	else
	{
		UIButton* backButton = [UIButton buttonWithType:(UIButtonType)101];
		[backButton addTarget:self action:@selector(gotoMainView) forControlEvents:UIControlEventTouchUpInside];
		[backButton setTitle:NSLocalizedString(@"SMSNinja", @"SMSNinja") forState:UIControlStateNormal];
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:backButton] autorelease];
	}
	[super setEditing:editing animated:animated];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	if (property == kABPersonEmailProperty || property == kABPersonPhoneProperty)
	{
		CFMutableStringRef firstName = (CFMutableStringRef)ABRecordCopyValue(person, kABPersonFirstNameProperty);
		CFMutableStringRef lastName =  (CFMutableStringRef)ABRecordCopyValue(person, kABPersonLastNameProperty);
		self.chosenName = [firstName ? (NSString *)firstName : @"" stringByAppendingString:lastName ? (NSString *)lastName : @""];
		if (firstName) CFRelease(firstName);
		if (lastName) CFRelease(lastName);
        
		ABMultiValueRef keywords = ABRecordCopyValue(person, property);
		if (!keywords)
		{
			CFRelease(keywords);
			return NO;
		}
		CFStringRef keyword = (CFStringRef)ABMultiValueCopyValueAtIndex(keywords, identifier);
		if (!keyword)
		{
			CFRelease(keywords);
			CFRelease(keyword);
			return NO;
		}
		self.chosenKeyword = (NSString *)keyword;
		CFRelease(keyword);
		CFRelease(keywords);
        
        __block SNBlacklistViewController *weakSelf = self;
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                       {
                           sqlite3 *database;
                           int openResult = sqlite3_open([DATABASE UTF8String], &database);
                           if (openResult == SQLITE_OK)
                           {
                               NSString *sql = [NSString stringWithFormat:@"insert or replace into whitelist (keyword, type, name, phone, sms, reply, message, forward, number, sound) values ('%@', '0', '%@', '1', '1', '0', '', '0', '', '0')", weakSelf.chosenKeyword, [weakSelf.chosenName stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
                               int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
                               if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
                               sqlite3_close(database);
                           }
                           else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
                       });
        
		[keywordArray addObject:self.chosenKeyword];
		[typeArray addObject:@"0"];
		[nameArray addObject:self.chosenName];
		[phoneArray addObject:@"1"];
		[smsArray addObject:@"1"];
		[replyArray addObject:@"0"];
		[messageArray addObject:@""];
		[forwardArray addObject:@"0"];
		[numberArray addObject:@""];
		[soundArray addObject:@"0"];
        
		[self.tableView beginUpdates];
		[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:YES];
		[self.tableView endUpdates];
        
		[self dismissModalViewControllerAnimated:YES];
	}
	return NO;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)gotoAddressbook
{
	ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
	picker.peoplePickerDelegate = self;
	[self presentModalViewController:picker animated:YES];
	[picker release];
}
@end