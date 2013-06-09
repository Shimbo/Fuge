//
//  TableAnnotationsViewViewController.h
//  SecondCircle
//
//  Created by Constantine Fry on 4/27/13.
//
//

#import <UIKit/UIKit.h>

@class REVClusterPin;
@interface TableAnnotationsViewController : UITableViewController {
    REVClusterPin *_selectedAnnotation;
}

@property (nonatomic,strong)NSMutableArray *objects;
@property (nonatomic,strong)NSMutableArray *annotations;
@end
