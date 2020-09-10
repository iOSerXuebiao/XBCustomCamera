//
//  XBCameraViewController.m
//  XBCustomCamera
//
//  Created by Xue on 2020/9/3.
//

#import "XBCameraViewController.h"
#import "XBCameraManager.h"
#import "UIImage+XBExtention.h"
#import "Masonry.h"

@interface XBCameraViewController () <XBVideoRecordManagerDelegate>

///管理类
@property (nonatomic, strong) XBCameraManager *recorderManager;
///数据集合
@property (nonatomic, strong) NSMutableArray *dataArray;

///已经录制的视频数量
@property (nonatomic, assign) NSInteger videoCount;
///达到录制视频数量，无法录制视频
@property (nonatomic, assign) BOOL unAbleRecordVideo;
 
@property (nonatomic, strong) NSURL *recordVideoUrl;
@property (nonatomic, strong) NSURL *recordVideoOutPutUrl;
@property (nonatomic, assign) BOOL videoCompressComplete;
///图片数据
@property (nonatomic, strong) NSMutableArray <UIImage *>*imageDataArray;

@end

@implementation XBCameraViewController

/// 自定义UI使用此初始化方法
/// @param customView 遵循KSCameraDefaultContentViewProtocol的视图
- (instancetype)initWithCustomView:(UIView <XBCameraDefaultContentViewProtocol>*)customView {
    self = [super init];
    if (self) {
        _contentView = customView;
    }
    return self;
}

- (void)dealloc {
    NSLog(@"orz   dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

///固定为竖屏
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

// 默认进入界面显示方向:默认垂直竖屏
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configSubViews];
    [self configLayoutSubViews];
    [self configBindSubViews];
    [self configNotifications];
    [self.recorderManager prepareForRecord];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (currentOrientation != UIDeviceOrientationPortrait) {
        [self _rotateInterfaceOrientation:UIInterfaceOrientationPortrait];
        [self.contentView setNeedsLayout];
        [self.contentView layoutIfNeeded];
        self.recorderManager.preViewLayer.frame = self.contentView.preViewLayerBackView.bounds;
    }
}

- (void)configSubViews {
    self.videoCount = 0;
    [self.view addSubview:self.contentView];
    [self.contentView.preViewLayerBackView.layer addSublayer:self.recorderManager.preViewLayer];
}

- (void)configLayoutSubViews {
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
}

- (void)configBindSubViews {
    self.recorderManager.delegate = self;
    self.contentView.delegate = self;
}

- (void)configNotifications {
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidChangeStatusBarOrientationNotification:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.recorderManager.preViewLayer.frame = self.contentView.preViewLayerBackView.bounds;
    
    NSLog(@"frame = %@",NSStringFromCGRect(self.contentView.preViewLayerBackView.bounds));
}

#pragma mark - Notifications

- (void)appWillEnterForegroundNotification:(NSNotification *)notification {
    [self.contentView setNeedsLayout];
    [self.contentView layoutIfNeeded];
    self.recorderManager.preViewLayer.frame = self.contentView.preViewLayerBackView.bounds;
}

- (void)appWillResignActiveNotification:(NSNotification *)notification {
    NSLog(@"%s",__FUNCTION__);
//    if (self.recorderManager.isRecording) {
//        [self _stopRecord];
//    }
}

- (void)appDidChangeStatusBarOrientationNotification:(NSNotification *)notification {
    [self.contentView setNeedsLayout];
    [self.contentView layoutIfNeeded];
    self.recorderManager.preViewLayer.frame = self.contentView.preViewLayerBackView.bounds;
}

#pragma mark - KSCameraFunctionProtocol 相机功能代理方法

