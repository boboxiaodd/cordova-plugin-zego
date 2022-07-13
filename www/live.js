const exec = require('cordova/exec');
const CDVZegoLive = {
    //异步回调
    joinRoom: function (success, option) {
        exec(success, null, 'CDVZegoLive', 'joinRoom', [option]);
    },
    startVideoCall: function (success) {
        exec(success, null, 'CDVZegoLive', 'startVideoCall', []);
    },
    startVoiceCall: function (success) {
        exec(success, null, 'CDVZegoLive', 'startVoiceCall', []);
    },
    startPublish: function (option) {
        exec(null, null, 'CDVZegoLive', 'startPublish', [option]);
    },
    startPlayStream: function (option) {
        exec(null, null, 'CDVZegoLive', 'startPlayStream', [option]);
    },
    snapshot: function () {
        exec(null, null, 'CDVZegoLive', 'snapshot', []);
    },
    playRingtone:function (option){
        exec(null,null,'CDVZegoLive','playRingtone',[option]);
    },
    stopRingtone:function (){
        exec(null,null,'CDVZegoLive','stopRingtone',[]);
    },
    //同步回调
    callStart: function (success) {
        exec(success, null, 'CDVZegoLive', 'callStart', []);
    },
    callEnd: function (success) {
        exec(success, null, 'CDVZegoLive', 'callEnd', []);
    },
    switchCamera: function (success) {
        exec(success, null, 'CDVZegoLive', 'switchCamera', []);
    },
    closeCamera: function (success) {
        exec(success, null, 'CDVZegoLive', 'closeCamera', []);
    },
    openCamera: function (success) {
        exec(success, null, 'CDVZegoLive', 'openCamera', []);
    },
    showBeauty: function (success) {
        exec(success, null, 'CDVZegoLive', 'showBeauty', []);
    },
    hideBeauty: function (success) {
        exec(success, null, 'CDVZegoLive', 'hideBeauty', []);
    },
};
module.exports = CDVZegoLive;
