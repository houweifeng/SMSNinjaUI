#import "SNPrivateMessageHistoryViewController.h"
#import "SNPrivateCallHistoryViewController.h"
#import "SNPictureViewController.h"
#import <UIKit/UIPasteboard.h>
#import <objc/runtime.h>
#import <sqlite3.h>

#ifndef SMSNinjaDebug
#define SETTINGS @"/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/var/mobile/Library/SMSNinja/smsninja.db"
#define PRIVATEPICTURES @"/var/mobile/Library/SMSNinja/PrivatePictures/"
#else
#define SETTINGS @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/9E87534C-FD0A-450A-8863-0BAF0D62C9F0/Documents/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/9E87534C-FD0A-450A-8863-0BAF0D62C9F0/Documents/var/mobile/Library/SMSNinja/smsninja.db"
#define PRIVATEPICTURES @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/9E87534C-FD0A-450A-8863-0BAF0D62C9F0/Documents/var/mobile/Library/SMSNinja/PrivatePictures/"
#endif

@implementation SNPrivateMessageHistoryViewController
- (void)dealloc
{
	[idArray release];
	idArray = nil;
    
	[nameArray release];
	nameArray = nil;
    
	[contentArray release];
	contentArray = nil;
    
	[timeArray release];
	timeArray = nil;
    
	[numberArray release];
	numberArray = nil;
    
	[picturesArray release];
	picturesArray = nil;
    
	[bulkSet release];
	bulkSet = nil;
    
	[super dealloc];
}

- (void)bulkDelete
{
    sqlite3 *database;
    int openResult = sqlite3_open([DATABASE UTF8String], &database);
    if (openResult == SQLITE_OK)
    {
        for (NSIndexPath *chosenRowIndexPath in bulkSet)
        {
            NSString *sql = [NSString stringWithFormat:@"delete from privatesms where number = '%@' and name = '%@' and time = '%@' and content = '%@' and id = '%@' and pictures = '%@'", [numberArray objectAtIndex:chosenRowIndexPath.row], [[nameArray objectAtIndex:chosenRowIndexPath.row] stringByReplacingOccurrencesOfString:@"'" withString:@"''"], [timeArray objectAtIndex:chosenRowIndexPath.row], [[contentArray objectAtIndex:chosenRowIndexPath.row] stringByReplacingOccurrencesOfString:@"'" withString:@"''"], [idArray objectAtIndex:chosenRowIndexPath.row], [picturesArray objectAtIndex:chosenRowIndexPath.row]];
            int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
            if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *error = nil;
            for (int i = 0; i < [[picturesArray objectAtIndex:chosenRowIndexPath.row] intValue]; i++)
            {
                [fileManager removeItemAtPath:[[PRIVATEPICTURES stringByAppendingString:[idArray objectAtIndex:chosenRowIndexPath.row]] stringByAppendingFormat:@"-%d.png", i] error:&error];
                if (error) NSLog(@"SMSNinja: Failed to delete %@, error %@", [[PRIVATEPICTURES stringByAppendingString:[idArray objectAtIndex:chosenRowIndexPath.row]] stringByAppendingFormat:@"-%d.png", i], [error localizedDescription]);
            }
        }
        sqlite3_close(database);
    }
    else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
    
    NSMutableIndexSet *discardedItems = [NSMutableIndexSet indexSet];
    for (NSIndexPath *chosenRowIndexPath in bulkSet) [discardedItems addIndex:chosenRowIndexPath.row];
    
    [idArray removeObjectsAtIndexes:discardedItems];
    [nameArray removeObjectsAtIndexes:discardedItems];
    [contentArray removeObjectsAtIndexes:discardedItems];
    [timeArray removeObjectsAtIndexes:discardedItems];
    [numberArray removeObjectsAtIndexes:discardedItems];
    [picturesArray removeObjectsAtIndexes:discardedItems];
    
	[self.tableView beginUpdates];
	[self.tableView deleteRowsAtIndexPaths:[bulkSet allObjects] withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView endUpdates];
}

