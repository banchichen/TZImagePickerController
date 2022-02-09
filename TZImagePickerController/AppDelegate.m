//
//  AppDelegate.m
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import "AppDelegate.h"
#import "TZImagePickerController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // 打开下面这句代码，使用导航栏控制器作为rootViewController
    // [self useNavControllerAsRoot];
    return YES;
}

- (void)useNavControllerAsRoot {
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor whiteColor];

    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(20, 200, 300, 44)];
    [btn setTitle:@"pushTZImagePickerController" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(pushTZImagePickerController) forControlEvents:UIControlEventTouchUpInside];
    [vc.view addSubview:btn];

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.navigationBar.barStyle = UIBarStyleBlack;
    nav.navigationBar.translucent = YES;
    nav.navigationBar.barTintColor = [UIColor colorWithRed:(34/255.0) green:(34/255.0)  blue:(34/255.0) alpha:1.0];
    nav.navigationBar.tintColor = [UIColor blackColor];
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *barAppearance = [[UINavigationBarAppearance alloc] init];
        if (nav.navigationBar.isTranslucent) {
            UIColor *barTintColor = nav.navigationBar.barTintColor;
            barAppearance.backgroundColor = [barTintColor colorWithAlphaComponent:0.85];
        } else {
            barAppearance.backgroundColor = nav.navigationBar.barTintColor;
        }
        barAppearance.titleTextAttributes = nav.navigationBar.titleTextAttributes;
        nav.navigationBar.standardAppearance = barAppearance;
        nav.navigationBar.scrollEdgeAppearance = barAppearance;
    }
    [nav setNavigationBarHidden:YES];

    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
}

- (void)pushTZImagePickerController {
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:9 columnNumber:4 delegate:nil];
    imagePickerVc.modalPresentationStyle = UIModalPresentationFullScreen;
    UINavigationController *nav = (UINavigationController *)[UIApplication sharedApplication].keyWindow.rootViewController;
    [nav.topViewController presentViewController:imagePickerVc animated:YES completion:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
   
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
   
}

- (void)applicationWillTerminate:(UIApplication *)application {

}

@end
