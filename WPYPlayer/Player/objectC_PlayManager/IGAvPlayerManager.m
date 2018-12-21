//
//  IGAvPlayerManager.m
//  ImGuider
//
//  Created by 王鹏宇 on 2017/10/12.
//  Copyright © 2017年 AudioCtrip. All rights reserved.
//

#import "IGAvPlayerManager.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>


#define kIGAvPlayerManagerState @"kIGAvPlayerManagerState"
#define kCurrentPlayURL @"CurrentPlayURL"
#define kPlayType @"kPlayType"


static void *kStatusKVOKey = &kStatusKVOKey;
static void *kDurationKVOKey = &kDurationKVOKey;
static void *kBufferingRatioKVOKey = &kBufferingRatioKVOKey;

@import AVFoundation;
@interface IGAvPlayerManager()

@property (nonatomic, strong)AVPlayer * player;
@property (nonatomic, strong)id  timeObserver;
@property (nonatomic)BOOL isEnterBackground;
@property (nonatomic)BOOL seekToZeroBeforePlay;
@property (nonatomic)BOOL isImmediately;
@property (nonatomic)BOOL isEmptyBufferPause;
@property (nonatomic)BOOL isFinish;
@property (nonatomic,strong) ScenicPoint * currentScenicPoint;
@property (nonatomic) UIBackgroundTaskIdentifier  bgTaskId;//后台播放任务ID
@property (nonatomic, strong)AVPlayerItem * playerItem;

@property (nonatomic, strong)NSURL * playUrl;


@end
@implementation IGAvPlayerManager


// 播放器单例

+ (instancetype)shareManeger {
    
    
    static IGAvPlayerManager *manager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        
    });
    return manager;
}



// 播放器初始化


- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configLockScreenPlay) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveCurrentPlayingTime) name:UIApplicationWillTerminateNotification object:nil];
        
        [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
        
        [self.player addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
        
        //开启后台处理多媒体事件
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        AVAudioSession  * session=[AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        //后台播放
        [session setCategory:AVAudioSessionCategoryPlayback error:nil];
        self.playSpeed = 1.0;
    }
    return self;
}



- (AVPlayer *)player {
    
    if (!_player) {
        
        _player = [[AVPlayer alloc] init];
        _player.volume = 2.0; // 默认最大音量
    }
    
    return _player;
}

- (void)setDataSource:(NSArray<ScenicPoint *> *)dataSource {
    
    _dataSource = [NSArray arrayWithArray:dataSource];
    if (!self.isPlay) {
        _playSpeed = 1.0f;
    }
}


- (void)resetPlaySpeed {
    _playSpeed = 1.0f;
}


//设置播放速度

- (void)setPlaySpeed:(CGFloat)playSpeed {
    
    if(self.isPlay){
        [self enableAudioTracks:YES inPlayerItem:_playerItem];
        self.player.rate = playSpeed;
    }
    _playSpeed = playSpeed;
    
}


#pragma mark -设置控制中心正在播放的信息

-(void)setNowPlayingInfo{
    
    if (self.currentScenicPoint ) {
        
        NSMutableDictionary *songDict=[NSMutableDictionary dictionary];
        [songDict setObject:self.currentScenicPoint.name forKey:MPMediaItemPropertyTitle];
        //        [songDict setObject:self.model.singerName forKey:MPMediaItemPropertyArtist];
        [songDict setObject:@(CMTimeGetSeconds(self.player.currentItem.currentTime)) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        [songDict setObject:@(1.0) forKey:MPNowPlayingInfoPropertyPlaybackRate];
        
        [songDict setObject:[NSNumber numberWithDouble:CMTimeGetSeconds(self.player.currentItem.duration)] forKeyedSubscript:MPMediaItemPropertyPlaybackDuration];
        
//        UIImage *image = [UIImageView imageFromDiskCacheForKey:self.currentScenicPoint.imageUrl];
//        if (image) {
//            //设置歌曲图片
//            MPMediaItemArtwork *imageItem=[[MPMediaItemArtwork alloc]initWithImage:image];
//            if (imageItem) {
//                [songDict setObject:imageItem forKey:MPMediaItemPropertyArtwork];
//            } else {
//
//            }
//        }else{
//
//            [UIImageView downloadImageWithURL:[NSURL URLWithString:self.currentScenicPoint.imageUrl] progress:nil completion:^(UIImage * _Nullable image, NSURL * _Nonnull url, YYWebImageFromType from, YYWebImageStage stage, NSError * _Nullable error) {
//
//                [self setNowPlayingInfo];
//            }];
//        }
        
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songDict];
    }
    
}



//在播放期间被电话 微信 打断的处理


- (void)handleInterreption:(NSNotification *)sender {
    
    NSDictionary *info = sender.userInfo;
    AVAudioSessionInterruptionType type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        [self pause];
    }else{
        AVAudioSessionInterruptionOptions options = [info[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
        if (options == AVAudioSessionInterruptionOptionShouldResume) {
            [self play];
            
        }
    }
    
}


// 消除前  移除观察

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.player removeObserver:self forKeyPath:@"rate"];
    [self.player removeObserver:self forKeyPath:@"currentItem"];
    
}


