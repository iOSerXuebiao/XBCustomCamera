//
//  XBCameraViewController.h
//  XBCustomCamera
//
//  Created by Xue on 2020/9/3.
//

#import <UIKit/UIKit.h>
#import "XBCameraDefaultContentView.h"

NS_ASSUME_NONNULL_BEGIN

/// 关闭相机页面回调
typedef void(^CloseCameraBlock)(void);

/// 完成回调
/// @param dataArray 图片和视频URL数据
typedef void(^CompletionBlock)(NSArray *dataArray);

/// 点击拍照和录制按钮的时候超过最大限制数量的回调（包含拍照和录制视频数，抛给业务层，做toast提示等行为）
typedef void(^ExceedMaxCountBlock)(void);

/// 超过视频限制，点击视频按钮回调
typedef void(^ExceedVideoCountBlock)(void);

/// 视频录制失败回调
typedef void(^VideoRecordFailedBlock)(void);

/// 视频开始压缩回调 (抛给业务层，做loading或者其他工作)
typedef void(^VideoCompressStartBlock)(void);

/// 视频压缩结果回调 (抛给业务层，取消loading或者其他工作)
/// @param isSuccess 是否成功
typedef void(^VideoCompressResultBlock)(BOOL isSuccess);

@interface XBCameraViewController : UIViewController <XBCameraFunctionProtocol>

/// 自定义UI使用此初始化方法
/// @param customView 遵循KSCameraDefaultContentViewProtocol的视图
- (instancetype)initWithCustomView:(UIView <XBCameraDefaultContentViewProtocol>*)customView;

///默认内容视图 （暴露给业务层可修改）
@property (nonatomic, strong) UIView <XBCameraDefaultContentViewProtocol> *contentView;
///取消回调
@property (nonatomic, copy) CloseCameraBlock cancelBlock;
///拍摄照片、视频完成回调
@property (nonatomic, copy) CompletionBlock completionBlock;

/// 点击拍照和录制按钮的时候超过最大限制数量的回调（包含拍照和录制视频数，抛给业务层，做toast提示等行为）
@property (nonatomic, copy) ExceedMaxCountBlock exceedMaxCountBlock;

/// 超过视频限制，点击视频按钮回调
@property (nonatomic, copy) ExceedVideoCountBlock exceedVideoCountBlock;

/// 视频录制失败回调
@property (nonatomic, copy) VideoRecordFailedBlock videoRecordFailedBlock;

/// 视频开始压缩回调
@property (nonatomic, copy) VideoCompressStartBlock videoCompressStartBlock;

/// 视频压缩结果回调
@property (nonatomic, copy) VideoCompressResultBlock videoCompressResultBlock;


///拍摄最大数量
@property (nonatomic, assign) NSInteger maxCount;
///视频最大录制数量
@property (nonatomic, assign) NSInteger maxVideoCount;
///视频最大录制时长 默认15秒
@property (nonatomic, assign) NSInteger maxRecordTime;
///是否需要压缩视频 默认NO
@property (nonatomic, assign) BOOL needCompressVideo;

///照片是否需要保存到系统相册 默认NO 不保存
@property (nonatomic, assign) BOOL photoNeedSaveToAlbum;
///视频是否需要保存到系统相册 默认NO 不保存
@property (nonatomic, assign) BOOL videoNeedSaveToAlbum;

///自定义设置采集区域圆角值  默认是18
@property (nonatomic, assign) CGFloat preViewCornerRadius;

@end

NS_ASSUME_NONNULL_END
