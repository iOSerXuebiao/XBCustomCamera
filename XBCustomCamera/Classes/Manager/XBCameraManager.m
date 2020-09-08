//
//  XBCameraManager.m
//  XBCustomCamera
//
//  Created by Xue on 2020/9/3.
//

#import "XBCameraManager.h"
#import "XBVideoCompressTool.h"
#import "UIImage+XBExtention.h"
#import "XBFileManager.h"

static const CGFloat KTimerInterval = 0.02;  //进度条timer

API_AVAILABLE(ios(10.0))
@interface XBCameraManager () <AVCaptureFileOutputRecordingDelegate,AVCapturePhotoCaptureDelegate>

/// 媒体（音、视频）捕获会话
@property (nonatomic, strong) AVCaptureSession *captureSession;
/// 视频输入
@property (nonatomic, strong) AVCaptureDeviceInput *mediaDeviceInput;
/// 音频输入
@property (nonatomic, strong) AVCaptureDeviceInput *audioDeviceInput;
/// 视频文件输出
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;

/// 照片输出流   API_AVAILABLE ( ios(10.0))
@property (nonatomic ,strong) AVCapturePhotoOutput *imageOutput;
//  照片输出流 API_AVAILABLE（ios(4.0, 10.0)）
@property (strong,nonatomic) AVCaptureStillImageOutput *stillImageOutput;

/// 输入输出对象连接
@property (nonatomic, strong) AVCaptureConnection *captureConnection;
/// 定时器
@property (nonatomic, strong) NSTimer *timer;
/// 录制时间
@property (nonatomic, assign) CGFloat recordTime;
/// 视频存储文件夹路径
@property (nonatomic, copy) NSString *localVieoPath;
/// 是否设置了镜像
@property (nonatomic, assign) BOOL isVideoMirrored;

@end

@implementation XBCameraManager

- (instancetype)init {
    self = [super init];
    if (self) {
        [self configAVCapture];
        self.localVideoFolderName = @"Video";
    }
    return self;
}

- (void)configAVCapture {
    self.maxRecordTime = 15;
    self.captureSession = [[AVCaptureSession alloc] init];
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    if (@available(iOS 10.0, *)) {
        self.imageOutput = [[AVCapturePhotoOutput alloc] init];
        
        AVCapturePhotoSettings *imageOutputSettings;
        if (@available(iOS 11.0, *)) {
            imageOutputSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey:AVVideoCodecTypeJPEG}];
        } else {
            // Fallback on earlier versions
            imageOutputSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey:AVVideoCodecJPEG}];
        }
        [self.imageOutput setPhotoSettingsForSceneMonitoring:imageOutputSettings];
        
    } else {
        // Fallback on earlier versions
        self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        [self.stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
    }
    
    //后台播放音频时需要注意加以下代码，否则会获取音频设备失败
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeVideoRecording error:nil];
    [[AVAudioSession sharedInstance] setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    //[self prepareForRecord];
}

- (void)dealloc {
    [self stopTimer];
    self.recordTime = 0;
    [self stopCurrentVideoRecording];
    [self.captureSession stopRunning];
    [self.preViewLayer removeFromSuperlayer];
}

#pragma mark 准备录制

