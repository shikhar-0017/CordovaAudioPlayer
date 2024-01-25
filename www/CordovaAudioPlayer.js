var exec = require('cordova/exec');

exports.preloadAudio = function (key, src, success, error) {
    exec(success, error, 'CordovaAudioPlayer', 'preloadSounds', [key, src]);
}

exports.playAudio = function (key, success, error) {
    exec(success, error, 'CordovaAudioPlayer', 'playSound', [key]);
}