//
//  XBVideoCompressTool.m
//  XBCustomCamera
//
//  Created by Xue on 2020/9/8.
//

#import "XBVideoCompressTool.h"
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "XBFileManager.h"

@implementation XBVideoCompressTool

+ (void)compressVideoWithVideoUrl:(NSString *)inputLocalVideoPath withVideoBiteRate:(CGFloat)outputVideoBiteRate withVideoFrameRate:(CGFloat )outputVideoFrameRate withVideoWidth:(CGFloat)outputVideoWidth withVideoHeight:(CGFloat )outputVideoHeight outputLocalVideoPath:(NSString *)
    outputLocalVideoPath outputVideoGop:(CGFloat)outputVideoGop
    videoMirrored:(BOOL)hasVideoMirrored
    completion:(VideoCompressBlock)callback {
    if (inputLocalVideoPath.length == 0 || outputLocalVideoPath.length == 0) return;
    if ([outputLocalVideoPath componentsSeparatedByString:@"."].count != 2) {
        !callback?:callback(NO);
        return;
    }
    //如果指定路径下已存在其他文件 先移除指定文件
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputLocalVideoPath]) {
        BOOL removeSuccess =  [[NSFileManager defaultManager] removeItemAtPath:outputLocalVideoPath error:nil];
        if (!removeSuccess) {
            !callback?:callback(NO);
            return;
        }
    }
    NSURL *inputUrl = [NSURL fileURLWithPath:inputLocalVideoPath];
    
    //先判断是否有旋转
    if ([self degressFromVideoFileWithURL:inputUrl] > 0) {
        NSArray *pathArray = [outputLocalVideoPath componentsSeparatedByString:@"."];
        NSString *outputLocalTmpVideoPath = [NSString stringWithFormat:@"%@_tmp.%@",pathArray.firstObject,pathArray.lastObject];
        NSURL *outputLocalTmpVideoUrl = [NSURL fileURLWithPath:outputLocalTmpVideoPath];
        [self disposeVideoComposition:outputLocalTmpVideoUrl inputLocalVideoUrl:inputUrl completion:^(BOOL success) {
            if (success) {
                [self compressFinalVideo:outputLocalTmpVideoPath withVideoBiteRate:outputVideoBiteRate withVideoFrameRate:outputVideoFrameRate withVideoWidth:outputVideoWidth withVideoHeight:outputVideoHeight outputLocalVideoPath:outputLocalVideoPath outputVideoGop:outputVideoGop
                    videoMirrored:hasVideoMirrored
                    completion:^(BOOL success) {
                    if (success) {
                        //移除临时视频
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [XBFileManager removeItemAtPath:outputLocalTmpVideoPath];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                !callback?:callback(YES);
                            });
                        });
                    }
                }];
            }
        }];
    } else {
        [self compressFinalVideo:inputLocalVideoPath withVideoBiteRate:outputVideoBiteRate withVideoFrameRate:outputVideoFrameRate withVideoWidth:outputVideoWidth withVideoHeight:outputVideoHeight outputLocalVideoPath:outputLocalVideoPath outputVideoGop:outputVideoGop
            videoMirrored:hasVideoMirrored
            completion:callback];
    }
}

+ (void)compressVideoWithVideoUrlExtendConvenience:(NSString *)inputLocalVideoPath outputLocalVideoPath:(NSString *) outputLocalVideoPath  completion:(VideoCompressBlock)callback {
    [self compressVideoWithVideoUrlExtend:inputLocalVideoPath withVideoBiteRate:0 withVideoFrameRate:0 withVideoWidth:0 withVideoHeight:0 outputLocalVideoPath:outputLocalVideoPath outputVideoGop:0 completion:callback];
}