//  播放前添加监测 观察

- (void)currentItemAddObserver{
    
        //监听是否靠近耳朵
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorStateChange:) name:@"UIDeviceProximityStateDidChangeNotification" object:nil];
    
    
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [self.player.currentItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterreption:) name:AVAudioSessionInterruptionNotification object:[AVAudioSession sharedInstance]];
    //监控缓冲加载情况属性
    [self.player.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    
    //监控播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playMusicFinished) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    
    //监控时间进度
    __weak typeof(self) weakSelf = self;
    
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        NSTimeInterval current = CMTimeGetSeconds(time);
        weakSelf.progress = current;
        if (weakSelf.isSeekingToTime) {
            return ;
        }
        if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(updateProgressWith:)]) {
            
            [weakSelf.delegate updateProgressWith:current / self.totaltime];
        }
    }];
}



//  播放后  移除监测 观察


- (void)currentItemRemoveObserver {
    
    [self.player.currentItem removeObserver:self  forKeyPath:@"status"];
    
    [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceProximityStateDidChangeNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
    
    [self.player removeTimeObserver:self.timeObserver];
}



- (void)resetPlayMusic{
    
    //    if (self.currentScenicPoint) {
    //
    //        [self currentItemRemoveObserver];
    //
    //        NSString *localPath = [[DownloadManager sharedManager] localFilePathForURLString:self.currentScenicPoint.playpath];
    //
    //        NSURL * playURL = [NSURL URLWithString:self.currentScenicPoint.playpath];
    //        if (localPath.length > 0) {
    //            playURL = [NSURL fileURLWithPath:localPath];
    //        }
    //        self.isImmediately = NO;
    //        // 创建要播放的资源
    //        AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithURL:playURL];
    //        // 播放当前资源
    //        [self.player replaceCurrentItemWithPlayerItem:playerItem];
    //        [self currentItemAddObserver];
    //    }
    CMTime seekTime = CMTimeMake(0.f, 1);
    [self.player seekToTime:seekTime completionHandler:^(BOOL finished) {
        [self stop];
    }];
}





/**
 用于播放单个音频  如  试听   回答等

 @param url   播放链接
 @param type  根据自己需要
 
 */

- (void)playMusic:(NSString *)url withPlayType:(NSInteger)type{
    
    self.playType = type;
    _playSpeed = 1.0f;//回复正常倍速
    [self currentItemRemoveObserver];
    NSURL *playURL = [self loadAudioWithPlaypath:url];
    
    self.playUrl = playURL;
    // 创建要播放的资源
    AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithURL:playURL];
    self.playerItem = playerItem;
    self.currentURL = url;
    self.isImmediately = YES;
    [self pause];
    // 播放当前资源
    NSLog(@"--try--%@",playURL.absoluteString);
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nil];
    [self currentItemAddObserver];
}



/**
 用于播放多个，切连续音频

 @param index  第几个音频
 @param isImmediately 是否立即播放
 */



