//
//  UIImage+BlurView.h
//  ImGuider
//
//  Created by llt on 2017/7/17.
//  Copyright © 2017年 imguider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (BlurView)

- (UIImage *)blurredImageWithRadius:(CGFloat)radius iterations:(NSUInteger)iterations tintColor:(UIColor *)tintColor;

@end
