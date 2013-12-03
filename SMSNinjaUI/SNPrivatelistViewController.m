#import "SNPrivatelistViewController.h"
#import "SNNumberViewController.h"
#import "SNContentViewController.h"
#import "SNTimeViewController.h"
#import "SNSystemMessageHistoryViewController.h"
#import "SNSystemCallHistoryViewController.h"
#import <sqlite3.h>

#ifndef SMSNinjaDebug
#define SETTINGS @"/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/var/mobile/Library/SMSNinja/smsninja.db"
#else
#define SETTINGS @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/9E87534C-FD0A-450A-8863-0BAF0D62C9F0/Documents/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/9E87534C-FD0A-450A-8863-0BAF0D62C9F0/Documents/var/mobile/Library/SMSNinja/smsninja.db"
#endif

@implementation SNPrivatelistViewController

@synthesize chosenKeyword;
@synthesize chosenName;

- (void)dealloc
{
	[keywordArray release];
	keywordArray = nil;
    
	[typeArray release];
	typeArray = nil;
    
	[nameArray release];
	nameArray = nil;
    
	[phoneArray release];
	phoneArray = nil;
    
	[smsArray release];
	smsArray = nil;
    
	[replyArray release];
	replyArray = nil;
    
	[messageArray release];
	messageArray = nil;
    
	[forwardArray release];
	forwardArray = nil;
    
	[numberArray release];
	numberArray = nil;
    
	[soundArray release];
	soundArray = nil;
    
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
		NSString *sql = [NSString stringWithFormat:@"select keyword, type, name, phone, sms, reply, message, forward, number, sound from privatelist limit %d, 50", [keywordArray count]];
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
                
				char *phone = (char *)sqlite3_column_text(statement, 3);
				[phoneArray addObject:phone ? [NSString stringWithUTF8String:phone] : @""];
                
				char *sms = (char *)sqlite3_column_text(statement, 4);
				[smsArray addObject:sms ? [NSString stringWithUTF8String:sms] : @""];
                
				char *reply = (char *)sqlite3_column_text(statement, 5);
				[replyArray addObject:reply ? [NSString stringWithUTF8String:reply] : @""];
                
				char *message = (char *)sqlite3_column_text(statement, 6);
				[messageArray addObject:message ? [NSString stringWithUTF8String:message] : @""];
                
				char *forward = (char *)sqlite3_column_text(statement, 7);
				[forwardArray addObject:forward ? [NSString stringWithUTF8String:forward] : @""];
                
				char *number = (char *)sqlite3_column_text(statement, 8);
				[numberArray addObject:number ? [NSString stringWithUTF8String:number] : @""];
                
				char *sound = (char *)sqlite3_column_text(statement, 9);
				[soundArray addObject:sound ? [NSString stringWithUTF8String:sound] : @""];
			}
			sqlite3_finalize(statement);
		}
		else NSLog(@"SMSNinja: Failed to prepare %@, error %d", DATABASE, prepareResult);
		sqlite3_close(database);
	}
	else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
}

