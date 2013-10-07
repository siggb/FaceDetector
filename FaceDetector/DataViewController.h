//
//  DataViewController.h
//  FaceDetector
//
//  Created by Ildar Sibagatov on 07.10.13.
//  Copyright (c) 2013 Sig Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DataViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *dataLabel;
@property (strong, nonatomic) id dataObject;

@end
