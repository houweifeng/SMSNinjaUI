#import "SNSystemCallHistoryViewController.h"
#import "SNNumberViewController.h"
#import "SNWhitelistViewController.h"
#import "SNBlacklistViewController.h"
#import "SNPrivatelistViewController.h"
#import <objc/runtime.h>
#import <sqlite3.h>

#ifndef SMSNinjaDebug
#define SETTINGS @"/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/var/mobile/Library/SMSNinja/smsninja.db"
#else
#define SETTINGS @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja/smsninja.db"
#endif

@implementation SNSystemCallHistoryViewController

@synthesize flag;

- (void)dealloc
{
    [numberArray release];
    numberArray = nil;
    
    [nameArray release];
    nameArray = nil;
    
    [timeArray release];
    timeArray = nil;
    
    [typeArray release];
    typeArray = nil;
    
    [keywordSet release];
    keywordSet = nil;
    
    [flag release];
    flag = nil;
    
    [super dealloc];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    id viewController = self.navigationController.topViewController;
    if ([viewController isKindOfClass:[SNNumberViewController class]]) return;
    [((UITableViewController *)viewController).tableView reloadData];
}

- (void)initializeAllArrays
{
    CPDistributedMessagingCenter *messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.naken.smsninjaspringboard"];
    NSDictionary *reply = [messagingCenter sendMessageAndReceiveReplyName:@"GetSystemCallHistory" userInfo:nil];
    numberArray = [[NSMutableArray alloc] initWithArray:[reply objectForKey:@"numberArray"]];
    nameArray = [[NSMutableArray alloc] initWithArray:[reply objectForKey:@"nameArray"]];
    timeArray = [[NSMutableArray alloc] initWithArray:[reply objectForKey:@"timeArray"]];
    typeArray = [[NSMutableArray alloc] initWithArray:[reply objectForKey:@"typeArray"]];
    keywordSet = [[NSMutableSet alloc] initWithCapacity:600];
    
    sqlite3 *database;
    sqlite3_stmt *statement;
    int openResult = sqlite3_open([DATABASE UTF8String], &database);
    if (openResult == SQLITE_OK)
    {
        NSString *sql = [NSString stringWithFormat:@"select keyword from %@list", self.flag];
        int prepareResult = sqlite3_prepare_v2(database, [sql UTF8String], -1, &statement, NULL);
        if (prepareResult == SQLITE_OK)
        {
            while (sqlite3_step(statement) == SQLITE_ROW)
            {
                char *keyword = (char *)sqlite3_column_text(statement, 0);
                [keywordSet addObject:keyword ? [NSString stringWithUTF8String:keyword] : @""];
            }
            sqlite3_finalize(statement);
        }
        else NSLog(@"SMSNinja: Failed to prepare %@, error %d", DATABASE, prepareResult);
        sqlite3_close(database);
    }
    else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
}

