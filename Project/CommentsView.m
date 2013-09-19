//
//  CommentsView.m
//  Fuge
//
//  Created by Mikhail Larionov on 9/12/13.
//
//

#import "CommentsView.h"
#import "Person.h"

#define CV_DEFAULT_AVATAR_SIZE      25
#define CV_DEFAULT_COMMENT_HEIGHT   30
#define CV_DEFAULT_COMMENT_OFFSET   10

@implementation CommentView

- (void) setComment:(Comment*)comment
{
    bOwn = false;
    owner = comment.owner;
    if ( [comment.systemType integerValue] == COMMENT_PLAIN )
        strText = [NSString stringWithFormat:@"%@: %@", comment.strNameUserFrom, comment.strComment ];
    else
        strText = comment.strComment;
    
    [self recalcStuff];
}

- (void) setMessage:(Message*)message
{
    bOwn = message.isOwn;
    owner = message.owner;
    strText = message.strText;
    
    [self recalcStuff];
}

- (void) recalcStuff
{
    // Layout
    /*if ( bOwn )
    {
        avatar = [[AsyncImageView alloc] initWithFrame:CGRectMake( self.frame.size.width - CV_DEFAULT_AVATAR_SIZE - 10, 8, CV_DEFAULT_AVATAR_SIZE, CV_DEFAULT_AVATAR_SIZE )];
        text = [[UITextView alloc] initWithFrame:CGRectMake( 10, 0, self.frame.size.width - CV_DEFAULT_AVATAR_SIZE - 20, CV_DEFAULT_COMMENT_HEIGHT )];
        text.textAlignment = UITextAlignmentRight;
    }
    else
    {*/
        avatar = [[AsyncImageView alloc] initWithFrame:CGRectMake( 10, 8, CV_DEFAULT_AVATAR_SIZE, CV_DEFAULT_AVATAR_SIZE )];
        text = [[UITextView alloc] initWithFrame:CGRectMake( CV_DEFAULT_AVATAR_SIZE+15, 0, self.frame.size.width - CV_DEFAULT_AVATAR_SIZE-15, CV_DEFAULT_COMMENT_HEIGHT )];
    //}
    text.userInteractionEnabled = FALSE;
    avatar.userInteractionEnabled = FALSE;
    [self addSubview:avatar];
    [self addSubview:text];
    
    // Font
    UIFont* font = [UIFont systemFontOfSize:14];
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = /*bOwn ? NSTextAlignmentRight :*/ NSTextAlignmentLeft;
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          font, NSFontAttributeName,
                                          paragraph, NSParagraphStyleAttributeName,
                                          nil];
    NSMutableAttributedString* strTemp = [[NSMutableAttributedString alloc] initWithString:strText attributes:attributesDictionary];
    text.attributedText = strTemp;
    
    // Resize
    CGSize newSize;
    if ( IOS_NEWER_OR_EQUAL_TO_7 )
    {
        CGRect paragraphRect = [text.attributedText.string boundingRectWithSize:CGSizeMake(text.width-2, 9999) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:attributesDictionary context:nil];
        newSize = paragraphRect.size;
    }
    else
        newSize = [text.text sizeWithFont:font constrainedToSize:CGSizeMake(text.width, 9999)];
    
    if ( newSize.height + CV_DEFAULT_COMMENT_OFFSET > CV_DEFAULT_COMMENT_HEIGHT )
    {
        text.height = newSize.height + CV_DEFAULT_COMMENT_OFFSET;
        self.height = newSize.height + CV_DEFAULT_COMMENT_OFFSET;
    }
    
    // Avatar
    if ( owner )
        [avatar loadImageFromURL:[owner smallAvatarUrl]];
    else
    {
        UIImageView* image = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CV_DEFAULT_AVATAR_SIZE, CV_DEFAULT_AVATAR_SIZE)];
        image.backgroundColor = [UIColor lightGrayColor];
        [avatar addSubview:image];
    }
}

@end


@implementation CommentsView

- (id) init
{
    self = [super init];
    if ( self )
    {
        textLabel = [[UILabel alloc] initWithFrame:self.frame];
        textLabel.text = @"Loading...";
        [self addSubview:textLabel];
    }
    return self;
}

- (void) addCommentInternal:(id)comment
{
    CommentView* commentView = [[CommentView alloc] initWithFrame:CGRectMake(0, viewHeight, self.frame.size.width, CV_DEFAULT_COMMENT_HEIGHT)];
    if ( [comment isKindOfClass:[Message class]] )
        [commentView setMessage:comment];
    else if ( [comment isKindOfClass:[Comment class]] )
        [commentView setComment:comment];
    else return;
    
    [self addSubview:commentView];
    [commentViews addObject:commentView];
    viewHeight += commentView.height;
}

- (void) setCommentsList:(NSArray*)list
{
    viewHeight = 0;
    commentsList = [NSMutableArray arrayWithArray:list];
    commentViews = [NSMutableArray arrayWithCapacity:list.count];
    textLabel.hidden = TRUE;
    
    for ( id comment in list )
        [self addCommentInternal:comment];
    self.height = viewHeight;
}

-(void) addComment:(id)comment
{
    [self addCommentInternal:comment];
    self.height = viewHeight;
}

-(void) setText:(NSString *)strText
{
    textLabel.hidden = FALSE;
    textLabel.text = strText;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
