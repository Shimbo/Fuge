//
//  MeetupInviteSearch.h
//  SecondCircle
//
//  Created by Constantine Fry on 3/8/13.
//
//

#import <Foundation/Foundation.h>

@interface MeetupInviteSearch : NSObject<UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate>


@property(nonatomic,weak)UITableView* tableView;
@property(nonatomic,strong)NSArray*searchResult;
@property (nonatomic,weak)NSMutableDictionary *selected;


@end