+ (void)compressVideoWithVideoUrlExtend:(NSString *)inputLocalVideoPath withVideoBiteRate:(CGFloat)outputVideoBiteRate withVideoFrameRate:(CGFloat )outputVideoFrameRate withVideoWidth:(CGFloat)outputVideoWidth withVideoHeight:(CGFloat )outputVideoHeight outputLocalVideoPath:(NSString *)
outputLocalVideoPath outputVideoGop:(CGFloat)outputVideoGop completion:(VideoCompressBlock)callback {
    if (inputLocalVideoPath.length == 0 || outputLocalVideoPath.length == 0) return;
    if ([outputLocalVideoPath componentsSeparatedByString:@"."].count != 2) {
        callback(NO);
        return;
    }
    //如果指定路径下已存在其他文件 先移除指定文件
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputLocalVideoPath]) {
        BOOL removeSuccess =  [[NSFileManager defaultManager] removeItemAtPath:outputLocalVideoPath error:nil];
        if (!removeSuccess) {
            callback(NO);
            return;
        }
    }
    NSURL *inputUrl = [NSURL fileURLWithPath:inputLocalVideoPath];
    //取出原视频详细资料
    AVURLAsset *asset = [AVURLAsset assetWithURL:inputUrl];
    //视频时长 S
    CMTime time = [asset duration];
    NSLog(@"time = %@",@(time.value));
    
    //压缩前原视频大小MB
    unsigned long long fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:inputUrl.path error:nil].fileSize;
    float fileSizeMB = fileSize / (1024.0*1024.0);
    NSLog(@"inputFileSizeMB = %@",@(fileSizeMB));
    //取出asset中的视频文件
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    
    NSInteger frameRate = [videoTrack nominalFrameRate];
    NSLog(@"frameRate = %@",@(frameRate));
    if (fileSizeMB < 3) {
        !callback?:callback(NO);
        return;
    }
    
    if (frameRate < 30) {
        !callback?:callback(NO);
        return;
    }
    NSInteger kbps = videoTrack.estimatedDataRate / 1024;
    //默认1500
    NSInteger compressBiteRate = outputVideoBiteRate >0 ? outputVideoBiteRate : 1500 * 1024;
    //原视频比特率小于默认比特率 不压缩 返回原视频
    if (kbps <= (compressBiteRate / 1024)) {
        !callback?:callback(NO);
        return;
    }
    NSInteger compressFrameRate = outputVideoFrameRate > 0 ? outputVideoFrameRate : 30;//默认30
    NSInteger compressWidth = outputVideoWidth >0 ? outputVideoWidth : 1280;//默认1280
    NSInteger compressHeight = outputVideoHeight >0  ? outputVideoHeight : 720;//默认720
    //压缩前原视频宽高
    NSInteger videoWidth = videoTrack.naturalSize.width;
    NSInteger videoHeight = videoTrack.naturalSize.height;
    [self finalDisposeAudioVideo:inputLocalVideoPath withVideoBiteRate:compressBiteRate withVideoFrameRate:compressFrameRate withVideoWidth:compressWidth withVideoHeight:compressHeight videoWidth:videoWidth videoHeight:videoHeight
            outputLocalVideoPath:outputLocalVideoPath outputVideoGop:outputVideoGop asset:asset videoTrack:videoTrack
                      videoMirrored:NO
                      completion:callback];
}

