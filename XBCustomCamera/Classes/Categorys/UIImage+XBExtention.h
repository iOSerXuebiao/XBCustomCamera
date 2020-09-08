//
//  UIImage+XBExtention.h
//  XBCustomCamera
//
//  Created by Xue on 2020/9/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (XBExtention)

/// 从pod的bundle加载图片
+ (UIImage *)xb_imageNamed:(NSString *)imageName inBundle:(NSString *)bundleName;

///  按照指定尺寸重绘图片
/// @param image 原始图片对象
/// @param newSize 新的size
+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize;

/// 获取视频第一帧
/// @param url 原始视频的路径
/// @param size 新的size
+ (UIImage *)firstFrameWithVideoURL:(NSURL *)url size:(CGSize)size;

/// 处理图片orientation
/// @param image 原始图片对象
+ (UIImage *)fixOrientation:(UIImage *)image;

/// 根据图片大小粗略压缩图片
/// @param image 原始图片对象
/// @param size  目标图片大小 单位M

//+ (UIImage *)compressImageSketchy:(UIImage *)image size:(CGFloat)size;

/// @brief 使图片压缩后刚好小于指定大小 精确
/// @param image 输入的原始图片
/// @param imageMBytes 目标大小

+ (UIImage *)compressedImagePrecise:(UIImage *)image imageSizeMB:(CGFloat)imageMBytes;

@end

NS_ASSUME_NONNULL_END
