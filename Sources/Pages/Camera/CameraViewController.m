//
//  CameraViewController.m
//  FaceDetector
//
//  Created by Ildar Sibagatov on 08.10.13.
//  Copyright (c) 2013 Sig Inc. All rights reserved.
//

#import "CameraViewController.h"
#import "CameraVCAdditions.h"
#import "UIImage+Flip.h"

@interface CameraViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, UIGestureRecognizerDelegate>
{
    AVCaptureStillImageOutput *stillImageOutput;
    AVCaptureVideoDataOutput *videoDataOutput;
    dispatch_queue_t videoDataOutputQueue;
    
    BOOL isUsingFrontFacingCamera;
    AVCaptureVideoPreviewLayer *previewLayer;
    
    CGFloat effectiveScale;
    
    CIDetector *faceDetector;
    
    UIImage *currentVideoFrame;
    UIDeviceOrientation currentVideoFrameDeviceOrientation;
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

/**
 *  Метод настройки механизма для связи устройства захвата, буфера и устройства вывода
 */
- (void)setupAVCapture
{
	NSError *error = nil;
	
    // создаем сессию для захвата данных с камеры и передачи в приложение
	AVCaptureSession *session = [AVCaptureSession new];
	[session setSessionPreset:AVCaptureSessionPresetiFrame960x540];
	
    // устанавливаем устройство захвата
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	AVCaptureDeviceInput *device_input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];

    if (error) {
        NSLog(@"Selected device can not be used for capture");
        return;
    }
    
    isUsingFrontFacingCamera = NO;
	
    // связываем устройство захвата с текущей сессией
	if ([session canAddInput:device_input]) {
		[session addInput:device_input];
    }
	
    // создаем объект для вывода статичных изображений
    // (необходимо для возможности получения снимков по нажатию на кнопку)
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
    // (необходимо для анализа потока видео по кадрам для определения признаков человеческого лица)
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
	[previewLayer setBackgroundColor:[[UIColor clearColor] CGColor]];
	[previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
	
    CALayer *root_layer = [self.previewView layer];
	[root_layer setMasksToBounds:YES];
	[previewLayer setFrame:[root_layer bounds]];
	[root_layer addSublayer:previewLayer];
	
    // запускаем текущую сессию
    [session startRunning];
}

/**
 *  Метод настройки механизма, отвечающего за определение очертаний лица на кадре из видео
 */
- (void)setupCIDetector
{
    // создаем объект для определения очертаний лица человека
    // на кадре видео-потока
	faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                      context:nil
                                      options:@{CIDetectorAccuracy:CIDetectorAccuracyLow}];
}

#pragma mark - Методы AVCaptureVideoDataOutputSampleBuffer Delegate

/**
 *  Делегированный метод - пулл кадров из видео потока устройства захвата
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // получили изображение в буфер
	CVPixelBufferRef pixel_buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                sampleBuffer,
                                                                kCMAttachmentMode_ShouldPropagate);
    
    // сохраняем текущую картинку для создания снимка
    CGImageRef src_image = NULL;
    CreateCGImageFromCVPixelBuffer(CMSampleBufferGetImageBuffer(sampleBuffer), &src_image);
    if (src_image) {
        currentVideoFrame = [UIImage imageWithCGImage:src_image];
        CFRelease(src_image);
    }
    
	CIImage *ci_image = [[CIImage alloc] initWithCVPixelBuffer:pixel_buffer
                                                       options:(__bridge NSDictionary *)attachments];
    (attachments)?CFRelease(attachments):nil;
    
    NSNumber *detected_orientation = nil;
    UIDeviceOrientation current_orientation = [[UIDevice currentDevice] orientation];
    currentVideoFrameDeviceOrientation = current_orientation;
    
    switch (current_orientation) {
        case UIDeviceOrientationPortrait:
            detected_orientation = @(kCIDetectorImageOrientation0RowOnTheRight0ColAtTheTop);
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            detected_orientation = @(kCIDetectorImageOrientation0RowOnTheLeft0ColAtTheBottom);
            break;
            
        case UIDeviceOrientationLandscapeLeft: {
            if (isUsingFrontFacingCamera)
                detected_orientation = @(kCIDetectorImageOrientation0RowAtTheBottom0ColOnTheRight);
            else
                detected_orientation = @(kCIDetectorImageOrientation0RowAtTheTop0ColOnTheLeft);
        }
            break;
            
        case UIDeviceOrientationLandscapeRight: {
            if (isUsingFrontFacingCamera)
                detected_orientation = @(kCIDetectorImageOrientation0RowAtTheTop0ColOnTheLeft);
            else
                detected_orientation = @(kCIDetectorImageOrientation0RowAtTheBottom0ColOnTheRight);
        }
            break;
            
        default:
            detected_orientation = @(kCIDetectorImageOrientation0RowOnTheRight0ColAtTheTop);
            return;
	}
    
	NSDictionary *image_options = @{CIDetectorImageOrientation:detected_orientation};
    
    // ищем признаки очертаний лица на текущем кадре
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
                           orientation:current_orientation];
	});
}

#pragma mark - Методы определения очертаний лица и выделения их на кадре

/**
 *  Метод для анализа найденных признаков очертаний лица конкретного кадра видео
 */
