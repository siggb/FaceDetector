//
//  DetailViewController.m
//  FaceDetector
//
//  Created by Ildar Sibagatov on 14.10.13.
//  Copyright (c) 2013 Sig Inc. All rights reserved.
//

#import "DetailViewController.h"
#import "NSNumber+StringFileSize.h"

@interface DetailViewController ()

@property (nonatomic, weak) IBOutlet UILabel *fileSizeLabel;
@property (nonatomic, weak) IBOutlet UIImageView *photoImageView;

@end



@implementation DetailViewController

#pragma mark - View Lifecicle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.fileSizeLabel setText:[self.photoModel.fileSize stringValueAsFileSize:YES]];
    [self.photoImageView setImage:self.photoModel.photo];
}

#pragma mark - Обработка нажатий по кнопкам

/**
 *  Возвращаемся на предыдущий контроллер
 */
- (IBAction)backButtonClicked:(UIButton*)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
