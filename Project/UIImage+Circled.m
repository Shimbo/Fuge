//
//  UIImage+Circled.m
//  SecondCircle
//
//  Created by Constantine Fry on 4/6/13.
//
//

#import "UIImage+Circled.h"

@implementation UIImage (Circled)

//http://blog.sallarp.com/iphone-uiimage-round-corners/
//http://iosdevelopertips.com/cocoa/how-to-mask-an-image.html
static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
    float fw, fh;
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM (context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

+(UIImage *)makeRoundCornerImage : (UIImage*) img
                            width: (int) cornerWidth
                           height: (int) cornerHeight
{
	UIImage * newImage = nil;
    
	if( nil != img)
	{
        
		int w = img.size.width;
		int h = img.size.height;
        
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
        
		CGContextBeginPath(context);
		CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
		addRoundedRectToPath(context, rect, cornerWidth, cornerHeight);
		CGContextClosePath(context);
		CGContextClip(context);
        
		CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage);
        
		CGImageRef imageMasked = CGBitmapContextCreateImage(context);
        
        
        
		CGContextRelease(context);
		CGColorSpaceRelease(colorSpace);
        
        
		newImage = [UIImage imageWithCGImage:imageMasked] ;
		CGImageRelease(imageMasked);
        
        
	}
    
    return newImage;
}

+(UIImage *)appleMask: (UIImage*) maskImage
            forImage: (UIImage*) inputImage
{
	UIImage * maskedImage = nil;
    
	if( nil != inputImage && nil != maskImage)
	{
        CGImageRef maskRef = maskImage.CGImage;
        
        CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                            CGImageGetHeight(maskRef),
                                            CGImageGetBitsPerComponent(maskRef),
                                            CGImageGetBitsPerPixel(maskRef),
                                            CGImageGetBytesPerRow(maskRef),
                                            CGImageGetDataProvider(maskRef), NULL, false);
        
        CGImageRef masked = CGImageCreateWithMask([inputImage CGImage], mask);
        CGImageRelease(mask);
        
        maskedImage = [UIImage imageWithCGImage:masked];
        
        CGImageRelease(masked);
        
        
	}
    
    return maskedImage;
}

@end
