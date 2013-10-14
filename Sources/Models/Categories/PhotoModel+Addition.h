//
//  PhotoModel+Addition.h
//  FaceDetector
//
//  Created by Ildar Sibagatov on 14.10.13.
//  Copyright (c) 2013 Sig Inc. All rights reserved.
//

#import "PhotoModel.h"

@interface PhotoModel (Addition)

+ (id)findByPK:(NSNumber*)pk;

+ (id)createEntity:(UIImage*)image createdDate:(NSDate*)createdDate;

@end