///拍照功能实现
- (void)takePhotoFunction {
    if (self.dataArray.count >= self.maxCount) {
        !self.exceedMaxCountBlock ?: self.exceedMaxCountBlock();
        return;
    }
    
    __weak typeof(self) _weakSelf = self;
    [XBCameraManager checkCameraAuth:^(BOOL isAuthorized, kHardwareType type, NSString * _Nonnull tipText) {
        if (!isAuthorized && type == kHardwareTypeCamera) {
            [_weakSelf _showOneActionAlertWithTitle:@"提示" message:tipText ?: @"没有获取到相机权限" actionTitle:@"知道了" actionHandler:^{
            }];
        } else {
            _weakSelf.contentView.recordBtn.userInteractionEnabled = NO;
            [_weakSelf.recorderManager takePhoto];
        }
    }];
}

///录制视频实现
- (void)recordVideoFunction {
    if (self.dataArray.count >= self.maxCount) {
        !self.exceedMaxCountBlock ?: self.exceedMaxCountBlock();
        return;
    }
    
    __weak typeof(self) _weakSelf = self;
    [XBCameraManager checkCameraAuth:^(BOOL isAuthorized, kHardwareType type, NSString * _Nonnull tipText) {
        if (isAuthorized) {
            
            //录视频
            if (_weakSelf.recorderManager.isRecording) {
                [_weakSelf _stopRecord];

            } else {
                ///录视频
                NSURL *url = [NSURL fileURLWithPath:[_weakSelf.recorderManager cacheFilePath:NO]];
                [_weakSelf.recorderManager startRecordToFile:url];

                ///修改录制按钮样式
                [_weakSelf.contentView dealWithSubViewsStatus:YES];
            }

        } else {
            [_weakSelf _showOneActionAlertWithTitle:@"提示" message:tipText ?: @"没有获取到权限" actionTitle:@"知道了" actionHandler:^{
            }];
        }
    }];
}

/// 选中图片实现
- (void)choosePhotoFunction {
    if (self.recorderManager.isRecording) {
        return;
    }
    ///修改 照片 视频按钮样式
    [self.contentView dealWithChoosePhotoButton];
    ///修改录制按钮样式
    [self.contentView dealWithRecordView];
}

/// 选中视频实现
- (void)chooseVideoFunction {
    if (self.unAbleRecordVideo) {
        !self.exceedVideoCountBlock ?: self.exceedVideoCountBlock();
        return;
    }
    ///修改选中视频后按钮样式
    [self.contentView dealWithChooseVideoButton];
}

/// 翻转摄像头实现
- (void)switchCameraFunction {
    __weak typeof(self) _weakSelf = self;
    [XBCameraManager checkCameraAuth:^(BOOL isAuthorized, kHardwareType type, NSString * _Nonnull tipText) {
        if (!isAuthorized && type == kHardwareTypeCamera) {
            
            [_weakSelf _showOneActionAlertWithTitle:@"提示" message:tipText ?: @"没有获取到权限" actionTitle:@"知道了" actionHandler:^{
            }];

        } else {
            [_weakSelf.recorderManager switchCamera];
        }
    }];
}

/// 关闭页面实现
- (void)closeFunction {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"确定要结束拍摄吗" message:@"确定要结束拍摄么？已拍摄的作业将不会被保存哦~" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"结束拍摄" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self _removeVideoFiles];
        !self.cancelBlock ?: self.cancelBlock();
        [self dismissViewControllerAnimated:YES completion:NULL];
    }];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"继续拍摄" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:cancelAction];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:NULL];
}

/// 确认事件实现
- (void)sureFunction {
    !self.completionBlock ?: self.completionBlock(self.dataArray.copy);
    [self dismissViewControllerAnimated:YES completion:NULL];
}

/// 保存的资源事件
- (void)saveDataImageButtonEventFunction {
    if (self.recorderManager.isRecording) {
        ///视频录制中
        return;
    }
    
}

/// 设置焦点
- (void)setFoucusFunctionWithPoint:(CGPoint)point {
    [self.recorderManager setFoucusWithPoint:point];
}

#pragma mark - KSVideoRecordManagerDelegate  拍照和视频录制代理方法

