//
//  MDConstants.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16..
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDConstants.h"



NSString *const kMDAuthenticationNotification          = @"com.blackdogsoftwarecompany.iMercury.authentication.Status";
NSString *const kMDStationNotification                 = @"com.blackdogsoftwarecompany.iMercury.stations.change";
NSString *const kMDFeedbackNotification                = @"com.blackdogsoftwarecompany.iMercury.stations.feedback";
NSString *const kMDReadyWithfirstSongNotification      = @"com.blackdogsoftwarecompany.iMercury.songs.loaded";
NSString *const kMDSongArtworkChangedSongNotification  = @"com.blackdogsoftwarecompany.iMercury.songs.artworkLoaded";


char *const kMDBackgroundQueue                         = "com.blackdogsoftwarecompany.iMercury.Queue.background";
char *const kMDStationBackgroundQueue                  = "com.blackdogsoftwarecompany.iMercury.Queue.station";
char *const kMDBackgroundProcessingQueue               = "com.blackdogsoftwarecompany.iMercury.Queue.PlayerControllerProcessing";


NSString *const kMDAnimationCompleteNotification       = @"com.blackdogsoftwarecompany.iMercury.Animation.completion";
NSString *const kMDTrackChangeNotification             = @"com.blackdogsoftwarecompany.iMercury.Track.change";


NSString *const pandoraJasonAuthenticationEndPoint = @"https://tuner.pandora.com/services/json/?method=%@&partner_id=%@&auth_token=%@&user_id=%@";
NSString *const pandoraJasonRequestEndPoint = @"http://tuner.pandora.com/services/json/?method=%@&partner_id=%@&auth_token=%@&user_id=%@";
NSString *const pandoraSearchJasonRequestEndPoint = @"http://autocomplete.pandora.com/services/json/?method=%@&partner_id=%@&auth_token=%@&user_id=%@";


#pragma mark - errors locations
NSString *const kMDAuthenticationAction = @"Authentication";
NSString *const kMDStationAction = @"StationList";
NSString *const kMDSearchAction = @"SongOrArtistSearch";
