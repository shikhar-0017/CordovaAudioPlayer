/********* CordovaAudioPlayer.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import <AVFoundation/AVFoundation.h>


@interface CordovaAudioPlayer : CDVPlugin <AVAudioPlayerDelegate>{}

@property (nonatomic, strong) NSMutableDictionary *preloadedSounds;
@property (nonatomic, strong) NSMutableDictionary *callbackIds;


- (void)preloadSounds:(CDVInvokedUrlCommand*)command;
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

- (void)preloadSounds:(CDVInvokedUrlCommand*)command {
    NSArray *assetKey = [command.arguments objectAtIndex:0];
    NSArray *assetPath = [command.arguments objectAtIndex:1];
    NSString* basePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"www"];
    NSString* soundPath = [NSString stringWithFormat:@"%@/%@", basePath, assetPath];
    NSURL *soundURL = [NSURL fileURLWithPath:soundPath];
    
    [self.commandDelegate runInBackground:^{
        NSError *error;
        AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&error];
        audioPlayer.delegate = self;
        
        if (audioPlayer) {
            [audioPlayer prepareToPlay];
            [self.preloadedSounds setObject:audioPlayer forKey:assetKey];
        } else {
            NSLog(@"Error loading sound: %@", error.localizedDescription);
        }
        
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
    }];
    
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