- (void)prepareForRecord {
    [self.captureSession beginConfiguration];
    
    /// 视频采集质量
    [self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720] ? [self.captureSession setSessionPreset:AVCaptureSessionPreset1280x720] : nil;
    
    /// 添加input
    [self.captureSession canAddInput:self.mediaDeviceInput] ? [self.captureSession addInput:self.mediaDeviceInput] : nil;
    [self.captureSession canAddInput:self.audioDeviceInput] ? [self.captureSession addInput:self.audioDeviceInput] : nil;
    
    /// 添加output
    [self.captureSession canAddOutput:self.movieFileOutput] ? [self.captureSession addOutput:self.movieFileOutput] : nil;
    
    if (@available(iOS 10.0, *)) {
        [self.captureSession canAddOutput:self.imageOutput] ? [self.captureSession addOutput:self.imageOutput] : nil;
        
    } else {
        [self.captureSession canAddOutput:self.stillImageOutput] ? [self.captureSession addOutput:self.stillImageOutput] : nil;
    }
    
    [self.captureSession commitConfiguration];
    
    /// 防抖功能
    if ([self.captureConnection isVideoStabilizationSupported] && self.captureConnection.activeVideoStabilizationMode == AVCaptureVideoStabilizationModeOff){
        self.captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
    
    [self.captureSession startRunning];
}

#pragma mark - 获取权限

/// 检查相机权限
/// @param isAuthorized 回调 isAuthorized：是否授权，type：硬件类型  ，tipText：提示文字
+ (void)checkCameraAuth:(void(^)(BOOL isAuthorized, kHardwareType type, NSString *tipText))isAuthorized {
    __weak typeof(self) instance = self;
    //获取权限
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusNotDetermined){
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                                 completionHandler:^(BOOL granted) {
            if (granted) {
                [instance checkCameraAuth:isAuthorized];
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    isAuthorized(NO, kHardwareTypeCamera ,@"没有获得相机权限");
                });
            }
        }];
    } else if (authStatus == AVAuthorizationStatusAuthorized){
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                isAuthorized(granted, kHardwareTypeMicrophone, @"没有获得麦克风权限");
            });
        }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            isAuthorized(NO, kHardwareTypeCamera ,@"没有获得相机权限");
        });
    }
}

#pragma mark - 摄像头视图层
- (AVCaptureVideoPreviewLayer *)preViewLayer {
    if (!_preViewLayer) {
        _preViewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
        _preViewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _preViewLayer;
}

#pragma mark 视频输入

- (AVCaptureDeviceInput *)mediaDeviceInput {
    if (!_mediaDeviceInput) {
        NSArray *cameras;
        if (@available(iOS 10.0, *)) {
            AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
            cameras = [captureDeviceDiscoverySession devices];
            
        } else {
            // Fallback on earlier versions
            cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        }
        
        __block AVCaptureDevice *backCamera  = nil;
        [cameras enumerateObjectsUsingBlock:^(AVCaptureDevice *camera, NSUInteger idx, BOOL * _Nonnull stop) {
            if (camera.position == AVCaptureDevicePositionBack) {
                backCamera = camera;
                *stop = YES;
            }
        }];
        [self setExposureModeWithDevice:backCamera];
        _mediaDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:nil];
    }
    return _mediaDeviceInput;
}

#pragma mark 音频输入
- (AVCaptureDeviceInput *)audioDeviceInput {
    if (!_audioDeviceInput) {
        NSError *error;
        _audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:&error];
    }
    return _audioDeviceInput;
}

#pragma mark - 输入输出对象连接

- (AVCaptureConnection *)captureConnection {
    if (@available(iOS 10.0, *)) {
        if (_captureConnection == nil) {
            _captureConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        }
        
    } else {
        if (_captureConnection == nil) {
            _captureConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        }
    }
    return _captureConnection;
}

#pragma mark 配置曝光模式 设置持续曝光模式