+ (void)compressFinalVideo:(NSString *)inputLocalVideoPath withVideoBiteRate:(CGFloat)outputVideoBiteRate withVideoFrameRate:(CGFloat )outputVideoFrameRate withVideoWidth:(CGFloat)outputVideoWidth withVideoHeight:(CGFloat )outputVideoHeight outputLocalVideoPath:(NSString *)
    outputLocalVideoPath outputVideoGop:(CGFloat)outputVideoGop
    videoMirrored:(BOOL)hasVideoMirrored
    completion:(VideoCompressBlock)callback {
    NSInteger compressBiteRate = outputVideoBiteRate >0 ? outputVideoBiteRate : 1500 * 1024; //默认1500
    NSInteger compressFrameRate = outputVideoFrameRate > 0 ? outputVideoFrameRate : 30;//默认30
    NSInteger compressWidth = outputVideoWidth >0 ? outputVideoWidth : 1280;//默认1280
    NSInteger compressHeight = outputVideoHeight >0  ? outputVideoHeight : 720;//默认720
    NSURL *inputUrl = [NSURL fileURLWithPath:inputLocalVideoPath];
    //取出原视频详细资料
    AVURLAsset *asset = [AVURLAsset assetWithURL:inputUrl];
    //视频时长 S
    CMTime time = [asset duration];
    NSLog(@"time = %@",@(time.value));
    
    //压缩前原视频大小MB
    unsigned long long fileSize = [[NSFileManager defaultManager] attributesOfItemAtPath:inputUrl.path error:nil].fileSize;
    float fileSizeMB = fileSize / (1024.0*1024.0);
    NSLog(@"inputFileSizeMB = %@",@(fileSizeMB));
    //取出asset中的视频文件
    AVAssetTrack *videoTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    //压缩前原视频宽高
    NSInteger videoWidth = videoTrack.naturalSize.width;
    NSInteger videoHeight = videoTrack.naturalSize.height;
    
    NSInteger frameRate = [videoTrack nominalFrameRate];
    NSLog(@"frameRate = %@",@(frameRate));
    [self finalDisposeAudioVideo:inputLocalVideoPath withVideoBiteRate:compressBiteRate withVideoFrameRate:compressFrameRate withVideoWidth:compressWidth withVideoHeight:compressHeight videoWidth:videoWidth videoHeight:videoHeight
            outputLocalVideoPath:outputLocalVideoPath outputVideoGop:outputVideoGop asset:asset
                      videoTrack:videoTrack
                      videoMirrored:hasVideoMirrored
                      completion:callback];
}

