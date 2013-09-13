//
//  CommentsView.h
//  Fuge
//
//  Created by Mikhail Larionov on 9/12/13.
//
//

#import <UIKit/UIKit.h>
#import "AsyncImageView.h"
#import "Comment.h"
#import "Message.h"

@class Person;

@interface CommentView : UIView
{
    Boolean             bOwn;
    NSString            *strText;
    Person              *owner;
    AsyncImageView      *avatar;
    UITextView          *text;
}

- (void) setComment:(Comment*)comment;
- (void) setMessage:(Message*)message;

@end

@interface CommentsView : UIView
{
    NSMutableArray*     commentsList;
    NSMutableArray*     commentViews;
    NSUInteger          viewHeight;
    UILabel*            textLabel;
}

-(void) setCommentsList:(NSArray*)list;
-(void) addComment:(id)comment;
-(void) setText:(NSString*)strText;

@end
