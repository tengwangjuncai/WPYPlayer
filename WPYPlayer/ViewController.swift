//
//  ViewController.swift
//  WPYPlayer
//
//  Created by 王鹏宇 on 12/13/18.
//  Copyright © 2018 王鹏宇. All rights reserved.
//

import UIKit
import Kingfisher


class ViewController: UIViewController,WPY_AVPlayerDelegate,MyPlayProgressViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource {
   
    
    var manager:WPY_AVPlayer = WPY_AVPlayer.playManager
    var recordArray:[Record]?
    var currentSpeed:Float = 1.0
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var progress: MyPlayProgressView!
    @IBOutlet weak var rateBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var preBtn: UIButton!
    @IBOutlet weak var currenttimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        self.setup()
        self.loadData()
       
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    func setup(){
        
        self.bgImageView.kf.setImage(with: URL(string: "http://cncdn.imguider.com/upload/images/20170620/1497971674022.jpg?x-oss-process=style/750x750"), placeholder: UIImage(named: ""), options: nil, progressBlock: nil) { (Image, _, _, _) in
            self.bgImageView.image = self.bgImageView.image?.blurredImage(withRadius: 30, iterations: 15, tintColor: UIColor.black)
        }
        self.manager.delegate = self;
        
       NotificationCenter.default.addObserver(self, selector: #selector(playBarChangePlayStateWith(notif:)), name: NSNotification.Name(rawValue: WPY_PlayerState), object: nil)
        
        self.progress.delegate = self;
        
        self.collectionView.register(UINib(nibName: "ItemCell", bundle: nil), forCellWithReuseIdentifier: "ItemCell");
        
        if let  layout = self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout{
            
            layout.itemSize = CGSize(width: UIScreen.main.bounds.width, height:UIScreen.main.bounds.height - 120)
            layout.minimumLineSpacing = 0.001
            layout.minimumInteritemSpacing = 0.001
        }
        
        
        
    }
    
    func setupSpeed(){
        
        self.currentSpeed = WPY_AVPlayer.playManager.playSpeed
        var str = "1.0x"
        if self.currentSpeed == 1.25 {
            str = "1.25x"
        }else if self.currentSpeed == 1.5{
            str = "1.5x"
        }
        
        rateBtn.setTitle(str, for: UIControl.State.normal)
    }
    
    func loadData(){
        
        let arr = [["imageUrl" : "http://cncdn.imguider.com/upload/images/20170620/1497971674022.jpg?x-oss-process=style/750x750","playpath":"http://cncdn.imguider.com/upload/records/20170901/b15988dc-8ed0-4500-aa45-2e7b92d73207.mp3"],["imageUrl" : "http://cncdn.imguider.com/upload/images/20170620/1497971705060.jpg?x-oss-process=style/750x750","playpath":"http://cncdn.imguider.com/upload/records/20170901/6ee9b58a-1bad-4a35-8b25-7417125f4993.mp3"],["imageUrl" : "http://cncdn.imguider.com/upload/images/20170621/1498049071704.jpg?x-oss-process=style/750x750","playpath":"http://cncdn.imguider.com/upload/records/20170901/f8bed23e-5f78-4931-af37-66b76c38c147.mp3"],["imageUrl" : "http://cncdn.imguider.com/upload/images/20170620/1497973852573.jpg?x-oss-process=style/750x750","playpath":"http://cncdn.imguider.com/upload/records/20170901/9390cfb5-fba1-411a-94a7-2f5d2ea93ff8.mp3"],["imageUrl" : "http://cncdn.imguider.com/upload/images/20170620/1497973755359.jpg?x-oss-process=style/750x750","playpath":"http://cncdn.imguider.com/upload/records/20170901/e237a3ed-d698-40b6-adcd-4a6f5bf6e660.mp3"]]
        
        recordArray = Array<Record>();
        
        for  var item in arr {
            
            let record = Record()
            record.imageUrl = item["imageUrl"]
            record.playpath = item["playpath"]
            recordArray?.append(record)
        }
        
        manager.musicArray = recordArray ?? []
        
        self.manager.playTheLine(index: 0, isImmediately: false)
        
        self.collectionView.reloadData()
    }

    @IBAction func PalyOrPause(_ sender: UIButton) {
        
        if manager.isPlay {
           self.manager.pause()
        }else{
            
            self.manager.play()
        }
    }
    
    
    @IBAction func preRecord(_ sender: UIButton) {
        
        self.manager.previous()
    }
    
    @IBAction func nextRecord(_ sender: UIButton) {
        self.manager.next()
    }
    
    @IBAction func changeRate(_ sender: UIButton) {
        
        if self.currentSpeed == 1.0 {
            rateBtn.setTitle("1.25x", for: UIControl.State.normal)
            self.currentSpeed = 1.25
            manager.playSpeed = 1.25
        }else if self.currentSpeed == 1.25 {
            rateBtn.setTitle("1.5x", for: UIControl.State.normal)
            self.currentSpeed = 1.5
            manager.playSpeed = 1.5
        }else if(self.currentSpeed == 1.5){
            rateBtn.setTitle("1.0x", for: UIControl.State.normal)
            self.currentSpeed = 1.0
            self.manager.playSpeed = 1.0
        }
        
    }
    
    
    
}


extension ViewController{
    
    
    //MyPlayProgressViewDelegate
    
