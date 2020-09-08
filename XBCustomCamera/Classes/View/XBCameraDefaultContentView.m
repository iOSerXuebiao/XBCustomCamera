//
//  XBCameraDefaultContentView.m
//  XBCustomCamera
//
//  Created by Xue on 2020/9/3.
//

#import "XBCameraDefaultContentView.h"
#import "Masonry.h"
#import "UIImage+XBExtention.h"
#import "UIColor+XBExtension.h"

@implementation XBCameraDefaultContentView

@synthesize preViewLayerBackView = _preViewLayerBackView;
@synthesize recordBtn = _recordBtn;
@synthesize recordBackView = _recordBackView;
@synthesize closeButton = _closeButton;
@synthesize sureButton = _sureButton;
@synthesize tipSecondLabel = _tipSecondLabel;
@synthesize focusImageView = _focusImageView;
@synthesize switchCameraButton = _switchCameraButton;
@synthesize choosePhotoButton = _choosePhotoButton;
@synthesize chooseVideoButton = _chooseVideoButton;
@synthesize saveDataImageView = _saveDataImageView;
@synthesize saveNumLabel = _saveNumLabel;
@synthesize progressView = _progressView;
@synthesize delegate = _delegate;

-(instancetype)init {
    if (self = [super init]) {
        [self configSubViews];
        [self configLayoutSubViews];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self configSubViews];
        [self configLayoutSubViews];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        [self configSubViews];
        [self configLayoutSubViews];
    }
    return self;
}

- (void)configSubViews {
    self.backgroundColor = [UIColor blackColor];
    self.userInteractionEnabled = YES;
    
    [self addSubview:self.recordBackView];
    [self addSubview:self.closeButton];
    [self addSubview:self.sureButton];
    [self addSubview:self.tipSecondLabel];
    [self addSubview:self.switchCameraButton];
    [self addSubview:self.progressView];
    [self addSubview:self.choosePhotoButton];
    [self addSubview:self.chooseVideoButton];
    [self addSubview:self.saveDataImageView];
    [self addSubview:self.saveNumLabel];
    [self addSubview:self.recordBtn];
    [self addSubview:self.preViewLayerBackView];
    [self addSubview:self.focusImageView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    [self addGestureRecognizer:tapGesture];
}

- (void)configLayoutSubViews {
    [self.switchCameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-40);
        make.width.height.mas_equalTo(54);
        make.centerY.equalTo(self.recordBtn);
    }];
    
    [self.recordBackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-93);
        make.width.height.mas_equalTo(70);
        make.centerX.mas_equalTo(0);
    }];

    [self.recordBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.recordBackView);
        make.width.height.mas_equalTo(60);
    }];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.recordBackView);
        make.size.equalTo(self.recordBackView).sizeOffset(CGSizeMake(1.5, 1.5));
    }];
    
    [self.tipSecondLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(2);
        make.bottom.equalTo(self.recordBackView.mas_top).offset(-8);
    }];
    
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(18);
        make.top.mas_equalTo(50);
    }];
    
    [self.sureButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-18);
        make.centerY.equalTo(self.closeButton);
    }];
    
    [self.choosePhotoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(-34);
        make.bottom.mas_equalTo(-40);
    }];
    
    [self.chooseVideoButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(34);
        make.centerY.equalTo(self.choosePhotoButton);
    }];
    
    [self.saveDataImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(33);
        make.centerY.equalTo(self.recordBtn);
        make.width.height.mas_equalTo(54);
    }];
    
    [self.saveNumLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.saveDataImageView);
        make.top.equalTo(self.saveDataImageView.mas_bottom).offset(5);
    }];
    
    [self.preViewLayerBackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
        make.top.mas_equalTo(112);
        make.bottom.mas_equalTo(-200);
    }];
}

#pragma mark - Actions

