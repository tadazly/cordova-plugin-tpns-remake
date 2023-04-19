#import "TPNSPlugin.h"
// #import "AppDelegate.h"

// @implementation AppDelegate (TPNSPlugin)

// - (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
// {
//     NSLog(@"AppDelegate APNS deviceToken: %@", deviceToken.description);
//     [[NSNotificationCenter defaultCenter] postNotificationName:@"CDVApnsDeviceTokenReceivedNotification" object:deviceToken];
// }

// @end


@implementation TPNSPlugin
// - (void)pluginInitialize {
//     [super pluginInitialize];
//     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRegisterForRemoteNotificationsWithDeviceToken:) name:@"CDVApnsDeviceTokenReceivedNotification" object:nil];
// }

- (void)addNotificationListener:(CDVInvokedUrlCommand *_Nonnull)command
{
    self.notificationCallbackId = command.callbackId;
}

- (void)addResponseListener:(CDVInvokedUrlCommand *_Nonnull)command
{
    self.responseCallbackId = command.callbackId;
}

- (void)setEnableDebug:(CDVInvokedUrlCommand *)command
{
    BOOL enabled = [[command.arguments objectAtIndex:0] boolValue];
    [[XGPush defaultManager] setEnableDebug:enabled];
}

- (void)setAccessInfo:(CDVInvokedUrlCommand *)command
{   
    if ([command.arguments count] > 0)
    {
        self.tpnsAccessID = [[command.arguments objectAtIndex:0] integerValue];
    }
    else
    {
        self.tpnsAccessID = [[[self.commandDelegate settings] objectForKey:@"tpns_access_id"] integerValue];
    }

    if ([command.arguments count] > 1)
    {
        self.tpnsAccessKey = [command.arguments objectAtIndex:1];
    }
    else
    {
        self.tpnsAccessKey = [[self.commandDelegate settings] objectForKey:@"tpns_access_key"];
    }
}

- (void)setConfigHost:(CDVInvokedUrlCommand *)command
{
    NSString *currentDomainName = TPNS_DOMAIN_SH;
    NSArray *arguments = command.arguments;
    if ([arguments count] > 0) {
        id arg = [arguments objectAtIndex:0];
        if ([arg isKindOfClass:[NSString class]] && [arg length] > 0) {
            currentDomainName = arg;
        }
    }
    self.currentDomainName = currentDomainName;
    /// 设置后调用startXG
}

- (void)startXG:(CDVInvokedUrlCommand *)command
{        
    if (self.isTPNSRegistSuccess) {
        //已经注册成功，避免重复注册；如需重新注册，先注销，后注册。
        NSDictionary *response = @{
            @"deviceToken": self.deviceToken != nil ? self.deviceToken : @"",
            @"xgToken": self.xgToken != nil ? self.xgToken : @"",
            @"errorCode": @(0)
        };
        NSLog(@"[TPNSPlugin StartXG] deviceToken: %@ xgToken: %@", [response objectForKey:@"deviceToken"], [response objectForKey:@"xgToken"]);

        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
        return;
    }
    NSInteger accessID = [[[self.commandDelegate settings] objectForKey:@"tpns_access_id"] integerValue];
    if (self.tpnsAccessID != 0) {
        accessID = self.tpnsAccessID;
    }
    NSString *accessKey = [[self.commandDelegate settings] objectForKey:@"tpns_access_key"];
    if (self.tpnsAccessKey != nil && ![self.tpnsAccessKey isEqualToString:@""]) {
        accessKey = self.tpnsAccessKey;
    }
    if (self.currentDomainName != nil && ![self.currentDomainName isEqualToString:@""]) {
        [[XGPush defaultManager] configureClusterDomainName:self.currentDomainName];
    } else {
        [[XGPush defaultManager] configureClusterDomainName:TPNS_DOMAIN_SH];
    }
    /// 暂存回掉函数的id
    self.currentStartCallbackId = command.callbackId;
    /// 如果通知权限弹框已展示过，则启动时调用注册
    /// 启动TPNS服务
    [[XGPush defaultManager] startXGWithAccessID:(uint32_t)accessID accessKey:accessKey delegate:self];

    /// 角标数目清零,通知中心清空
    if ([XGPush defaultManager].xgApplicationBadgeNumber > 0) {
        [XGPush defaultManager].xgApplicationBadgeNumber = 0;
    }
}

- (void)stopXG:(CDVInvokedUrlCommand *)command
{
    self.currentStopCallbackId = command.callbackId;
    [[XGPush defaultManager] stopXGNotification];
}

