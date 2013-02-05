//
//  ImageLoader.h
//  Ymo3
//
//  Created by Constantine Fry on 11/15/12.
//  Copyright (c) 2012 South Ventures USA, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ImageHandler)(UIImage *image);

@interface ImageLoader : NSObject

@property (nonatomic) NSUInteger maxImageSize;
@property (nonatomic) CGSize maxSize;



-(void)loadImageWithUrl:(NSString*)url
                handler:(ImageHandler)handler;
-(void)cancel;

@end
