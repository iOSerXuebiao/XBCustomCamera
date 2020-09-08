//
//  XBCameraManager.h
//  XBCustomCamera
//
//  Created by Xue on 2020/9/3.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, kHardwareType) {
    ///相机
    kHardwareTypeCamera = 0,
    ///麦克风
    kHardwareTypeMicrophone    = 1,
} API_AVAILABLE(macos(10.14), ios(7.0)) __WATCHOS_PROHIBITED __TVOS_PROHIBITED;

@protocol XBVideoRecordManagerDelegate <NSObject>

/// 拍照回调
/// @param image 图片
/// @param error 错误
- (void)takePhotoCompletedWithImage:(UIImage *)image error:(NSError *)error;

/// 视频录制结束
/// @param captureOutput 资源输出
/// @param outputFileURL 输出路径
/// @param isCompressed 是否压缩
/// @param connections 连接
/// @param error 错误
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *_Nullable)outputFileURL isCompressed:(BOOL)isCompressed fromConnections:(NSArray *)connections error:(NSError *)error;

/// 录制时间
/// @param currentTime 当前时间
/// @param totalTime 总时间
- (void)recordTimeCurrentTime:(CGFloat)currentTime totalTime:(CGFloat)totalTime;

/// 视频录制失败
- (void)videoRecordFailed;

/// 视频开始压缩
- (void)videoCompressStart;

/// 视频压缩的结果
/// @param isSuccess 是否成功
- (void)videoCompressResult:(BOOL)isSuccess;

@end

@interface XBCameraManager : NSObject

@property (nonatomic, weak) id<XBVideoRecordManagerDelegate> delegate;

/// 摄像头视图层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preViewLayer;

///最大录制时长 默认15秒
@property(nonatomic, assign) CGFloat maxRecordTime;
///是否需要压缩视频 默认NO
@property (nonatomic, assign) BOOL needCompressVideo;

///视频是否在录制中
@property(nonatomic, readonly, getter=isRecording) BOOL recording;

/// 本地存储文件夹的名称 默认是存在tmp目录下  默认名字Video
@property (nonatomic, copy) NSString *localVideoFolderName;

/// 拍照
- (void)takePhoto;

/// 准备录制
- (void)prepareForRecord;

/// 开始录制
- (void)startRecordToFile:(NSURL *)outPutFile;

/// 停止录制
- (void)stopCurrentVideoRecording;

/// 切换摄像头
- (void)switchCamera;

/// 设置对焦
- (void)setFoucusWithPoint:(CGPoint)point;

/// 压缩视频
- (void)compressVideo:(NSURL *)inputFileURL complete:(void(^)(BOOL success, NSURL* outputUrl))complete;

/// 缓存路径
- (NSString*)cacheFilePath:(BOOL)input;

/// 获取文件大小
/// @param filePath 路径
+ (CGFloat)getfileSize:(NSString *)filePath;

/// 检查相机权限
/// @param isAuthorized 回调 isAuthorized：是否授权，type：硬件类型  ，tipText：提示文字
+ (void)checkCameraAuth:(void(^)(BOOL isAuthorized, kHardwareType type, NSString *tipText))isAuthorized;

@end

NS_ASSUME_NONNULL_END
