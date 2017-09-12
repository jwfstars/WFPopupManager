//
//  WFPopupManager.h
//  WFPopupManager
//
//  Created by 江文帆 on 2017/7/20.
//  Copyright © 2017年 江文帆. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, WFPopupAnimationType) {
    WFPopupAnimationDefault = 0,
    WFPopupAnimationDropDown = 1,
    WFPopupAnimationActionSheet = 2
};

@interface WFPopupManager : NSObject
@property (nonatomic, strong, readonly) UIWindow *window;
@property (nonatomic, assign) BOOL transparanteMask;
@property (nonatomic, assign) BOOL canNotDismissByTouchMask;

+ (instancetype)sharedManager;

- (void)showWithViewController:(UIViewController *)viewController;

- (void)showWithViewController:(UIViewController *)viewController withAnimation:(WFPopupAnimationType)type;

- (void)dismiss;

- (void)dismissOnComplete:(dispatch_block_t)complete;

- (void)setOffsetY:(CGFloat)offset animated:(BOOL)animated;

- (void)clear;

- (void)setCenterViewFrame:(CGRect)frame;
@end


@interface UIViewController (WFPopupManager)

- (void)wf_dismiss;

@end