- (SNSystemCallHistoryViewController *)init
{
    if ((self = [super initWithStyle:UITableViewStylePlain]))
    {
        self.title = NSLocalizedString(@"Call History", @"Call History");
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        
        [self initializeAllArrays];
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [numberArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"any-cell"];
    if (cell == nil) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"any-cell"] autorelease];
    for (UIView *subview in [cell.contentView subviews])
        [subview removeFromSuperview];
    cell.textLabel.text = nil;
    cell.accessoryView = nil;
    
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 2.0f, (cell.contentView.bounds.size.width - 36.0f) / 2.0f, (cell.contentView.bounds.size.height - 4.0f) / 2.0f)];
    nameLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1) nameLabel.minimumFontSize = 8.0f;
    else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_5_1) nameLabel.minimumScaleFactor = 8.0f;
    nameLabel.adjustsFontSizeToFitWidth = YES;
    nameLabel.text = [[nameArray objectAtIndex:indexPath.row] length] != 0 ? [nameArray objectAtIndex:indexPath.row] : [numberArray objectAtIndex:indexPath.row];
    [cell.contentView addSubview:nameLabel];
    [nameLabel release];
    
    UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabel.frame.origin.x + nameLabel.bounds.size.width, nameLabel.frame.origin.y, nameLabel.bounds.size.width, nameLabel.bounds.size.height)];
    timeLabel.font = nameLabel.font;
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1)
    {
        timeLabel.minimumFontSize = nameLabel.minimumFontSize;
        timeLabel.textAlignment = UITextAlignmentRight;
    }
	else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_5_1)
    {
        timeLabel.minimumScaleFactor = nameLabel.minimumScaleFactor;
        timeLabel.textAlignment = NSTextAlignmentRight;
    }
    timeLabel.adjustsFontSizeToFitWidth = nameLabel.adjustsFontSizeToFitWidth;
    timeLabel.text = [timeArray objectAtIndex:indexPath.row];
    timeLabel.textColor = nameLabel.textColor;
    [cell.contentView addSubview:timeLabel];
    [timeLabel release];
    
    UILabel *numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabel.frame.origin.x, nameLabel.frame.origin.y + nameLabel.bounds.size.height, nameLabel.bounds.size.width, nameLabel.bounds.size.height)];
    numberLabel.font = nameLabel.font;
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1) numberLabel.minimumFontSize = nameLabel.minimumFontSize;
    else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_5_1) numberLabel.minimumScaleFactor = nameLabel.minimumScaleFactor;
    numberLabel.adjustsFontSizeToFitWidth = nameLabel.adjustsFontSizeToFitWidth;
    numberLabel.text = [numberArray objectAtIndex:indexPath.row];
    numberLabel.textColor = nameLabel.textColor;
    [cell.contentView addSubview:numberLabel];
    [numberLabel release];
    
    UILabel *typeLabel = [[UILabel alloc] initWithFrame:CGRectMake(timeLabel.frame.origin.x, numberLabel.frame.origin.y, nameLabel.bounds.size.width, nameLabel.bounds.size.height)];
    typeLabel.font = nameLabel.font;
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_5_0 && kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_5_1) typeLabel.minimumFontSize = nameLabel.minimumFontSize;
    else if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_5_1) typeLabel.minimumScaleFactor = nameLabel.minimumScaleFactor;
    typeLabel.adjustsFontSizeToFitWidth = nameLabel.adjustsFontSizeToFitWidth;
    typeLabel.text = [typeArray objectAtIndex:indexPath.row];
    typeLabel.textColor = nameLabel.textColor;
    [cell.contentView addSubview:typeLabel];
    [typeLabel release];
    
    if ([keywordSet containsObject:numberLabel.text]) cell.selected = YES;
    else cell.selected = NO;
    
    return cell;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 1) // single
    {
        if (buttonIndex == 2) [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:buttonIndex inSection:0]].selected = NO;
        
        __block NSInteger index = buttonIndex;
        __block SNSystemCallHistoryViewController *weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                       {
                           sqlite3 *database;
                           int openResult = sqlite3_open([DATABASE UTF8String], &database);
                           if (openResult == SQLITE_OK)
                           {
                               NSString *sql = [NSString stringWithFormat:@"insert or replace into %@list (keyword, type, name, phone, sms, reply, message, forward, number, sound) values ('%@', '0', '', '1', '1', '0', '', '0', '', '%d')", weakSelf.flag, [weakSelf->numberArray objectAtIndex:weakSelf->chosenRow], index];
                               int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
                               if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
                               sqlite3_close(database);
                               
                               id viewController = [weakSelf.navigationController.viewControllers objectAtIndex:([weakSelf.navigationController.viewControllers count] - 2)];
                               if ([viewController isKindOfClass:[SNBlacklistViewController class]])
                               {
                                   [((SNBlacklistViewController *)viewController)->keywordArray insertObject:[weakSelf->numberArray objectAtIndex:weakSelf->chosenRow] atIndex:0];
                                   [((SNBlacklistViewController *)viewController)->typeArray insertObject:@"0" atIndex:0];
                                   [((SNBlacklistViewController *)viewController)->nameArray insertObject:@"" atIndex:0];
                                   [((SNBlacklistViewController *)viewController)->messageArray insertObject:@"1" atIndex:0];
                                   [((SNBlacklistViewController *)viewController)->numberArray insertObject:@"1" atIndex:0];
                                   [((SNBlacklistViewController *)viewController)->smsArray insertObject:@"0" atIndex:0];
                                   [((SNBlacklistViewController *)viewController)->phoneArray insertObject:@"" atIndex:0];
                                   [((SNBlacklistViewController *)viewController)->forwardArray insertObject:@"0" atIndex:0];
                                   [((SNBlacklistViewController *)viewController)->replyArray insertObject:@"" atIndex:0];
                                   [((SNBlacklistViewController *)viewController)->soundArray insertObject:[NSString stringWithFormat:@"%d", index] atIndex:0];
                               }
                               else if ([viewController isKindOfClass:[SNPrivatelistViewController class]])
                               {
                                   [((SNPrivatelistViewController *)viewController)->keywordArray insertObject:[weakSelf->numberArray objectAtIndex:weakSelf->chosenRow] atIndex:0];
                                   [((SNPrivatelistViewController *)viewController)->typeArray insertObject:@"0" atIndex:0];
                                   [((SNPrivatelistViewController *)viewController)->nameArray insertObject:@"" atIndex:0];
                                   [((SNPrivatelistViewController *)viewController)->messageArray insertObject:@"1" atIndex:0];
                                   [((SNPrivatelistViewController *)viewController)->numberArray insertObject:@"1" atIndex:0];
                                   [((SNPrivatelistViewController *)viewController)->smsArray insertObject:@"0" atIndex:0];
                                   [((SNPrivatelistViewController *)viewController)->phoneArray insertObject:@"" atIndex:0];
                                   [((SNPrivatelistViewController *)viewController)->forwardArray insertObject:@"0" atIndex:0];
                                   [((SNPrivatelistViewController *)viewController)->replyArray insertObject:@"" atIndex:0];
                                   [((SNPrivatelistViewController *)viewController)->soundArray insertObject:[NSString stringWithFormat:@"%d", index] atIndex:0];
                               }
                           }
                           else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
                       });
    }
    else if (actionSheet.tag == 2) // all
    {
        if (buttonIndex == 2)
            for (int i = 0; i < [numberArray count]; i++)
                [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]].selected = NO;
        
        __block NSInteger index = buttonIndex;
        __block SNSystemCallHistoryViewController *weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                       {
                           sqlite3 *database;
                           int openResult = sqlite3_open([DATABASE UTF8String], &database);
                           if (openResult == SQLITE_OK)
                           {
                               for (NSString *number in weakSelf->numberArray)
                               {
                                   NSString *sql = [NSString stringWithFormat:@"insert or replace into %@list (keyword, type, name, phone, sms, reply, message, forward, number, sound) values ('%@', '0', '', '1', '1', '0', '', '0', '', '%d')", weakSelf.flag, number, index];
                                   int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
                                   if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
                                   
                                   id viewController = [weakSelf.navigationController.viewControllers objectAtIndex:([weakSelf.navigationController.viewControllers count] - 2)];
                                   if ([viewController isKindOfClass:[SNBlacklistViewController class]])
                                   {
                                       [((SNBlacklistViewController *)viewController)->keywordArray insertObject:number atIndex:0];
                                       [((SNBlacklistViewController *)viewController)->typeArray insertObject:@"0" atIndex:0];
                                       [((SNBlacklistViewController *)viewController)->nameArray insertObject:@"" atIndex:0];
                                       [((SNBlacklistViewController *)viewController)->messageArray insertObject:@"1" atIndex:0];
                                       [((SNBlacklistViewController *)viewController)->numberArray insertObject:@"1" atIndex:0];
                                       [((SNBlacklistViewController *)viewController)->smsArray insertObject:@"0" atIndex:0];
                                       [((SNBlacklistViewController *)viewController)->phoneArray insertObject:@"" atIndex:0];
                                       [((SNBlacklistViewController *)viewController)->forwardArray insertObject:@"0" atIndex:0];
                                       [((SNBlacklistViewController *)viewController)->replyArray insertObject:@"" atIndex:0];
                                       [((SNBlacklistViewController *)viewController)->soundArray insertObject:[NSString stringWithFormat:@"%d", index] atIndex:0];
                                   }
                                   else if ([viewController isKindOfClass:[SNPrivatelistViewController class]])
                                   {
                                       [((SNPrivatelistViewController *)viewController)->keywordArray insertObject:number atIndex:0];
                                       [((SNPrivatelistViewController *)viewController)->typeArray insertObject:@"0" atIndex:0];
                                       [((SNPrivatelistViewController *)viewController)->nameArray insertObject:@"" atIndex:0];
                                       [((SNPrivatelistViewController *)viewController)->messageArray insertObject:@"1" atIndex:0];
                                       [((SNPrivatelistViewController *)viewController)->numberArray insertObject:@"1" atIndex:0];
                                       [((SNPrivatelistViewController *)viewController)->smsArray insertObject:@"0" atIndex:0];
                                       [((SNPrivatelistViewController *)viewController)->phoneArray insertObject:@"" atIndex:0];
                                       [((SNPrivatelistViewController *)viewController)->forwardArray insertObject:@"0" atIndex:0];
                                       [((SNPrivatelistViewController *)viewController)->replyArray insertObject:@"" atIndex:0];
                                       [((SNPrivatelistViewController *)viewController)->soundArray insertObject:[NSString stringWithFormat:@"%d", index] atIndex:0];
                                   }
                               }
                               sqlite3_close(database);
                           }
                           else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
                       });
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!tableView.editing)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        SNNumberViewController *numberViewController = [[SNNumberViewController alloc] init];
        numberViewController.flag = self.flag;
        numberViewController.nameString = [nameArray objectAtIndex:indexPath.row];
        numberViewController.keywordString = [numberArray objectAtIndex:indexPath.row];
        numberViewController.phoneAction = @"1";
        numberViewController.messageAction = @"1";
        numberViewController.replyString = @"0";
        numberViewController.messageString = @"";
        numberViewController.forwardString = @"0";
        numberViewController.numberString = @"";
        numberViewController.soundString = @"1";
        UINavigationController *navigationController = self.navigationController;
        [navigationController popViewControllerAnimated:NO];
        [navigationController pushViewController:numberViewController animated:YES];
        [numberViewController release];
    }
    else
    {
        chosenRow = indexPath.row;
        if (![self.flag isEqualToString:@"white"])
        {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Turn off the beep", @"Turn off the beep"), NSLocalizedString(@"Turn on the beep", @"Turn on the beep"), nil];
            actionSheet.tag = 1;
            [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
            [actionSheet release];
        }
        else
        {
            __block SNSystemCallHistoryViewController *weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                           {
                               sqlite3 *database;
                               int openResult = sqlite3_open([DATABASE UTF8String], &database);
                               if (openResult == SQLITE_OK)
                               {
                                   NSString *sql = [NSString stringWithFormat:@"insert or replace into whitelist (keyword, type, name, phone, sms, reply, message, forward, number, sound) values ('%@', '0', '', '1', '1', '0', '', '0', '', '0')", [weakSelf->numberArray objectAtIndex:weakSelf->chosenRow]];
                                   int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
                                   if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
                                   sqlite3_close(database);
                                   
                                   SNWhitelistViewController *viewController = (SNWhitelistViewController *)[weakSelf.navigationController.viewControllers objectAtIndex:([weakSelf.navigationController.viewControllers count] - 2)];
                                   [viewController->nameArray insertObject:@"" atIndex:0];
                                   [viewController->keywordArray insertObject:[weakSelf->numberArray objectAtIndex:weakSelf->chosenRow] atIndex:0];
                                   [viewController->typeArray insertObject:@"0" atIndex:0];
                               }
                               else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
                           });
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block int index = indexPath.row;
    __block SNSystemCallHistoryViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                   {
                       sqlite3 *database;
                       int openResult = sqlite3_open([DATABASE UTF8String], &database);
                       if (openResult == SQLITE_OK)
                       {
                           NSString *sql = [NSString stringWithFormat:@"delete from %@list where keyword = '%@'", weakSelf.flag, [weakSelf->numberArray objectAtIndex:index]];
                           int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
                           if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
                           sqlite3_close(database);
                           
                           id viewController = [weakSelf.navigationController.viewControllers objectAtIndex:([weakSelf.navigationController.viewControllers count] - 2)];
                           if ([viewController isKindOfClass:[SNBlacklistViewController class]])
                           {
                               [((SNBlacklistViewController *)viewController)->keywordArray removeObjectAtIndex:index];
                               [((SNBlacklistViewController *)viewController)->typeArray removeObjectAtIndex:index];
                               [((SNBlacklistViewController *)viewController)->nameArray removeObjectAtIndex:index];
                               [((SNBlacklistViewController *)viewController)->messageArray removeObjectAtIndex:index];
                               [((SNBlacklistViewController *)viewController)->numberArray removeObjectAtIndex:index];
                               [((SNBlacklistViewController *)viewController)->smsArray removeObjectAtIndex:index];
                               [((SNBlacklistViewController *)viewController)->phoneArray removeObjectAtIndex:index];
                               [((SNBlacklistViewController *)viewController)->forwardArray removeObjectAtIndex:index];
                               [((SNBlacklistViewController *)viewController)->replyArray removeObjectAtIndex:index];
                               [((SNBlacklistViewController *)viewController)->soundArray removeObjectAtIndex:index];
                           }
                           else if ([viewController isKindOfClass:[SNWhitelistViewController class]])
                           {
                               [((SNWhitelistViewController *)viewController)->keywordArray removeObjectAtIndex:index];
                               [((SNWhitelistViewController *)viewController)->typeArray removeObjectAtIndex:index];
                               [((SNWhitelistViewController *)viewController)->nameArray removeObjectAtIndex:index];
                           }
                           else if ([viewController isKindOfClass:[SNPrivatelistViewController class]])
                           {
                               [((SNPrivatelistViewController *)viewController)->keywordArray removeObjectAtIndex:index];
                               [((SNPrivatelistViewController *)viewController)->typeArray removeObjectAtIndex:index];
                               [((SNPrivatelistViewController *)viewController)->nameArray removeObjectAtIndex:index];
                               [((SNPrivatelistViewController *)viewController)->messageArray removeObjectAtIndex:index];
                               [((SNPrivatelistViewController *)viewController)->numberArray removeObjectAtIndex:index];
                               [((SNPrivatelistViewController *)viewController)->smsArray removeObjectAtIndex:index];
                               [((SNPrivatelistViewController *)viewController)->phoneArray removeObjectAtIndex:index];
                               [((SNPrivatelistViewController *)viewController)->forwardArray removeObjectAtIndex:index];
                               [((SNPrivatelistViewController *)viewController)->replyArray removeObjectAtIndex:index];
                               [((SNPrivatelistViewController *)viewController)->soundArray removeObjectAtIndex:index];
                           }
                       }
                       else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
                   });
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
    if ([buttonItem.title isEqualToString:NSLocalizedString(@"All", @"All")])
    {
        buttonItem.title = NSLocalizedString(@"None", @"None");
        for (int i = 0; i < [numberArray count]; i++)
            [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]].selected = YES;
        
        if (![self.flag isEqualToString:@"white"])
        {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Turn off the beep", @"Turn off the beep"), NSLocalizedString(@"Turn on the beep", @"Turn on the beep"), nil];
            actionSheet.tag = 2;
            [actionSheet showInView:[[UIApplication sharedApplication] keyWindow]];
            [actionSheet release];
        }
        else
        {
            __block SNSystemCallHistoryViewController *weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                           {
                               sqlite3 *database;
                               int openResult = sqlite3_open([DATABASE UTF8String], &database);
                               if (openResult == SQLITE_OK)
                               {
                                   for (NSString *number in weakSelf->numberArray)
                                   {
                                       NSString *sql = [NSString stringWithFormat:@"insert or replace into whitelist (keyword, type, name, phone, sms, reply, message, forward, number, sound) values ('%@', '0', '', '1', '1', '0', '', '0', '', '0')", number];
                                       int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
                                       if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
                                       
                                       SNWhitelistViewController *viewController = (SNWhitelistViewController *)[weakSelf.navigationController.viewControllers objectAtIndex:([weakSelf.navigationController.viewControllers count] - 2)];
                                       [viewController->nameArray insertObject:@"" atIndex:0];
                                       [viewController->keywordArray insertObject:number atIndex:0];
                                       [viewController->typeArray insertObject:@"0" atIndex:0];
                                   }
                                   sqlite3_close(database);
                               }
                               else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
                           });
        }
    }
    else if ([buttonItem.title isEqualToString:NSLocalizedString(@"None", @"None")])
    {
        buttonItem.title = NSLocalizedString(@"All", @"All");
        for (int i = 0; i < [numberArray count]; i++)
            [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]].selected = NO;
        __block SNSystemCallHistoryViewController *weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                       {
                           sqlite3 *database;
                           int openResult = sqlite3_open([DATABASE UTF8String], &database);
                           if (openResult == SQLITE_OK)
                           {
                               for (NSString *number in weakSelf->numberArray)
                               {
                                   NSString *sql = [NSString stringWithFormat:@"delete from %@list where keyword = '%@'", weakSelf.flag, number];
                                   int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
                                   if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
                                   
                                   id viewController = [weakSelf.navigationController.viewControllers objectAtIndex:([weakSelf.navigationController.viewControllers count] - 2)];
                                   if ([viewController isKindOfClass:[SNBlacklistViewController class]])
                                   {
                                       [((SNBlacklistViewController *)viewController)->keywordArray removeObject:number];
                                       [((SNBlacklistViewController *)viewController)->typeArray removeObject:number];
                                       [((SNBlacklistViewController *)viewController)->nameArray removeObject:number];
                                       [((SNBlacklistViewController *)viewController)->messageArray removeObject:number];
                                       [((SNBlacklistViewController *)viewController)->numberArray removeObject:number];
                                       [((SNBlacklistViewController *)viewController)->smsArray removeObject:number];
                                       [((SNBlacklistViewController *)viewController)->phoneArray removeObject:number];
                                       [((SNBlacklistViewController *)viewController)->forwardArray removeObject:number];
                                       [((SNBlacklistViewController *)viewController)->replyArray removeObject:number];
                                       [((SNBlacklistViewController *)viewController)->soundArray removeObject:number];
                                   }
                                   else if ([viewController isKindOfClass:[SNWhitelistViewController class]])
                                   {
                                       [((SNWhitelistViewController *)viewController)->keywordArray removeObject:number];
                                       [((SNWhitelistViewController *)viewController)->typeArray removeObject:number];
                                       [((SNWhitelistViewController *)viewController)->nameArray removeObject:number];
                                   }
                                   else if ([viewController isKindOfClass:[SNPrivatelistViewController class]])
                                   {
                                       [((SNPrivatelistViewController *)viewController)->keywordArray removeObject:number];
                                       [((SNPrivatelistViewController *)viewController)->typeArray removeObject:number];
                                       [((SNPrivatelistViewController *)viewController)->nameArray removeObject:number];
                                       [((SNPrivatelistViewController *)viewController)->messageArray removeObject:number];
                                       [((SNPrivatelistViewController *)viewController)->numberArray removeObject:number];
                                       [((SNPrivatelistViewController *)viewController)->smsArray removeObject:number];
                                       [((SNPrivatelistViewController *)viewController)->phoneArray removeObject:number];
                                       [((SNPrivatelistViewController *)viewController)->forwardArray removeObject:number];
                                       [((SNPrivatelistViewController *)viewController)->replyArray removeObject:number];
                                       [((SNPrivatelistViewController *)viewController)->soundArray removeObject:number];
                                   }
                               }
                               sqlite3_close(database);
                           }
                           else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
                       });
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animate
{
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
@end