//
//  DetailViewController.m
//  FaceDetector
//
//  Created by Ildar Sibagatov on 14.10.13.
//  Copyright (c) 2013 Sig Inc. All rights reserved.
//

#import "DetailViewController.h"
#import "NSNumber+StringFileSize.h"

static const CGFloat ContainerWidth = 320;
static const CGFloat ContainerHeight = 369;

@interface DetailViewController () <UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *fileSizeLabel;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;

@property (nonatomic) UIScrollView *theScrollView;
@property (nonatomic) UIImageView *theImageView;

@end



@implementation DetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *image = self.photoModel.photo;
    [self.fileSizeLabel setText:[self.photoModel.fileSize stringValueAsFileSize:YES]];
    
    self.theScrollView = [UIScrollView new];
    [self.theScrollView setFrame:self.scrollView.frame];
    self.theScrollView.maximumZoomScale = 4.f;
    self.theScrollView.minimumZoomScale = 1.f;
    self.theScrollView.clipsToBounds = YES;
    self.theScrollView.zoomScale = 1.f;
    self.theScrollView.delegate = self;
    
    self.theImageView = [[UIImageView alloc] initWithImage:image];
    CGRect rect = self.imageView.frame;
    if (image.size.width >= image.size.height) {
        rect.size.width = ContainerWidth;
        rect.size.height = ContainerWidth * image.size.height / image.size.width;
    }
    else {
        rect.size.height = ContainerHeight;
        rect.size.width = ContainerHeight * image.size.width / image.size.height;
    }
    self.theImageView.frame = rect;
    self.theImageView.center = CGPointMake(self.theScrollView.frame.size.width/2,
                                           self.theScrollView.frame.size.height/2);
    self.theScrollView.contentSize = self.theImageView.bounds.size;
    
    self.theImageView.backgroundColor = [UIColor whiteColor];
    self.theScrollView.backgroundColor = [UIColor whiteColor];
    
    [self.theScrollView addSubview:self.theImageView];
    [self.view addSubview:self.theScrollView];
}

#pragma mark - Методы UIScrollView Delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)inScroll
{
    return self.theImageView;
}

-(void)scrollViewDidZoom:(UIScrollView *)scrollView
{    
    CGSize bounds_size = self.theScrollView.bounds.size;
    CGRect contents_frame = self.theImageView.frame;
    
    if (contents_frame.size.width < bounds_size.width) {
        contents_frame.origin.x = (bounds_size.width - contents_frame.size.width) / 2.0f;
    } else {
        contents_frame.origin.x = 0.0f;
    }
    
    if (contents_frame.size.height < bounds_size.height) {
        contents_frame.origin.y = (bounds_size.height - contents_frame.size.height) / 2.0f;
    } else {
        contents_frame.origin.y = 0.0f;
    }
    
    self.theImageView.frame = contents_frame;
}

#pragma mark - Обработка нажатий по кнопкам

- (IBAction)backButtonClicked:(UIButton*)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
