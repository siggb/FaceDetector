//
//  DetailViewController.m
//  FaceDetector
//
//  Created by Ildar Sibagatov on 14.10.13.
//  Copyright (c) 2013 Sig Inc. All rights reserved.
//

#import "DetailViewController.h"
#import "NSNumber+StringFileSize.h"
#import "SCRFTPRequest.h"

static const CGFloat ContainerWidth = 320;
static const CGFloat ContainerHeight = 369;
#define HomeDirectory [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]


@interface DetailViewController () <UIScrollViewDelegate, SCRFTPRequestDelegate>
{
    NSUInteger bytesTransmitted;
}
@property (nonatomic, weak) IBOutlet UILabel *fileSizeLabel;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UIButton *shareButton;

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

- (IBAction)shareButtonClicked:(UIButton*)sender
{
    NSLog(@"shareButtonClicked");
    
    bytesTransmitted = 0;
    [self.progressView setProgress:0];
    [self.shareButton setEnabled:NO];
    
    NSData *data = UIImagePNGRepresentation(self.photoModel.photo);
    NSString *path = [NSString stringWithFormat:@"%@/img%@_%@.png", HomeDirectory,
                      self.photoModel.pk,
                      [[DetailViewController visualDateFormatter] stringFromDate:[self.photoModel createdDate]]];
    [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
    
    SCRFTPRequest *ftp_request = [[SCRFTPRequest alloc] initWithURL:[NSURL URLWithString:@"ftp://192.168.0.103/"]
                                                       toUploadFile:path];
    ftp_request.username = @"sig";
    ftp_request.password = @"sig";
    ftp_request.delegate = self;
    [ftp_request startAsynchronous];
}

#pragma mark - Методы SCRFTPRequest Delegate

- (void)ftpRequestDidFinish:(SCRFTPRequest *)request
{
    NSLog(@"Upload finished");
    [self.shareButton setEnabled:YES];
    [self.progressView setProgress:0 animated:NO];
    bytesTransmitted = 0;
}

- (void)ftpRequest:(SCRFTPRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Upload failed: %@", [error localizedDescription]);
    [self.shareButton setEnabled:YES];
    [self.progressView setProgress:0 animated:NO];
    bytesTransmitted = 0;
}

- (void)ftpRequestWillStart:(SCRFTPRequest *)request
{
    NSLog(@"Will transfer %llu bytes", request.fileSize);
}

- (void)ftpRequest:(SCRFTPRequest *)request didWriteBytes:(NSUInteger)bytesWritten
{
    NSLog(@"Transferred: %d", bytesWritten);
    NSLog(@"Progress: %f", (float)bytesTransmitted/(float)request.fileSize);
    
    bytesTransmitted += bytesWritten;
    [self.progressView setProgress:(float)bytesTransmitted/(float)request.fileSize];
}

- (void)ftpRequest:(SCRFTPRequest *)request didChangeStatus:(SCRFTPRequestStatus)status
{
    switch ((NSUInteger) status) {
        case SCRFTPRequestStatusOpenNetworkConnection:
            NSLog(@"Opened connection");
            break;
        case SCRFTPRequestStatusReadingFromStream:
            NSLog(@"Reading from stream...");
            break;
        case SCRFTPRequestStatusWritingToStream:
            NSLog(@"Writing to stream...");
            break;
        case SCRFTPRequestStatusClosedNetworkConnection:
            NSLog(@"Closed connection");
            break;
        case SCRFTPRequestStatusError:
            NSLog(@"Error occurred");
            break;
    }
}

#pragma mark - Вспомогательные методы

+ (NSDateFormatter*)visualDateFormatter
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.locale = [NSLocale currentLocale];
    [df setDateFormat:@"d-MM-yy"];
    [df setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"MSK"]];
    return df;
}

@end
