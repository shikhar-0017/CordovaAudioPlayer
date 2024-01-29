package com.plugin.cordova.audioplayer;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.SoundPool;
import android.net.rtp.AudioStream;
import android.os.AsyncTask;
import android.util.Log;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.json.JSONArray;
import org.json.JSONException;

import java.io.IOException;
import java.util.HashMap;

/**
 * This class echoes a string called from JavaScript.
 */
public class CordovaAudioPlayer extends CordovaPlugin {

    private static final String TAG = "CordovaAudioPlayer:Android";
    private final HashMap<String, MediaPlayer> playerMaps = new HashMap<>();

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

        if (action.equals("preloadSound")) {
            String audioKey = args.getString(0);
            String audioPath = args.getString(1);
            this.preloadSound(audioKey, audioPath, callbackContext);
            return true;
        }

        if (action.equals("playSound")) {
            String audioKey = args.getString(0);
            this.playSound(audioKey, callbackContext);
            return true;
        }

        if (action.equals("stopSound")) {
            String audioKey = args.getString(0);
            this.stopSound(audioKey, callbackContext);
            return true;
        }

        return false;
    }

    private void preloadSound(String audioKey, String audioPath, CallbackContext callbackContext) {
        if (audioKey.isEmpty() || audioPath.isEmpty()) {
            callbackContext.error("Expected asset key or path for preloading sounds");
        } else {
            // Start preloading sounds
            new Thread(() -> {
                String fullPath = "www/".concat(audioPath);
                Context ctx = cordova.getActivity().getApplicationContext();
                AssetManager am = ctx.getResources().getAssets();
                MediaPlayer player = new MediaPlayer();
                try {
                    AssetFileDescriptor afd = am.openFd(fullPath);
                    player.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
                    player.prepare();
                    player.setAudioStreamType(AudioManager.STREAM_MUSIC);
                    // player.setOnPreparedListener(mp -> {});
                    playerMaps.put(audioKey, player);
                    Log.d(TAG, "preloadSound: Audio key = " + audioKey + ", Audio path: " + audioPath);
                    callbackContext.success();
                } catch (IOException e) {
                    Log.e(TAG, "Error preloading sound: " + e.getMessage());
                    callbackContext.error("Error preloading sound");
                }
            }).start();
        }
    }

    private void playSound(String audioKey, CallbackContext callbackContext) {
        if (audioKey.isEmpty()) {
            callbackContext.error("Expected audio key to play an audio");
        } else {
            // Start playing audio
            Log.d(TAG, "playSound: Playing audio: " + audioKey);
            MediaPlayer player1 = playerMaps.get(audioKey);
            if (player1 != null) {
                player1.seekTo(0);
                player1.start();
                player1.setOnCompletionListener(mp -> {
                    Log.d(TAG, "playSound: Finished playing audio: " + audioKey);
                    callbackContext.success();
                });
            }
        }
    }

    private void stopSound(String audioKey, CallbackContext callbackContext) {
        if (audioKey.isEmpty()) {
            callbackContext.error("Expected audio key to stop an audio");
        } else {
            MediaPlayer player = playerMaps.get(audioKey);
            if (player != null) {
                player.stop();
            }
        }
    }

    private void clearMediaPlayers() {
        for (MediaPlayer player : playerMaps.values()) {
            if (player != null) {
                player.release();
            }
        }
        playerMaps.clear();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        clearMediaPlayers();
    }

    @Override
    public void onStop() {
        super.onStop();
        clearMediaPlayers();
    }
}