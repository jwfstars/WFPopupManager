//
//  DemoPopupController.m
//  WFPopupManager
//
//  Created by 江文帆 on 16/12/30.
//  Copyright © 2016年 江文帆. All rights reserved.
//

#import "DemoPopupController.h"

@interface DemoPopupController ()
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@end

@implementation DemoPopupController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.dismissButton.layer.cornerRadius = 4;
    self.dismissButton.showsTouchWhenHighlighted = YES;
    
    self.view.layer.cornerRadius = 4;
    self.view.layer.masksToBounds = YES;
    self.view.frame = CGRectMake(0, 0, 300, 400);
}

- (IBAction)onTapButton:(id)sender {
    if (self.onDismiss) {
        self.onDismiss();
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