- (void)drawFaceBoxesForFeatures:(NSArray *)features
                     forVideoBox:(CGRect)clap
                     orientation:(UIDeviceOrientation)orientation
{
	NSArray *sublayers = [NSArray arrayWithArray:[previewLayer sublayers]];
	NSInteger sublayers_count = [sublayers count];
	NSInteger features_count = [features count];
	
    // начинаем отрисовку найденных признаков очертаний лиц
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// скрываем все признаки, показанные прежде
	for (CALayer *layer in sublayers) {
		if (([[layer name] isEqualToString:FaceLayerName]) || ([[layer name] isEqualToString:LeftEyeLayerName])
            || ([[layer name] isEqualToString:RightEyeLayerName]) || ([[layer name] isEqualToString:MouthLayerName]))
        {
			[layer setHidden:YES];
        }
	}
	
    // прекращаем отрисовку признаков, если они отсутствуют
	if (features_count == 0) {
		[CATransaction commit];
		return;
	}
    
    BOOL is_video_mirrored = [[previewLayer connection] isVideoMirrored];
	CGSize parent_frame_size = [self.previewView frame].size;
	NSString *gravity = [previewLayer videoGravity];
	CGRect preview_box = [self videoPreviewBoxForGravity:gravity
                                               frameSize:parent_frame_size
                                            apertureSize:clap.size];
	
    // отображаем все найденные признаки очертаний лица
    NSInteger current_feature = 0;
    NSInteger current_sublayer = 0;
	for (CIFaceFeature *face_feature in features)
    {
		CGRect face_rect = [self prepareFaceRect:[face_feature bounds] previewBox:preview_box
                                         andClap:clap mirrored:is_video_mirrored];
		
		CALayer *feature_layer = nil;
		
		// если слой уже существует - то используем его
		while ((feature_layer == nil) && (current_sublayer < sublayers_count)) {
			CALayer *current_layer = [sublayers objectAtIndex:current_sublayer++];
			if ([[current_layer name] isEqualToString:FaceLayerName]) {
				feature_layer = current_layer;
				[current_layer setHidden:NO];
			}
		}
		
		// если слой нет слоев для использования - создаем новый
		if (feature_layer == nil) {
			feature_layer = [CALayer new];
            [feature_layer setContents:(id)[[UIImage imageNamed:@"FaceSquare"] CGImage]];
			[feature_layer setName:FaceLayerName];
			[previewLayer addSublayer:feature_layer];
		}
        
        // позиционируем слой по координатам найденных очертаний лица
		[feature_layer setFrame:face_rect];
        switch (orientation) {
			case UIDeviceOrientationPortrait:
                [feature_layer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0.))];
				break;
			case UIDeviceOrientationPortraitUpsideDown:
				[feature_layer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(180.))];
				break;
			case UIDeviceOrientationLandscapeLeft:
				[feature_layer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(90.))];
				break;
			case UIDeviceOrientationLandscapeRight:
				[feature_layer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(-90.))];
				break;
            default:
                break;
		}
        
        // отмечаем признаки глаз и рта, если таковые имеются
        [self drawEyesAndMouth:face_feature previewBox:preview_box andClap:clap
                      mirrored:is_video_mirrored sublayersCount:sublayers_count
               currentSublayer:current_sublayer sublayers:sublayers];
        
		current_feature++;
	}
	
    // завершаем отрисовку выделения найденных признаков очертаний лиц
	[CATransaction commit];
}

/**
 *  Определяем границы, в пределах которых расположен кадр на области слоя с превью
 */
- (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat aperture_ratio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > aperture_ratio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > aperture_ratio) {
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
	
	CGRect video_box;
	video_box.size = size;
	if (size.width < frameSize.width)
		video_box.origin.x = (frameSize.width - size.width) / 2;
	else
		video_box.origin.x = (size.width - frameSize.width) / 2;
	
	if ( size.height < frameSize.height )
		video_box.origin.y = (frameSize.height - size.height) / 2;
	else
		video_box.origin.y = (size.height - frameSize.height) / 2;
    
	return video_box;
}

