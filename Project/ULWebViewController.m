//
//  WebViewController.m
//  Fuge
//
//  Created by Mikhail Larionov on 10/13/13.
//
//

#import "ULWebViewController.h"

@implementation ULWebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Right buttons
    UIBarButtonItem* done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancelButtonDown)];
    UIBarButtonItem* send = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(sendLinkDown)];
    NSArray* arrayButtons;
    if ([MFMailComposeViewController canSendMail])
        arrayButtons = @[done, send];
    else
        arrayButtons = @[done];
    [self.navigationItem setRightBarButtonItems:arrayButtons];
    
    // Load url
    NSURL* url = [NSURL URLWithString:_url];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [_webView loadRequest:request];
}

- (void)cancelButtonDown {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) sendLinkDown
{
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    NSString* subject = [NSString stringWithFormat:@"Check this event: %@", _event];
    [controller setSubject:subject];
    
    NSString* body;
    if ( _preview )
        body = [NSString stringWithFormat:@"Hey there!<BR><BR>Here's the link to the event \"%@\". Visit Songkick for tickets and venue details:<P><A HREF=%@>%@</A><BR><BR>Also, check artist preview on Deezer:<P><A HREF=%@>%@</A><BR><BR>--<BR>Regards,<BR>Sent from <A HREF=%@>Fuge</A>", _event, _url, _url, _preview, _preview, APP_STORE_PATH];
    else
    {
#ifdef TARGET_FUGE
        NSString* sentFrom = @"Fuge";
#elif defined TARGET_S2C
        NSString* sentFrom = @"Simple2Connect";
#endif
        body = [NSString stringWithFormat:@"Hey there!<BR><BR>Here's the link to the event \"%@\".<P><A HREF=%@>%@</A><BR><BR>--<BR>Regards,<BR>Sent from <A HREF=%@>%@</A>", _event, _url, _url, APP_STORE_PATH, sentFrom];
    }
    [controller setMessageBody:body isHTML:YES];
    
    NSString* email = [pCurrentUser objectForKey:@"email"];
    if ( email )
        [controller setCcRecipients:@[email]];
    if (controller)
        [self presentModalViewController:controller animated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        NSLog(@"It's away!");
    }
    [self dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setUrl:(NSString*)url andEvent:(NSString*)event withPreview:(NSString*)preview
{
    _url = url;
    _event = event;
    _preview = preview;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [_activityIndicator startAnimating];
    if ([_webView canGoBack])
        [self.navigationItem setLeftBarButtonItems:@[[[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:_webView action:@selector(goBack)]/*, [[UIBarButtonItem alloc] initWithTitle:@"Forward" style:UIBarButtonItemStylePlain target:_webView action:@selector(goForward)]]*/]];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_activityIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [_activityIndicator stopAnimating];
}


@end