+ (void)finalDisposeAudioVideo:(NSString *)inputLocalVideoPath withVideoBiteRate:(CGFloat)compressBiteRate withVideoFrameRate:(CGFloat )compressFrameRate withVideoWidth:(CGFloat)compressWidth withVideoHeight:(CGFloat )compressHeight
                    videoWidth:(NSInteger)videoWidth videoHeight:(NSInteger)videoHeight
          outputLocalVideoPath:(NSString *)outputLocalVideoPath outputVideoGop:(CGFloat)outputVideoGop asset:(AVURLAsset *)asset videoTrack:(AVAssetTrack *)videoTrack
                     videoMirrored:(BOOL)hasVideoMirrored
                    completion:(VideoCompressBlock)callback {
    NSError *error = nil;
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    if (!reader)  {
        !callback?:callback(NO);
        return;
    }
    AVAssetReaderTrackOutput *videoOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:[XBVideoCompressTool configVideoOutput]];
    AVAssetTrack *audioTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
    BOOL hasAudio = (audioTrack!=nil);
    AVAssetReaderTrackOutput *audioOutput = nil;
    if (hasAudio) {
        audioOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:[XBVideoCompressTool configAudioOutput]];
    }
    if ([reader canAddOutput:videoOutput]) {
        [reader addOutput:videoOutput];
    } else {
        !callback?:callback(NO);
        return;
    }
    if (hasAudio && audioOutput) {
        if ([reader canAddOutput:audioOutput]) {
            [reader addOutput:audioOutput];
        }
    }
    NSURL *outputLocalVideoUrl = [NSURL fileURLWithPath:outputLocalVideoPath];
    
    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:outputLocalVideoUrl fileType:AVFileTypeMPEG4 error:nil];
    AVAssetWriterInput *videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:[XBVideoCompressTool videoCompressSettingsWithVideoBitRate:compressBiteRate withVideoFrameRate:compressFrameRate withVideoWidth:compressWidth WithVideoHeight:compressHeight withVideoOriginalWidth:videoWidth withVideoOriginalHeight:videoHeight videoGeo:outputVideoGop]];
    if (hasVideoMirrored) {
        CGAffineTransform  transform = CGAffineTransformMakeRotation(3*M_PI/2);
              transform = CGAffineTransformScale(transform, -1, 1);
        videoInput.transform = transform;
    }
    AVAssetWriterInput *audioInput = nil;
    if (hasAudio) {
        audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:[XBVideoCompressTool audioCompressSettings]];
    }
    if ([writer canAddInput:videoInput]) {
        [writer addInput:videoInput];
    }
    if (hasAudio && audioOutput) {
        if ([writer canAddInput:audioInput]) {
            [writer addInput:audioInput];
        }
    }
    [reader startReading];
    [writer startWriting];
    [writer startSessionAtSourceTime:kCMTimeZero];
    dispatch_queue_t videoQueue = dispatch_queue_create("Video Queue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t audioQueue = nil;
    if (hasAudio) {
        audioQueue = dispatch_queue_create("Audio Queue", DISPATCH_QUEUE_SERIAL);
    }
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    [videoInput requestMediaDataWhenReadyOnQueue:videoQueue usingBlock:^{
        BOOL completedOrFailed = NO;
        while ([videoInput isReadyForMoreMediaData] && !completedOrFailed) {
            CMSampleBufferRef sampleBuffer = [videoOutput copyNextSampleBuffer];
            if (sampleBuffer != NULL) {
                [videoInput appendSampleBuffer:sampleBuffer];
                CFRelease(sampleBuffer);
            } else {
                completedOrFailed = YES;
                [videoInput markAsFinished];
                dispatch_group_leave(group);
            }
        }
    }];
    
    if (hasAudio) {
        dispatch_group_enter(group);
        [audioInput requestMediaDataWhenReadyOnQueue:audioQueue usingBlock:^{
            BOOL completedOrFailed = NO;
            while ([audioInput isReadyForMoreMediaData] && !completedOrFailed) {
                CMSampleBufferRef sampleBuffer = [audioOutput copyNextSampleBuffer];
                if (sampleBuffer != NULL) {
                    BOOL success = [audioInput appendSampleBuffer:sampleBuffer];
                    CFRelease(sampleBuffer);
                    completedOrFailed = !success;
                } else {
                    completedOrFailed = YES;
                }
            }
            if (completedOrFailed) {
                [audioInput markAsFinished];
                dispatch_group_leave(group);
            }
        }];
    }
    //完成压缩
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if ([reader status] == AVAssetReaderStatusReading) {
            [reader cancelReading];
        }
        switch (writer.status) {
            case AVAssetWriterStatusWriting: {
                //压缩成功
                [writer finishWritingWithCompletionHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        !callback?:callback(YES);
                    });
                }];
            }
                break;
            case AVAssetWriterStatusCancelled: {
                //取消压缩
                dispatch_async(dispatch_get_main_queue(), ^{
                    !callback?:callback(NO);
                });
                break;
            }
            case AVAssetWriterStatusFailed: {
                //压缩失败
                dispatch_async(dispatch_get_main_queue(), ^{
                    !callback?:callback(NO);
                });
                break;
            }
            case AVAssetWriterStatusCompleted: {
                //视频压缩完成
                dispatch_async(dispatch_get_main_queue(), ^{
                    !callback?:callback(YES);
                });
            }
                break;
            default:
                break;
        }
    });
}
+ (NSDictionary *)videoCompressSettingsWithVideoBitRate:(NSInteger)biteRate withVideoFrameRate:(NSInteger)frameRate withVideoWidth:(NSInteger)width WithVideoHeight:(NSInteger)height withVideoOriginalWidth:(NSInteger)originalWidth withVideoOriginalHeight:(NSInteger)originalHeight videoGeo:(NSInteger) videoGeo {
    NSInteger returnWidth = originalWidth > originalHeight ? width : height;
    NSInteger returnHeight = originalWidth > originalHeight ? height : width;
    
    NSDictionary *compressProperties = @{
        AVVideoAverageBitRateKey : @(biteRate),
        AVVideoExpectedSourceFrameRateKey : @(frameRate),
        AVVideoProfileLevelKey : AVVideoProfileLevelH264HighAutoLevel
    };
    if (@available(iOS 11.0, *)) {
        NSDictionary *compressSetting = @{
            AVVideoCodecKey : AVVideoCodecTypeH264,
            AVVideoWidthKey : @(returnWidth),
            AVVideoHeightKey : @(returnHeight),
            AVVideoCompressionPropertiesKey : compressProperties,
            AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill
        };
        return compressSetting;
    } else {
        NSDictionary *compressSetting = @{
            AVVideoCodecKey : AVVideoCodecH264,
            AVVideoWidthKey : @(returnWidth),
            AVVideoHeightKey : @(returnHeight),
            AVVideoCompressionPropertiesKey : compressProperties,
            AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill
        };
        return compressSetting;
    }
}
//音频设置
+ (NSDictionary *)audioCompressSettings {
    AudioChannelLayout stereoChannelLayout = {
        .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
        .mChannelBitmap = kAudioChannelBit_Left,
        .mNumberChannelDescriptions = 0,
    };
    NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
    NSDictionary *audioCompressSettings = @{
        AVFormatIDKey : @(kAudioFormatMPEG4AAC),
        AVEncoderBitRateKey : @(128000),
        AVSampleRateKey : @(44100),
        AVNumberOfChannelsKey : @(2),
        AVChannelLayoutKey : channelLayoutAsData
    };
    return audioCompressSettings;
}
// 音频解码
+ (NSDictionary *)configAudioOutput {
    NSDictionary *audioOutputSetting = @{
        AVFormatIDKey: @(kAudioFormatLinearPCM)
    };
    return audioOutputSetting;
}
// 视频解码
+ (NSDictionary *)configVideoOutput {
    NSDictionary *videoOutputSetting = @{
        (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_422YpCbCr8],
        (__bridge NSString *)kCVPixelBufferIOSurfacePropertiesKey:[NSDictionary dictionary]
    };
    
    return videoOutputSetting;
}

