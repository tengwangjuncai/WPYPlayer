//
//  ItemCell.swift
//  WPYPlayer
//
//  Created by 王鹏宇 on 12/19/18.
//  Copyright © 2018 王鹏宇. All rights reserved.
//

import UIKit


class ItemCell: UICollectionViewCell {

    @IBOutlet weak var itemIcon: UIImageView!
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var pointView: UIView!
    
    @IBOutlet weak var maskImageView: UIImageView!
    var url:String = ""
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.itemIcon.layer.cornerRadius = (UIScreen.main.bounds.width - 140)/2;
        self.itemIcon.clipsToBounds = true;
        self.maskImageView.layer.cornerRadius = (UIScreen.main.bounds.width - 136)/2
        
        self.itemIcon.layer.shadowOpacity = 1.0
        self.itemIcon.layer.shadowRadius = 20
        self.itemIcon.layer.shadowColor = UIColor.black.cgColor
        self.itemIcon.layer.shadowOffset = CGSize(width: 0, height: 20)
        self.itemIcon.layer.shadowPath = UIBezierPath(roundedRect: self.itemIcon.bounds, cornerRadius: 5).cgPath
    
        NotificationCenter.default.addObserver(self, selector: #selector(playBarChangePlayStateWith(notif:)), name: Notification.Name(rawValue: "WPY_PlayerState"), object: nil)
        
      
    }
    
    func start(){

        self.itemIcon.layer.removeAllAnimations()
        //让其在z轴旋转
        let rotationAnimation  = CABasicAnimation(keyPath: "transform.rotation.z")
        
        //旋转角度
        rotationAnimation.toValue = NSNumber(value:  Double.pi )
        
        //旋转周期
        rotationAnimation.duration = 10;
        
        //旋转累加角度
        rotationAnimation.isCumulative = true;
        
        //旋转次数
        rotationAnimation.repeatCount = Float(NSNotFound);
        
        self.itemIcon.layer.add(rotationAnimation, forKey: "rotationAnimation")
        
       
       
    }
    
    
    func stop(){
       self.itemIcon.layer.removeAllAnimations()
    }
    
    @objc func circel(){
        
       
    }
    
    
    @objc func  playBarChangePlayStateWith(notif : Notification){


        let url = notif.userInfo?[CurrentPlayUrl] as! String
        
        if url == self.url {
            guard let state = notif.userInfo?[WPY_PlayerState] as? AVPlayerPlayState else {return}
            
            switch state {
            case AVPlayerPlayState.AVPlayerPlayStatePreparing,AVPlayerPlayState.AVPlayerPlayStateBeigin,.AVPlayerPlayStatePlaying:
                self.start()
                
                
            default: self.stop()
                
            }
        }
    }
    

}


extension CALayer {
    //暂停动画
    func pauseAnimation() {
        
    let pauseTime = convertTime(CACurrentMediaTime(), from: nil)
    speed = 0.0
    timeOffset = pauseTime
    }
    
    //恢复动画
    
    func resumeAnimation() {
    // 1.取出时间
    let pauseTime = timeOffset
    // 2.设置动画的属性
    speed = 1.0
    timeOffset = 0.0
    beginTime = 0.0
    // 3.设置开始动画
let startTime = convertTime(CACurrentMediaTime(), from: nil) - pauseTime
    beginTime = startTime
   }
    
    
}



