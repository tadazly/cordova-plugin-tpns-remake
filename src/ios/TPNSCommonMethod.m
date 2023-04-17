//
//  TPNSCommonMethod.m
//  TPNS-Demo-Cloud
//
//  Created by boblv on 2020/4/16.
//  Copyright © 2020 TPNS of Tencent. All rights reserved.
//

#import "TPNSCommonMethod.h"
#import "XGPush.h"
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>
#endif

#define TPNS_AUTHOR_CUSTOM_KEY @"tpns_author_custom_key" /// 通知权限授权弹框标识

/// TPNS Common Method
@implementation TPNSCommonMethod

+ (void)showAlertViewWithText:(NSString *)title {
    [TPNSCommonMethod showAlertViewWithText:title message:nil];
}

+ (void)showAlertViewWithText:(NSString *)title message:(nullable NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        AppDelegate *appdelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        UIViewController *rootViewController = appdelegate.window.rootViewController;
        if (rootViewController && [rootViewController isKindOfClass:[UIViewController class]]) {
            [self showAlert:title message:message viewController:rootViewController completion:nil];
        }
    });
}

+ (UIAlertController *)initAlert:(nullable NSString *)title
                         message:(nullable NSString *)message
                 inputTextTitles:(nullable NSArray *)inputTextTitles
               otherButtonTitles:(nullable NSArray *)otherButtonTitles
                  viewController:(UIViewController *)viewController
                           block:(nullable TPNSUIAlertCompletionBlock)block {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             if (block) {
                                                                 block(alertController, -1);
                                                             }
                                                         }];
    [alertController addAction:cancleAction];

    int currentIndex = 0;
    for (NSString *inputTextTitle in inputTextTitles) {
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *_Nonnull textField) {
            textField.placeholder = inputTextTitle;
        }];
    }

    currentIndex = 0;
    for (NSString *buttonTitle in otherButtonTitles) {
        int buttonIndex = currentIndex++;
        UIAlertAction *action = [UIAlertAction actionWithTitle:buttonTitle
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                           if (block) {
                                                               block(alertController, buttonIndex);
                                                           }
                                                       }];
        [alertController addAction:action];
    }

    return alertController;
}

+ (void)showAlert:(nullable NSString *)title
           message:(nullable NSString *)message
    viewController:(UIViewController *)viewController
        completion:(void (^__nullable)(UIAlertController *alertController))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [self initAlert:title
                                                     message:message
                                             inputTextTitles:nil
                                           otherButtonTitles:nil
                                              viewController:viewController
                                                       block:nil];
        [self presentAlertController:alertController fromViewController:viewController completion:completion];
    });
}

+ (void)showAlert:(nullable NSString *)title
              message:(nullable NSString *)message
      inputTextTitles:(nullable NSArray *)inputTextTitles
    otherButtonTitles:(nullable NSArray *)otherButtonTitles
       viewController:(UIViewController *)viewController
                block:(nullable TPNSUIAlertCompletionBlock)block
           completion:(void (^__nullable)(UIAlertController *alertController))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [self initAlert:title
                                                     message:message
                                             inputTextTitles:inputTextTitles
                                           otherButtonTitles:otherButtonTitles
                                              viewController:viewController
                                                       block:block];

        [self presentAlertController:alertController fromViewController:viewController completion:completion];
    });
}

+ (void)presentAlertController:(UIAlertController *)alertController
            fromViewController:(UIViewController *)viewController
                    completion:(void (^__nullable)(UIAlertController *alertController))completion {
    //    if (vc.presentedViewController) {
    //        [vc.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    //    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [viewController presentViewController:alertController
                                     animated:true
                                   completion:^{
                                       if (completion) {
                                           completion(alertController);
                                       }
                                   }];
    });
}

//检查AccessID、DomainName是否匹配,如果需要定制化，则去掉该判断
+ (BOOL)isMatchingDomainName:(NSString *)currentDomainName withAccessID:(uint32_t)accessID {
    //默认没有配置不检查
    if (!currentDomainName) {
        return true;
    }
    //配置了非法的DomainName
    if (![self isValidNonEmptyString:currentDomainName]) {
        return false;
    }
    //如果配置检查AccessID、DomainName是否匹配
    NSString *accessIDStr = [[NSString alloc] initWithFormat:@"%d", accessID];
    if ([self isValidNonEmptyString:accessIDStr] && accessIDStr.length > 3) {
        NSDictionary *matchDic = @{ TPNS_DOMAIN_GZ_DEFAULT : @"160", TPNS_DOMAIN_SGP : @"162", TPNS_DOMAIN_HK : @"163", TPNS_DOMAIN_SH : @"168" };
        NSString *accessIDPre = [accessIDStr substringToIndex:3];
        NSString *currentAccessIDPre = [matchDic objectForKey:currentDomainName];
        //如果currentAccessIDPre找到，然而不符合规则，返回失败
        if (currentAccessIDPre && ![accessIDPre isEqualToString:currentAccessIDPre]) {
            return false;
        }
    } else {
        return false;
    }

    return true;
}

/// 检测是否是有效的String
+ (BOOL)isValidNonEmptyString:(NSString *)string {
    return (string && [string isKindOfClass:NSString.class] && string.length);
}

+ (BOOL)hasTPNSAuthorAlertShown {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (paths.firstObject) {
        NSString *path = [paths.firstObject stringByAppendingPathComponent:TPNS_AUTHOR_CUSTOM_KEY];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
        return [[dict objectForKey:TPNS_AUTHOR_CUSTOM_KEY] boolValue];
    }
    return YES;
}

+ (void)writeTPNSAuthorShowTag {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if (paths.firstObject) {
        NSString *path = [paths.firstObject stringByAppendingPathComponent:TPNS_AUTHOR_CUSTOM_KEY];
        NSDictionary *tmpDict = [NSDictionary dictionaryWithObject:@(1) forKey:TPNS_AUTHOR_CUSTOM_KEY];
        [tmpDict writeToFile:path atomically:YES];
    }
}

/// 反序列化json String为对象
+ (id)json2Obj:(NSString *)jsonStr {
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    if (nil != jsonData) {
        id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
        if (jsonObject != nil && error == nil) {
            if ([jsonObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *deserializedDictionary = (NSDictionary *)jsonObject;
                return deserializedDictionary;
            } else if ([jsonObject isKindOfClass:[NSArray class]]) {
                NSArray *deserializedArray = (NSArray *)jsonObject;
                return deserializedArray;
            } else {
                return nil;
            }
        }
    }
    return nil;
}

@end
