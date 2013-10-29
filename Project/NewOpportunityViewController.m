//
//  NewOpportunityViewController.m
//  Fuge
//
//  Created by Mikhail Larionov on 10/19/13.
//
//

#import "NewOpportunityViewController.h"
#import "Person.h"

@implementation NewOpportunityViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

-(void)setOpportunityToEdit:(FUGOpportunity*)op
{
    _op = op;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    if ( _op )
    {
        UIBarButtonItem *delete = [[UIBarButtonItem alloc] initWithTitle:@"Delete" style:UIBarButtonItemStylePlain target:self action:@selector(delete)];
        [self.navigationItem setRightBarButtonItems:@[done, delete]];
    }
    else
        [self.navigationItem setRightBarButtonItem:done];
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
    [self.navigationItem setLeftBarButtonItem:back];
    _textBorder.height = _opportunityText.height;
    _opportunityText.text = _op.text;
    
    _keyboard = [[ULKeyboardHandler alloc] init];
    _keyboard.delegate = self;
    
    _scrollView.contentSize = CGSizeMake(self.view.width, _opportunityHint.height + _opportunityHint.originY);
    
    [_opportunityText becomeFirstResponder];
}

- (void)back
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)delete
{
    [currentPerson deleteOpportunity:_op];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)done
{
    if ( _op )
    {
        _op.text = _opportunityText.text;
        [currentPerson saveOpportunity:_op];
    }
    else
        [currentPerson addOpportunity:_opportunityText.text];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSUInteger newLength = [_opportunityText.text length] + [text length] - range.length;
    return (newLength > TEXT_MAX_OPPORTUNITY_LENGTH) ? NO : YES;
}

- (void)keyboardSizeChanged:(CGSize)delta
{
    _scrollView.height -= delta.height;
}

@end
