#import "SNMessageActionViewController.h"
#import "SNTimeViewController.h"
#import "SNTextTableViewCell.h"
#import <objc/runtime.h>

@implementation SNMessageActionViewController

@synthesize messageAction;
@synthesize forwardString;
@synthesize numberString;

- (void)dealloc
{
	[messageAction release];
	messageAction = nil;
    
	[forwardString release];
	forwardString = nil;
    
	[numberString release];
	numberString = nil;
    
	[forwardSwitch release];
	forwardSwitch = nil;
    
	[numberField release];
	numberField = nil;
    
	[super dealloc];
}

- (SNMessageActionViewController *)init
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped]))
	{
		self.title= NSLocalizedString(@"Message", @"Message");
        
        forwardSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        numberField = [[UITextField alloc] initWithFrame:CGRectZero];
	}
	return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	SNTextTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"any-cell"];
	if (cell == nil) cell = [[[SNTextTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"any-cell"] autorelease];
    
    switch (indexPath.row)
    {
        case 0:
            cell.textLabel.text = NSLocalizedString(@"Block", @"Block");
            if ([self.messageAction isEqualToString:@"1"]) cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else cell.accessoryType = UITableViewCellAccessoryNone;
            
            break;
        case 1:
            cell.textLabel.text = NSLocalizedString(@"Forward", @"Forward");
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryView = forwardSwitch;
            forwardSwitch.on = [self.forwardString isEqualToString:@"0"] ? NO : YES;
            
            break;
        case 2:
            cell.textLabel.text = NSLocalizedString(@"To", @"To");
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            numberField.delegate = self;
            numberField.text = self.numberString;
            numberField.clearButtonMode = UITextFieldViewModeWhileEditing;
            numberField.placeholder = NSLocalizedString(@"Number here", @"Number here");
            [cell.contentView addSubview:numberField];
            
            break;
    }
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    
	if (indexPath.row == 0)
	{
		if ([tableView cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryCheckmark)
		{
			[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
            
			self.messageAction = nil;
			self.messageAction = @"0";
		}
		else if ([tableView cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryNone)
		{
			[tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
            
			self.messageAction = nil;
			self.messageAction = @"1";
		}
	}
    
    id viewController = [self.navigationController.viewControllers objectAtIndex:([self.navigationController.viewControllers count] - 2)];
    [viewController setMessageAction:nil];
    [viewController setMessageAction:self.messageAction];
}

- (void)viewWillDisappear:(BOOL)animated
{
    id viewController = [self.navigationController.viewControllers objectAtIndex:([self.navigationController.viewControllers count] - 2)];
    SEL selector = NSSelectorFromString(@"setForwardString:");
    [viewController performSelector:selector withObject:nil];
    [viewController performSelector:selector withObject:forwardSwitch.on ? @"1" : @"0"];

    selector = NSSelectorFromString(@"setNumberString:");
    [viewController performSelector:selector withObject:nil];
    [viewController performSelector:selector withObject:[numberField.text length] == 0 ? @"" : [numberField.text stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];

    if ([viewController isKindOfClass:[SNTimeViewController class]]) [((SNTimeViewController *)viewController)->settingsTableView reloadData];
    else [((UITableViewController *)viewController).tableView reloadData];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}
@end