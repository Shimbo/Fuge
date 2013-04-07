//
//  ImageLoader.m
//  Ymo3
//
//  Created by Constantine Fry on 11/15/12.
//  Copyright (c) 2012 South Ventures USA, LLC. All rights reserved.
//

#import "ImageLoader.h"
#import "ParseStarterProjectAppDelegate.h"


@implementation ImageLoader{
    NSURLConnection *connection;
    NSMutableData *data;
    NSString *__weak _urlString;
    ImageHandler _handler;
}

- (id)initForCircleImages
{
    self = [super init];
    if (self) {
        ParseStarterProjectAppDelegate *dlgt = (ParseStarterProjectAppDelegate*)[[UIApplication sharedApplication]delegate];
        _imageCache = dlgt.circledImageCache;
        self.maxImageSize = 400000;
        self.maxSize = CGSizeMake(200, 200);
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        ParseStarterProjectAppDelegate *dlgt = (ParseStarterProjectAppDelegate*)[[UIApplication sharedApplication]delegate];
        _imageCache = dlgt.imageCache;
        self.maxImageSize = 400000;
        self.maxSize = CGSizeMake(200, 200);
    }
    return self;
}

-(UIImage*)getImage:(NSString*)url{
    return [_imageCache objectForKey:url];
}

-(void)setImage:(UIImage*)image url:(NSString*)url {
    [_imageCache setObject:image
                    forKey:url
                      cost:1];
}

-(void)loadImageWithUrl:(NSString*)url
                handler:(ImageHandler)handler{
    
    [connection cancel];
    data = nil;
    
    if (!url ) {
        handler(nil);
    }
    
    
    
    _urlString = url;
    UIImage *cachedImage = [_imageCache objectForKey:_urlString];
    
    if ( cachedImage != nil ) {
//        STLog(@"asd:%@",_urlString);
        handler(cachedImage);
        return;
    }
    
    _handler = handler;
    //    spinny.hidden = NO;
    
    //    STLog(@"%d",[[NSURLCache sharedURLCache] currentDiskUsage]);
    //    STLog(@"%d",[[NSURLCache sharedURLCache] currentMemoryUsage]);
    
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                             cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                         timeoutInterval:10];
    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}



- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)incrementalData {
    if ( data == nil ) {
        data = [[NSMutableData alloc] initWithCapacity:2048];
    }
    [data appendData:incrementalData];
}


- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
    
    connection = nil;
    
    
    
    UIImage *image = [UIImage imageWithData:data];
    

    if (!image) {
        NSLog(@"no image: %@",_urlString);
    }
    if (image) {
        [_imageCache setObject:image
                        forKey:_urlString
                          cost:data.length];
    }
    _handler(image);

    
    data = nil;
}


-(void)cancel{
    [connection cancel];
    connection = nil;
    data = nil;
}

@end
