//
//  PhotoModel.h
//  FaceDetector
//
//  Created by Ildar Sibagatov on 15.10.13.
//  Copyright (c) 2013 Sig Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AbstractModel.h"


@interface PhotoModel : AbstractModel

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * fileSize;
@property (nonatomic, retain) id photo;

@end