- (SNPrivateMessageHistoryViewController *)init
{
	if ((self = [super initWithStyle:UITableViewStylePlain]))
	{
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
        self.tableView.allowsSelectionDuringEditing = YES;
        
		UIBarButtonItem *deleteButton = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Delete", @"Delete") style: UIBarButtonItemStyleBordered target: self action:@selector(bulkDelete)] autorelease];
		deleteButton.tintColor = [UIColor redColor];
		self.toolbarItems = [NSArray arrayWithObjects:deleteButton, nil];
        
		idArray = [[NSMutableArray alloc] initWithCapacity:600];
		nameArray = [[NSMutableArray alloc] initWithCapacity:600];
		contentArray = [[NSMutableArray alloc] initWithCapacity:600];
		timeArray = [[NSMutableArray alloc] initWithCapacity:600];
		numberArray = [[NSMutableArray alloc] initWithCapacity:600];
		picturesArray = [[NSMutableArray alloc] initWithCapacity:600];
		bulkSet = [[NSMutableSet alloc] initWithCapacity:600];
        
		[self loadDatabaseSegment];
	}
	return self;
}

- (void)viewDidLoad
{
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:NSLocalizedString(@"SMS", @"SMS"), NSLocalizedString(@"Call", @"Call"), nil]];
    segmentedControl.selectedSegmentIndex = 0;
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.frame = CGRectMake(0.0f, 0.0f, 100.0f, 30.0f);
	[segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	self.navigationItem.titleView = segmentedControl;
	[segmentedControl release];
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:@"/var/mobile/Library/SMSNinja/UnreadPrivateInfo"]) [fileManager removeItemAtPath:@"/var/mobile/Library/SMSNinja/UnreadPrivateInfo" error:nil];
}

- (void)loadDatabaseSegment
{
	sqlite3 *database;
	sqlite3_stmt *statement;
	int openResult = sqlite3_open([DATABASE UTF8String], &database);
	if (openResult == SQLITE_OK)
	{
		NSString *sql = [NSString stringWithFormat:@"select name, content, time, number, id, pictures from privatesms order by (cast(id as integer)) desc limit %d, 50", [idArray count]];
		int prepareResult = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
		if (prepareResult == SQLITE_OK)
		{
			while (sqlite3_step(statement) == SQLITE_ROW)
			{
				char *name = (char *)sqlite3_column_text(statement, 0);
				[nameArray addObject:name ? [NSString stringWithUTF8String:name] : @""];
                
				char *content = (char *)sqlite3_column_text(statement, 1);
				[contentArray addObject:content ? [NSString stringWithUTF8String:content] : @""];
                
				char *time = (char *)sqlite3_column_text(statement, 2);
				[timeArray addObject:time ? [NSString stringWithUTF8String:time] : @""];;
                
				char *number = (char *)sqlite3_column_text(statement, 3);
				[numberArray addObject:number ? [NSString stringWithUTF8String:number] : @""];
                
				char *identifier = (char *)sqlite3_column_text(statement, 4);
				[idArray addObject:identifier ? [NSString stringWithUTF8String:identifier] : @""];
                
				char *pictures = (char *)sqlite3_column_text(statement, 5);
				[picturesArray addObject:pictures ? [NSString stringWithUTF8String:pictures] : @""];
			}
			sqlite3_finalize(statement);
		}
		else NSLog(@"SMSNinja: Failed to prepare %@, error %d", DATABASE, prepareResult);
		sqlite3_close(database);
	}
	else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
}

