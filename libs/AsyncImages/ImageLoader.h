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

@property (nonatomic,strong) NSCache *imageCache;
@property (nonatomic) NSUInteger maxImageSize;
@property (nonatomic) CGSize maxSize;
- (id)initForCircleImages;

-(UIImage*)getImage:(NSString*)url;
-(void)setImage:(UIImage*)image url:(NSString*)url;
-(void)loadImageWithUrl:(NSString*)url
                handler:(ImageHandler)handler;
-(void)cancel;

@end
