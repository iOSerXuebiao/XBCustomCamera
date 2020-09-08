//
//  UIColor+XBExtension.h
//  XBCustomCamera
//
//  Created by Xue on 2020/9/8.
//

#import <UIKit/UIKit.h>

#define XB_HEX_COLOR(_ref) ([UIColor colorWithHexString:(_ref)])

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (XBExtension)

+ (UIColor *)colorWithRGBHex:(UInt32)hex;
+ (UIColor *)colorWithHexString:(NSString *)stringToConvert;

@end

NS_ASSUME_NONNULL_END