+ (NSUInteger)degressFromVideoFileWithURL:(NSURL *)url {
    NSUInteger degress = 0;
    
    AVAsset *asset = [AVAsset assetWithURL:url];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90;
        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270;
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 180;
        }
    }
    return degress;
}

+ (AVMutableVideoComposition *)fetchVideoComposition:(AVAsset *)asset {
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    CGSize videoSize = videoTrack.naturalSize;
    
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        if((t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) ||
           (t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)){
            videoSize = CGSizeMake(videoSize.height, videoSize.width);
        }
    }
    composition.naturalSize    = videoSize;
    videoComposition.renderSize = videoSize;
    videoComposition.frameDuration = CMTimeMakeWithSeconds( 1 / videoTrack.nominalFrameRate, 600);
    
    AVMutableCompositionTrack *compositionVideoTrack;
    compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
    AVMutableVideoCompositionLayerInstruction *layerInst;
    layerInst = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    [layerInst setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
    AVMutableVideoCompositionInstruction *inst = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    inst.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    inst.layerInstructions = [NSArray arrayWithObject:layerInst];
    videoComposition.instructions = [NSArray arrayWithObject:inst];
    return videoComposition;
}


+ (void)disposeVideoComposition:(NSURL *)outputLocalVideoUrl
             inputLocalVideoUrl:(NSURL *)inputLocalVideoUrl
                     completion:(VideoCompressBlock)callback {
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:inputLocalVideoUrl options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    NSString *quality = AVAssetExportPresetLowQuality;
    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
        quality = AVAssetExportPresetHighestQuality;
    } else if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        quality = AVAssetExportPresetMediumQuality;
    }
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset
                                                                          presetName:quality];
    exportSession.outputURL = outputLocalVideoUrl;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.shouldOptimizeForNetworkUse = YES;
    AVMutableVideoComposition *videoComposition = [self fetchVideoComposition:avAsset];
    if (videoComposition) {
        exportSession.videoComposition = videoComposition;
    }
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(),^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusFailed:{
                    NSLog(@"Export failed: %@ : %@", [[exportSession error] localizedDescription], [exportSession error]);
                    break;
                } case AVAssetExportSessionStatusCancelled:{
                    NSLog(@"Export canceled");
                    break;
                    
                } case AVAssetExportSessionStatusCompleted:{
                    NSLog(@"Export canceled");
                    callback(YES);
                    break;
                }
                default:
                    break;
            }
        });
    }];
}

@end