///视频录制回调
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL * _Nullable)outputFileURL isCompressed:(BOOL)isCompressed fromConnections:(NSArray *)connections error:(NSError *)error {
    ///视频结束处理View层
    [self.contentView dealWithDidFinishRecordingWithMaxRecordTime:self.maxRecordTime];
    [self.recorderManager prepareForRecord];

    if (!outputFileURL) {
        NSLog(@"************** 录制视频URL为空 ***************");
        return;
    }
    
    if (isCompressed) {
        
        if (self.needCompressVideo) {
            ///保存到数据源里
            [self _videoDidFinishRecordingEventWithoutputFileURL:outputFileURL];
        }
        
    } else {
        
        if (!self.needCompressVideo) {
            ///不需要压缩的保持原始资源路径
            [self _videoDidFinishRecordingEventWithoutputFileURL:outputFileURL];
        }

        self.recordVideoUrl = outputFileURL;
        
        if (self.videoNeedSaveToAlbum) {
            ///保存到相册
            [self _saveVideoAlbum];
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            ///16 / 9 比例
            UIImage *thumbImage = [UIImage firstFrameWithVideoURL:outputFileURL size:CGSizeMake(180, 320)];
            if (thumbImage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.imageDataArray addObject:thumbImage];
                    [self.contentView dealWithSaveDataViewWithCount:self.imageDataArray.count maxCount:self.maxCount image:thumbImage];
                });
            }
        });
    }
}

///视频录制时间回调
- (void)recordTimeCurrentTime:(CGFloat)currentTime totalTime:(CGFloat)totalTime {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.contentView dealWithRecordTimeCurrentTime:currentTime totalTime:totalTime];
    });
}

///视频录制失败了
- (void)videoRecordFailed {
    dispatch_async(dispatch_get_main_queue(), ^{
        !self.videoRecordFailedBlock ?: self.videoRecordFailedBlock();
    });
}

/// 视频开始压缩
- (void)videoCompressStart {
    dispatch_async(dispatch_get_main_queue(), ^{
        !self.videoCompressStartBlock ?: self.videoCompressStartBlock();
    });
}

/// 视频压缩结果
/// @param isSuccess 是否成功
- (void)videoCompressResult:(BOOL)isSuccess {
    dispatch_async(dispatch_get_main_queue(), ^{
        !self.videoCompressResultBlock ?: self.videoCompressResultBlock(isSuccess);
    });
}

///拍照完成回调
- (void)takePhotoCompletedWithImage:(UIImage *)image error:(NSError *)error {
    if (!image) {
        NSLog(@"************** 拍照image为nil ***************");
        return;
    }
    ///保存到数据源里
    [self.dataArray addObject:image];

    if (self.photoNeedSaveToAlbum) {
        ///保存到系统相册
        [self _savePhotosAlbum:image];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *thumbImage = [UIImage imageWithImage:image scaledToSize:CGSizeMake(180, 320)];
        if (thumbImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.contentView.recordBtn.userInteractionEnabled = YES;
                [self.imageDataArray addObject:thumbImage];
                [self.contentView dealWithSaveDataViewWithCount:self.dataArray.count maxCount:self.maxCount image:thumbImage];
            });
        }
    });
}

#pragma mark - Private
/// 停止录制
- (void)_stopRecord {
    [self.recorderManager stopCurrentVideoRecording];
}

- (void)_videoDidFinishRecordingEventWithoutputFileURL:(NSURL *)outputFileURL {
    [self.dataArray addObject:outputFileURL];
    self.videoCount += 1;
    [self _checkVideoCount];
}