/**
 *  Метод для подготовки координат и размеров области, содержащей очертания лица
 */
- (CGRect)prepareFaceRect:(CGRect)featureBounds previewBox:(CGRect)previewBox
                  andClap:(CGRect)clap mirrored:(BOOL)mirrored
{
    CGRect face_rect = featureBounds;
    
    // меняем местами высоту и ширину, х и у
    CGFloat temp = face_rect.size.width;
    face_rect.size.width = face_rect.size.height;
    face_rect.size.height = temp;
    temp = face_rect.origin.x;
    face_rect.origin.x = face_rect.origin.y;
    face_rect.origin.y = temp;
    
    // координируем размер кадра
    CGFloat width_scale_by = CGRectGetWidth(previewBox) / clap.size.height;
    CGFloat height_scale_by = CGRectGetHeight(previewBox) / clap.size.width;
    face_rect.size.width *= width_scale_by;
    face_rect.size.height *= height_scale_by;
    face_rect.origin.x *= width_scale_by;
    face_rect.origin.y *= height_scale_by;
    
    // зеркально разворачиваем изображение, если требуется
    if (mirrored) {
        face_rect = CGRectOffset(face_rect,
                                 CGRectGetMinX(previewBox) + CGRectGetWidth(previewBox) -
                                 face_rect.size.width - (face_rect.origin.x * 2), CGRectGetMinY(previewBox));
    }
    else {
        face_rect = CGRectOffset(face_rect, CGRectGetMinX(previewBox), CGRectGetMinY(previewBox));
    }
    return face_rect;
}

/**
 *  Метод для отрисовки признаков глаз и рта на кадре видео-потока
 */