    func beiginSliderScrubbing() {
        
        self.manager.isSeekingToTime = true
    }
    
    func endSliderScrubbing() {
        
        if let value = self.progress?.value {
            
            self.manager.musicSeekToTime(time: Float(value))
        }
    }
    
    func sliderScrubbing() {
        
        let total = self.manager.durantion
        
        let time = self.progress.value * CGFloat(total)
        
        self.currenttimeLabel.text = self.manager.timeFormatted(totalSeconds: total - Double(time))
    }
    
    
    
    
    
    
    func updateProgressWith(progress: Float) {
        
        self.progress.value = CGFloat(progress)
        self.totalTimeLabel.text = self.manager.totalTime
        self.currenttimeLabel.text = self.manager.currentTime
    }
    
    func changeMusicToIndex(index: Int) {
        
        let record = self.recordArray?[index]
        
//        self.bgImageView.kf.setImage(with: URL(string: record?.imageUrl ?? ""))
        
        self.bgImageView.kf.setImage(with: URL(string: record?.imageUrl ?? ""), placeholder: UIImage(named: ""), options: nil, progressBlock: nil) { (Image, _, _, _) in
            self.bgImageView.image = self.bgImageView.image?.blurredImage(withRadius: 30, iterations: 15, tintColor: UIColor.black)
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        
        self.collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.left, animated: true)
    }
    
    func updateBufferProgress(progress: Float) {
        //swift 初始化有问题，不判断为空时会p崩溃
        if progress.isNaN || progress.isInfinite {
            return
        }
        self.progress.trackValue = CGFloat(progress)
        self.totalTimeLabel.text = self.manager.totalTime
    }
    
    
    @objc func  playBarChangePlayStateWith(notif : Notification){
        
        
        //        let url = notif.userInfo?[CurrentPlayUrl]
        if let type = notif.userInfo?[PlayType] as? WPY_AVPlayerType,type != .PlayTypeLine {
            self.progress.value = 0.0
            self.playBtn.setBackgroundImage(UIImage(named: "bofang-2"), for: UIControl.State.normal)
        }
        
        guard let state = notif.userInfo?[WPY_PlayerState] as? AVPlayerPlayState else {return}
        
        switch state {
        case AVPlayerPlayState.AVPlayerPlayStatePreparing,AVPlayerPlayState.AVPlayerPlayStateBeigin:
            
            self.playBtn.setBackgroundImage(UIImage(named: "bofang-3"), for: UIControl.State.normal)
        case AVPlayerPlayState.AVPlayerPlayStatePlaying:
            
            self.playBtn.setBackgroundImage(UIImage(named: "bofang-3"), for: UIControl.State.normal)
        case .AVPlayerPlayStatePause:
            
            self.playBtn.setBackgroundImage(UIImage(named: "bofang-2"), for: UIControl.State.normal)
        case .AVPlayerPlayStateEnd:
            self.totalTimeLabel.text = "00:00"
            self.playBtn.setBackgroundImage(UIImage(named: "bofang-2"), for: UIControl.State.normal)
            
        case .AVPlayerPlayStateNotPlay:
            self.totalTimeLabel.text = ""
            self.currenttimeLabel.text = ""
            self.progress.value = 0.0
            self.playBtn.setBackgroundImage(UIImage(named: "bofang-2"), for: UIControl.State.normal)
        case .AVPlayerPlayStateseekToZeroBeforePlay:
            self.progress.value = 0.0
            
        default:
            
            self.playBtn.setBackgroundImage(UIImage(named: "bofang-2"), for: UIControl.State.normal)
        }
    }
}


// UICollectionViewDelegate,UICollectionViewDataSource

extension ViewController {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let index = Int(scrollView.contentOffset.x / UIScreen.main.bounds.width)
        
        let record = self.recordArray?[index]
        
        self.bgImageView.kf.setImage(with: URL(string: record?.imageUrl ?? ""), placeholder: UIImage(named: ""), options: nil, progressBlock: nil) { (Image, _, _, _) in
          self.bgImageView.image =  self.bgImageView.image?.blurredImage(withRadius: 30, iterations: 15, tintColor: UIColor.black)
        }
        self.manager.playTheLine(index: index, isImmediately: true)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.recordArray?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: "ItemCell", for: indexPath) as? ItemCell else{return ItemCell()}
        
        let record = self.recordArray?[indexPath.row]
        
        cell.itemIcon.kf.setImage(with: URL(string:record?.imageUrl ?? ""))
        cell.url = record?.playpath ?? "-"
        
        return cell;
    }
}