- (void)setExposureModeWithDevice:(AVCaptureDevice *)device {
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    NSError *error = nil;
    [device lockForConfiguration:&error];
    if ([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]){
        [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
    }
    [device unlockForConfiguration];
}

#pragma mark 计时器相关
- (NSTimer *)timer {
    if (!_timer){
        _timer = [NSTimer scheduledTimerWithTimeInterval:KTimerInterval target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
    }
    return _timer;
}

- (void)timerAction:(NSTimer *)timer {
    self.recordTime += KTimerInterval;
    if ([self.delegate respondsToSelector:@selector(recordTimeCurrentTime:totalTime:)]) {
        [self.delegate recordTimeCurrentTime:self.recordTime totalTime:self.maxRecordTime];
    }
    if(_recordTime >= self.maxRecordTime){
        [self stopCurrentVideoRecording];
    }
}

- (void)startTimer {
    [self stopTimer];
    
    self.recordTime = 0;
    [self.timer fire];
}

- (void)stopTimer {
    if (_timer && [_timer isValid]) {
        [_timer invalidate];
        _timer = nil;
    }
}

#pragma mark 切换摄像头

- (void)switchCamera {
    self.isVideoMirrored = NO;

    [_captureSession beginConfiguration];
    [_captureSession removeInput:_mediaDeviceInput];
    
    AVCaptureDevice *swithToDevice = [self switchCameraDevice];
    [swithToDevice lockForConfiguration:nil];
    
    ///配置曝光模式 设置持续曝光模式
    [self setExposureModeWithDevice:swithToDevice];
    
    self.mediaDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:swithToDevice error:nil];
    
    if ([_captureSession canAddInput:_mediaDeviceInput]) {
        [_captureSession addInput:_mediaDeviceInput];
    }
    [_captureSession commitConfiguration];
    
    //判断是否是前置摄像头状态
    if (swithToDevice.position == AVCaptureDevicePositionFront) {
        for (AVCaptureVideoDataOutput* output in self.captureSession.outputs) {
            for (AVCaptureConnection* connection in output.connections) {
                if (connection.supportsVideoMirroring) {
                    //镜像设置
                    connection.videoMirrored = YES;
                    self.isVideoMirrored = YES;
                }
            }
        }
    }
}

#pragma mark 获取切换时的摄像头

- (AVCaptureDevice *)switchCameraDevice {
    AVCaptureDevice *currentDevice = [self.mediaDeviceInput device];
    AVCaptureDevicePosition currentPosition = [currentDevice position];
    
    BOOL isUnspecifiedOrFront = (currentPosition == AVCaptureDevicePositionUnspecified || currentPosition ==AVCaptureDevicePositionFront );
    AVCaptureDevicePosition swithToPosition = isUnspecifiedOrFront ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
    
    NSArray *cameras;
    if (@available(iOS 10.0, *)) {
        AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:swithToPosition];
        cameras = [captureDeviceDiscoverySession devices];
        
    } else {
        cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    }
    
    __block AVCaptureDevice *cameraDevice = nil;
    [cameras enumerateObjectsUsingBlock:^(AVCaptureDevice *camera, NSUInteger idx, BOOL * _Nonnull stop) {
        if (camera.position == swithToPosition) {
            cameraDevice = camera;
            *stop = YES;
        };
    }];
    return cameraDevice;
}

/// 拍照
- (void)takePhoto {
    if (@available(iOS 10.0, *)) {
        AVCapturePhotoSettings *imageOutputSettings;
        if (@available(iOS 11.0, *)) {
            imageOutputSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey:AVVideoCodecTypeJPEG}];
        } else {
            // Fallback on earlier versions
            imageOutputSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{AVVideoCodecKey:AVVideoCodecJPEG}];
        }
        [self.imageOutput capturePhotoWithSettings:imageOutputSettings delegate:self];
        
    } else {
        // Fallback on earlier versions
        //根据设备输出获得连接
        //AVCaptureConnection *videoConnection=[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        _captureConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:self.captureConnection completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
            if (imageDataSampleBuffer) {
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                [self _takePhotoCompleteWithImageData:imageData error:error];
            }
        }];
    }
}

#pragma mark 开始录制

- (void)startRecordToFile:(NSURL *)outPutFile {
    if (!self.captureConnection) {
        return;
    }
    if ([self.movieFileOutput isRecording]) {
        return;
    }
    if ([self.captureConnection isVideoOrientationSupported]) {
        self.captureConnection.videoOrientation = [self.preViewLayer connection].videoOrientation;
    }
    [_movieFileOutput startRecordingToOutputFileURL:outPutFile recordingDelegate:self];
}

#pragma mark  停止录制

- (void)stopCurrentVideoRecording {
    if (self.movieFileOutput.isRecording) {
        [self stopTimer];
        [_movieFileOutput stopRecording];
    }
}

#pragma mark 设置对焦

- (void)setFoucusWithPoint:(CGPoint)point {
    CGPoint cameraPoint= [self.preViewLayer captureDevicePointOfInterestForPoint:point];
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposureMode:AVCaptureExposureModeContinuousAutoExposure atPoint:cameraPoint];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode
         exposureMode:(AVCaptureExposureMode)exposureMode
              atPoint:(CGPoint)point {
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        //聚焦
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:focusMode];
        }
        //聚焦位置
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        //曝光模式
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:exposureMode];
        }
        //曝光点位置
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

#pragma mark - 改变设备属性方法

