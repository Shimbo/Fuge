//
//  EventbriteLoader.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 6/21/13.
//
//

#import <Foundation/Foundation.h>

@interface EventbriteLoader : NSObject <NSURLConnectionDelegate>
{
    id resultTarget;
    SEL resultCallback;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)loadData:(id)target selector:(SEL)callback;

@end