///检查录制视频的数量是否超过限制
- (void)_checkVideoCount {
    if (self.videoCount >= self.maxVideoCount) {
        ///修改 照片 视频按钮样式
        [self.contentView dealWithChoosePhotoButton];
        ///修改录制按钮样式
        [self.contentView dealWithRecordView];

        self.unAbleRecordVideo = YES;
        [self.contentView.chooseVideoButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    } else {
        self.unAbleRecordVideo = NO;
        [self.contentView.chooseVideoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}

/// 保存视频到相簿
- (void)_saveVideoAlbum {
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([self.recordVideoUrl path])) {
        UISaveVideoAtPathToSavedPhotosAlbum([self.recordVideoUrl path], self,
                                            @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSLog(@"保存视频完成");
}

/// 保存照片到相册
- (void)_savePhotosAlbum:(UIImage *)image {
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *msg = nil;
    if (error != NULL) {
        msg = @"保存图片失败" ;
    } else {
        msg = @"保存图片成功" ;
    }
    NSLog(@"%@", msg);
}

/// 压缩视频
- (void)compressVideo {
    __weak typeof(self) instance = self;
    [self.recorderManager compressVideo:self.recordVideoUrl complete:^(BOOL success, NSURL *outputUrl) {
        if (success && outputUrl) {
            instance.recordVideoOutPutUrl = outputUrl;
            ///保存视频到相册
            [instance _saveVideoAlbum];
        }
        instance.videoCompressComplete = YES;
    }];
}

///删除本地视频资源
- (void)_removeVideoFiles {
    for (id obj in self.dataArray) {
        if ([obj isKindOfClass:[NSURL class]]) {
            NSURL *url = (NSURL *)obj;
            [self _removeVideoFileAtPath:url.path];
        }
    }
}

/// 根据本地路径移除资源
/// @param filePath 路径
- (void)_removeVideoFileAtPath:(NSString *)filePath {
    //filePath = [filePath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError *error;
        if ([[NSFileManager defaultManager] removeItemAtPath:filePath error:&error]) {
            NSLog(@"删除成功");
        } else {
            NSLog(@"删除失败 Unable to delete file: %@", [error localizedDescription]);
        }
    }
}

/// 显示一个action的alert
/// @param title 标题
/// @param message 文字
/// @param actionTitle 按钮标题
/// @param actionHandler 回调
- (void)_showOneActionAlertWithTitle:(NSString *)title message:(NSString *)message actionTitle:(NSString *)actionTitle actionHandler:(void (^)(void))actionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        actionHandler();
    }];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:NULL];
}

- (void)_rotateInterfaceOrientation:(UIInterfaceOrientation)orientation {
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:orientation] forKey:@"orientation"];
        [UIViewController attemptRotationToDeviceOrientation];
    }
}

#pragma mark - Setter

- (void)setMaxRecordTime:(NSInteger)maxRecordTime {
    _maxRecordTime = maxRecordTime;
    self.recorderManager.maxRecordTime = maxRecordTime;
    self.contentView.tipSecondLabel.text = [NSString stringWithFormat:@"%@''",@(maxRecordTime)];
}

- (void)setNeedCompressVideo:(BOOL)needCompressVideo {
    _needCompressVideo = needCompressVideo;
    self.recorderManager.needCompressVideo = needCompressVideo;
}

- (void)setMaxVideoCount:(NSInteger)maxVideoCount {
    _maxVideoCount = maxVideoCount;
    if (maxVideoCount <= 0) {
        self.unAbleRecordVideo = YES;
        [self.contentView.chooseVideoButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    }
}

- (void)setPreViewCornerRadius:(CGFloat)preViewCornerRadius {
    _preViewCornerRadius = preViewCornerRadius;
    self.contentView.preViewLayerBackView.layer.cornerRadius = preViewCornerRadius;
}

#pragma mark - Getter

- (UIView<XBCameraDefaultContentViewProtocol> *)contentView {
    if (!_contentView) {
        _contentView = [[XBCameraDefaultContentView alloc] init];
    }
    return _contentView;
}

- (XBCameraManager *)recorderManager {
    if (!_recorderManager) {
        _recorderManager = [[XBCameraManager alloc] init];
    }
    return _recorderManager;
}

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = @[].mutableCopy;
    }
    return _dataArray;
}

- (NSMutableArray<UIImage *> *)imageDataArray {
    if (!_imageDataArray) {
        _imageDataArray = @[].mutableCopy;
    }
    return _imageDataArray;
}

@end