- (void)segmentAction:(UISegmentedControl *)sender
{
    if ([sender selectedSegmentIndex] == 1)
    {
        [self setEditing:NO animated:NO];
        
        SNPrivateCallHistoryViewController *privateCallHistoryViewController = [[SNPrivateCallHistoryViewController alloc] init];
        UINavigationController *navigationController = self.navigationController;
        [navigationController popViewControllerAnimated:NO];
        [navigationController pushViewController:privateCallHistoryViewController animated:NO];
        [privateCallHistoryViewController release];
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [idArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"any-cell"];
	if (cell == nil) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"any-cell"] autorelease];
    for (UIView *subview in [cell.contentView subviews])
        [subview removeFromSuperview];
    cell.textLabel.text = nil;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
	cell.accessoryType = [[picturesArray objectAtIndex:indexPath.row] intValue] == 0 ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryDetailDisclosureButton;
    if ([[[UIDevice currentDevice] systemVersion] hasPrefix:@"7"] && cell.accessoryType == UITableViewCellAccessoryDetailDisclosureButton) cell.accessoryType = UITableViewCellAccessoryDetailButton;
    
    UITableViewCell *defaultCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"default-cell"];
    int defaultCellHeight = defaultCell.bounds.size.height;
    int defaultCellWidth = defaultCell.bounds.size.width;
    [defaultCell release];
    
	UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 2.0f, (defaultCellWidth  - 50.0f) / 2.0f, (defaultCellHeight - 4.0f) / 2.0f)];
	nameLabel.tag = 1;
	nameLabel.adjustsFontSizeToFitWidth = YES;
	nameLabel.text = [[nameArray objectAtIndex:indexPath.row] length] != 0 ? [nameArray objectAtIndex:indexPath.row] : [numberArray objectAtIndex:indexPath.row];
	[cell.contentView addSubview:nameLabel];
	[nameLabel release];
    
	UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabel.frame.origin.x + nameLabel.bounds.size.width, nameLabel.frame.origin.y, nameLabel.bounds.size.width, nameLabel.bounds.size.height)];
	timeLabel.tag = 2;
	timeLabel.font = nameLabel.font;
	if ([[[UIDevice currentDevice] systemVersion] hasPrefix:@"5"]) timeLabel.textAlignment = UITextAlignmentRight;
	else if ([[[UIDevice currentDevice] systemVersion] intValue] > 5) timeLabel.textAlignment = NSTextAlignmentRight;
	timeLabel.adjustsFontSizeToFitWidth = nameLabel.adjustsFontSizeToFitWidth;
	timeLabel.text = [timeArray objectAtIndex:indexPath.row];
	timeLabel.textColor = nameLabel.textColor;
	[cell.contentView addSubview:timeLabel];
	[timeLabel release];
    
	UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabel.frame.origin.x, nameLabel.frame.origin.y + nameLabel.bounds.size.height, nameLabel.bounds.size.width + timeLabel.bounds.size.width, nameLabel.bounds.size.height)];
	contentLabel.tag = 3;
	contentLabel.numberOfLines = 0;
	contentLabel.font = nameLabel.font;
	contentLabel.text = [contentArray objectAtIndex:indexPath.row];
	CGSize expectedLabelSize = [contentLabel.text sizeWithFont:contentLabel.font constrainedToSize:CGSizeMake(contentLabel.bounds.size.width, contentLabel.bounds.size.height * 60.0f) lineBreakMode:contentLabel.lineBreakMode];
	CGRect newFrame = contentLabel.frame;
	newFrame.size.height = expectedLabelSize.height;
	contentLabel.frame = newFrame;
	contentLabel.textColor = nameLabel.textColor;
	[cell.contentView addSubview:contentLabel];
	[contentLabel release];
    
	return cell;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex)
	{
		case 0:
            [bulkSet removeAllObjects];
            [bulkSet addObject:[NSIndexPath indexPathForRow:chosenRow inSection:0]];
            
            sqlite3 *database;
            int openResult = sqlite3_open([DATABASE UTF8String], &database);
            if (openResult == SQLITE_OK)
            {
                for (NSIndexPath *chosenRowIndexPath in bulkSet)
                {
                    NSString *sql = [NSString stringWithFormat:@"delete from privatesms where number = '%@' and name = '%@' and time = '%@' and content = '%@' and id = '%@' and pictures = '%@'", [numberArray objectAtIndex:chosenRowIndexPath.row], [[nameArray objectAtIndex:chosenRowIndexPath.row] stringByReplacingOccurrencesOfString:@"'" withString:@"''"], [timeArray objectAtIndex:chosenRowIndexPath.row], [[contentArray objectAtIndex:chosenRowIndexPath.row] stringByReplacingOccurrencesOfString:@"'" withString:@"''"], [idArray objectAtIndex:chosenRowIndexPath.row], [picturesArray objectAtIndex:chosenRowIndexPath.row]];
                    int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
                    if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
                    
                    NSFileManager *fileManager = [NSFileManager defaultManager];
                    NSError *error = nil;
                    for (int i = 0; i < [[picturesArray objectAtIndex:chosenRowIndexPath.row] intValue]; i++)
                    {
                        [fileManager removeItemAtPath:[[PRIVATEPICTURES stringByAppendingString:[idArray objectAtIndex:chosenRowIndexPath.row]] stringByAppendingFormat:@"-%d.png", i] error:&error];
                        if (error) NSLog(@"SMSNinja: Failed to delete %@, error %@", [[PRIVATEPICTURES stringByAppendingString:[idArray objectAtIndex:chosenRowIndexPath.row]] stringByAppendingFormat:@"-%d.png", i], [error localizedDescription]);
                    }
                }
                sqlite3_close(database);
            }
            else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
            
            NSMutableIndexSet *discardedItems = [NSMutableIndexSet indexSet];
            for (NSIndexPath *chosenRowIndexPath in bulkSet) [discardedItems addIndex:chosenRowIndexPath.row];
            
            [idArray removeObjectsAtIndexes:discardedItems];
            [nameArray removeObjectsAtIndexes:discardedItems];
            [contentArray removeObjectsAtIndexes:discardedItems];
            [timeArray removeObjectsAtIndexes:discardedItems];
            [numberArray removeObjectsAtIndexes:discardedItems];
            [picturesArray removeObjectsAtIndexes:discardedItems];
            
			[self.tableView beginUpdates];
			[self.tableView deleteRowsAtIndexPaths:[bulkSet allObjects] withRowAnimation:UITableViewRowAnimationFade];
			[self.tableView endUpdates];
			break;
		case 1:
            [[UIPasteboard generalPasteboard] setValue:[numberArray objectAtIndex:chosenRow] forPasteboardType:@"public.utf8-plain-text"];
            break;
        case 2:
            [[UIPasteboard generalPasteboard] setValue:[contentArray objectAtIndex:chosenRow] forPasteboardType:@"public.utf8-plain-text"];
            break;
        case 3:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"sms:%@", [numberArray objectAtIndex:chosenRow]]]];
            break;
        case 4:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", [numberArray objectAtIndex:chosenRow]]]];
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.editing) [bulkSet addObject:indexPath];
    else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        chosenRow = indexPath.row;
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:NSLocalizedString(@"Delete", @"Delete") otherButtonTitles:NSLocalizedString(@"Copy number", @"Copy number"), NSLocalizedString(@"Copy content", @"Copy content"), NSLocalizedString(@"SMS", @"SMS"), NSLocalizedString(@"Call", @"Call"), nil];
        [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
        [actionSheet release];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.editing) [bulkSet removeObject:indexPath];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    SNPictureViewController *picturesViewController = [[SNPictureViewController alloc] init];
    picturesViewController.flag = @"private";
    picturesViewController.idString = [idArray objectAtIndex:indexPath.row];
    picturesViewController->picturesCount = [[picturesArray objectAtIndex:indexPath.row] intValue];
    [self.navigationController pushViewController:picturesViewController animated:YES];
    [picturesViewController release];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return NSLocalizedString(@"SMS", @"SMS");
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"default-cell"] autorelease];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    UIFont *font = label.font;
    [label release];
    return (cell.contentView.bounds.size.height - 4.0f) / 2.0f + [[contentArray objectAtIndex:indexPath.row] sizeWithFont:font constrainedToSize:CGSizeMake((cell.contentView.bounds.size.width  - 50.0f), (cell.contentView.bounds.size.height - 4.0f) / 2.0f * 60.0f) lineBreakMode:NSLineBreakByWordWrapping].height + 4.0f;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleInsert | UITableViewCellEditingStyleDelete;
}

