//
//  CameraViewController.m
//  FaceDetector
//
//  Created by Ildar Sibagatov on 08.10.13.
//  Copyright (c) 2013 Sig Inc. All rights reserved.
//

#import "CameraViewController.h"
#import "CameraVCAdditions.h"

@interface CameraViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate>
{
    AVCaptureStillImageOutput *stillImageOutput;
    AVCaptureVideoDataOutput *videoDataOutput;
    dispatch_queue_t videoDataOutputQueue;
    
    AVCaptureVideoPreviewLayer *previewLayer;
    
    CGFloat effectiveScale;
    
    CIDetector *faceDetector;
}

@property (nonatomic, weak) IBOutlet UIView *previewView;

@end



@implementation CameraViewController

#pragma mark - View Lifecicle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupAVCapture];
    
    [self setupCIDetector];
}

#pragma mark - Методы настройки механизма захвата видео

- (void)setupAVCapture
{
	NSError *error = nil;
	
    // создаем сессию для захвата данных с камеры и передачи в приложение
	AVCaptureSession *session = [AVCaptureSession new];
	[session setSessionPreset:AVCaptureSessionPresetiFrame960x540]; // AVCaptureSessionPreset640x480
	
    // устанавливаем устройство захвата
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	AVCaptureDeviceInput *device_input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];

    if (error) {
        NSLog(@"Selected device can not be used for capture");
        return;
    }
	
    // связываем устройство захвата с текущей сессией
	if ([session canAddInput:device_input]) {
		[session addInput:device_input];
    }
	
    // создаем объект для вывода статичных изображений
	stillImageOutput = [AVCaptureStillImageOutput new];
	[stillImageOutput addObserver:self
                       forKeyPath:@"capturingStillImage"
                          options:NSKeyValueObservingOptionNew
                          context:(__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext)];
	
    // связываем устройство вывода статичных изображений с текущей сессией
	if ([session canAddOutput:stillImageOutput]) {
		[session addOutput:stillImageOutput];
    }
	
    // создаем объект для получения не сжатых кадров из потока видео
	videoDataOutput = [AVCaptureVideoDataOutput new];
	NSDictionary *rgb_output_settings = nil;
    rgb_output_settings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCMPixelFormat_32BGRA]
                                                    forKey:(id)kCVPixelBufferPixelFormatTypeKey];
	[videoDataOutput setVideoSettings:rgb_output_settings];
	[videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    // создаем очередь на выполнение по принципу FIFO
    // для буферизации статичных кадров из видео-потока
	videoDataOutputQueue = dispatch_queue_create("com.apple.videoDataOutputDispatchQueue", DISPATCH_QUEUE_SERIAL);
	[videoDataOutput setSampleBufferDelegate:self
                                       queue:videoDataOutputQueue];
	
    // связываем устройство вывода кадров видео-потока с текущей сессией
    if ([session canAddOutput:videoDataOutput]) {
		[session addOutput:videoDataOutput];
    }
    
	[[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
	
    // коэфициент зуминга кадров из видео
	effectiveScale = 1.0;
    
    // создаем слой для отображения видео с устройства захвата
	previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
	[previewLayer setBackgroundColor:[[UIColor whiteColor] CGColor]];
	[previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
	
    CALayer *root_layer = [self.previewView layer];
	[root_layer setMasksToBounds:YES];
	[previewLayer setFrame:[root_layer bounds]];
	[root_layer addSublayer:previewLayer];
	
    // запускаем текущую сессию
    [session startRunning];
}

- (void)setupCIDetector
{
    // создаем объект для определения очертаний лица человека
    // на кадре видео-потока
	faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                      context:nil
                                      options:@{CIDetectorAccuracy:CIDetectorAccuracyLow}]; // CIDetectorAccuracyHigh
}

#pragma mark - Методы AVCaptureVideoDataOutputSampleBuffer Delegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"- captureOutput");
    
    // получили изображение в буфер
	CVPixelBufferRef pixel_buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                sampleBuffer,
                                                                kCMAttachmentMode_ShouldPropagate);
    
	CIImage *ci_image = [[CIImage alloc] initWithCVPixelBuffer:pixel_buffer
                                                       options:(__bridge NSDictionary *)attachments];
    (attachments)?CFRelease(attachments):nil;
    
	NSDictionary *image_options = @{CIDetectorImageOrientation:@(kCIDetectorImageOrientation0RowOnTheRight0ColAtTheTop)};
    
	NSArray *features = [faceDetector featuresInImage:ci_image
                                              options:image_options];
	
    // очистка диафрагмы
	CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false);
    
    // чистая диафрагма представляет собой прямоугольник,
    // который определяет часть кодированных размеров пикселей текущего изображения
    
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self drawFaceBoxesForFeatures:features
                           forVideoBox:clap
                       isVideoMirrored:[connection isVideoMirrored]];
	});
}