- (void)playMusic:(NSInteger)index withIsPlay:(BOOL)isImmediately{
    
    ScenicPoint * sceniPoint = self.dataSource[index];
    
    [self currentItemRemoveObserver];
    
    NSURL *playURL = [self loadAudioWithPlaypath:sceniPoint.playpath];
    self.playUrl = playURL;
    // 创建要播放的资源
    AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithURL:playURL];
    self.playerItem = playerItem;
    self.currentScenicPoint = sceniPoint;
    self.currentIndex = index;
    self.currentURL = self.currentScenicPoint.playpath;
    
    self.isImmediately = isImmediately;
    if (!isImmediately) {
        [self pause];
    }
    // 播放当前资源
    [self.player replaceCurrentItemWithPlayerItem:playerItem];
   
    [self currentItemAddObserver];

}



// 统一管理播放地址   本地 和 网络


- (NSURL *)loadAudioWithPlaypath:(NSString *)playpath {
        
    NSString *name = [playpath componentsSeparatedByString:@"/"].lastObject;
    
    if (name.length > 0) {
        
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:nil];
        
        if (path.length > 0) {
            
            return  [NSURL fileURLWithPath:path];
        }
    }
    
    
    return [NSURL URLWithString:playpath];
}


// 停止

- (void)stop {
    [self pause];
    self.isImmediately = NO;
    self.currentURL = nil;
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nil];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    
}


// 根据靠近耳朵距离   来切换播放模式

-(void)sensorStateChange:(NSNotificationCenter *)notification;
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *sessionError;
        
        
        if ([[UIDevice currentDevice] proximityState] == YES)
        {
            
            //靠近耳朵
            [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
        }
        else
        {
            //远离耳朵
            [session setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
        }
        
    });
}


//调整播放进度

- (void)musicSeekToTime:(float)time {
    
    NSTimeInterval interval =CMTimeGetSeconds(self.player.currentItem.duration);
    self.isSeekingToTime = YES;
    if (interval) {
        CMTime seekTime = CMTimeMake(time * interval, 1);
        
        [self.player seekToTime:seekTime completionHandler:^(BOOL finished) {
            self.isSeekingToTime = NO;
            [self setNowPlayingInfo];
        }];
        self.progress = time;
    }else {
        CMTime seekTime = CMTimeMake(0.f, 1);
        [self.player seekToTime:seekTime completionHandler:^(BOOL finished) {
            self.isSeekingToTime = NO;
            [self setNowPlayingInfo];
        }];
        self.progress = 0;
    }
    
}



//暂停播放
- (void)pause {
    self.isPlay = false;
    [self updateCurrentPlayStatus:AVPlayerPlayStatePause];
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    [_player pause];
    
    [self setNowPlayingInfo];
}



//播放
- (void)play {
    
    if ([self.playUrl.absoluteString hasPrefix:@"http"]) {
        
//        if (![AppManager sharedManager].allowWhenPlay && [AppManager sharedManager].networkState == AFNetworkReachabilityStatusReachableViaWWAN) {
//
//            [IGAlertView alertWithTitle:@"" message:MYLocalizedString(@"PUBLIC_NOWIFI_PLAY_ALERT_CONTENT", nil) cancelButtonTitle:MYLocalizedString(@"PUBLIC_CANCEL", nil) commitBtn:MYLocalizedString(@"PUBLIC_NOWIFI_PLAY_ALERT_COMMIT", nil) commit:^{
//
//                [AppManager sharedManager].allowWhenPlay = YES;
//
//                [self updateCurrentPlayStatus:AVPlayerPlayStatePlaying];
//                self.isPlay = true;
//                [_player play];
//                //改变播放倍速
//                [self enableAudioTracks:YES inPlayerItem:_playerItem];//要实现倍速必须实现该方法
//                self.player.rate = _playSpeed;
//
//            } cancel:nil];
//
//            return;
//        }
        
    }
    
    if (self.seekToZeroBeforePlay) {
        
        [self musicSeekToTime:0.f];
        [self updateCurrentPlayStatus:AVPlayerPlayStateseekToZeroBeforePlay];
        self.seekToZeroBeforePlay = NO;
    }
    [self updateCurrentPlayStatus:AVPlayerPlayStatePlaying];
    self.isPlay = true;
    
    //开启红外感应  及判断是否贴耳听
//    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    
    [_player play];
    //改变播放倍速
    [self enableAudioTracks:YES inPlayerItem:_playerItem];//要实现倍速必须实现该方法
    self.player.rate = _playSpeed;
    [self setNowPlayingInfo];
}