- (void)drawEyesAndMouth:(CIFaceFeature *)face_feature previewBox:(CGRect)previewBox
                 andClap:(CGRect)clap mirrored:(BOOL)mirrored
          sublayersCount:(NSInteger)sublayersCount currentSublayer:(NSInteger)currentSublayer
               sublayers:(NSArray *)sublayers
{
    // отмечаем левый глаз на изображении
    if(face_feature.hasLeftEyePosition) {
        CGPoint left_eye_position = face_feature.leftEyePosition;
        CGRect left_eye_rect = CGRectMake(left_eye_position.x - CGRectGetWidth([face_feature bounds])*0.15,
                                          left_eye_position.y - CGRectGetHeight([face_feature bounds])*0.15,
                                          CGRectGetWidth([face_feature bounds])*0.3,
                                          CGRectGetWidth([face_feature bounds])*0.3);
        left_eye_rect = [self prepareFaceRect:left_eye_rect previewBox:previewBox
                                      andClap:clap mirrored:mirrored];
        
        // если слой уже существует - то используем его
        CALayer *left_eye_layer = nil;
        while ((left_eye_layer == nil) && (currentSublayer < sublayersCount)) {
            CALayer *current_layer = [sublayers objectAtIndex:currentSublayer++];
            if ( [[current_layer name] isEqualToString:LeftEyeLayerName] ) {
                left_eye_layer = current_layer;
                [left_eye_layer setHidden:NO];
                [left_eye_layer setFrame:left_eye_rect];
                left_eye_layer.borderWidth = 0.05*CGRectGetWidth(left_eye_rect);
            }
        }
        
        // если слой не был найден - создаем его заново
        if (left_eye_layer == nil) {
            UIView *left_eye_view = [[UIView alloc] initWithFrame:left_eye_rect];
            [left_eye_view setBackgroundColor:[UIColor clearColor]];
            left_eye_view.layer.borderWidth = 0.05*CGRectGetWidth(left_eye_rect);
            left_eye_view.layer.borderColor = WhiteCGColor;
            left_eye_view.layer.name = LeftEyeLayerName;
            [previewLayer addSublayer:left_eye_view.layer];
        }
    }
    
    // отмечаем правый глаз на изображении
    if(face_feature.hasRightEyePosition) {
        CGPoint right_eye_position = face_feature.rightEyePosition;
        CGRect right_eye_rect = CGRectMake(right_eye_position.x - CGRectGetWidth([face_feature bounds])*0.15,
                                           right_eye_position.y - CGRectGetHeight([face_feature bounds])*0.15,
                                           CGRectGetWidth([face_feature bounds])*0.3,
                                           CGRectGetWidth([face_feature bounds])*0.3);
        right_eye_rect = [self prepareFaceRect:right_eye_rect previewBox:previewBox
                                       andClap:clap mirrored:mirrored];
        
        // если слой уже существует - то используем его
        CALayer *right_eye_layer = nil;
        while ((right_eye_layer == nil) && (currentSublayer < sublayersCount)) {
            CALayer *current_layer = [sublayers objectAtIndex:currentSublayer++];
            if ( [[current_layer name] isEqualToString:RightEyeLayerName] ) {
                right_eye_layer = current_layer;
                [right_eye_layer setHidden:NO];
                [right_eye_layer setFrame:right_eye_rect];
                right_eye_layer.borderWidth = 0.05*CGRectGetWidth(right_eye_rect);
            }
        }
        
        // если слой не был найден - создаем его заново
        if (right_eye_layer == nil) {
            UIView *left_eye_view = [[UIView alloc] initWithFrame:right_eye_rect];
            [left_eye_view setBackgroundColor:[UIColor clearColor]];
            left_eye_view.layer.borderWidth = 0.05*CGRectGetWidth(right_eye_rect);
            left_eye_view.layer.borderColor = WhiteCGColor;
            left_eye_view.layer.name = LeftEyeLayerName;
            [previewLayer addSublayer:left_eye_view.layer];
        }
    }
    
    // отмечаем рот на изображении
    if(face_feature.hasMouthPosition) {
        CGPoint mouth_position = face_feature.mouthPosition;
        CGRect mouth_rect = CGRectMake(mouth_position.x - CGRectGetWidth([face_feature bounds])*0.15,
                                       mouth_position.y - CGRectGetHeight([face_feature bounds])*0.15,
                                       CGRectGetWidth([face_feature bounds])*0.3,
                                       CGRectGetWidth([face_feature bounds])*0.3);
        mouth_rect = [self prepareFaceRect:mouth_rect previewBox:previewBox
                                   andClap:clap mirrored:mirrored];
        
        // если слой уже существует - то используем его
        CALayer *mouth_layer = nil;
        while ((mouth_layer == nil) && (currentSublayer < sublayersCount)) {
            CALayer *current_layer = [sublayers objectAtIndex:currentSublayer++];
            if ( [[current_layer name] isEqualToString:MouthLayerName] ) {
                mouth_layer = current_layer;
                [mouth_layer setHidden:NO];
                [mouth_layer setFrame:mouth_rect];
                mouth_layer.borderWidth = 0.05*CGRectGetWidth(mouth_rect);
            }
        }
        
        // если слой не был найден - создаем его заново
        if (mouth_layer == nil) {
            UIView *mouth_view = [[UIView alloc] initWithFrame:mouth_rect];
            [mouth_view setBackgroundColor:[UIColor clearColor]];
            mouth_view.layer.borderWidth = 0.05*CGRectGetWidth(mouth_rect);
            mouth_view.layer.borderColor = WhiteCGColor;
            mouth_view.layer.name = MouthLayerName;
            [previewLayer addSublayer:mouth_view.layer];
        }
    }
}

#pragma mark - Методы подготовки и сохранения изображений

