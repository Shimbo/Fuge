//
//  ULKeyboardHandler.h
//  Fuge
//
//  Created by Mikhail Larionov on 10/21/13.
//
//

#import <Foundation/Foundation.h>

@protocol ULKeyboardHandlerDelegate

- (void)keyboardSizeChanged:(CGSize)delta;

@end

@interface ULKeyboardHandler : NSObject

- (id)init;

// Put 'weak' instead of 'assign' if you use ARC
@property(nonatomic, assign) id<ULKeyboardHandlerDelegate> delegate;
@property(nonatomic) CGRect frame;

@end