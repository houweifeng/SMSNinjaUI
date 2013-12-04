#import "SNNumberViewController.h"
#import "SNCallActionViewController.h"
#import "SNMessageActionViewController.h"
#import "SNBlacklistViewController.h"
#import "SNWhitelistViewController.h"
#import "SNPrivatelistViewController.h"
#import "SNTextTableViewCell.h"
#import <sqlite3.h>

#ifndef SMSNinjaDebug
#define SETTINGS @"/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/var/mobile/Library/SMSNinja/smsninja.db"
#else
#define SETTINGS @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja/smsninja.plist"
#define DATABASE @"/Users/snakeninny/Library/Application Support/iPhone Simulator/7.0.3/Applications/0C9D35FB-B626-42B7-AAE9-45F6F537890B/Documents/var/mobile/Library/SMSNinja/smsninja.db"
#endif

@implementation SNNumberViewController

@synthesize nameString;
@synthesize keywordString;
@synthesize phoneAction;
@synthesize messageAction;
@synthesize replyString;
@synthesize messageString;
@synthesize soundString;
@synthesize flag;
@synthesize forwardString;
@synthesize numberString;
@synthesize originalKeyword;

- (void)dealloc
{
    [nameField release];
	nameField = nil;
    
	[nameString release];
	nameString = nil;
    
    [keywordField release];
	keywordField = nil;
    
	[keywordString release];
	keywordString = nil;
    
	[phoneAction release];
	phoneAction = nil;
    
	[messageAction release];
	messageAction = nil;
    
	[replySwitch release];
	replySwitch = nil;
    
	[replyString release];
	replyString = nil;
    
	[messageField release];
	messageField = nil;
    
	[messageString release];
	messageString = nil;
    
    [soundSwitch release];
	soundSwitch = nil;
    
	[soundString release];
	soundString = nil;
    
	[forwardString release];
	forwardString = nil;
    
	[numberString release];
	numberString = nil;
    
	[flag release];
	flag = nil;
    
    [keywordArray release];
	keywordArray = nil;
    
    [originalKeyword release];
    originalKeyword = nil;
    
    [tapRecognizer release];
    tapRecognizer = nil;
    
	[super dealloc];
}

