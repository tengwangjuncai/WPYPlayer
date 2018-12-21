//
//  MyTestView.m
//  DrawTest
//
//  Created by Mango on 16/6/26.
//  Copyright © 2016年 Mango. All rights reserved.
//

#import "MyPlayProgressView.h"

/* 拖动按钮的宽度 */
#define kBtnWith 35

/* 整个bar的宽度 */
#define kMyPlayProgressViewWidth (self.frame.size.width - (kBtnWith*0.5)*2)
/* slider 的高度 */
#define  kPlayProgressBarHeight 2


@implementation MyPlayProgressView{
    
    UIView *_bgProgressView;         // 背景颜色
    UIView *_ableBufferProgressView; // 缓冲进度颜色
    UIView *_finishPlayProgressView; // 已经播放的进度颜色
    
    CGPoint _lastPoint;
    
    BOOL isMove;
    
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil) {
        // 转换坐标系
        CGPoint newPoint = [self.sliderBtn convertPoint:point fromView:self];
        // 判断触摸点是否在button上
        if (CGRectContainsPoint(self.sliderBtn.bounds, newPoint)) {
            view = self.sliderBtn;
        }
    }
    return view;
}


- (void)awakeFromNib{
    
    [super awakeFromNib];
     self.frame = CGRectMake(50, 0, UIScreen.mainScreen.bounds.size.width - 100, 3);
    self.isOnlyProgress = YES;
    [self setup];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.isOnlyProgress = YES;
        [self setup];
    }
    return self;
}


- (void)setup {
    
    _minimumValue = 0.f;
    _maximumValue = 1.f;
    
    self.backgroundColor = [UIColor clearColor];
    
    CGFloat showY = (self.frame.size.height - kPlayProgressBarHeight)*0.5;
    
    /* 背景 */
    _bgProgressView = [[UIView alloc] initWithFrame:CGRectMake(kBtnWith*0.5, showY, kMyPlayProgressViewWidth, kPlayProgressBarHeight)];
    _bgProgressView.backgroundColor = [UIColor darkGrayColor];
    [self addSubview:_bgProgressView];
    
    /* 缓存进度 */
    _ableBufferProgressView = [[UIView alloc] initWithFrame:CGRectMake(kBtnWith*0.5, showY, 0, kPlayProgressBarHeight)];
    _ableBufferProgressView.backgroundColor = [UIColor lightGrayColor];
    [self addSubview:_ableBufferProgressView];
    
    /* 播放进度 */
    _finishPlayProgressView = [[UIView alloc] initWithFrame:CGRectMake(kBtnWith*0.5, showY, 0, kPlayProgressBarHeight)];
    _finishPlayProgressView.backgroundColor = UIColor.cyanColor;
    [self addSubview:_finishPlayProgressView];
    
    /* 滑动按钮 */
    _sliderBtn = [[MyProgressSliderBtn alloc] initWithFrame:CGRectMake(0, showY, 35, 35)];
    [_sliderBtn setAdjustsImageWhenHighlighted:NO];
    _sliderBtn.backgroundColor = [UIColor clearColor];
     [_sliderBtn setImage:[UIImage imageNamed:@"progressSlider"] forState:UIControlStateNormal];
    
    CGPoint center = _sliderBtn.center;
    center.x = _bgProgressView.frame.origin.x;
    center.y = _finishPlayProgressView.center.y;
    _sliderBtn.center = center;
    
    
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panMoving:)];
    [_sliderBtn addGestureRecognizer:pan];
    //
    //                UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playBtnClicked)];
    //                [_sliderBtn addGestureRecognizer:tap];
    //        [_sliderBtn addTarget:self action:@selector(beiginSliderScrubbing) forControlEvents:UIControlEventTouchDown];
    //        [_sliderBtn addTarget:self action:@selector(endSliderScrubbing) forControlEvents:UIControlEventTouchCancel];
    //[_sliderBtn addTarget:self action:@selector(dragMoving:withEvent:) forControlEvents:UIControlEventTouchDragInside];
   // [_sliderBtn addTarget:self action:@selector(playBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    //        [_sliderBtn addTarget:self action:@selector(endSliderScrubbing) forControlEvents:UIControlEventTouchUpOutside];
    _lastPoint = _sliderBtn.center;
    [self addSubview:_sliderBtn];
}
- (void)setPlayProgressBackgoundColor:(UIColor *)playProgressBackgoundColor{
    if (_playProgressBackgoundColor != playProgressBackgoundColor) {
        _finishPlayProgressView.backgroundColor = playProgressBackgoundColor;
    }
    
}

- (void)setTrackBackgoundColor:(UIColor *)trackBackgoundColor{
    if (_trackBackgoundColor != trackBackgoundColor) {
        _ableBufferProgressView.backgroundColor = trackBackgoundColor;
    }
}

