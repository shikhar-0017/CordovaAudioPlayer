var exec = require('cordova/exec');

exports.preloadAudio = function (key, src, success, error) {
    exec(success, error, 'CordovaAudioPlayer', 'preloadSound', [key, src]);
}

exports.playAudio = function (key, success, error) {
    exec(success, error, 'CordovaAudioPlayer', 'playSound', [key]);
}

exports.stopAudio = function (key, success, error) {
    exec(success, error, 'CordovaAudioPlayer', 'stopSound', [key]);
}