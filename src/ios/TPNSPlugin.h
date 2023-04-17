#import <Cordova/CDV.h>
#import "XGPush.h"
#import "XGPushPrivate.h"

@interface TPNSPlugin : CDVPlugin

@property (nonatomic, strong) NSString *currentDomainName;
@property (nonatomic, strong) NSString *currentStartCallbackId;
@property (nonatomic, strong) NSString *currentStopCallbackId;
@property (nonatomic, assign) NSInteger tpnsAccessID;
@property (nonatomic, assign) NSString *tpnsAccessKey;
@property (nonatomic, assign) BOOL isTPNSRegistSuccess;
@property (nonatomic, assign) BOOL launchTag;

/// 设置开启关闭调试
- (void)setEnableDebug:(CDVInvokedUrlCommand *)command;
/// 可选手动设置accessID和key
- (void)setAccessInfo:(CDVInvokedUrlCommand *)command;
/// 设置host
- (void)setConfigHost:(CDVInvokedUrlCommand *)command;
/// 开启入口（停止后需要再次调用）
- (void)startXG:(CDVInvokedUrlCommand *)command;
/// 停止推送
- (void)stopXG:(CDVInvokedUrlCommand *)command;
/// 查询Token
- (NSString)getToken:(CDVInvokedUrlCommand *)command;

/// 同步角标
- (void)setBadge:(CDVInvokedUrlCommand *)command;
- (nonnull NSString *)getSdkVersion:(CDVInvokedUrlCommand *)command;
- (BOOL)clearTPNSCache:(CDVInvokedUrlCommand *)command;
/// 查询设备通知权限
- (void)deviceNotificationIsAllowed:(CDVInvokedUrlCommand *)command;
/// 日志上报接口
- (void)uploadLogCompletionHandler:(CDVInvokedUrlCommand *)command;


/// 接下来的要在注册成功后使用
// - (void)upsertAccount:(CDVInvokedUrlCommand *)command;
// - (void)upsertPhone:(CDVInvokedUrlCommand *)command;




@end