- (void)getToken:(CDVInvokedUrlCommand *)command
{
    NSString *token = [[XGPushTokenManager defaultTokenManager] xgTokenString];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:token];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)setBadge:(CDVInvokedUrlCommand *)command
{
    NSInteger value = [[command.arguments objectAtIndex:0] integerValue];
    [[XGPush defaultManager] setBadge:value];
}

- (void)getSdkVersion:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[[XGPush defaultManager] sdkVersion]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)clearTPNSCache:(CDVInvokedUrlCommand *)command
{
    [[XGPush defaultManager] clearTPNSCache];
}

- (void)deviceNotificationIsAllowed:(CDVInvokedUrlCommand *)command
{
    [[XGPush defaultManager] deviceNotificationIsAllowed:^(BOOL isAllowed) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isAllowed];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)uploadLogCompletionHandler:(CDVInvokedUrlCommand *)command
{
    [[XGPush defaultManager] uploadLogCompletionHandler:^(BOOL result,  NSString * _Nullable errorMessage) {
        NSDictionary *response = @{
            @"result": @(result),
            @"errorMsg": errorMessage
        };
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
    }];
}

- (void)addLocalNotificationByTimestamp:(CDVInvokedUrlCommand *_Nonnull)command
{
    BOOL (^hasProperty)(NSObject *, NSString *) = ^BOOL(NSObject *object, NSString *propertyName) {
        return [object respondsToSelector:NSSelectorFromString(propertyName)];
    };
    
    NSDictionary *jsContent = [command.arguments objectAtIndex:0];
    double jsTimestamp = [[command.arguments objectAtIndex:1] doubleValue];
    NSString *requestId = [NSString stringWithFormat:@"tpns_local%.0f", jsTimestamp];
    
    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    
    for (NSString *key in jsContent) {
        if ([key isEqualToString:@"requestId"]) {
            requestId = jsContent[key];
        }
        else if (hasProperty(content, key)) {
            [content setValue:[NSString localizedUserNotificationStringForKey:jsContent[key] arguments:nil] forKey:key];
        }
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(jsTimestamp / 1000)];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:date];
    UNCalendarNotificationTrigger* trigger = [UNCalendarNotificationTrigger
           triggerWithDateMatchingComponents:components repeats:NO];
    
    UNNotificationRequest* request = [UNNotificationRequest
           requestWithIdentifier:requestId content:content trigger:trigger];
    
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
       if (error != nil) {
           NSLog(@"%@", error.localizedDescription);
       }
    }];
    
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:requestId];
    [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
}

- (void)addLocalNotificationByDate:(CDVInvokedUrlCommand *_Nonnull)command
{
    BOOL (^hasProperty)(NSObject *, NSString *) = ^BOOL(NSObject *object, NSString *propertyName) {
        return [object respondsToSelector:NSSelectorFromString(propertyName)];
    };
    
    NSDictionary *jsContent = [command.arguments objectAtIndex:0];
    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    
    NSInteger year = [[command.arguments objectAtIndex:1] integerValue];
    NSInteger month = [[command.arguments objectAtIndex:2] integerValue];
    NSInteger day = [[command.arguments objectAtIndex:3] integerValue];
    NSInteger hour = [[command.arguments objectAtIndex:4] integerValue];
    NSInteger minute = [[command.arguments objectAtIndex:5] integerValue];
    NSInteger second = [[command.arguments objectAtIndex:6] integerValue];

    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = month;
    components.day = day;
    components.hour = hour;
    components.minute = minute;
    components.second = second;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *date = [calendar dateFromComponents:components];
    NSTimeInterval timestamp = [date timeIntervalSince1970];
    
    UNCalendarNotificationTrigger* trigger = [UNCalendarNotificationTrigger
           triggerWithDateMatchingComponents:components repeats:NO];
    
    NSString *requestId = [NSString stringWithFormat:@"tpns_local%.0f", timestamp];
    
    for (NSString *key in jsContent) {
        if ([key isEqualToString:@"requestId"]) {
            requestId = jsContent[key];
        }
        else if (hasProperty(content, key)) {
            [content setValue:[NSString localizedUserNotificationStringForKey:jsContent[key] arguments:nil] forKey:key];
        }
    }
    
    UNNotificationRequest* request = [UNNotificationRequest
           requestWithIdentifier:requestId content:content trigger:trigger];
    
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
       if (error != nil) {
           NSLog(@"%@", error.localizedDescription);
       }
    }];
    
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:requestId];
    [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
}