///翻转相机事件
- (void)switchCameraAction:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(switchCameraFunction)]) {
        [self.delegate switchCameraFunction];
    }
}

///关闭按钮事件
- (void)closeButtonAction:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(closeFunction)]) {
        [self.delegate closeFunction];
    }
}

///确认按钮事件
-  (void)sureButtonAction:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(sureFunction)]) {
        [self.delegate sureFunction];
    }
}

///选中照片
- (void)choosePhotoButtonAction:(UIButton *)button {
    if (self.choosePhotoButton.isSelected) {
        ///如果已经是选中的照片，不让重复点击
        return;
    }

    if (self.delegate && [self.delegate respondsToSelector:@selector(choosePhotoFunction)]) {
        [self.delegate choosePhotoFunction];
    }
}

///选中视频
- (void)chooseVideoButtonAction:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chooseVideoFunction)]) {
        [self.delegate chooseVideoFunction];
    }
}

///拍照和录制事件
- (void)recordBtnAction:(UIButton *)button {
    if (self.choosePhotoButton.isSelected) {
        ///拍照
        if (self.delegate && [self.delegate respondsToSelector:@selector(takePhotoFunction)]) {
            [self.delegate takePhotoFunction];
        }
        
    } else if (self.chooseVideoButton.isSelected) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(recordVideoFunction)]) {
            [self.delegate recordVideoFunction];
        }
    }
}

///保存图片按钮点击事件
- (void)saveDataImageViewTapAction {
    if (self.delegate && [self.delegate respondsToSelector:@selector(saveDataImageButtonEventFunction)]) {
        [self.delegate saveDataImageButtonEventFunction];
    }
}

///点击事件 设置焦点
- (void)tapGestureAction:(UITapGestureRecognizer *)tapGesture {
    CGPoint point= [tapGesture locationInView:self];
    if (120 < point.y && point.y < [[UIScreen mainScreen] bounds].size.height - 200) {
        [self dealWithFocusCursorWithPoint:point];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(setFoucusFunctionWithPoint:)]) {
            [self.delegate setFoucusFunctionWithPoint:point];
        }
    }
}

#pragma mark - Public

/// 处理选中视频的UI样式
- (void)dealWithChooseVideoButton {
    if (self.chooseVideoButton.isSelected) {
        ///如果已经是选中的视频，不让重复点击
        return;
    }
    self.tipSecondLabel.hidden = NO;
    self.choosePhotoButton.selected = NO;
    self.choosePhotoButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];

    self.chooseVideoButton.selected = YES;
    self.chooseVideoButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    
    ///修改样式
    [self dealWithRecordView];
}

/// 处理选中照片的UI样式
- (void)dealWithChoosePhotoButton {
    self.tipSecondLabel.hidden = YES;
    self.chooseVideoButton.selected = NO;
    self.chooseVideoButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];

    self.choosePhotoButton.selected = YES;
    self.choosePhotoButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
}

///处理录制背景视图的UI样式
- (void)dealWithRecordView {
    if (self.choosePhotoButton.isSelected) {
        ///选中照片
        self.recordBackView.layer.borderWidth = 0;
        self.recordBackView.backgroundColor = [UIColor whiteColor];

    } else if (self.chooseVideoButton.isSelected) {
        ///选中视频
        
        ///黄色
        self.recordBackView.layer.borderColor = XB_HEX_COLOR(@"#FFE34A").CGColor;
        self.recordBackView.layer.borderWidth = 3;
        self.recordBackView.backgroundColor = [UIColor blackColor];
    }
}