- (void)changeDeviceProperty:(void (^)(id obj))propertyChange {
    AVCaptureDevice *captureDevice = [self.mediaDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        
    }
}

#pragma mark - AVCaptureFileOutputRecordignDelegate

/// 录制开始
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    [self startTimer];
}

/// 录制结束
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    [self stopTimer];
    [self.captureSession stopRunning];
    
    ///通过AVErrorRecordingSuccessfullyFinishedKey这个key检查用户信息在错误信息中,因为该文件可能已成功保存,即使你有一个错误.这种错误可能表名你的一个录制参数到了最大值,就是不能再继续录制了
    BOOL recordedSuccessfully = YES;
    if ([error code] != noErr) {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value) {
            recordedSuccessfully = [value boolValue];
        }
    }
    
    ///视频录制失败了
    if (recordedSuccessfully == NO) {
        NSLog(@"录制视频失败了");
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoRecordFailed)]) {
            [self.delegate videoRecordFailed];
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(captureOutput:didFinishRecordingToOutputFileAtURL:isCompressed:fromConnections:error:)]) {
            [self.delegate captureOutput:captureOutput didFinishRecordingToOutputFileAtURL:nil isCompressed:NO fromConnections:connections error:error];
        }
        return;
    }
    
    ///录制中退到后台的情况
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive && error && outputFileURL.absoluteString.length >0) {

        if (self.delegate && [self.delegate respondsToSelector:@selector(captureOutput:didFinishRecordingToOutputFileAtURL:isCompressed:fromConnections:error:)]) {
            [self.delegate captureOutput:captureOutput didFinishRecordingToOutputFileAtURL:nil isCompressed:NO fromConnections:connections error:error];
        }
        return;
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(captureOutput:didFinishRecordingToOutputFileAtURL:isCompressed:fromConnections:error:)]) {
        [self.delegate captureOutput:captureOutput didFinishRecordingToOutputFileAtURL:outputFileURL isCompressed:NO fromConnections:connections error:error];
    }
        
    ///压缩视频
    if (self.needCompressVideo) {
        NSString *compressMp4FilePath = [NSString stringWithFormat:@"%@/final-%@",self.localVieoPath,[[outputFileURL.absoluteString componentsSeparatedByString:@"/"] lastObject]];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoCompressStart)]) {
            [self.delegate videoCompressStart];
        }
        
        NSLog(@"isVideoMirrored == %d",self.isVideoMirrored);
        [XBVideoCompressTool compressVideoWithVideoUrl:outputFileURL.path
                                     withVideoBiteRate:0
                                    withVideoFrameRate:0
                                        withVideoWidth:0
                                       withVideoHeight:0
                                  outputLocalVideoPath:compressMp4FilePath
                                        outputVideoGop:0
                                         videoMirrored:self.isVideoMirrored
                                            completion:^(BOOL success) {
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoCompressResult:)]) {
                [self.delegate videoCompressResult:success];
            }

            if (success) {
                unsigned long long fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSURL fileURLWithPath:compressMp4FilePath].path error:nil].fileSize;
                float fileSizeMB = fileSize / (1024.0*1024.0);
                NSLog(@"compressedfileSizeMB = %@",@(fileSizeMB));
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(captureOutput:didFinishRecordingToOutputFileAtURL:isCompressed:fromConnections:error:)]) {
                    [self.delegate captureOutput:captureOutput didFinishRecordingToOutputFileAtURL:[NSURL fileURLWithPath:compressMp4FilePath] isCompressed:YES fromConnections:connections error:error];
                }
            } else {
                ///如果压缩失败，把原视频回调出去
                if (self.delegate && [self.delegate respondsToSelector:@selector(captureOutput:didFinishRecordingToOutputFileAtURL:isCompressed:fromConnections:error:)]) {
                    [self.delegate captureOutput:captureOutput didFinishRecordingToOutputFileAtURL:outputFileURL isCompressed:YES fromConnections:connections error:error];
                }
            }
        }];
    }
}

#pragma mark AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(nullable CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(nullable CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(nullable AVCaptureBracketedStillImageSettings *)bracketSettings error:(nullable NSError *)error  API_AVAILABLE(ios(10.0)){
    
    NSData *data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
    [self _takePhotoCompleteWithImageData:data error:error];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error  API_AVAILABLE(ios(11.0)){
    NSData *imageData = [photo fileDataRepresentation];
    [self _takePhotoCompleteWithImageData:imageData error:error];
}

