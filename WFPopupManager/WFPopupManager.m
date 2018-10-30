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

CGFloat WFPopupManagerScreenHeight(void)
{
    CGRect rect = [[UIScreen mainScreen] bounds];
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationLandscapeLeft == orientation || UIInterfaceOrientationLandscapeRight == orientation) {
        return rect.size.width > rect.size.height ? rect.size.height : rect.size.width;
    } else {
        return rect.size.width > rect.size.height ? rect.size.width : rect.size.height;
    }
}

CGFloat WFPopupManagerScreenWidth(void)
{
    CGRect rect = [[UIScreen mainScreen] bounds];
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationLandscapeLeft == orientation || UIInterfaceOrientationLandscapeRight == orientation) {
        return rect.size.width > rect.size.height ? rect.size.width : rect.size.height;
    } else {
        return rect.size.width > rect.size.height ? rect.size.height : rect.size.width;
    }
}


NSString *const WF_N_POPUP_WILL_SHOW = @"WF_N_POPUP_WILL_SHOW";

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
@property (nonatomic, strong) UIView *popupTargetView;
@end

@implementation UIViewController (WFPopAnimation)


WF_ADD_DYNAMIC_PROPERTY(NSNumber *, transparanteMask, setTransparanteMask)
WF_ADD_DYNAMIC_PROPERTY(NSNumber *, canNotDismissByTouchMask, setCanNotDismissByTouchMask)
WF_ADD_DYNAMIC_PROPERTY(NSNumber *, isOld, setIsOld)
WF_ADD_DYNAMIC_PROPERTY(UIViewController *, popupTargetView, setPopupTargetView)

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
//@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) WFPopupRootController *rootController;
@property (nonatomic, assign) BOOL isDismissAnimating;
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
        _tapMaskGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(onTapMask:)];
    }
    return _tapMaskGesture;
}

+ (UIViewController *)lastPresentController {
    return [self getVisibleViewControllerFrom:[UIApplication sharedApplication].keyWindow.rootViewController];
}

+ (UIViewController *)getVisibleViewControllerFrom:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self getVisibleViewControllerFrom:[((UINavigationController *) vc) visibleViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self getVisibleViewControllerFrom:[((UITabBarController *) vc) selectedViewController]];
    } else if ([[NSStringFromClass([vc class]) lowercaseString] containsString:@"tabbarcontroller"]) {
        if ([vc respondsToSelector:@selector(selectedViewController)]) {
            return [self getVisibleViewControllerFrom:[((UITabBarController *) vc) selectedViewController]];
        }
        return vc;
    } else {
        
        if (vc.presentedViewController) {
            return [self getVisibleViewControllerFrom:vc.presentedViewController];
        } else {
            return vc;
        }
    }
}

- (UIViewController *)rootController
{
    if (!_rootController) {
        _rootController = [WFPopupRootController new];
        _rootController.view.userInteractionEnabled = NO;
    }
    return _rootController;
}

- (UIView *)mask
{
    if (!_mask) {
        _mask = [[UIView alloc]initWithFrame:[UIScreen mainScreen].bounds];
        _mask.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        _mask.userInteractionEnabled = YES;
    }
    return _mask;
}

- (UIView *)popupViewContainer
{
    if (!_popupViewContainer) {
        _popupViewContainer = [WFPopupContainer new];
    }
    return _popupViewContainer;
}

- (void)showWithViewController:(UIViewController *)viewController
{
    [self showWithViewController:viewController withAnimation:WFPopupAnimationDefault];
}

- (void)showWithViewController:(UIViewController *)viewController withAnimation:(WFPopupAnimationType)type
{
    if (![NSThread currentThread].isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showWithViewController:viewController withAnimation:type];
        });
        return;
    }
    
    if (!viewController) {
        return;
    }
    
    if (![viewController.isOld boolValue]) {
        viewController.animationType = type;
        viewController.canNotDismissByTouchMask = @(self.canNotDismissByTouchMask);
        viewController.transparanteMask = @(self.transparanteMask);
        viewController.popupTargetView = self.popupTargetView;
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
    UIViewController *targetController;
    if ([viewController.popupTargetView isEqual:[UIApplication sharedApplication].keyWindow.rootViewController.view]) {
        targetController = [UIApplication sharedApplication].keyWindow.rootViewController;
    }else {
        targetController = [[self class] lastPresentController];
        if (viewController.popupTargetView &&
            targetController.view != viewController.popupTargetView &&
            ![targetController.view.subviews containsObject:viewController.popupTargetView]) {
            return;
        }
    }
    
    UIView *targetView = targetController.view;
    if (targetController.navigationController) {
        targetView = targetController.navigationController.view;
        if (targetController.navigationController.viewControllers.count == 1 &&
            [targetController.navigationController.parentViewController isKindOfClass:[UITabBarController class]]
            ) {
            targetView = targetController.navigationController.parentViewController.view;
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WF_N_POPUP_WILL_SHOW object:nil];
    
    [targetView addSubview:self.mask];
    [targetView addSubview:self.popupViewContainer];
    
    self.mask.backgroundColor = WF_POP_MASK_COLOR;
    [self.mask removeGestureRecognizer:self.tapMaskGesture];
    
    if (![viewController.canNotDismissByTouchMask boolValue]) {
        [self.mask addGestureRecognizer:self.tapMaskGesture];
    }
    
    viewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.currentPopupController = viewController;
    [self.popupViewContainer addSubview:viewController.view];
    //    [_window makeKeyAndVisible];
    
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
        case WFPopupAnimationLeftSlide: {
            [self animationWithLeftSlide];
            break;
        }
    }
}

