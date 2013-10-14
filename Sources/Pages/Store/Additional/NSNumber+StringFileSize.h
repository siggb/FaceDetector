//
//  NSNumber+StringFileSize.h
//  FaceDetector
//
//  Created by Ildar Sibagatov on 14.10.13.
//  Copyright (c) 2013 Sig Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNumber (StringFileSize)

- (NSString *)stringValueAsFileSize:(BOOL)fractionalEnabled;

@end