- (SNNumberViewController *)init
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped]))
	{
		self.title = NSLocalizedString(@"Details", @"Details");
        
        nameField = [[UITextField alloc] initWithFrame:CGRectZero];
        keywordField = [[UITextField alloc] initWithFrame:CGRectZero];
        replySwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        messageField = [[UITextField alloc] initWithFrame:CGRectZero];
        soundSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        
		keywordArray = [[NSMutableArray alloc] init];
        
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboardWithTap:)];
        tapRecognizer.delegate = self;
	}
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if ([self.flag isEqualToString:@"white"])
		return 1;
	return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 3)
		return 1;
	return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	SNTextTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"any-cell"];
	if (cell == nil) cell = [[[SNTextTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"any-cell"] autorelease];
    for (UIView *subview in [cell.contentView subviews])
        [subview removeFromSuperview];
    cell.textLabel.text = nil;
    cell.detailTextLabel.text = nil;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    switch (indexPath.section)
    {
        case 0:
            if (indexPath.row == 0)
            {
                cell.textLabel.text = NSLocalizedString(@"Name", @"Name");
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                nameField.delegate = self;
                nameField.placeholder = NSLocalizedString(@"Input here", @"Input here");
                nameField.text = self.nameString;
                nameField.clearButtonMode = UITextFieldViewModeWhileEditing;
                [cell.contentView addSubview:nameField];
            }
            else if (indexPath.row == 1)
            {
                cell.textLabel.text = NSLocalizedString(@"Number", @"Number");
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                keywordField.delegate = self;
                keywordField.placeholder = NSLocalizedString(@"Input here", @"Input here");
                keywordField.text = self.keywordString;
                keywordField.clearButtonMode = UITextFieldViewModeWhileEditing;
                keywordField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                [cell.contentView addSubview:keywordField];
            }
            
            break;
        case 1:
            if (indexPath.row == 0)
            {
                cell.textLabel.text = NSLocalizedString(@"Call", @"Call");
                NSString *detailText = @"";
                if ([self.phoneAction isEqualToString:@"1"]) detailText = NSLocalizedString(@"Disconnect", @"Disconnect");
                else if ([self.phoneAction isEqualToString:@"2"]) detailText = NSLocalizedString(@"Ignore", @"Ignore");
                else if ([self.phoneAction isEqualToString:@"3"]) detailText = NSLocalizedString(@"Let go", @"Let go");
                cell.detailTextLabel.text = detailText;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            else if (indexPath.row == 1)
            {
                cell.textLabel.text = NSLocalizedString(@"SMS", @"SMS");
                NSString *detailText = @"";
                if ([self.messageAction isEqualToString:@"1"]) detailText = [detailText stringByAppendingString:NSLocalizedString(@"Block", @"Block")];
                if ([self.forwardString isEqualToString:@"1"]) detailText = [detailText stringByAppendingString:NSLocalizedString(@", Forward", @", Forward")];
                if ([detailText hasPrefix:@", "]) detailText = [detailText substringFromIndex:2];
                cell.detailTextLabel.text = detailText;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            
            break;
        case 2:
            if (indexPath.row == 0)
            {
                cell.textLabel.text = NSLocalizedString(@"Reply", @"Reply");
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.accessoryView = replySwitch;
                replySwitch.on = [self.replyString isEqualToString:@"0"] ? NO : YES;
                [replySwitch addTarget:self action:@selector(saveSwitchValues) forControlEvents:UIControlEventValueChanged];
            }
            else if (indexPath.row == 1)
            {
                cell.textLabel.text = NSLocalizedString(@"With", @"With");
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                messageField.delegate = self;
                messageField.text = self.messageString;
                messageField.clearButtonMode = UITextFieldViewModeWhileEditing;
                messageField.placeholder = NSLocalizedString(@"Message here", @"Message here");
                [cell.contentView addSubview:messageField];
            }
            
            break;
        case 3:
            cell.textLabel.text = NSLocalizedString(@"Beep", @"Beep");
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryView = soundSwitch;
            soundSwitch.on = [self.soundString isEqualToString:@"0"] ? NO : YES;
            [soundSwitch addTarget:self action:@selector(saveSwitchValues) forControlEvents:UIControlEventValueChanged];
            
            break;
    }
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
	if (indexPath.section == 1)
	{
		switch (indexPath.row)
		{
			case 0:
            {
                SNCallActionViewController *callActionViewController = [[SNCallActionViewController alloc] init];
                callActionViewController.phoneAction = self.phoneAction;
                callActionViewController.flag = self.flag;
                [self.navigationController pushViewController:callActionViewController animated:YES];
                [callActionViewController release];
                break;
            }
			case 1:
            {
                SNMessageActionViewController *messageActionViewController = [[SNMessageActionViewController alloc] init];
                messageActionViewController.messageAction = self.messageAction;
                messageActionViewController.forwardString = self.forwardString;
                messageActionViewController.numberString = self.numberString;
                [self.navigationController pushViewController:messageActionViewController animated:YES];
                [messageActionViewController release];
                break;
            }
		}
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [keywordArray removeAllObjects];
    [keywordArray addObjectsFromArray:[self.keywordString componentsSeparatedByString:@" "]];
    
    id viewController = self.navigationController.topViewController;
    if ([viewController isKindOfClass:[SNCallActionViewController class]] || [viewController isKindOfClass:[SNMessageActionViewController class]]) return;
    
    __block SNNumberViewController *weakSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                   {
                       sqlite3 *database;
                       int openResult = sqlite3_open([DATABASE UTF8String], &database);
                       if (openResult == SQLITE_OK)
                       {
                           NSString *sql = @"";
                           for (NSString *keyword in weakSelf->keywordArray)
                           {
                               if ([keyword isEqualToString:weakSelf.originalKeyword]) sql = [NSString stringWithFormat:@"update %@list set keyword = '%@', type = '0', name = '%@', phone = '%@', sms = '%@', reply = '%@', message = '%@', forward = '%@', number = '%@', sound = '%@' where keyword = '%@'", weakSelf.flag, keyword, weakSelf.nameString, weakSelf.phoneAction, weakSelf.messageAction, weakSelf.replyString, weakSelf.messageString, weakSelf.forwardString, weakSelf.numberString, weakSelf.soundString, weakSelf.keywordString];
                               else sql = [NSString stringWithFormat:@"insert or replace into %@list (keyword, type, name, phone, sms, reply, message, forward, number, sound) values ('%@', '0', '%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@')", weakSelf.flag, keyword, weakSelf.nameString, weakSelf.phoneAction, weakSelf.messageAction, weakSelf.replyString, weakSelf.messageString, weakSelf.forwardString, weakSelf.numberString, weakSelf.soundString];
                               int execResult = sqlite3_exec(database, [sql UTF8String], NULL, NULL, NULL);
                               if (execResult != SQLITE_OK) NSLog(@"SMSNinja: Failed to exec %@, error %d", sql, execResult);
                           }
                           sqlite3_close(database);
                       }
                       else NSLog(@"SMSNinja: Failed to open %@, error %d", DATABASE, openResult);
                   });
    
	for (NSString *keyword in keywordArray)
	{
        if ([viewController isKindOfClass:[SNBlacklistViewController class]])
        {
            int index = [((SNBlacklistViewController *)viewController)->keywordArray indexOfObject:self.originalKeyword];
            if ([keyword isEqualToString:self.originalKeyword])
            {
                [((SNBlacklistViewController *)viewController)->keywordArray replaceObjectAtIndex:index withObject:keyword];
                [((SNBlacklistViewController *)viewController)->nameArray replaceObjectAtIndex:index withObject:self.nameString];
                [((SNBlacklistViewController *)viewController)->replyArray replaceObjectAtIndex:index withObject:self.replyString];
                [((SNBlacklistViewController *)viewController)->messageArray replaceObjectAtIndex:index withObject:self.messageString];
                [((SNBlacklistViewController *)viewController)->forwardArray replaceObjectAtIndex:index withObject:self.forwardString];
                [((SNBlacklistViewController *)viewController)->numberArray replaceObjectAtIndex:index withObject:self.numberString];
                [((SNBlacklistViewController *)viewController)->soundArray replaceObjectAtIndex:index withObject:self.soundString];
                [((SNBlacklistViewController *)viewController)->smsArray replaceObjectAtIndex:index withObject:self.messageAction];
                [((SNBlacklistViewController *)viewController)->phoneArray replaceObjectAtIndex:index withObject:self.phoneAction];
            }
            else
            {
                if (![((SNBlacklistViewController *)viewController)->keywordArray containsObject:keyword])
                {
                    [((SNBlacklistViewController *)viewController)->keywordArray addObject:keyword];
                    [((SNBlacklistViewController *)viewController)->typeArray addObject:@"0"];
                    [((SNBlacklistViewController *)viewController)->nameArray addObject:self.nameString];
                    [((SNBlacklistViewController *)viewController)->messageArray addObject:self.messageString];
                    [((SNBlacklistViewController *)viewController)->numberArray addObject:self.numberString];
                    [((SNBlacklistViewController *)viewController)->smsArray addObject:self.messageAction];
                    [((SNBlacklistViewController *)viewController)->phoneArray addObject:self.phoneAction];
                    [((SNBlacklistViewController *)viewController)->forwardArray addObject:self.forwardString];
                    [((SNBlacklistViewController *)viewController)->replyArray addObject:self.replyString];
                    [((SNBlacklistViewController *)viewController)->soundArray addObject:self.soundString];
                }
            }
        }
        else if ([viewController isKindOfClass:[SNWhitelistViewController class]])
        {
            int index = [((SNWhitelistViewController *)viewController)->keywordArray indexOfObject:self.originalKeyword];
            if ([keyword isEqualToString:weakSelf.originalKeyword])
            {
                [((SNWhitelistViewController *)viewController)->keywordArray replaceObjectAtIndex:index withObject:keyword];
                [((SNWhitelistViewController *)viewController)->nameArray replaceObjectAtIndex:index withObject:self.nameString];
            }
            else
            {
                if (![((SNWhitelistViewController *)viewController)->keywordArray containsObject:keyword])
                {
                    [((SNWhitelistViewController *)viewController)->keywordArray addObject:keyword];
                    [((SNWhitelistViewController *)viewController)->typeArray addObject:@"0"];
                    [((SNWhitelistViewController *)viewController)->nameArray addObject:self.nameString];
                }
            }
        }
        else if ([viewController isKindOfClass:[SNPrivatelistViewController class]])
        {
            int index = [((SNPrivatelistViewController *)viewController)->keywordArray indexOfObject:self.originalKeyword];
            if ([keyword isEqualToString:weakSelf.originalKeyword])
            {
                [((SNPrivatelistViewController *)viewController)->keywordArray replaceObjectAtIndex:index withObject:keyword];
                [((SNPrivatelistViewController *)viewController)->nameArray replaceObjectAtIndex:index withObject:self.nameString];
                [((SNPrivatelistViewController *)viewController)->replyArray replaceObjectAtIndex:index withObject:self.replyString];
                [((SNPrivatelistViewController *)viewController)->messageArray replaceObjectAtIndex:index withObject:self.messageString];
                [((SNPrivatelistViewController *)viewController)->forwardArray replaceObjectAtIndex:index withObject:self.forwardString];
                [((SNPrivatelistViewController *)viewController)->numberArray replaceObjectAtIndex:index withObject:self.numberString];
                [((SNPrivatelistViewController *)viewController)->soundArray replaceObjectAtIndex:index withObject:self.soundString];
                [((SNPrivatelistViewController *)viewController)->smsArray replaceObjectAtIndex:index withObject:self.messageAction];
                [((SNPrivatelistViewController *)viewController)->phoneArray replaceObjectAtIndex:index withObject:self.phoneAction];
            }
            else
            {
                if (![((SNPrivatelistViewController *)viewController)->keywordArray containsObject:keyword])
                {
                    [((SNPrivatelistViewController *)viewController)->keywordArray addObject:keyword];
                    [((SNPrivatelistViewController *)viewController)->typeArray addObject:@"0"];
                    [((SNPrivatelistViewController *)viewController)->nameArray addObject:self.nameString];
                    [((SNPrivatelistViewController *)viewController)->messageArray addObject:self.messageString];
                    [((SNPrivatelistViewController *)viewController)->numberArray addObject:self.numberString];
                    [((SNPrivatelistViewController *)viewController)->smsArray addObject:self.messageAction];
                    [((SNPrivatelistViewController *)viewController)->phoneArray addObject:self.phoneAction];
                    [((SNPrivatelistViewController *)viewController)->forwardArray addObject:self.forwardString];
                    [((SNPrivatelistViewController *)viewController)->replyArray addObject:self.replyString];
                    [((SNPrivatelistViewController *)viewController)->soundArray addObject:self.soundString];
                }
            }
        }
	}
    
    [((UITableViewController *)viewController).tableView reloadData];
}

- (void)saveTextFieldValues
{
    if (nameField)
    {
        self.nameString = nil;
        self.nameString = nameField.text ? nameField.text : @"";
    }
    if (keywordField)
    {
        self.keywordString = nil;
        self.keywordString = keywordField.text ? keywordField.text : @"";
    }
    if (messageField)
    {
        self.messageString = nil;
        self.messageString = messageField.text ? messageField.text : @"";
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self saveTextFieldValues];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addGestureRecognizer:tapRecognizer];
}

- (void)dismissKeyboardWithTap:(UITapGestureRecognizer *)tap
{
    [keywordField resignFirstResponder];
    [nameField resignFirstResponder];
    [messageField resignFirstResponder];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == tapRecognizer && [touch.view isKindOfClass:NSClassFromString(@"UITableViewCellContentView")]) return NO;
    return YES;
}
- (void)saveSwitchValues
{
    if (replySwitch)
    {
        self.replyString = nil;
        self.replyString = replySwitch.on ? @"1" : @"0";
    }
    if (soundSwitch)
    {
        self.soundString = nil;
        self.soundString = soundSwitch.on ? @"1" : @"0";
    }
}
@end