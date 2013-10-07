//
//  ModelController.h
//  FaceDetector
//
//  Created by Ildar Sibagatov on 07.10.13.
//  Copyright (c) 2013 Sig Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DataViewController;

@interface ModelController : NSObject <UIPageViewControllerDataSource>

- (DataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard;
- (NSUInteger)indexOfViewController:(DataViewController *)viewController;

@end
