const exec = require('cordova/exec');
const CDVZegoLive = {
    //异步回调
    initZego: function (success, options){
        exec(success, null, 'CDVZegoLive', 'initZego', [options]);
    },
    joinRoom: function (option) {
        exec(null, null, 'CDVZegoLive', 'joinRoom', [option]);
    },
    setMineViewText:function (options){
        exec(null, null, 'CDVZegoLive', 'setMineViewText', [options]);
    },
    setPlayViewText:function (options){
        exec(null, null, 'CDVZegoLive', 'setPlayViewText', [options]);
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
    setCameraPosition: function (success,options) {
        exec(success, null, 'CDVZegoLive', 'setCameraPosition', [options]);
    },
    closeCamera: function (success) {
        exec(success, null, 'CDVZegoLive', 'closeCamera', []);
    },
    openCamera: function (success) {
        exec(success, null, 'CDVZegoLive', 'openCamera', []);
    },
    startPreview:function (success){
        exec(success,null,'CDVZegoLive','startPreview',[]);
    },
    stopPreview:function (){
        exec(null,null,'CDVZegoLive','stopPreview',[]);
    },
    showBeauty: function (success) {
        exec(success, null, 'CDVZegoLive', 'showBeauty', []);
    },
    hideBeauty: function (success) {
        exec(success, null, 'CDVZegoLive', 'hideBeauty', []);
    },
};
module.exports = CDVZegoLive;