- (void)prepareAndSavePicture:(UIImage*)currentFrameImage
            previewLayerImage:(UIImage*)previewLayerImage
         forDeviceOrientation:(UIDeviceOrientation)currentDeviceOrientation
{
    // поворачиваем кадр видео потока
    CGFloat frame_rotation_degrees = 0.f;
    CGFloat preview_rotation_degrees = 0.f;
    NSLog(@"current_device_orientation : %ld", (long)currentDeviceOrientation);
	switch (currentDeviceOrientation) {
		case UIDeviceOrientationPortrait:
			frame_rotation_degrees = -90.f;
			break;
            
		case UIDeviceOrientationPortraitUpsideDown:
			frame_rotation_degrees = 90.f;
			break;
            
		case UIDeviceOrientationLandscapeLeft: {
            preview_rotation_degrees = 90.f;
            if (isUsingFrontFacingCamera)
                frame_rotation_degrees = 180.f;
            else
                frame_rotation_degrees = 0.f;
        } break;
            
		case UIDeviceOrientationLandscapeRight: {
            preview_rotation_degrees = -90.f;
            if (isUsingFrontFacingCamera)
                frame_rotation_degrees = 0.f;
            else
                frame_rotation_degrees = 180.f;
        } break;
            
		case UIDeviceOrientationFaceUp:
		case UIDeviceOrientationFaceDown:
		default: break;
	}
    
    if (frame_rotation_degrees != 0.f) {
        currentFrameImage = [currentFrameImage rotateInDegrees:frame_rotation_degrees];
    }
    
    if (isUsingFrontFacingCamera) {
        currentFrameImage = [currentFrameImage theHorizontalFlip];
    }
    
    if (preview_rotation_degrees != 0.f) {
        previewLayerImage = [previewLayerImage rotateInDegrees:preview_rotation_degrees];
    }
    
    NSLog(@"preview size: %@, frame size: %@",
          NSStringFromCGSize(previewLayerImage.size), NSStringFromCGSize(currentFrameImage.size));
    
    // масштабируем слой с признаками до размеров кадра видео потока (сохраняя пропорции)
    previewLayerImage = [previewLayerImage scaleToFitSize:currentFrameImage.size];
    NSLog(@"new preview size: %@", NSStringFromCGSize(previewLayerImage.size));
    
    // объединяем два изображения в одно (признаки лица и кадр видео потока)
    UIGraphicsBeginImageContextWithOptions(currentFrameImage.size, NO, 0.0f);
    [currentFrameImage drawInRect:CGRectMake(0, 0, currentFrameImage.size.width, currentFrameImage.size.height)];
    [previewLayerImage drawInRect:CGRectMake(0, 0, previewLayerImage.size.width, previewLayerImage.size.height)];
    UIImage *result_image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // полученное финальное изображение сохраняем в модели локальной БД
    PhotoModel *model = [PhotoModel createEntity:result_image
                                     createdDate:[NSDate date]];
    NSLog(@"model = %@", model);
    [[NSManagedObjectContext MR_contextForCurrentThread] MR_saveToPersistentStoreAndWait];
}

#pragma mark - Обработка нажатий по кнопкам

/**
 *  Делаем снимок с камеры и сохраняем его в локальном хранилище
 */
- (IBAction)takePhotoClicked:(UIButton*)sender
{
    NSLog(@"- Click!");
    
    // получаем текущие данные (т.к. значение в этих переменных динамично)
    UIImage *current_frame_image = [UIImage imageWithCGImage:currentVideoFrame.CGImage];
    UIDeviceOrientation current_device_orientation = currentVideoFrameDeviceOrientation;
    
    // преобразуем слой (с отмеченными признаками лица) в изображение
    UIGraphicsBeginImageContextWithOptions(previewLayer.bounds.size, previewLayer.opaque, 0.0f);
	[previewLayer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage *preview_layer_image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
    
    __weak CameraViewController *weak_self = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, (unsigned long)NULL), ^(void) {
        [weak_self prepareAndSavePicture:current_frame_image
                       previewLayerImage:preview_layer_image
                    forDeviceOrientation:current_device_orientation];
    });
}

/**
 *  Меняем источник ввода с фронтальной камеры на тыльную (и наоборот)
 */
- (IBAction)switchCamerasClicked:(UIButton*)sender
{
    NSLog(@"- Switch!");
    
    AVCaptureDevicePosition desired_position = (isUsingFrontFacingCamera)?AVCaptureDevicePositionBack
                                                                         :AVCaptureDevicePositionFront;
	
	for (AVCaptureDevice *dev in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
		if ([dev position] != desired_position)
            continue;
        
        [[previewLayer session] beginConfiguration];
        AVCaptureDeviceInput *new_input = [AVCaptureDeviceInput deviceInputWithDevice:dev
                                                                                error:nil];
        for (AVCaptureInput *old_input in [[previewLayer session] inputs]) {
            [[previewLayer session] removeInput:old_input];
        }
        
        // при смене камеры меняет высоту слоя превью,
        // чтобы картинка видео-потока отображалась над таббаром
        CALayer *root_layer = [self.previewView layer];
        CGRect rect = root_layer.frame;
        
        // меняем размеры фрейма сессии устройства захвата видео потока
        switch ([dev position]) {
            case AVCaptureDevicePositionBack:
                rect.size.height = 568.f;
                [[previewLayer session] setSessionPreset:AVCaptureSessionPresetiFrame960x540];
                break;
                
            case AVCaptureDevicePositionFront:
                rect.size.height = 427.f;
                [[previewLayer session] setSessionPreset:AVCaptureSessionPreset640x480];
                break;
                
            default:
                break;
        }
        
        root_layer.frame = rect;
        [previewLayer setFrame:rect];
        
        // связываем устройство захвата с текущей сессией
        if ([[previewLayer session] canAddInput:new_input]) {
            [[previewLayer session] addInput:new_input];
        }
        
        [[previewLayer session] commitConfiguration];
        break;
	}
	isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
}

@end
