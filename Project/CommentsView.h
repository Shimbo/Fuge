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
    NSString            *strOwnerId;
    Person              *owner;
    AsyncImageView      *avatar;
    UITextView          *text;
    UIButton            *tapButton;
}

- (void) setComment:(Comment*)comment;
- (void) setMessage:(Message*)message;
- (void) updateAvatar;

@end

@interface CommentsView : UIView
{
    NSMutableArray*     commentsList;
    NSMutableArray*     commentViews;
    NSUInteger          viewHeight;
    UILabel*            textLabel;
    UINavigationController  *navigationController;
}

-(void) setCommentsList:(NSArray*)list navigation:(UINavigationController*)navigation;
-(void) addComment:(id)comment;
-(void) setText:(NSString*)strText;

-(UINavigationController*) getNavigationController;

-(void) updateAvatars;

@end
