
//
//  NSObject+PerformBlockAfterDelay.h
//  Elevator
//
//  Created by Igor Khmurets on 27.11.12.
//  Copyright (c) 2012 Igor Khmurets/Alexander Lednik. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IPAD (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad)

#define DEVICE_IS_IPHONE_5 ([UIScreen mainScreen].bounds.size.height == 568.f)

#define SYSTEM_VERSION_IS_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

#define KEYBOARD_HEIGHT 216.f

@interface NSObject (PerformBlockAfterDelay)

- (void)performAfterDelay:(NSTimeInterval)delay block:(void (^)(void))block;

@end


@interface UIColor (HexColor)

+ (UIColor *)colorWithHexString:(NSString *)hexString;

@end


@interface UIView (Coordinates)

@property (nonatomic) CGFloat originX;
@property (nonatomic) CGFloat originY;
@property (nonatomic) CGPoint origin;
@property (nonatomic) CGFloat centerX;
@property (nonatomic) CGFloat centerY;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGSize size;

@end


@interface UILabel (Copy) <NSCopying>

@end