- (void)setProgressBackgoundColor:(UIColor *)progressBackgoundColor{
    if (_progressBackgoundColor != progressBackgoundColor) {
        _bgProgressView.backgroundColor = progressBackgoundColor;
    }
}

/**
 进度值
 */
- (void)setValue:(CGFloat)progressValue{
    
    _value = progressValue;
    
    CGFloat finishValue = _bgProgressView.frame.size.width * progressValue;
    CGPoint tempPoint = _sliderBtn.center;
    tempPoint.x =  _bgProgressView.frame.origin.x + finishValue;
    
    if (tempPoint.x >= _bgProgressView.frame.origin.x &&
        tempPoint.x <= (self.frame.size.width - (kBtnWith*0.5))){
        
        //        [UIView animateWithDuration:0.5 animations:^{
        //
        //        }];
        
        _sliderBtn.center = tempPoint;
        _lastPoint = _sliderBtn.center;
        
        CGRect tempFrame = _finishPlayProgressView.frame;
        tempFrame.size.width = tempPoint.x - kBtnWith*0.5;
        _finishPlayProgressView.frame = tempFrame;
        
    }
    
}

/**
 设置缓冲进度值
 */
-(void)setTrackValue:(CGFloat)trackValue{
    CGFloat finishValue = _bgProgressView.frame.size.width * trackValue;
    
    CGRect tempFrame = _ableBufferProgressView.frame;
    tempFrame.size.width = finishValue;
    _ableBufferProgressView.frame = tempFrame;
}


- (void)panMoving:(UIPanGestureRecognizer *)pan {
    
    CGPoint distance = [pan locationInView:_bgProgressView];
    CGFloat offsetX = distance.x - _lastPoint.x;
    CGPoint tempPoint = CGPointMake(_sliderBtn.center.x + offsetX, _sliderBtn.center.y);
    
    // 得到进度值
    CGFloat progressValue = (tempPoint.x - _bgProgressView.bounds.origin.x)*1.0f/_bgProgressView.frame.size.width;
    if (progressValue < 0) {
        progressValue = 0;
    }else if(progressValue > 1.0){
        progressValue = 1.0;
    }
    [self setValue:progressValue];
    
    
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:
        {
            
            [self beiginSliderScrubbing];
        }
            
            break;
        case UIGestureRecognizerStateChanged:
        {
            
            if (_delegate && [_delegate respondsToSelector:@selector(sliderScrubbing)]) {
                [_delegate sliderScrubbing];
            }
        }
            
            break;
        case UIGestureRecognizerStateEnded:
        {
            [self endSliderScrubbing];
        }
            
            break;
        default:
            break;
    }
    
}

/**
 拖动值发生改变
 */
//- (void) dragMoving: (UIButton *)btn withEvent:(UIEvent *)event{
//
//    CGPoint point = [[[event allTouches] anyObject] locationInView:self];
//    CGFloat offsetX = point.x - _lastPoint.x;
//    CGPoint tempPoint = CGPointMake(btn.center.x + offsetX, btn.center.y);
//
//    // 得到进度值
//    CGFloat progressValue = (tempPoint.x - _bgProgressView.frame.origin.x)*1.0f/_bgProgressView.frame.size.width;
//    [self setValue:progressValue];
//
//    isMove = YES;
//    if ([PlayerManager shareManeger].isPlay) {
//        [[PlayerManager shareManeger] pause];
//    }
//    [_delegate sliderScrubbing];
//}
// 开始拖动


- (void)beiginSliderScrubbing{
    
    if (_delegate && [_delegate respondsToSelector:@selector(beiginSliderScrubbing)]) {
        [_delegate beiginSliderScrubbing];
    }
}

- (void)playBtnClicked {
    
    if (_delegate && [_delegate respondsToSelector:@selector(playOrPause)] && !self.isOnlyProgress) {
        [_delegate playOrPause];
    }
}

// 结束拖动
- (void)endSliderScrubbing{
    if (_delegate && [_delegate respondsToSelector:@selector(endSliderScrubbing)]) {
        [_delegate endSliderScrubbing];
    }
}
@end


/**
 *  为了让拖动按钮变得更大
 */
@implementation MyProgressSliderBtn{
    UIImageView *_iconImageView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        //        _iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.frame.size.width - 17)*0.5,
        //                                                                       0.5*(self.frame.size.height - 17),
        //                                                                       17, 17)];
        //        _iconImageView.backgroundColor = [UIColor whiteColor];
        //        _iconImageView.layer.cornerRadius = _iconImageView.frame.size.height*0.5;
        //        _iconImageView.layer.masksToBounds = YES;
        //        [self addSubview:_iconImageView];
    }
    return self;
}

@end