- (void)animationWithDefault
{
    self.popupViewContainer.frame = self.currentPopupController.view.bounds;
    self.popupViewContainer.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2);
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
    } completion:^(BOOL success){
        if (self.didShowBlock) {
            self.didShowBlock();
            self.didShowBlock = nil;
        }
    }];
}

- (void)animationWithDropDown
{
    self.popupViewContainer.frame = CGRectMake(0, 0, 260, 320);
    self.popupViewContainer.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2);
    self.mask.alpha = 0;
    self.mask.backgroundColor = [self.currentPopupController.transparanteMask boolValue] ? [UIColor clearColor] : WF_POP_MASK_COLOR;
    self.popupViewContainer.alpha = 1.0f;
    self.popupViewContainer.wf_height = .0f;
    self.popupViewContainer.wf_y = 64.0f;
    [UIView animateWithDuration:0.3 animations:^{
        self.mask.alpha = 1;
        self.popupViewContainer.wf_height = 400.0f;
    } completion:^(BOOL success){
        if (self.didShowBlock) {
            self.didShowBlock();
            self.didShowBlock = nil;
        }
    }];
}

- (void)animationWithActionSheet
{
    self.mask.alpha = 0;
    self.mask.backgroundColor = [self.currentPopupController.transparanteMask boolValue] ? [UIColor clearColor] : WF_POP_MASK_COLOR;
    self.popupViewContainer.alpha = 1.0f;
    self.popupViewContainer.frame = CGRectMake(0, WFPopupManagerScreenHeight(), WFPopupManagerScreenWidth(), self.currentPopupController.view.wf_height);
    self.currentPopupController.view.wf_x = 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.mask.alpha = 1;
        self.popupViewContainer.wf_y = WFPopupManagerScreenHeight() - self.currentPopupController.view.wf_height;
    } completion:^(BOOL success){
        if (self.didShowBlock) {
            self.didShowBlock();
            self.didShowBlock = nil;
        }
    }];
}

- (void)animationWithLeftSlide
{
    self.mask.alpha = 0;
    self.mask.backgroundColor = [self.currentPopupController.transparanteMask boolValue] ? [UIColor clearColor] : WF_POP_MASK_COLOR;
    self.popupViewContainer.alpha = 1.0f;
    self.popupViewContainer.frame = CGRectMake(0, 0, self.currentPopupController.view.wf_width, WFPopupManagerScreenHeight());
    self.popupViewContainer.wf_x = - self.currentPopupController.view.wf_width;
    self.popupViewContainer.wf_y = 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.mask.alpha = 1;
        self.popupViewContainer.wf_x = 0;
    } completion:^(BOOL success){
        if (self.didShowBlock) {
            self.didShowBlock();
            self.didShowBlock = nil;
        }
    }];
}

- (void)onTapMask:(UITapGestureRecognizer *)rec
{
    [self.currentPopupController wf_dismiss];
    if (self.onTapMaskBlock) {
        self.onTapMaskBlock();
        self.onTapMaskBlock = nil;
    }
}

- (void)dismiss
{
    [self dismissOnComplete:nil];
}

- (void)dismissOnComplete:(dispatch_block_t)complete
{
    if (self.isDismissAnimating) {
        if (complete) complete();
        return;
    }
    NSLog(@"WFPopupManager dismissOnComplete");
    self.isDismissAnimating = YES;
    [UIView animateWithDuration:0.3f animations:^{
        if (self.currentPopupController.animationType == WFPopupAnimationActionSheet) {
            self.popupViewContainer.wf_y = WFPopupManagerScreenHeight();
        }else if (self.currentPopupController.animationType == WFPopupAnimationLeftSlide) {
            self.popupViewContainer.wf_x = - self.currentPopupController.view.wf_width;
        }
        else {
            self.popupViewContainer.alpha = 0;
        }
        self.mask.alpha = 0;
    } completion:^(BOOL finished) {
        [self clear];
        self.isDismissAnimating = NO;
        if (complete) complete();
        UIViewController *controller = self.popupQueue.firstObject;
        if (controller) {
            [self showWithViewController:controller withAnimation:controller.animationType];
        }
        if (self.dismissBlock) {
            self.dismissBlock();
            self.dismissBlock = nil;
        }
    }];
}

- (void)clear
{
    [self.currentPopupController.view removeFromSuperview];
    [self.popupQueue removeObject:self.currentPopupController];
    [self.currentPopupController removeFromParentViewController];
    self.currentPopupController = nil;
    //    self.window.hidden = YES;
    //    [self.window resignKeyWindow];
    self.canNotDismissByTouchMask = NO;
    self.transparanteMask = NO;
    self.popupTargetView = nil;
}

- (void)setOffsetY:(CGFloat)offset animated:(BOOL)animated
{
    [UIView animateWithDuration:animated?.3f:.0f animations:^{
        self.popupViewContainer.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2 + offset);
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


