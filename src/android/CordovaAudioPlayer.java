package com.plugin.cordova.audioplayer;

import android.media.MediaPlayer;
import android.util.Log;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.json.JSONArray;
import org.json.JSONException;

import java.io.IOException;

/**
 * This class echoes a string called from JavaScript.
 */
public class CordovaAudioPlayer extends CordovaPlugin {

    private static final String TAG = "CordovaAudioPlayer:Android";
    MediaPlayer player = null;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

        if (action.equals("preloadSound")) {
            String assetKey = args.getString(0);
            String assetPath = args.getString(1);
            this.preloadSound(assetKey, assetPath, callbackContext);
            return true;
        }

        if (action.equals("playSound")) {
            String assetKey = args.getString(0);
            this.playSound(assetKey, callbackContext);
            return true;
        }

        return false;
    }

    private void playSound(String assetKey, CallbackContext callbackContext) {
        if (assetKey.isEmpty()) {
            callbackContext.error("Expected audio key to play an audio");
        } else {
            // Start playing audio
            if (player != null) {
                player.start();
            }
        }
    }

    private void preloadSound(String assetKey, String assetPath, CallbackContext callbackContext) {
        if (assetKey.isEmpty() || assetPath.isEmpty()) {
            callbackContext.error("Expected asset key or path for preloading sounds");
        } else {
            // Start preloading sounds
            Log.d(TAG, "preloadSound: Asset key = " + assetKey + ", Asset path: " + assetPath);
            player = new MediaPlayer();
            try {
                player.setDataSource(assetPath);
                player.prepare();
                callbackContext.success();
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }
    }
}
