namespace tpns {
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
     *  ios内消息对象结构
     */
    type iosNotificationObject = {
        requestId: string,
        title: string,
        subtitle: string,
        body: string,
        badge: number,
        userInfo: object
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

    /**
     *  获取TPNS SDK Version
     */
    function getSdkVersion(onSuccess: (sdkVersion: string) => void): void;

    /**
     *  清除TPNS缓存
     */
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

    /**
     *  添加指定时间戳的通知
     * @param content 消息对象
     * @param timestamp 时间戳，毫秒
     * @param onSuccess 返回一个requestId
     */
    function addLocalNotificationByTimestamp(
        content: Object,
        timestamp: number,
        onSuccess: (requestId: number) => void
    ): void

    /**
     *  添加指定日期的通知
     * @param content 消息对象
     * @param date Date对象
     * @param onSuccess 返回一个requestId
     */
    function addLocalNotificationByTimestamp(
        content: Object,
        timestamp: number,
        onSuccess: (requestId: number) => void
    ): void

    /**
     *  通过requestId数组删除已经添加但未推送的消息
     * @param requestIds 
     */
    function removeLocalNotificationByRequestIds(requestIds: number[]): void;

    /**
     *  删除所有已经添加但未推送的消息
     */
    function removeAllLocalNotifications(): void;

    /**
     *  获取已经成功推送的通知（通知中心显示的）
     * @param onSuccess 
     */
    function getDeliveredNotifications(onSuccess: (notifications: iosNotificationObject[]) => void): void

    /**
     *  通过requestId数组删除已经成功推送的通知
     * @param requestIds 
     */
    function removeDeliveredNotificationsByRequestIds(requestIds: number[]): void;

    /**
     *  删除所有已经成功推送的通知
     */
    function removeAllDeliveredNotifications(): void;
}