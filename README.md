# cordova-plugin-tpns-remake

为Cordova项目接入新版本TPNS SDK

## TPNS SDK版本
- iOS SDK          v1.3.9.5
- Android SDK      待定

## 接入说明
### 在项目中安装插件

``` shell
cordova plugin add https://github.com/tadazly/cordova-plugin-tpns-remake.git --variable TPNS_ACCESS_ID=1600007893 --variable TPNS_ACCESS_KEY=IX4BGYYG8L4L
```
TPNS_ACCESS_ID 和 TPNS_ACCESS_KEY 腾讯云任务中心=>App推送管理=>基础配置 中获取自行提换

### 项目配置
- iOS
    - 搜索路径设置
        
        1. 项目配置选中你的TARGETS => app => Build Settings
        2. Framework Search Paths 添加 "你的app名字/Plugins/cordova-plugin-tpns-remake"
        3. Library Search Paths 添加 "$(SRCROOT)/$(TARGET_NAME)/Plugins/cordova-plugin-tpns-remake"

    - 参照[SDK文档-工程配置](https://cloud.tencent.com/document/product/548/36663#.E5.B7.A5.E7.A8.8B.E9.85.8D.E7.BD.AE)完成工程配置
    
        1. 项目配置选中你的TARGETS => app => Signing & Capabilities
        2. 点击 +Capability 按钮
        3. 搜索并添加 Push Notifications、Background Modes(勾选Remote notifications)、Time Sensitive Notifications

### 使用方式

1. （可选，默认开启）[设置Debug输出](https://github.com/tadazly/cordova-plugin-tpns-remake/blob/main/www/tpns.js#L19)

``` javascript
    tpns.setEnableDebug(true);
```

2. （可选，默认使用上海域名）[设置域名接口](https://github.com/tadazly/cordova-plugin-tpns-remake/blob/main/www/tpns.js#L23)

``` javascript
    tpns.setConfigHost(tpns.TPNS_DOMAIN.SH);
```

3. （可选）[添加收到通知、点击通知的监听](https://github.com/tadazly/cordova-plugin-tpns-remake/blob/main/www/tpns.js#L11)

``` javascript
    // 添加收到消息时触发的回调函数
    tpns.addNotificationListener((data) => {
        if (data && data.aps) {
            // ...
        }
        if (data && data.xg) {
            // ...
        }
    });
    // 添加点击消息时触发的回调函数
    tpns.addResponseListener((data) => {
        if (data && data.aps) {
            // ...
        }
        if (data && data.xg) {
            // ...
        }
    });
```

4. &nbsp;[注册并开启TPNS](https://github.com/tadazly/cordova-plugin-tpns-remake/blob/main/www/tpns.js#L31)，在回调函数中获得TPNS Token(XgToken)

``` javascript
    // !!! 上面几步都需要在执行starXG前调用哦
    tpns.startXG((data) => {
        if (!data.errorCode) {
            console.log(`注册成功！`);
            console.log(`TPNS推送用token / xgToken：${data.xgToken}`);
            console.log(`APNS token / deviceToken：${data.deviceToken}`);
            // ...
        }
    })
```

5. &nbsp;[注销TPNS](https://github.com/tadazly/cordova-plugin-tpns-remake/blob/main/www/tpns.js#L35)

``` javascript
    tpns.stopXG((data) => {
        if (!data.errorCode) {
            console.log(`注销成功！`);
            // ...
        }
    })
```


### [API](https://github.com/tadazly/cordova-plugin-tpns-remake/blob/main/types/index.d.ts#L58)&nbsp;说明

``` typescript
    /**
     *  注册/注销回调函数的参数类型
     */
    type response = {
        /** 0 为正常， > 0 为报错 **/
        errorCode: number,
        /** 大于0时有错误信息 **/
        errorMsg?: string,
        /** APNS TOKEN **/
        deviceToken?: number,
        /** TPNS TOKEN **/
        xgToken?: number,
    }

    type alertObject = {
        title: string,
        subtitle: string,
        body: string,
        sound: string
    }

    type apsObject = {
        alert: alertObject,
        badge_add_num: number,
        badge_type: number,
        category: string,
        'mutable-content': number,
        sound: string
    }

    type xgObject = {
        bid: number,
        groupId: string,
        guid: number,
        msgid: number,
        msgtype: number,
        pushChannel: number,
        pushTime: number,
        showType: number,
        source: number,
        targettype: number,
        templateId: string,
        tpnsCollapseId: number,
        traceId: string,
        ts: number,
        xgToken: string
    }

    /**
     *  消息、点击消息回调参数类型
     */
    type notification = {
        aps: apsObject,
        xg: xgObject
    }

    /**
     *  域名接口
     */ 
    enum TPNS_DOMAIN {
        GZ_DEFAULT = "tpns.tencent.com",
        HK = "tpns.hk.tencent.com",
        SGP = "tpns.sgp.tencent.com",
        SH = "tpns.sh.tencent.com"
    }

    /**
     *  添加收到通知监听
     */
    function addNotificationListener(onSuccess: (data: notification) => void): void;

    /**
     *  添加点击通知监听
     */
    function addResponseListener(onSuccess: (data: notification) => void): void;

    /**
     *  设置Debug输出（非js-console输出，是Xcode的控制台输出）
     */
    function setEnableDebug(enabled: boolean): void;

    /**
     *  （不推荐，仅测试时使用）在代码中设置accessID，accessKey，设置完成后调用startXG
     */
    function setAccessInfo(accessID: number, accessKey: string): void;

    /**
     *  配置域名接口，不配置默认使用 TPNS_DOMAIN.SH
     *  配置完成后调用startXG
     */ 
    function setConfigHost(host: TPNS_DOMAIN): void;

    /**
     *  注册并开启TPNS
     */
    function startXG(
        onSuccess: (data: response) => void, 
        onError: (data: response) => void
    ): void

    /**
     *  注销TPNS
     */
    function stopXGG(
        onSuccess: (data: response) => void, 
        onError: (data: response) => void
    ): void

    /**
     *  读取TOKEN，需要成功注册开启后使用
     */
    function getToken(onSuccess: (token: string) => void): void;

    /**
     *  设置角标
     */
    function setBadge(value): void;

    function getSdkVersion(onSuccess: (sdkVersion: string) => void): void;

    function clearTPNSCache(): void;

    /**
     *  获取设备通知是否开启
     */
    function deviceNotificationIsAllowed(onSuccess: (isAllowed: boolean) => void): void;

    /**
     *  上传Log日志
     */
    function uploadLogCompletionHandler(
        onSuccess: (data: response) => void, 
        onError: (data: response) => void
    ): void
```