- (void)removeLocalNotificationByRequestIds:(CDVInvokedUrlCommand *_Nonnull)command
{
    NSArray *requestIds = [command.arguments objectAtIndex:0];
        
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center removePendingNotificationRequestsWithIdentifiers:requestIds];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Notification requests removed"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)removeAllLocalNotifications:(CDVInvokedUrlCommand *_Nonnull)command
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center removeAllPendingNotificationRequests];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Notification requests removed all"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getDeliveredNotifications:(CDVInvokedUrlCommand *_Nonnull)command
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        
    [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *notifications) {
        NSMutableArray *deliveredNotifications = [NSMutableArray new];
        
        for (UNNotification *notification in notifications) {
            UNNotificationContent *content = notification.request.content;
            NSDictionary *notificationInfo = @{
                @"requestId": notification.request.identifier,
                @"title": content.title,
                @"subtitle": content.subtitle,
                @"body": content.body,	
                @"badge": content.badge,
                @"userInfo": content.userInfo
            };
            [deliveredNotifications addObject:notificationInfo];
        }
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:deliveredNotifications];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)removeDeliveredNotificationsByRequestIds:(CDVInvokedUrlCommand *_Nonnull)command
{
    NSArray *requestIds = [command.arguments objectAtIndex:0];
        
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center removeDeliveredNotificationsWithIdentifiers:requestIds];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Delivered notifications removed"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)removeAllDeliveredNotifications:(CDVInvokedUrlCommand *_Nonnull)command
{
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center removeAllDeliveredNotifications];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Delivered notifications removed all"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

// - (void)startAPNS:(CDVInvokedUrlCommand *_Nonnull)command
// {
//     self.apnsCallbackId = command.callbackId;
//     UIApplication *application = [UIApplication sharedApplication];
//     UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
//     UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;

//     [center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
//         if (granted) {
//             dispatch_async(dispatch_get_main_queue(), ^{
//                 [application registerForRemoteNotifications];
//             });
//         } else {
//             CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"User denied notification permission"];
//             [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
//         }
//     }];
// }

// - (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSNotification *)notification {
//     NSData *deviceToken = [notification object];
//     const unsigned *tokenBytes = [deviceToken bytes];
//     NSString *token = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
//                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
//                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
//                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
//     if (self.apnsCallbackId != 0) {
//         CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:token];
//         [self.commandDelegate sendPluginResult:commandResult callbackId:self.apnsCallbackId];
//         self.apnsCallbackId = nil;
//     }
//     NSLog(@"APNS deviceToken translate: %@", token);
// }

/********XGPush代理，提供注册机反注册结果回调，消息接收机消息点击回调，清除角标回调********/

#pragma mark *** XGPushDelegate ***

/// 注册推送服务成功回调
/// @param deviceToken APNs 生成的Device Token
/// @param xgToken TPNS 生成的 Token，推送消息时需要使用此值。TPNS 维护此值与APNs 的 Device Token的映射关系
/// @param error 错误信息，若error为nil则注册推送服务成功
- (void)xgPushDidRegisteredDeviceToken:(nullable NSString *)deviceToken xgToken:(nullable NSString *)xgToken error:(nullable NSError *)error { 
    NSDictionary *response = nil;
    NSLog(@"%s, result %@, error %@", __FUNCTION__, error ? @"NO" : @"OK", error);
    NSString *errorStr = !error ? NSLocalizedString(@"success", nil) : NSLocalizedString(@"failed", nil);
    NSString *message = [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"register_app", nil), errorStr];

    //在注册完成后上报角标数目
    if (!error) {
        //重置服务端自动+1基数
        [[XGPush defaultManager] setBadge:0];
        response = @{
            @"deviceToken": deviceToken != nil ? deviceToken : @"",
            @"xgToken": xgToken != nil ? xgToken : @"",
            @"errorCode": @(0)
        };
        self.deviceToken = deviceToken;
        self.xgToken = xgToken;
        NSLog(@"[TPNSPlugin StartXG] deviceToken: %@ xgToken: %@", [response objectForKey:@"deviceToken"], [response objectForKey:@"xgToken"]);
    } else {
        response = @{
            @"errorCode": @(1001),
            @"errorMsg": @"注册成功回掉内失败"
        };
    }
    //设置是否注册成功
    self.isTPNSRegistSuccess = error ? false : true;

    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
    [self.commandDelegate sendPluginResult:commandResult callbackId:self.currentStartCallbackId];
    self.currentStartCallbackId = nil;
}

/// 注册推送服务失败回调
/// @param error 注册失败错误信息
- (void)xgPushDidFailToRegisterDeviceTokenWithError:(nullable NSError *)error {
    NSLog(@"%s, errorCode:%ld, errMsg:%@", __FUNCTION__, (long)error.code, error.localizedDescription);

    NSDictionary *response = @{
        @"errorCode": @(error.code),
        @"errorMsg": error.localizedDescription
    };
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
    [self.commandDelegate sendPluginResult:commandResult callbackId:self.currentStartCallbackId];
    self.currentStartCallbackId = nil;
}

