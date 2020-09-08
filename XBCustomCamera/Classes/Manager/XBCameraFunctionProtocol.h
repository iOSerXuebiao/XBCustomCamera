//
//  XBCameraFunctionProtocol.h
//  XBCustomCamera
//
//  Created by Xue on 2020/9/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol XBCameraFunctionProtocol <NSObject>

/// 拍照
- (void)takePhotoFunction;

/// 录视频
- (void)recordVideoFunction;

/// 翻转摄像头
- (void)switchCameraFunction;

/// 关闭页面
- (void)closeFunction;

/// 确认
- (void)sureFunction;

/// 选中照片
- (void)choosePhotoFunction;

/// 选中视频
- (void)chooseVideoFunction;

/// 保存的资源事件
- (void)saveDataImageButtonEventFunction;

/// 设置焦点
- (void)setFoucusFunctionWithPoint:(CGPoint)point;

@end

NS_ASSUME_NONNULL_END
