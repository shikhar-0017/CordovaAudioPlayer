/********* CordovaAudioPlayer.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import <AVFoundation/AVFoundation.h>


@interface CordovaAudioPlayer : CDVPlugin <AVAudioPlayerDelegate>{}

@property (nonatomic, strong) NSMutableDictionary *preloadedSounds;
@property (nonatomic, strong) NSMutableDictionary *callbackIds;


- (void)preloadSound:(CDVInvokedUrlCommand*)command;
- (void)playSound:(CDVInvokedUrlCommand*)command;

@end

@implementation CordovaAudioPlayer

- (void)pluginInitialize{
    NSLog(@"Custom Audio Plugin init");
    self.preloadedSounds = [NSMutableDictionary dictionary];
    self.callbackIds = [NSMutableDictionary dictionary];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (void)preloadSound:(CDVInvokedUrlCommand*)command {
    NSString *assetKey = [command.arguments objectAtIndex:0];
    NSString *assetPath = [command.arguments objectAtIndex:1];
    NSString* basePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"www"];
    NSString* soundPath = [NSString stringWithFormat:@"%@/%@", basePath, assetPath];
    NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
    

    if ([self.preloadedSounds valueForKey:assetKey]) {
        // Audio already preloaded for this key
        NSLog(@"Audio already preloaded for key: %@", assetKey);
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
    }else{
        [self.commandDelegate runInBackground:^{
            NSError *error;
            AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&error];
            audioPlayer.delegate = self;
            
            if (audioPlayer) {
                [audioPlayer prepareToPlay];
                [self.preloadedSounds setObject:audioPlayer forKey:assetKey];
            } else {
                NSLog(@"Error loading sound for key %@: %@", assetKey, error.localizedDescription);
            }
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
        }];
    }
}

- (void)playSound:(CDVInvokedUrlCommand*)command {
    NSString *audioKey = [command.arguments objectAtIndex:0];
    NSString *path = [[self.preloadedSounds[audioKey] url] path];
    if(path){
        [self.callbackIds setObject:command.callbackId forKey:path];
        [self.commandDelegate runInBackground:^{
            AVAudioPlayer *audioPlayer = self.preloadedSounds[audioKey];
            if (audioPlayer) {
                [audioPlayer setCurrentTime: 0.0];
                [audioPlayer play];
            } else {
                NSLog(@"Sound not preloaded");
            }
        }];
    }
}

- (void)stopSound:(CDVInvokedUrlCommand*)command {
    NSString *audioKey = [command.arguments objectAtIndex:0];
    AVAudioPlayer *audioPlayer = self.preloadedSounds[audioKey];
    if(audioPlayer && [audioPlayer isPlaying]){
        [audioPlayer stop];
        NSLog(@"%@ audio stopped successfully", audioKey);
    }else{
        NSLog(@"Error in stopping audio");
    }
}


- (void)stopAllSounds:(CDVInvokedUrlCommand*)command {
    for (AVAudioPlayer *player in self.preloadedSounds) {
        if ([player isPlaying ]) {
            [player stop];
        }
    }
    NSLog(@"Finished stopping all sounds");
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)isCompleted{
    
    NSString *path = [[[player url] path] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSString *callbackId = [self.callbackIds objectForKey:path];
    
    if (isCompleted && callbackId) {
        NSLog(@"Finished playing successfully");
        // Send success result to Cordova using the stored callbackId
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:callbackId];
        
        // Remove the callback ID for this sound to avoid duplicate responses
        [self.callbackIds removeObjectForKey:path];
    } else {
        NSLog(@"Finished playing with an error");
        // Send error result to Cordova using the stored callbackId
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Failed to play sound"] callbackId:callbackId];
    }
}

@end