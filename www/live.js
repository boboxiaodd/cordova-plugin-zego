const exec = require('cordova/exec');
const CDVZegoLive = {
    update:function (success,fail,option){
        exec(success,fail,'CDVZegoLive','update',[option]);
    }
};
module.exports = CDVZegoLive;