/// 根据录制状态处理字视图的状态
/// @param isRecording 是否录制中
- (void)dealWithSubViewsStatus:(BOOL)isRecording {
    self.closeButton.hidden = isRecording;
    self.sureButton.hidden = isRecording;
    self.switchCameraButton.hidden = isRecording;

    if (isRecording) {
        //self.progressView.frame = self.recordBackView.frame;

        [self.recordBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.recordBackView);
            make.width.height.mas_equalTo(24);
        }];
        self.recordBtn.layer.cornerRadius = 6;
        
        self.recordBackView.layer.borderColor = XB_HEX_COLOR(@"#494949").CGColor;
        self.recordBackView.layer.borderWidth = 2.5;

    } else {
        [self.recordBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.recordBackView);
            make.width.height.mas_equalTo(60);
        }];
        self.recordBtn.layer.cornerRadius = 30;
        
        self.recordBackView.layer.borderColor = XB_HEX_COLOR(@"#FFE34A").CGColor;
        self.recordBackView.layer.borderWidth = 3;
    }
}
/// 处理视频录制结束的case
/// @param maxRecordTime 最大录制时长
- (void)dealWithDidFinishRecordingWithMaxRecordTime:(NSInteger)maxRecordTime {
    [self.progressView setProgress:0];
    self.tipSecondLabel.text = [NSString stringWithFormat:@"%@''",@(maxRecordTime)];

    [self dealWithSubViewsStatus:NO];
}

/// 处理聚焦的UI
/// @param point 触发点
- (void)dealWithFocusCursorWithPoint:(CGPoint)point {
    self.focusImageView.center = point;
    self.focusImageView.transform = CGAffineTransformMakeScale(1.5, 1.5);
    [UIView animateWithDuration:0.2 animations:^{
        self.focusImageView.alpha = 1;
        self.focusImageView.transform = CGAffineTransformMakeScale(1, 1);
    } completion:^(BOOL finished) {
        [self performSelector:@selector(_autoHideFocusImageView) withObject:nil afterDelay:1];
    }];
}

///更新保存数据的视图
- (void)dealWithSaveDataViewWithCount:(NSUInteger)count maxCount:(NSUInteger)maxCount image:(UIImage *)image {
    if (count == 0) {
        self.saveDataImageView.hidden = YES;
        self.saveNumLabel.hidden = YES;
        return;
    }
    self.saveDataImageView.hidden = NO;
    self.saveNumLabel.hidden = NO;
    self.saveDataImageView.image = image;
    self.saveNumLabel.text = [NSString stringWithFormat:@"%@/%@",@(count),@(maxCount)];
}

/// 处理视频录制进度case
/// @param currentTime 当前时间
/// @param totalTime 总时间
- (void)dealWithRecordTimeCurrentTime:(CGFloat)currentTime totalTime:(CGFloat)totalTime {
    CGFloat showTime = totalTime - currentTime;
    if (showTime >= 0) {
        self.tipSecondLabel.text = [NSString stringWithFormat:@"%.0f''",showTime];
    }
    self.progressView.totolProgress = totalTime;
    self.progressView.progress = currentTime;
}

#pragma mark - Private

- (void)_autoHideFocusImageView {
    self.focusImageView.alpha = 0;
}

#pragma mark - Getter