- (SNPrivatelistViewController *)init
{
	if ((self = [super initWithStyle:UITableViewStylePlain]))
	{
		self.title= NSLocalizedString(@"Private", @"Private");
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
        
		keywordArray = [[NSMutableArray alloc] initWithCapacity:600];
		typeArray = [[NSMutableArray alloc] initWithCapacity:600];
		nameArray = [[NSMutableArray alloc] initWithCapacity:600];
		phoneArray = [[NSMutableArray alloc] initWithCapacity:600];
		smsArray = [[NSMutableArray alloc] initWithCapacity:600];
		replyArray = [[NSMutableArray alloc] initWithCapacity:600];
		messageArray = [[NSMutableArray alloc] initWithCapacity:600];
		forwardArray = [[NSMutableArray alloc] initWithCapacity:600];
		numberArray = [[NSMutableArray alloc] initWithCapacity:600];
		soundArray = [[NSMutableArray alloc] initWithCapacity:600];
		chosenName = [[NSString alloc] initWithString:@""];
		chosenKeyword = [[NSString alloc] initWithString:@""];
        
		[self loadDatabaseSegment];
	}
	return self;
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
    for (UIView *subview in [cell.contentView subviews])
        [subview removeFromSuperview];
    cell.textLabel.text = nil;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
	UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 2.0f, cell.contentView.bounds.size.width - 50.0f, (cell.contentView.bounds.size.height - 4.0f) / 2.0f)];
	nameLabel.text = [nameArray objectAtIndex:indexPath.row];
	[cell.contentView addSubview:nameLabel];
	[nameLabel release];
    
	UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabel.frame.origin.x, nameLabel.frame.origin.y + nameLabel.frame.size.height, nameLabel.bounds.size.width, nameLabel.bounds.size.height)];
	contentLabel.text = [keywordArray objectAtIndex:indexPath.row];
	[cell.contentView addSubview:contentLabel];
	[contentLabel release];
    
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSSet *deleteSet = [NSSet setWithObject:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
    
    sqlite3 *database;
    int openResult = sqlite3_open([DATABASE UTF8String], &database);
    if (openResult == SQLITE_OK)
    {
        for (NSIndexPath *chosenRowIndexPath in deleteSet)
        {
            NSString *sql = [NSString stringWithFormat:@"delete from privatelist where keyword = '%@' and type = '%@' and name = '%@' and phone = '%@' and sms = '%@' and reply = '%@' and message = '%@' and forward = '%@' and number = '%@' and sound = '%@'", [keywordArray objectAtIndex:chosenRowIndexPath.row], [typeArray objectAtIndex:chosenRowIndexPath.row], [[nameArray objectAtIndex:chosenRowIndexPath.row] stringByReplacingOccurrencesOfString:@"'" withString:@"''"], [phoneArray objectAtIndex:chosenRowIndexPath.row], [smsArray objectAtIndex:chosenRowIndexPath.row], [replyArray objectAtIndex:chosenRowIndexPath.row], [[messageArray objectAtIndex:chosenRowIndexPath.row] stringByReplacingOccurrencesOfString:@"'" withString:@"''"], [forwardArray objectAtIndex:chosenRowIndexPath.row], [numberArray objectAtIndex:chosenRowIndexPath.row], [soundArray objectAtIndex:chosenRowIndexPath.row]];
            int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
            if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
        }
        sqlite3_close(database);
    }
    else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
    
    NSMutableIndexSet *discardedItems = [NSMutableIndexSet indexSet];
    for (NSIndexPath *chosenRowIndexPath in deleteSet) [discardedItems addIndex:chosenRowIndexPath.row];
    
    [keywordArray removeObjectsAtIndexes:discardedItems];
    [typeArray removeObjectsAtIndexes:discardedItems];
    [nameArray removeObjectsAtIndexes:discardedItems];
    [phoneArray removeObjectsAtIndexes:discardedItems];
    [smsArray removeObjectsAtIndexes:discardedItems];
    [replyArray removeObjectsAtIndexes:discardedItems];
    [messageArray removeObjectsAtIndexes:discardedItems];
    [forwardArray removeObjectsAtIndexes:discardedItems];
    [numberArray removeObjectsAtIndexes:discardedItems];
    [soundArray removeObjectsAtIndexes:discardedItems];
    
	[tableView beginUpdates];
	[tableView deleteRowsAtIndexPaths:[deleteSet allObjects] withRowAnimation:UITableViewRowAnimationFade];
	[tableView endUpdates];
}

- (void)gotoNumberView
{
	SNNumberViewController *numberViewController = [[SNNumberViewController alloc] init];
	numberViewController.flag = @"private";
	numberViewController.nameString = @"";
	numberViewController.keywordString = @"";
    numberViewController.originalKeyword = numberViewController.keywordString;
	numberViewController.phoneAction = @"1";
	numberViewController.messageAction = @"1";
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
	contentViewController.flag = @"private";
	contentViewController.nameString = @"";
	contentViewController.keywordString = @"";
    contentViewController.originalKeyword = contentViewController.keywordString;
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
	systemCallHistoryViewController.flag = @"private";
	[self.navigationController pushViewController:systemCallHistoryViewController animated:YES];
	[systemCallHistoryViewController release];
}

- (void)gotoSystemMessageHistoryView
{
	SNSystemMessageHistoryViewController *systemMessageHistoryViewController = [[SNSystemMessageHistoryViewController alloc] init];
	systemMessageHistoryViewController.flag = @"private";
	[self.navigationController pushViewController:systemMessageHistoryViewController animated:YES];
	[systemMessageHistoryViewController release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (actionSheet.tag == 1)
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
	else if (actionSheet.tag == 2)
	{
        if (buttonIndex != 2)
        {
            __block SNPrivatelistViewController *weakSelf = self;
            __block NSInteger weakButtonIndex = buttonIndex;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                           {
                               sqlite3 *database;
                               int openResult = sqlite3_open([DATABASE UTF8String], &database);
                               if (openResult == SQLITE_OK)
                               {
                                   NSString *sql = [NSString stringWithFormat:@"insert or replace into privatelist (keyword, type, name, phone, sms, reply, message, forward, number, sound) values ('%@', '0', '%@', '1', '1', '0', '', '0', '', '%d')", weakSelf.chosenKeyword, [weakSelf.chosenName stringByReplacingOccurrencesOfString:@"'" withString:@"''"], weakButtonIndex];
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
            [soundArray addObject:[NSString stringWithFormat:@"%d", buttonIndex]];
            
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:([keywordArray count] - 1) inSection:0]] withRowAnimation:YES];
            [self.tableView endUpdates];
            
            [self dismissModalViewControllerAnimated:YES];
        }
	}
}

