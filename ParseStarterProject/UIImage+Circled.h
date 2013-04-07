//
//  UIImage+Circled.h
//  SecondCircle
//
//  Created by Constantine Fry on 4/6/13.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (Circled)

+(UIImage *)makeRoundCornerImage : (UIImage*) img
                            width: (int) cornerWidth
                           height: (int) cornerHeight;

+(UIImage *)appleMask: (UIImage*) maskImage
             forImage: (UIImage*) inputImage;
@end
