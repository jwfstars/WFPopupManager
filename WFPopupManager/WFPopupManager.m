//
//  WFPopupManager.m
//  WFPopupManager
//
//  Created by 江文帆 on 2017/7/20.
//  Copyright © 2017年 江文帆. All rights reserved.
//

#import "WFPopupManager.h"
#import "WFPopupManagerHelper.h"
#import <objc/runtime.h>

#define WF_POP_MASK_COLOR [[UIColor blackColor] colorWithAlphaComponent:.5f]

#define WF_ADD_DYNAMIC_PROPERTY(PROPERTY_TYPE,PROPERTY_NAME,SETTER_NAME) \
@dynamic PROPERTY_NAME ; \
static char kProperty##PROPERTY_NAME; \
- ( PROPERTY_TYPE ) PROPERTY_NAME \
{ \
return ( PROPERTY_TYPE ) objc_getAssociatedObject(self, &(kProperty##PROPERTY_NAME ) ); \
} \
\
- (void) SETTER_NAME :( PROPERTY_TYPE ) PROPERTY_NAME \
{ \
objc_setAssociatedObject(self, &kProperty##PROPERTY_NAME , PROPERTY_NAME , OBJC_ASSOCIATION_RETAIN); \
}

@interface WFPopupRootController : UIViewController

@end

@implementation WFPopupRootController
- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }else {
        return UIInterfaceOrientationMaskPortrait;
    }
}
@end

@interface WFPopupContainer : UIView

@end

@implementation WFPopupContainer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 2;
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)addSubview:(UIView *)view
{
    self.bounds = view.bounds;
    [super addSubview:view];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil) {
        for (UIView *subView in self.subviews.firstObject.subviews) {
            CGPoint p = [subView convertPoint:point fromView:self];
            if (CGRectContainsPoint(subView.bounds, p)) {
                view = subView;
            }
        }
    }
    return view;
}
@end


@interface UIViewController (WFPopAnimation)
@property (nonatomic, assign)  WFPopupAnimationType animationType;
@property (nonatomic, strong) NSNumber *transparanteMask;
@property (nonatomic, strong) NSNumber *canNotDismissByTouchMask;
@property (nonatomic, strong) NSNumber *isOld;
@end

@implementation UIViewController (WFPopAnimation)


WF_ADD_DYNAMIC_PROPERTY(NSNumber *, transparanteMask, setTransparanteMask)
WF_ADD_DYNAMIC_PROPERTY(NSNumber *, canNotDismissByTouchMask, setCanNotDismissByTouchMask)
WF_ADD_DYNAMIC_PROPERTY(NSNumber *, isOld, setIsOld)

static NSString *WFPopupAnimationTypeKey;
- (WFPopupAnimationType)animationType
{
    return [objc_getAssociatedObject(self, &WFPopupAnimationTypeKey) integerValue];
}

- (void)setAnimationType:(WFPopupAnimationType)animationType
{
    objc_setAssociatedObject(self, &WFPopupAnimationTypeKey, @(animationType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

#pragma mark - PopupManager

@interface WFPopupManager ()
@property (nonatomic, strong) WFPopupContainer *popupViewContainer;
@property (nonatomic, strong) UIView *mask;
@property (nonatomic, strong) UIViewController *currentPopupController;
@property (nonatomic, strong) UITapGestureRecognizer *tapMaskGesture;

@property (nonatomic, strong) NSMutableArray *popupQueue;
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) WFPopupRootController *rootController;
@end

@implementation WFPopupManager

static WFPopupManager *_instance;
+ (instancetype)sharedManager
{
    if (_instance == nil) {
        _instance = [[self alloc] init];
    }
    return _instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

- (NSMutableArray *)popupQueue
{
    if (_popupQueue == nil) {
        _popupQueue = [[NSMutableArray alloc]init];
    }
    return _popupQueue;
}

- (UITapGestureRecognizer *)tapMaskGesture
{
    if (!_tapMaskGesture) {
        _tapMaskGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismiss)];
    }
    return _tapMaskGesture;
}

- (void)setup
{
    if (!self.window) {
        self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.window.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.window.windowLevel = UIWindowLevelAlert;
        // WFPopupManager 标识tag
        self.window.tag = 6666;
    }
    if (!self.rootController) {
        self.rootController = [WFPopupRootController new];
        self.rootController.view.userInteractionEnabled = NO;
        self.window.rootViewController = self.rootController;
    }
    if (!self.mask) {
        self.mask = [[UIView alloc]initWithFrame:_window.bounds];
        self.mask.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.window addSubview:self.mask];
        self.mask.userInteractionEnabled = YES;
    }
    if (!self.popupViewContainer) {
        self.popupViewContainer = [WFPopupContainer new];
        [self.window addSubview:self.popupViewContainer];
    }
}

- (void)showWithViewController:(UIViewController *)viewController
{
    [self showWithViewController:viewController withAnimation:WFPopupAnimationDefault];
}

