//
//  EventbriteLoader.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 6/21/13.
//
//

#import <Foundation/Foundation.h>

#define EVENTBRITE_API_KEY      @"UVEOELJK66WVH2CFIG"

@interface EventbriteLoader : NSObject <NSURLConnectionDelegate>
{
    id resultTarget;
    SEL resultCallback;
    NSMutableData* receivedData;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)loadData:(NSString*)strSource target:(id)target selector:(SEL)callback;

@end
