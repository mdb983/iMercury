//
//  MDConstants.h
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//




#pragma mark - Pandora Constants

//define for android
//#define PARTNER_USERNAME @"android"
//#define PARTNER_PASSWORD @"AC7IBG09A3DTSYM4R41UJWL07VLN8JI7"
//#define PARTNER_DEVICEID @"android-generic"
//#define PARTNER_DECRYPT  "R=U!LH$O2B#"
//#define PARTNER_ENCRYPT  "6#26FRL$ZWD"


//define for iphone

#define PARTNER_USERNAME @"iphone"
#define PARTNER_PASSWORD @"P2E4FC0EAD3*878N92B2CDp34I0B1@388137C"
#define PARTNER_DEVICEID @"IP01"
#define PARTNER_DECRYPT  "20zE1E47BE57$51"
#define PARTNER_ENCRYPT  "721^26xE22776"


#define PANDORA_API_VERSION @"5"


#pragma mark - NSNotification
#define kWHBackgroundFetchQueue "com.blackdogsoftwarecompany.iMercury.utility.backgroundFetchQueue"
extern NSString *const kMDAuthenticationNotification;
extern NSString *const kMDStationNotification;
extern NSString *const  kMDFeedbackNotification;
extern NSString *const kMDReadyWithfirstSongNotification;
extern NSString *const kMDTrackChangeNotification;
extern NSString *const kMDSongArtworkChangedSongNotification;


#pragma mark - queues
extern char *const kMDBackgroundQueue;
extern char *const kMDStationBackgroundQueue;
extern char *const kMDBackgroundProcessingQueue;

#pragma mark - Animations
extern NSString *const kMDAnimationCompleteNotification;

#pragma mark - Endpoints
extern NSString *const pandoraJasonAuthenticationEndPoint;
extern NSString *const pandoraJasonRequestEndPoint;
extern NSString *const pandoraSearchJasonRequestEndPoint;

#pragma mark - errors locations
extern NSString *const kMDAuthenticationAction;
extern NSString *const kMDStationAction;
extern NSString *const kMDSearchAction;

#pragma mark - enums

typedef NS_ENUM(NSInteger, MDPlayProgressViewMenuItem) {
    MDProgressViewMenu,
    MDProgresViewEQ,
};
