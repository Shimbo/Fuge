//
//  FacebookLoader.h
//  SecondCircle
//
//  Created by Mikhail Larionov on 6/22/13.
//
//

#import <Foundation/Foundation.h>

@interface FacebookLoader : NSObject

- (void)loadMeetups:(id)target selector:(SEL)callback;
- (void)loadLikes:(id)target selector:(SEL)callback;

@end
