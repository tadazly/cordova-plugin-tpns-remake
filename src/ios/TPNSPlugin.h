#import <Cordova/CDV.h>
#import "XGPush.h"
#import "XGPushPrivate.h"

#define TPNS_DOMAIN_GZ_DEFAULT @"tpns.tencent.com"
#define TPNS_DOMAIN_HK @"tpns.hk.tencent.com"
#define TPNS_DOMAIN_SGP @"tpns.sgp.tencent.com"
#define TPNS_DOMAIN_SH @"tpns.sh.tencent.com"

@interface TPNSPlugin : CDVPlugin

@property (nonatomic, strong, nonnull) NSString *currentDomainName;
@property (nonatomic, strong, nullable) NSString *currentStartCallbackId;
@property (nonatomic, strong, nullable) NSString *currentStopCallbackId;
@property (nonatomic, strong, nullable) NSString *notificationCallbackId;
@property (nonatomic, strong, nullable) NSString *responseCallbackId;
@property (nonatomic, assign) NSInteger tpnsAccessID;
@property (nonatomic, assign, nullable) NSString *tpnsAccessKey;
@property (nonatomic, assign) BOOL isTPNSRegistSuccess;
@property (nonatomic, assign) BOOL launchTag;

/// 添加接收消息监听
- (void)addNotificationListener:(CDVInvokedUrlCommand *_Nonnull)command;
/// 添加点击消息监听
- (void)addResponseListener:(CDVInvokedUrlCommand *_Nonnull)command;
/// 设置开启关闭调试
- (void)setEnableDebug:(CDVInvokedUrlCommand *_Nonnull)command;
/// 可选手动设置accessID和key
- (void)setAccessInfo:(CDVInvokedUrlCommand *_Nonnull)command;
/// 设置host
- (void)setConfigHost:(CDVInvokedUrlCommand *_Nonnull)command;
/// 开启入口（停止后需要再次调用）
- (void)startXG:(CDVInvokedUrlCommand *_Nonnull)command;
/// 停止推送
- (void)stopXG:(CDVInvokedUrlCommand *_Nonnull)command;
/// 查询Token
- (void)getToken:(CDVInvokedUrlCommand *_Nonnull)command;
/// 同步角标
- (void)setBadge:(CDVInvokedUrlCommand *_Nonnull)command;
- (void)getSdkVersion:(CDVInvokedUrlCommand *_Nonnull)command;
- (void)clearTPNSCache:(CDVInvokedUrlCommand *_Nonnull)command;
/// 查询设备通知权限
- (void)deviceNotificationIsAllowed:(CDVInvokedUrlCommand *_Nonnull)command;
/// 日志上报接口
- (void)uploadLogCompletionHandler:(CDVInvokedUrlCommand *_Nonnull)command;


/// 接下来的要在注册成功后使用
// - (void)upsertAccount:(CDVInvokedUrlCommand *)command;
// - (void)upsertPhone:(CDVInvokedUrlCommand *)command;




@end