// 下一曲

-(void)next {
    
  
        NSInteger index = self.currentIndex + 1;
        NSInteger totalCount = self.dataSource.count;
        
        if (index >= totalCount) {
            
//            提示已是最后一个，做相应操作
            return;
        }
        
        
        [self changeScenicPointBy:index];
    }


// 上一曲

- (void)previous{
   
        NSInteger index = self.currentIndex - 1;
        
        if (index < 0 ) {
            
            // 提示已是第一个，做相应操作
            
            return;
        }
        
        [self changeScenicPointBy:index];
}



- (void)changeScenicPointBy:(NSInteger)index {
    
    [self playMusic:index withIsPlay:YES];
    
    if (_delegate && [_delegate respondsToSelector:@selector(changeScenicPointTo:)]) {
        [_delegate changeScenicPointTo:index];
    }
}



/**
 想改变 音频播放速率  必须实现的方法

 @param enable      ‘’
 @param playerItem  当前播放item
 */


- (void)enableAudioTracks:(BOOL)enable inPlayerItem:(AVPlayerItem*)playerItem
{
    
    for (AVPlayerItemTrack *track in playerItem.tracks)
    {
        if ([track.assetTrack.mediaType isEqual:AVMediaTypeAudio])
        {
            track.enabled = enable;
        }
    }
    
}


//app 进入后台后进行配置


-(void)configLockScreenPlay {
    
    //这样做，可以在按home键进入后台后 ，播放一段时间，几分钟吧。但是不能持续播放网络歌曲，若需要持续播放网络歌曲，还需要申请后台任务id，具体做法是：
    _bgTaskId=[self backgroundPlayerID:_bgTaskId];
    //其中的_bgTaskId是后台任务UIBackgroundTaskIdentifier _bgTaskId;
}


