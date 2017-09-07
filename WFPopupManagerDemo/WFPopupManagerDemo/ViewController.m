//
//  ViewController.m
//  WFPopupManagerDemo
//
//  Created by 江文帆 on 2017/7/20.
//  Copyright © 2017年 江文帆. All rights reserved.
//

#import "ViewController.h"
#import "WFPopupManager.h"
#import "DemoPopupController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *showButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.showButton.showsTouchWhenHighlighted = YES;
}

- (IBAction)show:(id)sender {
    DemoPopupController *demo = [DemoPopupController new];
    [WFPopupManager sharedManager].transparanteMask = NO;
    [[WFPopupManager sharedManager] showWithViewController:demo];
    demo.onDismiss = ^{
        [[WFPopupManager sharedManager] dismiss];
    };
}

@end