- (void)selectAll:(UIBarButtonItem *)buttonItem
{
    [bulkSet removeAllObjects];
    
    if ([buttonItem.title isEqualToString:NSLocalizedString(@"All", @"All")])
    {
        buttonItem.title = NSLocalizedString(@"None", @"None");
        for (int i = 0; i < [idArray count]; i++)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        for (int i = 0; i < [idArray count]; i++)
            [bulkSet addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    else if ([buttonItem.title isEqualToString:NSLocalizedString(@"None", @"None")])
    {
        buttonItem.title = NSLocalizedString(@"All", @"All");
        for (int i = 0; i < [idArray count]; i++)
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animate
{
    for (int i = 0; i < [idArray count]; i++)
        [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO];
    [bulkSet removeAllObjects];
    [self.navigationController setToolbarHidden:!editing animated:animate];
    if (editing)
    {
        for (UITableViewCell *cell in [self.tableView visibleCells])
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        [self.navigationItem setLeftBarButtonItem:[[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"All", @"All") style:UIBarButtonItemStylePlain target:self action:@selector(selectAll:)] autorelease] animated:animate];
    }
    else
    {
        for (UITableViewCell *cell in [self.tableView visibleCells])
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        [self.navigationItem setLeftBarButtonItem:nil animated:animate];
    }
    [super setEditing:editing animated:animate];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.size.height && scrollView.contentOffset.y != -64.0f && scrollView.contentOffset.y != 0.0f)
    {
        [self.tableView beginUpdates];
        int count = [idArray count];
        [self loadDatabaseSegment];
        NSMutableArray *insertIndexPaths = [NSMutableArray arrayWithCapacity:50];
        for (int i = count; i < [idArray count]; i++)
        {
            NSIndexPath *newPath =  [NSIndexPath indexPathForRow:i inSection:0];
            [insertIndexPaths insertObject:newPath atIndex:i];
        }
        [self.tableView insertRowsAtIndexPaths:insertIndexPaths withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}
@end
