//
//  NSNumber+StringFileSize.m
//  FaceDetector
//
//  Created by Ildar Sibagatov on 14.10.13.
//  Copyright (c) 2013 Sig Inc. All rights reserved.
//

#import "NSNumber+StringFileSize.h"

@implementation NSNumber (StringFileSize)

- (NSString *)stringValueAsFileSize:(BOOL)fractionalEnabled
{
    double converted_value = self.doubleValue;
    int multiply_factor = 0;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"bytes", @"KiB", @"MiB", @"GiB", @"TiB", nil];
    
    while (converted_value > 1024) {
        converted_value /= 1024;
        multiply_factor++;
    }
    
    NSString *string_value = @"";
    
    if (fractionalEnabled) {
        string_value = [NSString stringWithFormat:@"%4.2f %@",converted_value,
                        [tokens objectAtIndex:multiply_factor]];
    }
    else {
        string_value = [NSString stringWithFormat:@"%ld %@",lround(converted_value),
                        [tokens objectAtIndex:multiply_factor]];
    }
    
    return string_value;
}

@end
