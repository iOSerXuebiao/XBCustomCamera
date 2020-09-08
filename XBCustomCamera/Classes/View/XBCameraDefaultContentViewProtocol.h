//
//  XBCameraDefaultContentViewProtocol.h
//  XBCustomCamera
//
//  Created by Xue on 2020/9/3.
//

#import <Foundation/Foundation.h>
#import "XBVideoRecordProgress.h"
#import "XBCameraFunctionProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol XBCameraDefaultContentViewProtocol <NSObject>

@required
///采集layer的背景视图
@property (nonatomic, strong) UIView *preViewLayerBackView;
///需要设置一个代理 实现KSCameraFunctionProtocol接口
@property (nonatomic, weak) id <XBCameraFunctionProtocol> delegate;

@optional
///录制按钮
@property (nonatomic, strong) UIButton *recordBtn;
///录制按钮背景视图
@property (nonatomic, strong) UIView *recordBackView;
///关闭按钮
@property (nonatomic, strong) UIButton *closeButton;
///确认按钮
@property (nonatomic, strong) UIButton *sureButton;
///录制时间提示文字
@property (nonatomic, strong) UILabel *tipSecondLabel;
///聚焦图片
@property (nonatomic, strong) UIImageView *focusImageView;
///翻转摄像头按钮
@property (nonatomic, strong) UIButton *switchCameraButton;
///选择照片按钮
@property (nonatomic, strong) UIButton *choosePhotoButton;
///选择视频按钮
@property (nonatomic, strong) UIButton *chooseVideoButton;
///保存数据的展示图按钮
@property (nonatomic, strong) UIImageView *saveDataImageView;
///保存数量
@property (nonatomic, strong) UILabel *saveNumLabel;
///进度条
@property (nonatomic, strong) XBVideoRecordProgress *progressView;

/// 处理选中照片的UI样式
- (void)dealWithChoosePhotoButton;

/// 处理选中视频的UI样式
- (void)dealWithChooseVideoButton;

/// 处理录制背景视图的UI样式
- (void)dealWithRecordView;

/// 根据录制状态处理字视图的状态
/// @param isRecording 是否录制中
- (void)dealWithSubViewsStatus:(BOOL)isRecording;

/// 处理视频录制结束的case
/// @param maxRecordTime 最大录制时长
- (void)dealWithDidFinishRecordingWithMaxRecordTime:(NSInteger)maxRecordTime;

/// 处理聚焦的UI
/// @param point 触发点
- (void)dealWithFocusCursorWithPoint:(CGPoint)point;

/// 处理视频录制进度case
/// @param currentTime 当前时间
/// @param totalTime 总时间
- (void)dealWithRecordTimeCurrentTime:(CGFloat)currentTime totalTime:(CGFloat)totalTime;

/// 处理保存数据的视图
/// @param count 已存数量
/// @param maxCount 最大数量
/// @param image 显示的缩略图片
- (void)dealWithSaveDataViewWithCount:(NSUInteger)count maxCount:(NSUInteger)maxCount image:(UIImage *)image;


@end

NS_ASSUME_NONNULL_END
