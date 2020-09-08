//
//  XBVideoCompressTool.h
//  XBCustomCamera
//
//  Created by Xue on 2020/9/8.
//

#import <Foundation/Foundation.h>

typedef void (^VideoCompressBlock)(BOOL success);

NS_ASSUME_NONNULL_BEGIN

@interface XBVideoCompressTool : NSObject

/// 自定义视频宽高 码率 帧率 gop 宽高等压缩视频
/// @param inputLocalVideoPath 输入的原始视频路径
/// @param outputVideoBiteRate 输出的视频码率
/// @param outputVideoFrameRate 输出的视频帧率
/// @param outputVideoWidth 输出的视频宽度 默认1280
/// @param outputVideoHeight 输出的视频高度 默认720
/// @param outputLocalVideoPath 输出的压缩完毕的视频路径 里边不要除了扩展名 不要包含 例如m.a.mp4 不支持 修改为m-a.mp4
/// @param outputVideoGop 输出视频的gop数值
/// @param hasVideoMirrored 是否有镜像
/// @param callback 回调是否成功
+ (void)compressVideoWithVideoUrl:(NSString *)inputLocalVideoPath withVideoBiteRate:(CGFloat)outputVideoBiteRate withVideoFrameRate:(CGFloat )outputVideoFrameRate withVideoWidth:(CGFloat)outputVideoWidth withVideoHeight:(CGFloat )outputVideoHeight outputLocalVideoPath:(NSString *)
    outputLocalVideoPath outputVideoGop:(CGFloat)outputVideoGop
    videoMirrored:(BOOL)hasVideoMirrored
    completion:(VideoCompressBlock)callback;


/// 自定义视频宽高 码率 帧率 gop 宽高等压缩视频
/// @param inputLocalVideoPath 输入的原始视频路径
/// @param outputVideoBiteRate 输出的视频码率
/// @param outputVideoFrameRate  输出的视频帧率
/// @param outputVideoWidth 输出的视频宽度 无默认值
/// @param outputVideoHeight 输出的视频高度 无默认值
/// @param outputLocalVideoPath 输出的视频路径 如果传入的视频小于标准数值 不需要压缩
/// @param outputVideoGop 输出视频的gop数值
/// @param callback  回调是否成功
+ (void)compressVideoWithVideoUrlExtend:(NSString *)inputLocalVideoPath withVideoBiteRate:(CGFloat)outputVideoBiteRate withVideoFrameRate:(CGFloat )outputVideoFrameRate withVideoWidth:(CGFloat)outputVideoWidth withVideoHeight:(CGFloat )outputVideoHeight outputLocalVideoPath:(NSString *)
    outputLocalVideoPath outputVideoGop:(CGFloat)outputVideoGop
    completion:(VideoCompressBlock)callback;

/// 便利压缩方法
/// @param inputLocalVideoPath 输入的原始视频路径
/// @param outputLocalVideoPath 输出的视频码率
/// @param callback 回调是否成功
+ (void)compressVideoWithVideoUrlExtendConvenience:(NSString *)inputLocalVideoPath outputLocalVideoPath:(NSString *)
     outputLocalVideoPath  completion:(VideoCompressBlock)callback;

@end

NS_ASSUME_NONNULL_END
