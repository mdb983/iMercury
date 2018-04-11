//
//  AppDelegate.m
//  iMercury
//
//  Created by Marino di Barbora on 2/3/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDAppDelegate.h"
#import "MDPandoraPlayerManager.h"
#import "MDPandoraInterface.h"
#import "AFImageDownloader.h"

@interface MDAppDelegate ()

@end

@implementation MDAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // expensive init - invoke at startup
    MDPandoraInterface *pandoraInterface = [[MDPandoraInterface alloc]initWithBaseURL:nil];
    MDPandoraPlayerManager *initClient = [MDPandoraPlayerManager client];
    //
    initClient.pandoraInterface = pandoraInterface;
    
    AFImageDownloader __unused *initImageDownloader = [AFImageDownloader defaultInstance];
    
    // hook into global Audio Session for Lock Screen Access
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    NSError *setCategoryError = nil;
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    
    NSError *activationError = nil;
    [audioSession setActive:YES error:&activationError];
    if (activationError) {
        NSLog(@"activationError %@",activationError);
    }else{
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }
    
    // set the tint color glbally
    [self.window setTintColor:[UIColor whiteColor]];
 
    //set properties for nav bar
    NSShadow *shadow = [NSShadow new];
    shadow.shadowOffset = CGSizeMake(0,0);
    shadow.shadowColor = [UIColor clearColor];
    shadow.shadowBlurRadius = 0.0;
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName: [UIFont fontWithName:@"AvenirNext-Regular" size:18.0],
                                                           NSForegroundColorAttributeName: [UIColor whiteColor],
                                                           NSShadowAttributeName:shadow,
                                                           } forState:UIControlStateNormal];
  

    return YES;
}




- (void)applicationWillResignActive:(UIApplication *)application {
    [[MDPandoraPlayerManager client]setPlayingNowInfo];
    [[MDPandoraPlayerManager client]activeAppState:NO ];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
      [[MDPandoraPlayerManager client]activeAppState:YES ];
}

//MARK: -  Global Audio Control callbacks
- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlStop:
                [[MDPandoraPlayerManager client] playOrStop];
                break;
                
            case UIEventSubtypeRemoteControlPause:
                [[MDPandoraPlayerManager client] playOrStop];
                break;
                
            case UIEventSubtypeRemoteControlPlay:
                [[MDPandoraPlayerManager client] playOrStop];
                break;
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [[MDPandoraPlayerManager client] playOrStop];
                break;
       
            case UIEventSubtypeRemoteControlPreviousTrack:
                [[MDPandoraPlayerManager client] rewindTrack];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                [[MDPandoraPlayerManager client] playNextSong];
                break;
                
            default:
                break;
        }
    }
}


@end
