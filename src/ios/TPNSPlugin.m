#import "TPNSPlugin.h"
#import "TPNSCommonMethod.h"

@implementation TPNSPlugin

- (void)setEnableDebug:(CDVInvokedUrlCommand *)command
{
    BOOL enabled = [[command.arguments objectAtIndex:0] boolValue];
    [[XGPush defaultManager] setEnableDebug:enabled];
}

- (void)setAccessInfo:(CDVInvokedUrlCommand *)command
{   
    if ([command.arguments count] > 0)
    {
        self.tpnsAccessID = [command.arguments objectAtIndex:0];
    }
    else
    {
        self.tpnsAccessID = TPNS_ACCESS_ID;
    }

    if ([command.arguments count] > 1)
    {
        self.tpnsAccessKey = [command.arguments objectAtIndex:1];
    }
    else
    {
        self.tpnsAccessKey = TPNS_ACCESS_KEY;
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
    // [[XGPush defaultManager] configureClusterDomainName:currentDomainName];
    //过滤配置的DomainName与AccessID不匹配问题
    NSInteger accessID = self.tpnsAccessID != 0 ? self.tpnsAccessID : TPNS_ACCESS_ID;
    if (![TPNSCommonMethod isMatchingDomainName:currentDomainName withAccessID:accessID]) {
        NSLog(@"%@",NSLocalizedString(@"domainname_accessid_not_match", nil));
    } else {
        self.currentDomainName = currentDomainName;
    }
}

- (void)startXG:(CDVInvokedUrlCommand *)command
{        
    if (self.isTPNSRegistSuccess) {
        //已经注册成功，避免重复注册；如需重新注册，先注销，后注册。
        NSString *message = [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"register_app", nil), NSLocalizedString(@"success", nil)];
        [TPNSCommonMethod showAlertViewWithText:message];
        return;
    }
    NSInterger accessID = TPNS_ACCESS_ID;
    if (self.tpnsAccessID != 0) {
        accessID = self.tpnsAccessID;
    }
    NSString *accessKey = TPNS_ACCESS_KEY;
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
    [[XGPush defaultManager] startXGWithAccessID:accessID accessKey:accessKey delegate:self];

    /// 角标数目清零,通知中心清空
    if ([XGPush defaultManager].xgApplicationBadgeNumber > 0) {
        TPNS_DISPATCH_MAIN_SYNC_SAFE(^{
            [XGPush defaultManager].xgApplicationBadgeNumber = 0;
        });
    }
}

- (void)stopXG:(CDVInvokedUrlCommand *)command
{
    self.currentStopCallbackId = command.callbackId;
    [[XGPush defaultManager] stopXGNotification];
}

- (NSString)getToken:(CDVInvokedUrlCommand *)command
{
    NSString *token = [[XGPushTokenManager defaultTokenManager] xgTokenString];
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:token];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)setBadge:(CDVInvokedUrlCommand *)command
{
    NSInteger value = command.arguments objectAtIndex:0];
    [[XGPush defaultManager] setBadge:num];
}

- (nonnull NSString *)getSdkVersion:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[[XGPush defaultManager] sdkVersion]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (BOOL)clearTPNSCache:(CDVInvokedUrlCommand *)command
{
    [[XGPush defaultManager] clearTPNSCache];
}

- (void)deviceNotificationIsAllowed:(CDVInvokedUrlCommand *)command
{
    [[XGPush defaultManager] deviceNotificationIsAllowed:^(BOOL isAllowed) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isAllowed]];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)uploadLogCompletionHandler:(CDVInvokedUrlCommand *)command
{
    [[XGPush defaultManager] uploadLogCompletionHandler:(nullable void(^)(BOOL result,  NSString * _Nullable errorMessage)) {
        NSDictionary *response = @{
            @"result": result,
            @"errorMsg": errorMessage
        }
        CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
        [self.commandDelegate sendPluginResult:commandResult callbackId:command.callbackId];
    }];
}

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
            @"errorCode": 0
        };
    } else {
        response = @{
            @"errorCode": 1001,
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
        @"errorCode": error.code,
        @"errorMsg": error.localizedDescription
    }
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:response];
    [self.commandDelegate sendPluginResult:commandResult callbackId:self.currentStartCallbackId];
    self.currentStartCallbackId = nil;
}

/// 注销推送服务回调
- (void)xgPushDidFinishStop:(BOOL)isSuccess error:(nullable NSError *)error {
    NSDictionary *response = nil;
    NSString *errorStr = !error ? NSLocalizedString(@"success", nil) : NSLocalizedString(@"failed", nil);
    NSString *message = [NSString stringWithFormat:@"%@%@", NSLocalizedString(@"unregister_app", nil), errorStr];

    //设置是否注册成功
    if (!error) {
        self.isTPNSRegistSuccess = false;
        NSDictionary *response = @{
            @"errorCode": 0
        }
    } else {
        NSDictionary *response = @{
            @"errorCode": 1001,
            @"errorMsg": @"注销回掉内失败"
        }
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
    NSDictionary *notificationDic = nil;
    if ([notification isKindOfClass:[UNNotification class]]) {
        notificationDic = ((UNNotification *)notification).request.content.userInfo;
        completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
    } else if ([notification isKindOfClass:[NSDictionary class]]) {
        notificationDic = notification;
        completionHandler(UIBackgroundFetchResultNewData);
    }
    NSLog(@"receive notification dic: %@", notificationDic);
}

/// 统一点击回调
/// @param response 如果iOS 10+/macOS 10.14+则为UNNotificationResponse，低于目标版本则为NSDictionary
/// 区分消息类型说明：xg字段里的msgtype为1则代表通知消息,msgtype为9则代表本地通知
- (void)xgPushDidReceiveNotificationResponse:(nonnull id)response withCompletionHandler:(nonnull void (^)(void))completionHandler {
    NSLog(@"[TPNS Demo] click notification");
    if ([response isKindOfClass:[UNNotificationResponse class]]) {
        /// iOS10+消息体获取
        NSLog(@"notification dic: %@", ((UNNotificationResponse *)response).notification.request.content.userInfo);
    } else if ([response isKindOfClass:[NSDictionary class]]) {
        /// 低于iOS10消息体获取
        NSLog(@"notification dic: %@", response);
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
    if (_launchTag) {
        /// 重置应用角标，-1不清空通知栏，0清空通知栏
        [XGPush defaultManager].xgApplicationBadgeNumber = -1;
        /// 重置服务端自动+1基数
        [[XGPush defaultManager] setBadge:0];
        _launchTag = NO;
    }
}

/// TPNS网络连接断开
- (void)xgPushNetworkDisconnected {
    NSLog(@"TPNS connection disconnected.");
    self._launchTag = YES;
}

/// 销毁资源
- (void)dealloc {
    /// 取消订阅通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end