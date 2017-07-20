//
//  DemoPopupController.h
//  WFPopupManager
//
//  Created by 江文帆 on 16/12/30.
//  Copyright © 2016年 江文帆. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DemoPopupController : UIViewController
@property (nonatomic,   copy) dispatch_block_t onDismiss;
@end