/// 注销推送服务回调
- (void)xgPushDidFinishStop:(BOOL)isSuccess error:(nullable NSError *)error {
    NSDictionary *response = nil;
    NSString *errorStr = !error ? NSLocalizedString(@"success", nil) : NSLocalizedString(@"failed", nil);
    NSString *message = [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"unregister_app", nil), errorStr];

    //设置是否注销成功
    if (!error) {
        self.isTPNSRegistSuccess = false;
        response = @{
            @"errorCode": @(0)
        };
        self.deviceToken = nil;
        self.xgToken = nil;
    } else {
        response = @{
            @"errorCode": @(1001),
            @"errorMsg": @"注销回掉内失败"
        };
    }
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
    [self.commandDelegate sendPluginResult:commandResult callbackId:self.currentStopCallbackId];
    self.currentStopCallbackId = nil;
}

/// 统一接收消息的回调
/// @param notification 消息对象(有2种类型NSDictionary和UNNotification具体解析参考示例代码)
/// @note 此回调为前台收到通知消息及所有状态下收到静默消息的回调（消息点击需使用统一点击回调）
/// 区分消息类型说明：xg字段里的msgtype为1则代表通知消息,msgtype为2则代表静默消息,msgtype为9则代表本地通知
- (void)xgPushDidReceiveRemoteNotification:(nonnull id)notification withCompletionHandler:(nullable void (^)(NSUInteger))completionHandler {
    NSLog(@"[TPNS] remote notification");
    NSDictionary *notificationDic = nil;
    if ([notification isKindOfClass:[UNNotification class]]) {
        notificationDic = ((UNNotification *)notification).request.content.userInfo;
        completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
    } else if ([notification isKindOfClass:[NSDictionary class]]) {
        notificationDic = notification;
        completionHandler(UIBackgroundFetchResultNewData);
    }
    NSLog(@"remote notification dic: %@", notificationDic);
    if (self.notificationCallbackId != 0) {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:notificationDic];
        [self.commandDelegate sendPluginResult:commandResult callbackId:self.notificationCallbackId];
    }
}

/// 统一点击回调
/// @param response 如果iOS 10+/macOS 10.14+则为UNNotificationResponse，低于目标版本则为NSDictionary
/// 区分消息类型说明：xg字段里的msgtype为1则代表通知消息,msgtype为9则代表本地通知
- (void)xgPushDidReceiveNotificationResponse:(nonnull id)response withCompletionHandler:(nonnull void (^)(void))completionHandler {
    NSLog(@"[TPNS] click notification");
    NSDictionary *notificationDic = nil;
    if ([response isKindOfClass:[UNNotificationResponse class]]) {
        /// iOS10+消息体获取
        notificationDic = ((UNNotificationResponse *)response).notification.request.content.userInfo;
        NSLog(@"click notification dic: %@", ((UNNotificationResponse *)response).notification.request.content.userInfo);
    } else if ([response isKindOfClass:[NSDictionary class]]) {
        /// 低于iOS10消息体获取
        notificationDic = response;
        NSLog(@"click notification dic: %@", response);
    }
    if (self.responseCallbackId != 0) {
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:notificationDic];
        [self.commandDelegate sendPluginResult:commandResult callbackId:self.responseCallbackId];
    }
    completionHandler();
}

/// 角标设置成功回调
/// @param isSuccess 设置角标是否成功
/// @param error 错误标识，若设置不成功会返回
- (void)xgPushDidSetBadge:(BOOL)isSuccess error:(nullable NSError *)error {
    NSLog(@"%s, result %@, error %@", __FUNCTION__, isSuccess ? @"OK" : @"NO", error);
}

/// 通知授权弹框的回调
/// @param isEnable 用户是否授权
- (void)xgPushDidRequestNotificationPermission:(bool)isEnable error:(nullable NSError *)error {
    NSLog(@"%s, result %@, error %@", __FUNCTION__, isEnable ? @"OK" : @"NO", error);
}

/// TPNS网络连接成功
- (void)xgPushNetworkConnected {
    NSLog(@"TPNS connection connected.");
    if (self.launchTag) {
        /// 重置应用角标，-1不清空通知栏，0清空通知栏
        [XGPush defaultManager].xgApplicationBadgeNumber = -1;
        /// 重置服务端自动+1基数
        [[XGPush defaultManager] setBadge:0];
        self.launchTag = NO;
    }
}

/// TPNS网络连接断开
- (void)xgPushNetworkDisconnected {
    NSLog(@"TPNS connection disconnected.");
    self.launchTag = YES;
}

/// 销毁资源
- (void)dealloc {
    /// 取消订阅通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
