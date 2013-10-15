//
//  UIImage+Flip.m
//  FaceDetector
//
//  Created by Ildar Sibagatov on 15.10.13.
//  Copyright (c) 2013 Sig Inc. All rights reserved.
//

#import "UIImage+Flip.h"

@implementation UIImage (Flip)

- (UIImage*)theHorizontalFlip
{
    UIGraphicsBeginImageContext(self.size);
    CGContextRef current_context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(current_context, self.size.width, 0);
    CGContextScaleCTM(current_context, -1.0, 1.0);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    
    UIImage *flipped_img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return flipped_img;
}

@end
