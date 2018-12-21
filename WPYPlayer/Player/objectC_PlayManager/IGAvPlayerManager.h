//
//  IGAvPlayerManager.h
//  ImGuider
//
//  Created by 王鹏宇 on 2017/10/12.
//  Copyright © 2017年 AudioCtrip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MPMediaItem.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>

typedef NS_ENUM(NSInteger,AVPlayerPlayState) {

    AVPlayerPlayStatePreparing = 0x0, // 准备播放
    AVPlayerPlayStateBeigin,       // 开始播放
    AVPlayerPlayStatePlaying,      // 正在播放
    AVPlayerPlayStatePause,        // 播放暂停
    AVPlayerPlayStateEnd,          // 播放结束
    AVPlayerPlayStateBufferEmpty,  // 没有缓存的数据供播放了
    AVPlayerPlayStateBufferToKeepUp,//有缓存的数据可以供播放

    AVPlayerPlayStateseekToZeroBeforePlay,

    AVPlayerPlayStateNotPlay,      // 不能播放
    AVPlayerPlayStateNotKnow       // 未知情况
};

@interface ScenicPoint : NSObject
@property (nonatomic, copy)NSString  * name;
@property (nonatomic, copy)NSString  * imageUrl;
@property (nonatomic, copy)NSString  * playpath;
@end


@protocol IGAvPlayerManagerDelegate <NSObject>

@optional

//改变播放状态
//- (void)changePlayStateWith:(AVPlayerPlayState)state;//因为多处用到  所以改发通知了
//更新进度条进度

- (void)updateProgressWith:(CGFloat)value;

//视频缓冲进度
- (void)updateBufferProgress:(NSTimeInterval)progress;

//顺序播放
- (void)sequentialPlay;

//上一曲 下一曲 切换界面的相应操作
- (void)changeScenicPointTo:(NSInteger)index;

//重置播放歌曲
- (void)resetPlayMusic;
@end
@interface IGAvPlayerManager : NSObject

@property (nonatomic, copy)NSString * currentURL;

@property (nonatomic, copy)NSString * currentTime;
@property (nonatomic, copy)NSString * durantion;

@property (nonatomic)NSTimeInterval totaltime;


@property (nonatomic)float progress;  //记录进度条位置
@property (nonatomic)BOOL isPlay;
@property (nonatomic, weak)id<IGAvPlayerManagerDelegate> delegate;
@property (nonatomic, strong)NSTimer *timer;
@property (nonatomic)BOOL isSeekingToTime;

@property (nonatomic)NSInteger currentIndex;
@property (nonatomic, strong) NSArray<ScenicPoint *> * dataSource;
@property (nonatomic,assign)NSInteger playType;//1 景点，线路  2 专题播放  3 试听  4 回答问题 5 其他



@property (nonatomic, assign)CGFloat playSpeed;//播放速度


+ (instancetype)shareManeger;

//播放音频的方法
- (void)playMusic:(NSInteger)index withIsPlay:(BOOL) isImmediately;//播放 数组类型的 如：类型 1 2

//播放音频的方法
- (void)playMusic:(NSString *)url withPlayType:(NSInteger)type;// 播放 单个音频类型 如:3 4 5

// 直接重新播放
- (void)resetPlayMusic;
//调整播放进度
- (void)musicSeekToTime:(float)time;


//暂停播放
- (void)pause;

//播放
- (void)play;
//停止播放
- (void)stop;

//下一曲
-(void)next;
// 上一曲
- (void)previous;

- (void)resetPlaySpeed;

- (NSString *)timeFormatted:(int)totalSeconds;
@end