#pragma mark - Методы определения очертаний лица и выделения их на кадре

- (void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap isVideoMirrored:(BOOL)isVideoMirrored
{
    NSLog(@"- drawFaceBoxesForFeatures");
    
	NSArray *sublayers = [NSArray arrayWithArray:[previewLayer sublayers]];
	NSInteger sublayers_count = [sublayers count];
    
    // количество распознаных признаков очертаний лица человека
	NSInteger features_count = [features count];
	
    // начинаем отрисовку выделения найденных признаков очертаний лиц
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// скрываем все прежние показанные признаки
	for (CALayer *layer in sublayers) {
		if ([[layer name] isEqualToString:@"FaceLayer"])
			[layer setHidden:YES];
	}
	
    // выходим, если распознаные признаки очертаний лица отсутствуют
	if (features_count == 0) {
		[CATransaction commit];
		return;
	}
    
	CGSize parent_frame_size = [self.previewView frame].size;
	NSString *gravity = [previewLayer videoGravity];
	CGRect preview_box = [self.class videoPreviewBoxForGravity:gravity
                                                     frameSize:parent_frame_size
                                                  apertureSize:clap.size];
	
    // отображаем все найденные признаки очертаний лица
    NSInteger currentFeature = 0;
    NSInteger currentSublayer = 0;
	for (CIFaceFeature *ff in features)
    {
		// find the correct position for the square layer within the previewLayer
		// the feature box originates in the bottom left of the video frame.
		// (Bottom right if mirroring is turned on)
		CGRect faceRect = [ff bounds];
        
		// flip preview width and height
		CGFloat temp = faceRect.size.width;
		faceRect.size.width = faceRect.size.height;
		faceRect.size.height = temp;
		temp = faceRect.origin.x;
		faceRect.origin.x = faceRect.origin.y;
		faceRect.origin.y = temp;
		// scale coordinates so they fit in the preview box, which may be scaled
		CGFloat widthScaleBy = CGRectGetWidth(preview_box) / clap.size.height;
		CGFloat heightScaleBy = CGRectGetHeight(preview_box) / clap.size.width;
		faceRect.size.width *= widthScaleBy;
		faceRect.size.height *= heightScaleBy;
		faceRect.origin.x *= widthScaleBy;
		faceRect.origin.y *= heightScaleBy;
        
		if (isVideoMirrored)
			faceRect = CGRectOffset(faceRect, CGRectGetMinX(preview_box) + CGRectGetWidth(preview_box) - faceRect.size.width - (faceRect.origin.x * 2), CGRectGetMinY(preview_box));
		else
			faceRect = CGRectOffset(faceRect, CGRectGetMinX(preview_box), CGRectGetMinY(preview_box));
		
		CALayer *featureLayer = nil;
		
		// re-use an existing layer if possible
		while ( !featureLayer && (currentSublayer < sublayers_count) ) {
			CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
			if ( [[currentLayer name] isEqualToString:@"FaceLayer"] ) {
				featureLayer = currentLayer;
				[currentLayer setHidden:NO];
			}
		}
		
		// create a new one if necessary
		if ( !featureLayer ) {
			featureLayer = [CALayer new];
			// [featureLayer setContents:(id)[square CGImage]];  == !!! наш прямоугольник
            [featureLayer setContents:(id)[[UIImage imageNamed:@"CameraIcon"] CGImage]];
			[featureLayer setName:@"FaceLayer"];
			[previewLayer addSublayer:featureLayer];
		}
		[featureLayer setFrame:faceRect];
		
		[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0.))];
        
		currentFeature++;
	}
	
    // завершаем отрисовку выделения найденных признаков очертаний лиц
	[CATransaction commit];
}

// find where the video box is positioned within the preview layer based on the video size and gravity
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    NSLog(@"- videoPreviewBoxForGravity");
    
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
	
	CGRect videoBox;
	videoBox.size = size;
	if (size.width < frameSize.width)
		videoBox.origin.x = (frameSize.width - size.width) / 2;
	else
		videoBox.origin.x = (size.width - frameSize.width) / 2;
	
	if ( size.height < frameSize.height )
		videoBox.origin.y = (frameSize.height - size.height) / 2;
	else
		videoBox.origin.y = (size.height - frameSize.height) / 2;
    
	return videoBox;
}

@end
