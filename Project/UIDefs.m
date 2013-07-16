//
//  NSObject+PerformBlockAfterDelay.m
//  Elevator
//
//  Created by Igor Khmurets on 27.11.12.
//  Copyright (c) 2012 Igor Khmurets/Alexander Lednik. All rights reserved.
//

#import "UIDefs.h"

@implementation NSObject (PerformBlockAfterDelay)

- (void)performAfterDelay:(NSTimeInterval)delay block:(void (^)(void))block
{
    block = [block copy];
    [self performSelector:@selector(fireBlockAfterDelay:) withObject:block afterDelay:delay];
}

- (void)fireBlockAfterDelay:(void (^)(void))block
{
    block();
}

@end

@implementation UIColor (HexColor)

+ (UIColor *)colorWithHexString:(NSString *)hexString {
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if(cleanString.length == 3) {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                       [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
                       [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
                       [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    if (cleanString.length == 6) {
        cleanString = [cleanString stringByAppendingString:@"ff"];
    }
    
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    float red = ((baseValue >> 24) & 0xFF) / 255.f;
    float green = ((baseValue >> 16) & 0xFF) / 255.f;
    float blue = ((baseValue >> 8) & 0xFF) / 255.f;
    float alpha = ((baseValue >> 0) & 0xFF) / 255.f;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end

@implementation UIView (Coordinates)

- (void)setCenterX:(CGFloat)centerX
{
    self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)centerX
{
    return self.center.x;
}

- (void)setCenterY:(CGFloat)centerY
{
    self.center = CGPointMake(self.center.x, centerY);
}

- (CGFloat)centerY
{
    return self.center.y;
}

- (void)setOrigin:(CGPoint)origin
{
    self.frame = CGRectMake(origin.x, origin.y, self.frame.size.width, self.frame.size.height);
}

- (CGPoint)origin
{
    return CGPointMake(self.frame.origin.x, self.frame.origin.y);
}

- (void)setOriginX:(CGFloat)originX
{
    self.frame = CGRectMake(originX, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
}

- (CGFloat)originX
{
    return self.frame.origin.x;
}

- (void)setOriginY:(CGFloat)originY
{
    self.frame = CGRectMake(self.frame.origin.x, originY, self.frame.size.width, self.frame.size.height);
}

- (CGFloat)originY
{
    return self.frame.origin.y;
}

- (void)setWidth:(CGFloat)width
{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, self.frame.size.height);
}

- (CGFloat)width
{
    return self.frame.size.width;
}

- (void)setHeight:(CGFloat)height
{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
}

- (CGFloat)height
{
    return self.frame.size.height;
}

- (void)setSize:(CGSize)size
{
    self.frame = CGRectMake(0.f, 0.f, size.width, size.height);
}

- (CGSize)size
{
    return self.frame.size;
}

@end