- (UIImageView *)focusImageView {
    if (!_focusImageView) {
        _focusImageView = [[UIImageView alloc] init];
        _focusImageView.image = [UIImage xb_imageNamed:@"record_video_focus" inBundle:@"XBCustomCamera"];
        _focusImageView.alpha = 0;
        _focusImageView.frame = CGRectMake(0, 0, 75, 75);
    }
    return _focusImageView;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_closeButton setImage:[UIImage xb_imageNamed:@"camera_cancel_icon" inBundle:@"XBCustomCamera"] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UIButton *)sureButton {
    if (!_sureButton) {
        _sureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_sureButton setImage:[UIImage xb_imageNamed:@"camera_confirm_icon" inBundle:@"XBCustomCamera"] forState:UIControlStateNormal];
        [_sureButton addTarget:self action:@selector(sureButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sureButton;
}

- (XBVideoRecordProgress *)progressView {
    if (!_progressView) {
        _progressView = [[XBVideoRecordProgress alloc] init];
    }
    return _progressView;
}

- (UIButton *)switchCameraButton {
    if (!_switchCameraButton) {
        _switchCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_switchCameraButton setImage:[UIImage xb_imageNamed:@"camera_trun_icon" inBundle:@"XBCustomCamera"] forState:UIControlStateNormal];
        [_switchCameraButton addTarget:self action:@selector(switchCameraAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchCameraButton;
}

- (UIView *)recordBackView {
    if (!_recordBackView) {
        _recordBackView = [[UIView alloc] init];
        _recordBackView.backgroundColor = [UIColor whiteColor];
        _recordBackView.layer.cornerRadius = 35;
    }
    return _recordBackView;
}

- (UILabel *)tipSecondLabel {
    if (!_tipSecondLabel) {
        _tipSecondLabel = [[UILabel alloc] init];
        _tipSecondLabel.textColor = [UIColor whiteColor];
        _tipSecondLabel.text = @"0''";
        _tipSecondLabel.textAlignment = NSTextAlignmentCenter;
        _tipSecondLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        _tipSecondLabel.hidden = YES;
    }
    return _tipSecondLabel;
}

- (UIButton *)recordBtn {
    if (!_recordBtn) {
        _recordBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _recordBtn.layer.cornerRadius = 30.f;
        _recordBtn.clipsToBounds = YES;
        _recordBtn.backgroundColor = XB_HEX_COLOR(@"#FFE34A");
        [_recordBtn addTarget:self action:@selector(recordBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _recordBtn;
}

- (UIButton *)choosePhotoButton {
    if (!_choosePhotoButton) {
        _choosePhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_choosePhotoButton setTitle:@"照片" forState:UIControlStateNormal];
        [_choosePhotoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_choosePhotoButton setTitleColor:XB_HEX_COLOR(@"#FFE34A") forState:UIControlStateSelected];
        _choosePhotoButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        [_choosePhotoButton addTarget:self action:@selector(choosePhotoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        _choosePhotoButton.selected = YES;
    }
    return _choosePhotoButton;
}

- (UIButton *)chooseVideoButton {
    if (!_chooseVideoButton) {
        _chooseVideoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_chooseVideoButton setTitle:@"视频" forState:UIControlStateNormal];
        [_chooseVideoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_chooseVideoButton setTitleColor:XB_HEX_COLOR(@"#FFE34A") forState:UIControlStateSelected];
        _chooseVideoButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        [_chooseVideoButton addTarget:self action:@selector(chooseVideoButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _chooseVideoButton;
}

- (UIImageView *)saveDataImageView {
    if (!_saveDataImageView) {
        _saveDataImageView = [[UIImageView alloc] init];
        _saveDataImageView.backgroundColor = [UIColor whiteColor];
        _saveDataImageView.layer.cornerRadius = 12;
        _saveDataImageView.contentMode = UIViewContentModeScaleAspectFill;
        _saveDataImageView.clipsToBounds = YES;
        _saveDataImageView.hidden = YES;
        _saveDataImageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(saveDataImageViewTapAction)];
        [_saveDataImageView addGestureRecognizer:tap];
    }
    return _saveDataImageView;
}

- (UILabel *)saveNumLabel {
    if (!_saveNumLabel) {
        _saveNumLabel = [[UILabel alloc] init];
        _saveNumLabel.textColor = [UIColor whiteColor];
        _saveNumLabel.textAlignment = NSTextAlignmentCenter;
        _saveNumLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        _saveNumLabel.hidden = YES;
    }
    return _saveNumLabel;
}

- (UIView *)preViewLayerBackView {
    if (!_preViewLayerBackView) {
        _preViewLayerBackView = [[UIView alloc] init];
        _preViewLayerBackView.layer.cornerRadius = 18;
        _preViewLayerBackView.layer.masksToBounds = YES;
    }
    return _preViewLayerBackView;
}

@end
