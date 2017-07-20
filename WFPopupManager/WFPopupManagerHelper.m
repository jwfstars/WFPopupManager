//
//  WFPopupManagerHelper.m
//  WFPopupManager
//
//  Created by 江文帆 on 2017/7/20.
//  Copyright © 2017年 江文帆. All rights reserved.
//

#import "WFPopupManagerHelper.h"

@implementation UIView (WFFrame)

- (CGFloat)wf_height
{
    return self.frame.size.height;
}

- (CGFloat)wf_width
{
    return self.frame.size.width;
}

- (void)setWf_height:(CGFloat)wf_height {
    CGRect frame = self.frame;
    frame.size.height = wf_height;
    self.frame = frame;
}
- (void)setWf_width:(CGFloat)wf_width {
    CGRect frame = self.frame;
    frame.size.width = wf_width;
    self.frame = frame;
}

- (CGFloat)wf_x
{
    return self.frame.origin.x;
}

- (void)setWf_x:(CGFloat)wf_x {
    CGRect frame = self.frame;
    frame.origin.x = wf_x;
    self.frame = frame;
}

- (CGFloat)wf_y
{
    return self.frame.origin.y;
}

- (void)setWf_y:(CGFloat)wf_y {
    CGRect frame = self.frame;
    frame.origin.y = wf_y;
    self.frame = frame;
}

- (void)setWf_centerX:(CGFloat)wf_centerX {
    CGPoint center = self.center;
    center.x = wf_centerX;
    self.center = center;
}

- (CGFloat)wf_centerX
{
    return self.center.x;
}

- (void)setWf_centerY:(CGFloat)wf_centerY {
    CGPoint center = self.center;
    center.y = wf_centerY;
    self.center = center;
}

- (CGFloat)wf_centerY
{
    return self.center.y;
}

@end

CGFloat WFScreenHeight(void)
{
    CGRect rect = [[UIScreen mainScreen] bounds];
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationLandscapeLeft == orientation || UIInterfaceOrientationLandscapeRight == orientation) {
        return rect.size.width > rect.size.height ? rect.size.height : rect.size.width;
    } else {
        return rect.size.width > rect.size.height ? rect.size.width : rect.size.height;
    }
}

CGFloat WFScreenWidth(void)
{
    CGRect rect = [[UIScreen mainScreen] bounds];
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationLandscapeLeft == orientation || UIInterfaceOrientationLandscapeRight == orientation) {
        return rect.size.width > rect.size.height ? rect.size.width : rect.size.height;
    } else {
        return rect.size.width > rect.size.height ? rect.size.height : rect.size.width;
    }
}
