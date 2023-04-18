# cordova-plugin-tpns-remake

为Cordova项目接入新版本TPNS SDK的插件

## TPNS SDK版本
- iOS SDK          v1.3.9.5
- Android SDK      待定

## 接入说明
### 在项目中安装插件

``` shell
cordova plugin add https://github.com/tadazly/cordova-plugin-tpns-remake.git --VARIABLE TPNS_ACCESS_ID=1600007893 TPNS_ACCESS_KEY=IX4BGYYG8L4L
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