- (void)showWithViewController:(UIViewController *)viewController withAnimation:(WFPopupAnimationType)type
{
    if (!viewController) {
        return;
    }
    
    if (![viewController.isOld boolValue]) {
        viewController.animationType = type;
        viewController.canNotDismissByTouchMask = @(self.canNotDismissByTouchMask);
        viewController.transparanteMask = @(self.transparanteMask);
    }
    
    if (self.currentPopupController) {
        viewController.isOld = @YES;
        if (![self.popupQueue containsObject:viewController]) {
            [self.popupQueue addObject:viewController];
        }
    }else {
        [self _showWithViewController:viewController];
    }
}

- (void)_showWithViewController:(UIViewController *)viewController
{
    [self setup];
    
    self.mask.backgroundColor = WF_POP_MASK_COLOR;
    [self.mask removeGestureRecognizer:self.tapMaskGesture];
    
    if (![viewController.canNotDismissByTouchMask boolValue]) {
        [self.mask addGestureRecognizer:self.tapMaskGesture];
    }
    
    viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.currentPopupController = viewController;
    [self.popupViewContainer addSubview:viewController.view];
    [_window makeKeyAndVisible];
    
    switch (viewController.animationType) {
        case WFPopupAnimationDefault: {
            [self animationWithDefault];
            break;
        }
        case WFPopupAnimationDropDown: {
            [self animationWithDropDown];
            break;
        }
        case WFPopupAnimationActionSheet: {
            [self animationWithActionSheet];
            break;
        }
    }
}

- (void)animationWithDefault
{
    self.popupViewContainer.frame = self.currentPopupController.view.bounds;
    self.popupViewContainer.center = CGPointMake(_window.wf_width/2, _window.wf_height/2);
    self.popupViewContainer.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
    self.mask.alpha = 0;
    self.mask.backgroundColor = [self.currentPopupController.transparanteMask boolValue] ? [UIColor clearColor] : WF_POP_MASK_COLOR;
    self.popupViewContainer.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.mask.alpha = 1;
        self.popupViewContainer.alpha = 1;
    }];
    self.popupViewContainer.transform = CGAffineTransformMakeScale(1.3, 1.3);
    [UIView animateWithDuration:0.6 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:0 options:UIViewAnimationOptionTransitionNone animations:^{
        self.popupViewContainer.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)animationWithDropDown
{
    self.popupViewContainer.frame = CGRectMake(0, 0, 260, 320);
    self.popupViewContainer.center = CGPointMake(_window.wf_width/2, _window.wf_height/2);
    self.mask.alpha = 0;
    self.mask.backgroundColor = [self.currentPopupController.transparanteMask boolValue] ? [UIColor clearColor] : WF_POP_MASK_COLOR;
    self.popupViewContainer.alpha = 1.0f;
    self.popupViewContainer.wf_height = .0f;
    self.popupViewContainer.wf_y = 64.0f;
    [UIView animateWithDuration:0.3 animations:^{
        self.mask.alpha = 1;
        self.popupViewContainer.wf_height = 400.0f;
    }];
}

- (void)animationWithActionSheet
{
    self.mask.alpha = 0;
    self.mask.backgroundColor = [self.currentPopupController.transparanteMask boolValue] ? [UIColor clearColor] : WF_POP_MASK_COLOR;
    self.popupViewContainer.alpha = 1.0f;
    self.popupViewContainer.frame = CGRectMake(0, WFScreenHeight(), WFScreenWidth(), self.currentPopupController.view.wf_height);
    self.currentPopupController.view.wf_x = 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.mask.alpha = 1;
        self.popupViewContainer.wf_y = WFScreenHeight() - self.currentPopupController.view.wf_height;
    }];
}

- (void)dismiss
{
    [self dismissOnComplete:nil];
}

- (void)dismissOnComplete:(dispatch_block_t)complete
{
//    NSTimeInterval dutation = .0f;
//    if (self.currentPopupController) {
//        dutation = 0.3;
//    }
    [UIView animateWithDuration:0.3f animations:^{
        if (self.currentPopupController.animationType == WFPopupAnimationActionSheet) {
            self.popupViewContainer.wf_y = WFScreenHeight();
        }else {
            self.popupViewContainer.alpha = 0;
        }
        self.mask.alpha = 0;
    } completion:^(BOOL finished) {
        [self clear];
        
        if (complete) complete();
        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        });
        UIViewController *controller = self.popupQueue.firstObject;
        if (controller) {
            [self showWithViewController:controller withAnimation:controller.animationType];
        }
    }];
}

- (void)clear
{
    [self.currentPopupController.view removeFromSuperview];
    [self.popupQueue removeObject:self.currentPopupController];
    [self.currentPopupController removeFromParentViewController];
    self.currentPopupController = nil;
    self.window.hidden = YES;
    [self.window resignKeyWindow];
    self.canNotDismissByTouchMask = NO;
    self.transparanteMask = NO;
}

- (void)setOffsetY:(CGFloat)offset animated:(BOOL)animated
{
    [UIView animateWithDuration:animated?.3f:.0f animations:^{
        self.popupViewContainer.center = CGPointMake(_window.wf_width/2, _window.wf_height/2 + offset);
    }];
}

- (void)setCenterViewFrame:(CGRect)frame
{
    [UIView animateWithDuration:0.3 animations:^{
        self.popupViewContainer.frame = frame;
    }];
}
@end

@implementation UIViewController (WFPopupManager)

- (void)wf_dismiss
{
    [[WFPopupManager sharedManager] dismiss];
}

@end
