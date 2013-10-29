//
//  WebViewController.h
//  Fuge
//
//  Created by Mikhail Larionov on 10/13/13.
//
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface ULWebViewController : UIViewController <UIWebViewDelegate, MFMailComposeViewControllerDelegate>
{
    NSString            *_url;
    NSString            *_event;
    NSString            *_preview;
    IBOutlet UIWebView  *_webView;
    IBOutlet UIActivityIndicatorView *_activityIndicator;
}

-(void)setUrl:(NSString*)url andEvent:(NSString*)event withPreview:(NSString*)preview;

@end