- (UIBackgroundTaskIdentifier)backgroundPlayerID:(UIBackgroundTaskIdentifier)backTaskId
{
    //设置并激活音频会话类别
    AVAudioSession *session=[AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
    //允许应用程序接收远程控制
    if (self.isPlay) {
        
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }
    //设置后台任务ID
    UIBackgroundTaskIdentifier newTaskId=UIBackgroundTaskInvalid;
    newTaskId=[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    if(newTaskId!=UIBackgroundTaskInvalid&&backTaskId!=UIBackgroundTaskInvalid)
    {
        [[UIApplication sharedApplication] endBackgroundTask:backTaskId];
    }
    return newTaskId;
}




/**
   单个音频播放结束后的 罗杰处理
 */

- (void)playMusicFinished {
    
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    self.seekToZeroBeforePlay = YES;
    self.isPlay = NO;
    [self updateCurrentPlayStatus:AVPlayerPlayStateEnd];
    
    [self next];
    
}



#pragma kvo


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [change[@"new"] integerValue];
        switch (status) {
            case AVPlayerItemStatusReadyToPlay:
            {
                
                
                if (!_isEnterBackground) {
                    
                    if (self.isImmediately) {
                        
                        [self play];
                        
                        
                       // [self updateCurrentPlayStatus:AVPlayerPlayStateBeigin];
                    }
                    
                }else {
                    _isEnterBackground = NO;
                }
            }
                break;
            case AVPlayerItemStatusFailed:
            {
                AVPlayerItem *playerItem = (AVPlayerItem *)object;
                
                
                
                [self avplayerFalileWith:playerItem.error];
                
            }
                break;
            case AVPlayerItemStatusUnknown:
            {
                // [self currentItemRemoveObserver];
                [self updateCurrentPlayStatus:AVPlayerPlayStateNotPlay];
            }
                break;
            default:
                break;
        }
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray *array=playerItem.loadedTimeRanges;
        //本次缓冲时间范围
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        //缓冲总长度
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;
        
        [self updateAVPlayerAvailabel:totalBuffer];
        
    }else if([keyPath isEqualToString:@"playbackBufferEmpty"]){
        
    }else if([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){
        
    }else if([keyPath isEqualToString:@"rate"]){
        
        
        //        if (self.player.rate == 0) {
        //
        //            //缓冲不够暂停
        //            if (!_isForcusPause) {
        //                [self updateCurrentPlayStatus:AVPlayerPlayStatePreparing];
        //                _isEmptyBufferPause = YES;
        //            }else {
        //                [self updateCurrentPlayStatus:AVPlayerPlayStatePause];
        //            }
        //        }
        //
        //        /**
        //         *  播放都一样
        //         */
        //        if (self.player.rate == 1) {
        //            _isForcusPause = NO;
        //            _isEmptyBufferPause = NO;
        //            //IGLog(@"self.mPlayer.rate == 1----AVPlayerPlayStatePreparing");
        //            [self play];
        //            [self updateCurrentPlayStatus:AVPlayerPlayStateBeigin];
        //        }
        
    }else if([keyPath isEqualToString:@"currentItem"]){
        
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        if (newPlayerItem == (id)[NSNull null]){
            [self updateCurrentPlayStatus:AVPlayerPlayStateNotPlay];
            
        }
    }
}




- (void)updateAVPlayerAvailabel:(float)totalBuffer{
    
    NSTimeInterval duration = self.totaltime;
    double progress = 0;
    if (duration != 0) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(updateBufferProgress:)]) {
            progress = totalBuffer / duration;
            [self.delegate updateBufferProgress:progress];
        }
        
        /**
         *  如果因为缓冲被暂停的，如果缓冲值已经够了，需要重新播放
         */
        float minValue = 0;
        float maxValue = 1;
        double time = CMTimeGetSeconds([self.player currentTime]);
        double sliderProgress = (maxValue - minValue) * time / duration + minValue;
        
        /**
         *  当前处于缓冲不够暂停状态时
         */
        if ((progress - sliderProgress) > 0.01 &&
            self.player.rate == 0 &&
            _isEmptyBufferPause) {
            
            [self play];
        }
    }
}



- (void)updateCurrentPlayStatus:(AVPlayerPlayState)state {
    // IGLog(@"-----%@",self.currentURL);
    
    if (self.currentURL) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kIGAvPlayerManagerState  object:nil userInfo:@{kIGAvPlayerManagerState : @(state),kCurrentPlayURL:self.currentURL,kPlayType:@(self.playType)}];
    }else{
        [[NSNotificationCenter defaultCenter] postNotificationName:kIGAvPlayerManagerState  object:nil userInfo:@{kIGAvPlayerManagerState : @(state),kCurrentPlayURL:@"nil",kPlayType:@(self.playType)}];
    }
    
}

- (void)avplayerFalileWith:(NSError *)error{
    
    
    if (!error) {
        return;
    }
    [self updateCurrentPlayStatus:AVPlayerPlayStateNotPlay];
    /* Display the error. */
    //    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
    //                                                        message:[IGUtil tipFromError:error]
    //                                                       delegate:nil
    //                                              cancelButtonTitle:MYLocalizedString(@"PUBLIC_OK", nil)
    //                                              otherButtonTitles:nil];
    //    [alertView show];
}



- (NSString *)currentTime {
    //当前播放进度
    NSTimeInterval current = CMTimeGetSeconds(self.player.currentItem.currentTime);
    return [self timeFormatted:(int)current];
}

- (NSTimeInterval)totaltime {
    
    //视频的总长度
    NSTimeInterval total = CMTimeGetSeconds(self.player.currentItem.duration);
    
    if (total>0) {
        _totaltime = total;
    }else {
        _totaltime = 0;
    }
    
    
    return _totaltime;
}
- (NSString *)durantion {
    
    //当前播放进度
//    NSTimeInterval current = CMTimeGetSeconds(self.player.currentItem.currentTime);
//    //视频总长度
//    NSTimeInterval total =   -current ;
    return [self timeFormatted:self.totaltime];
}

#pragma mark - 时间转换

- (NSString *)timeFormatted:(int)totalSeconds {
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60);
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

@end

