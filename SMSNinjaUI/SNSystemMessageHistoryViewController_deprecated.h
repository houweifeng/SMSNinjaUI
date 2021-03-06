#import "SMSNinja-private.h"

@interface SNSystemMessageHistoryViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate>
{
@public
	NSMutableArray *numberArray;
	NSMutableArray *nameArray;
	NSMutableArray *timeArray;
	NSMutableArray *contentArray;
    NSMutableSet *keywordSet;
	int chosenRow;
}
@property (nonatomic, retain) NSString *flag;
- (void)initializeAllArrays;
- (void)selectAll:(UIBarButtonItem *)buttonItem;
@end