- (void)addRecord
{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"From addressbook", @"From addressbook"), NSLocalizedString(@"From call history", @"From call history"), NSLocalizedString(@"From message history", @"From message history"), NSLocalizedString(@"Enter numbers", @"Enter numbers"), NSLocalizedString(@"Enter keywords", @"Enter keywords"), nil];
	actionSheet.tag = 1;
	[actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
	[actionSheet release];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	if (editing) [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", @"Add") style:UIBarButtonItemStyleBordered target:self action:@selector(addRecord)] autorelease] animated:animated];
	else [self.navigationItem setLeftBarButtonItem:nil animated:animated];
	[super setEditing:editing animated:animated];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([[typeArray objectAtIndex:indexPath.row] isEqualToString:@"0"]) // SNNumberViewController
	{
		SNNumberViewController *numberViewController = [[SNNumberViewController alloc] init];
		numberViewController.flag = @"private";
		numberViewController.nameString = [nameArray objectAtIndex:indexPath.row];
		numberViewController.keywordString = [keywordArray objectAtIndex:indexPath.row];
        numberViewController.originalKeyword = numberViewController.keywordString;
		numberViewController.phoneAction = [phoneArray objectAtIndex:indexPath.row];
		numberViewController.messageAction = [smsArray objectAtIndex:indexPath.row];
		numberViewController.replyString = [replyArray objectAtIndex:indexPath.row];
		numberViewController.messageString = [messageArray objectAtIndex:indexPath.row];
		numberViewController.forwardString = [forwardArray objectAtIndex:indexPath.row];
		numberViewController.numberString = [numberArray objectAtIndex:indexPath.row];
		numberViewController.soundString = [soundArray objectAtIndex:indexPath.row];
		[self.navigationController pushViewController:numberViewController animated:YES];
		[numberViewController release];
	}
	else if ([[typeArray objectAtIndex:indexPath.row] isEqualToString:@"1"]) // SNContentViewController
	{
		SNContentViewController *contentViewController = [[SNContentViewController alloc] init];
        contentViewController.flag = @"private";
		contentViewController.nameString = [nameArray objectAtIndex:indexPath.row];
		contentViewController.keywordString = [keywordArray objectAtIndex:indexPath.row];
        contentViewController.originalKeyword = contentViewController.keywordString;
		contentViewController.replyString = [replyArray objectAtIndex:indexPath.row];
		contentViewController.messageString = [messageArray objectAtIndex:indexPath.row];
		contentViewController.forwardString = [forwardArray objectAtIndex:indexPath.row];
		contentViewController.numberString = [numberArray objectAtIndex:indexPath.row];
		contentViewController.soundString = [soundArray objectAtIndex:indexPath.row];
		[self.navigationController pushViewController:contentViewController animated:YES];
		[contentViewController release];
	}
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
        self.chosenName = nil;
		self.chosenName = [firstName ? (NSString *)firstName : @"" stringByAppendingString:lastName ? (NSString *)lastName : @""];
		if (firstName) CFRelease(firstName);
		if (lastName) CFRelease(lastName);
        
		ABMultiValueRef keywords = ABRecordCopyValue(person, property);
		if (!keywords) return NO;
		CFStringRef keyword = (CFStringRef)ABMultiValueCopyValueAtIndex(keywords, identifier);
		if (!keyword)
		{
			CFRelease(keywords);
			return NO;
		}

        NSString *tempString = (NSString *)keyword;
        tempString = [tempString stringByReplacingOccurrencesOfString:@" " withString:@""];
        tempString = [tempString stringByReplacingOccurrencesOfString:@"-" withString:@""];
        tempString = [tempString stringByReplacingOccurrencesOfString:@"(" withString:@""];
        tempString = [tempString stringByReplacingOccurrencesOfString:@")" withString:@""];
        
        self.chosenKeyword = nil;
        self.chosenKeyword = tempString;
        
        CFRelease(keyword);
		CFRelease(keywords);
        
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Turn off the beep", @"Turn off the beep"), NSLocalizedString(@"Turn on the beep", @"Turn on the beep"), nil];
		actionSheet.tag = 2;
        [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
		[actionSheet release];
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.size.height && scrollView.contentOffset.y != -64.0f && scrollView.contentOffset.y != 0.0f)
	{
		[self.tableView beginUpdates];
		int count = [keywordArray count];
		[self loadDatabaseSegment];
		NSMutableArray *insertIndexPaths = [NSMutableArray arrayWithCapacity:50];
		for (int i = count; i < [keywordArray count]; i++)
		{
			NSIndexPath *newPath =  [NSIndexPath indexPathForRow:i inSection:0];
			[insertIndexPaths insertObject:newPath atIndex:i];
		}
		[self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationFade];
		[self.tableView endUpdates];
	}
}
@end