#pragma mark - 压缩视频

- (void)compressVideo:(NSURL *)inputFileURL
             complete:(void(^)(BOOL success, NSURL* outputUrl))complete {
    NSURL *outPutUrl = [NSURL fileURLWithPath:[self cacheFilePath:NO]];
    [self convertVideoQuailtyWithInputURL:inputFileURL outputURL:outPutUrl completeHandler:^(AVAssetExportSession *exportSession) {
        complete(exportSession.status == AVAssetExportSessionStatusCompleted, outPutUrl);
    }];
}

- (void)convertVideoQuailtyWithInputURL:(NSURL*)inputURL
                              outputURL:(NSURL*)outputURL
                        completeHandler:(void (^)(AVAssetExportSession*))handler {
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse= YES;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void){
        handler(exportSession);
    }];
}

#pragma mark 获取文件大小

+ (CGFloat)getfileSize:(NSString *)filePath {
    NSFileManager *fm = [NSFileManager defaultManager];
    filePath = [filePath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    CGFloat fileSize = 0;
    if ([fm fileExistsAtPath:filePath]) {
        fileSize = [[fm attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return fileSize/1024/1024;
}

#pragma mark 视频缓存目录

- (NSString*)cacheFilePath:(BOOL)input {
    //NSString *cacheDirectory = [self getCacheDirWithCreate:YES];
    NSString *cacheDirectory = self.localVieoPath;
    
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    
    NSDate *NowDate = [NSDate dateWithTimeIntervalSince1970:now];
    NSString *timeStr = [formatter stringFromDate:NowDate];
    NSString *put = input ? @"input" : @"output";
    NSString *path = input ? @"mov" : @"mp4";
    NSString *fileName = [NSString stringWithFormat:@"video_%@_%@.%@",timeStr,put,path];
    return [cacheDirectory stringByAppendingFormat:@"/%@", fileName];
}

+ (NSString *)getCacheDirWithCreate:(BOOL)isCreate {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    NSString *dir = [paths objectAtIndex:0];
    dir = [dir stringByAppendingPathComponent:@"Caches"];
    dir = [dir stringByAppendingPathComponent:@"cache"];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = YES;
    if (![fm fileExistsAtPath:dir isDirectory:&isDir]) {
        // 不存在
        if (isCreate) {
            [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
            return dir;
        } else {
            return @"";
        }
    } else {
        // 存在
        return dir;
    }
}

#pragma mark - Private

///拍照完成
- (void)_takePhotoCompleteWithImageData:(NSData *)imageData error:(NSError *)error {
    if (imageData == nil) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        UIImage *image = [UIImage imageWithData:imageData];
        AVCaptureDevice *device = [self switchCameraDevice];
        if (device && device.position == AVCaptureDevicePositionBack) {
            image = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:UIImageOrientationLeftMirrored];
        }
        UIImage *fixImage = [UIImage fixOrientation:image];
        fixImage =  [UIImage compressedImagePrecise:fixImage imageSizeMB:1.0];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.delegate && [self.delegate respondsToSelector:@selector(takePhotoCompletedWithImage:error:)]) {
                [self.delegate takePhotoCompletedWithImage:fixImage error:error];
            }
        });
    });
}

- (BOOL)isRecording {
    return self.movieFileOutput.isRecording;
}

#pragma mark - Setter

- (void)setLocalVideoFolderName:(NSString *)localVideoFolderName {
    //说明已经存在
    if ([_localVideoFolderName isEqualToString:localVideoFolderName]) return;
    _localVideoFolderName = localVideoFolderName;
    //如果文件夹路径不存在需要创建
    NSString *videoPath = [NSString stringWithFormat:@"%@%@",[XBFileManager pathForTemporaryDirectory],_localVideoFolderName];
    if (![XBFileManager existsItemAtPath:videoPath]) {
        if ([XBFileManager createDirectoriesForPath:videoPath]) {
            self.localVieoPath = videoPath;
        }
    } else {
        self.localVieoPath = videoPath;
    }
}

@end
