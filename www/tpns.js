var exec = require('cordova/exec');

module.exports = {
    TPNS_DOMAIN: {
        GZ_DEFAULT: "tpns.tencent.com",
        HK: "tpns.hk.tencent.com",
        SGP: "tpns.sgp.tencent.com",
        SH: "tpns.sh.tencent.com"
    },

    addNotificationListener: function(onSuccess, onError) {
        exec(onSuccess, onError, "tpns", "addNotificationListener", []);
    },

    addResponseListener: function(onSuccess, onError) {
        exec(onSuccess, onError, "tpns", "addResponseListener", []);
    },

    setEnableDebug: function(enabled, onSuccess, onError) {
        exec(onSuccess, onError, "tpns", "setEnableDebug", [enabled]);
    },

    setAccessInfo: function(accessID, accessKey, onSuccess, onError) {
        exec(onSuccess, onError, "tpns", "setAccessInfo", [accessID, accessKey]);
    },

    setConfigHost: function(host, onSuccess, onError) {
        exec(onSuccess, onError, "tpns", "setConfigHost", [host || this.TPNS_DOMAIN.SH]);
    },

    startXG: function(onSuccess, onError) {
        exec(onSuccess, onError, "tpns", "startXG", []);
    },

    stopXG: function(onSuccess, onError) {
        exec(onSuccess, onError, "tpns", "stopXG", []);
    },

    getToken: function(onSuccess, onError) {
        exec(onSuccess, onError, "tpns", "getToken", []);
    },

    setBadge: function(value, onSuccess, onError) {
        exec(onSuccess, onError, "tpns", "setBadge", [value]);
    },

    getSdkVersion: function(onSuccess, onError) {
        exec(onSuccess, onError, "tpns", "getSdkVersion", []);
    },

    clearTPNSCache: function(onSuccess, onError) {
        exec(onSuccess, onError, "tpns", "clearTPNSCache", []);
    },

    deviceNotificationIsAllowed: function(onSuccess, onError) {
        exec(onSuccess, onError, "tpns", "deviceNotificationIsAllowed", []);
    },

    uploadLogCompletionHandler: function(onSuccess, onError) {
        exec(onSuccess, onError, "tpns", "uploadLogCompletionHandler", []);
    },
}