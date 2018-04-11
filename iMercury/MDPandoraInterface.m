//
//  MDPandoraInterface.m
//  iMercury
//
//  Created by Marino di Barbora on 2/3/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDPandoraInterface.h"
#import "MDCryptography.h"
#import "MDPandoraRequestSerializer.h"
#import "MDPandoraResponseSerializer.h"
#import "MDConstants.h"
#import "MDStation.h"
#import "MDSong.h"
#import "MDSeedBase.h"
#import "MDSearchResult.h"

@interface MDPandoraInterface ()
@property (nonatomic) NSString *partnerAuthToken;
@property (nonatomic) NSString *partnerID;
@property (nonatomic) NSString *userAuthToken;
@property (nonatomic) NSString *userID;
@property (assign, nonatomic) long long syncTime;
@property (assign, nonatomic) long long startTime;
@property (nonatomic) NSString *userName;
@property (nonatomic) NSString * password;
@property (nonatomic) NSDictionary *errorDictionary;
@property (nonatomic) BOOL didAuthenticate;
@property (nonatomic) AFHTTPSessionManager *sessionManager;
@property (nonatomic) NSMutableArray * taskArray;
@end

@implementation MDPandoraInterface

- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super init];
    if (self)
    {
        NSURLSessionConfiguration *sConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sConfig.HTTPMaximumConnectionsPerHost = 12;
        
        _sessionManager = [[AFHTTPSessionManager alloc]initWithBaseURL:url sessionConfiguration:sConfig];
        _sessionManager.requestSerializer = [MDPandoraRequestSerializer serializer];
        _sessionManager.responseSerializer = [MDPandoraResponseSerializer serializer];
        _taskArray = [NSMutableArray new];
        [self setupPandoraErrorDictionary];
    }
    return self;
}

#pragma mark - Authentication

- (void)startUserAuthentication:(NSString*)userName password:(NSString*)password success:(nullable void (^)(id _Nonnull responseObject))success authenticationFailure:(nullable void (^)(NSError  * _Nullable error))authenticationFailure {
    
    //Store credentials for retry on listeningtime/authtoken expired;
    self.userName = userName;
    self.password = password;
  
    if (!self.startTime) {
        self.startTime = [[NSDate date]timeIntervalSince1970];
    }
    
    //if login fails on user credentials, skip partner authentication or pandora will respond with internal error
    if (self.partnerAuthToken) {
        [self authenticationUser:self.userName password:self.password success:success authenticationFailure:authenticationFailure];
    }else{
    
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"username": PARTNER_USERNAME,
                                                                                      @"password": PARTNER_PASSWORD,
                                                                                      @"deviceModel": PARTNER_DEVICEID,
                                                                                      @"version": PANDORA_API_VERSION,
                                                                                      @"includeUrls": [NSNumber numberWithBool:YES]}];
    
    
        [self.sessionManager POST:[self authenticationStringForAction:@"auth.partnerLogin"] parameters:params
                                                                            progress:nil
                                                                            success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
        {
            NSString *status  = [responseObject  valueForKey: @"stat"];
            NSDictionary *res = [responseObject objectForKey: @"result"];

            if (status && [status isEqualToString:@"ok"]) {
                self.partnerAuthToken = [res valueForKey: @"partnerAuthToken"];
                self.partnerID = [res valueForKey: @"partnerId"];
                NSData *sync = [MDCryptography pandoraDecrypt:[res valueForKey:@"syncTime"]
                                        withPartnerDecryptKey:(unsigned char *)PARTNER_DECRYPT];
                
                const char *bytes = [sync bytes];
                self.syncTime = strtoull(bytes + 4, NULL, 10);
                
                [self authenticationUser:self.userName password:self.password success:success authenticationFailure:authenticationFailure];
            }else{
                NSError *errorStatus = [self formatResponseFromErrorCode:[[responseObject valueForKey:@"code"] integerValue] fromAction:kMDAuthenticationAction];
                authenticationFailure(errorStatus);
            }
     
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
           NSLog(@"ERROR: %@", error);
        }];
    }
}



- (void)authenticationUser:(NSString*)userName password:(NSString*)password success:(nullable void (^)(id _Nullable responseObject))success
                                                                            authenticationFailure:(nullable void (^)(NSError  * _Nullable error))authenticationFailure{
    
    NSMutableDictionary *params =  [NSMutableDictionary dictionaryWithDictionary:@{@"loginType": @"user",
                                                                                   @"username": self.userName,
                                                                                   @"password": self.password,
                                                                                   @"partnerAuthToken": self.partnerAuthToken,
                                                                                   @"includePandoraOneInfo": [NSNumber numberWithBool:NO],
                                                                                   @"includeAdAttributes": [NSNumber numberWithBool:NO],
                                                                                   @"includeSubscriptionExpiration": [NSNumber numberWithBool:NO],
                                                                                   @"syncTime": [NSNumber numberWithLongLong:[self syncTimeNum]]}];
   
    
   [self.sessionManager POST:[self authenticationStringForAction:@"auth.userLogin"] parameters:params  progress:nil success:^(NSURLSessionDataTask * _Nonnull task,  id  _Nullable responseObject)
    {
        NSString *status  = [responseObject  valueForKey: @"stat"];
        NSDictionary *res = [responseObject objectForKey: @"result"];
        
        if ([status isEqualToString:@"ok"]) {
            self.userAuthToken = [res valueForKey:@"userAuthToken"];
            self.userID = [res valueForKey:@"userId"];
            self.didAuthenticate = YES;
            success(responseObject);
        }else{
            NSError *errorStatus = [self formatResponseFromErrorCode:[[responseObject valueForKey:@"code"] integerValue] fromAction:kMDAuthenticationAction];
            authenticationFailure(errorStatus);
        }
   } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
       authenticationFailure(error);

   }];
}


#pragma mark - Station 

- (void)retrieveStationList: (nonnull void (^)(id _Nonnull responseObject))success stationLoadFailure:(nullable void (^)(NSError  * _Nullable error))stationLoadFailure
{

    NSMutableDictionary *params =  [NSMutableDictionary dictionaryWithDictionary:@{@"userAuthToken": self.userAuthToken,
                                                                                   @"syncTime": [NSNumber numberWithLongLong:[self syncTimeNum]],
                                                                                   @"includeStationArtUrl" : [NSNumber numberWithBool:YES],
                                                                                   @"stationArtSize": @"W250H250",
                                                                                   @"includeStationSeeds": [NSNumber numberWithBool:NO],
                                                                                   @"includeRecommendations": [NSNumber numberWithBool:NO]}];
    
    
    [self.sessionManager POST:[self requestStringForAction:@"user.getStationList"] parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSString *status = [responseObject valueForKey:@"stat"];
        
        if ([status isEqualToString:@"ok"]) {
            success(responseObject);
        }else{
            NSError *errorStatus = [self formatResponseFromErrorCode:[[responseObject valueForKey:@"code"] integerValue] fromAction:kMDStationAction];
            stationLoadFailure(errorStatus);
        }
    
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              stationLoadFailure(error);

    }];
}



- (void)loadExtendedDetailsForStation:(MDStation * _Nonnull)currentStation success:(nonnull void (^)(id _Nonnull responseObject))success stationExtendedDetailsFailure:(nullable void (^)(NSError  * _Nullable error))stationExtendedDetailsFailure{
    
    NSMutableDictionary *params =  [NSMutableDictionary dictionaryWithDictionary:@{@"userAuthToken": self.userAuthToken,
                                                                                   @"stationToken": currentStation.stationId,
                                                                                   @"includeExtendedAttributes": [NSNumber numberWithBool:YES],
                                                                                   @"syncTime": [NSNumber numberWithLongLong:[self syncTimeNum]]}];
    
    [self.sessionManager POST:[self requestStringForAction:@"station.getStation"] parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
 
        NSString *status = [responseObject valueForKey:@"stat"];
      
        if ([status isEqualToString:@"ok"]) {
            success(responseObject);
        }else{
            NSError *errorStatus = [self formatResponseFromErrorCode:[[responseObject valueForKey:@"code"] integerValue] fromAction:kMDStationAction];
            stationExtendedDetailsFailure(errorStatus);
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        stationExtendedDetailsFailure(error);
    }];

}



- (void)loadSongsForStation:(MDStation * _Nonnull)station success:(nonnull void (^)(id _Nonnull responseObject))success stationSongLoadFailure:(nullable void (^)(NSError  * _Nullable error))stationSongLoadFailure{

    // Pandora's getPlaylist API returns 4 song
    NSMutableDictionary *params =  [NSMutableDictionary dictionaryWithDictionary:@{@"userAuthToken": self.userAuthToken,
                                                                                   @"stationToken": station.stationToken,
                                                                                   @"additionalAudioUrl":
                                                                                   @"HTTP_32_AACPLUS_ADTS,HTTP_64_AACPLUS_ADTS,HTTP_128_MP3",
                                                                                   @"syncTime": [NSNumber numberWithLongLong:[self syncTimeNum]]}];
 
    [self.sessionManager POST:[self requestStringForAction:@"station.getPlaylist"] parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSString *status = [responseObject valueForKey:@"stat"];
        
        if ([status isEqualToString:@"ok"]) {
            success(responseObject);
        }else{
            NSError *errorStatus = [self formatResponseFromErrorCode:[[responseObject valueForKey:@"code"] integerValue] fromAction:kMDStationAction];
            stationSongLoadFailure(errorStatus);
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        stationSongLoadFailure(error);
    }];
}



- (void)addFeedbackForCurrentSong:(MDSong * _Nonnull)song isPositive:(BOOL)positive forStation:(MDStation * _Nonnull)station success:(nonnull void (^)(id _Nonnull responseObject))success stationSongLoadFailure:(nullable void (^)(NSError  * _Nullable error))feedbackAdditionError{

    NSMutableDictionary *params =  [NSMutableDictionary dictionaryWithDictionary:@{@"trackToken": song.songToken,
                                                                                   @"isPositive": @(positive),
                                                                                   @"userAuthToken": self.userAuthToken,
                                                                                   @"syncTime": [NSNumber numberWithLongLong:[self syncTimeNum]],
                                                                                   @"stationToken": song.stationId}];

    [self.sessionManager POST:[self requestStringForAction:@"station.addFeedback"] parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
       
        NSString *status = [responseObject valueForKey:@"stat"];
       
        if ([status isEqualToString:@"ok"]) {
            success(responseObject);
        }else{
            NSError *errorStatus = [self formatResponseFromErrorCode:[[responseObject valueForKey:@"code"] integerValue] fromAction:kMDStationAction];
            feedbackAdditionError(errorStatus);
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        feedbackAdditionError(error);
    }];
}



- (void)createStationFromSearchResult:(MDSearchResult*)searchResult success:(nonnull void (^)(id _Nonnull responseObject))success createStationFailure:(nullable void (^)(NSError  * _Nullable error))createStationError{
    
    NSString *musicType = (searchResult.songName == nil) ? @"artist" :@"song";
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"musicToken": searchResult.musicToken,
                                                                                  @"musicType": musicType,
                                                                                  @"includeStationArtUrl": [NSNumber numberWithBool:YES],
                                                                                  @"stationArtSize": @"W250H250",
                                                                                  @"userAuthToken": self.userAuthToken,
                                                                                  @"syncTime": [NSNumber numberWithLongLong:[self syncTimeNum]]}];
 

    [self.sessionManager POST:[self requestStringForAction:@"station.createStation"] parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
       
        NSString *status = [responseObject valueForKey:@"stat"];
      
        if ([status isEqualToString:@"ok"]) {
            success(responseObject);
        }else{
            NSError *errorStatus = [self formatResponseFromErrorCode:[[responseObject valueForKey:@"code"] integerValue] fromAction:kMDStationAction];
            createStationError(errorStatus);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        createStationError(error);
    }];

}



- (void)createSeedFromSearchResult:(MDSearchResult * _Nonnull)searchResult forStation:(MDStation * _Nonnull)station  success:(nonnull void (^)(id               _Nonnull responseObject))success createSeedFailure:(nullable void (^)(NSError  * _Nullable error))createSeedError{

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{@"musicToken": searchResult.musicToken,
                                                                                  @"stationToken": station.stationToken,
                                                                                  @"userAuthToken": self.userAuthToken,
                                                                                  @"syncTime": [NSNumber numberWithLongLong:[self syncTimeNum]]}];

    
    [self.sessionManager POST:[self requestStringForAction:@"station.addMusic"] parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSString *status = [responseObject valueForKey:@"stat"];
    
        if ([status isEqualToString:@"ok"]) {
            success(responseObject);
        }else{
            NSError *errorStatus = [self formatResponseFromErrorCode:[[responseObject valueForKey:@"code"] integerValue] fromAction:kMDStationAction];
            createSeedError(errorStatus);
        }

        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        createSeedError(error);
    }];
    
}

- (void) deleteStationForStation:(MDStation*) stationToDelete{
    NSMutableDictionary *params =  [NSMutableDictionary dictionaryWithDictionary:@{@"userAuthToken": self.userAuthToken,
                                                                                   @"stationToken": stationToDelete.stationToken,
                                                                                   @"syncTime": [NSNumber numberWithLongLong:[self syncTimeNum]]}];
    
 [self.sessionManager POST:[self requestStringForAction:@"station.deleteStation"] parameters:params progress:nil success:nil failure:nil];
}

- (void) deleteSeedForSeedId:(MDSeedBase *)seedToDelete success:(void (^)(BOOL))success{
    NSMutableDictionary *params = [ NSMutableDictionary dictionaryWithDictionary:@{@"userAuthToken":self.userAuthToken,
                                                                                   @"syncTime":[NSNumber numberWithLongLong:[self syncTimeNum]],
                                                                                   @"seedId":seedToDelete.seedId                                                                                   }];
    [self.sessionManager POST:[self requestStringForAction:@"station.deleteMusic"] parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject){
        success(YES);
    }
    failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error){
        success(NO);
    }];
     

}

#pragma mark - Search

- (void)searchForSongOrArtist:(NSString * _Nonnull)searchString success:(nonnull void (^)(id _Nonnull responseObject))success searchFailure:(nullable void (^)(NSError  * _Nullable error))songOrArtistSearchError{
    
    // called on incremental search,  if the response has yet to be received, cancel it
    for (NSURLSessionDataTask *task in self.taskArray) {
        [task cancel];
    }

    
    NSMutableDictionary *params =  [NSMutableDictionary dictionaryWithDictionary:@{@"searchText": searchString,
                                                                                   @"userAuthToken": self.userAuthToken,
                                                                                   @"syncTime": [NSNumber numberWithLongLong:[self syncTimeNum]]}];
    
    
    NSURLSessionDataTask *currentTask =  [self.sessionManager POST:[self requestStringForAction:@"music.search"] parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
      [self.taskArray removeObject:task];
        NSString *status = [responseObject valueForKey:@"stat"];
        if ([status isEqualToString:@"ok"]) {
            
            success(responseObject);
        }else{
            NSError *errorStatus = [self formatResponseFromErrorCode:[[responseObject valueForKey:@"code"] integerValue] fromAction:kMDSearchAction];
            songOrArtistSearchError(errorStatus);
        }

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.taskArray removeObject:task];
        songOrArtistSearchError(error);
    }];
    
    [self.taskArray addObject:currentTask ];
}




#pragma mark - Helper methods

- (NSString*)urlEncoded: (NSString*)unescapedString
{
     NSString *encodedString = [unescapedString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:              @"!*'();:@$,#[]"]];
     return encodedString;
}


- (long long)getRelativeTime{
    return [[NSDate date]timeIntervalSince1970];
}

- (long long)syncTimeNum {
    return self.syncTime + ([self getRelativeTime] - self.startTime);
}


- (NSError*)formatResponseFromErrorCode:(NSInteger) errorCode fromAction:(NSString*) actionString {
    
    if (errorCode == 1001) {
         NSLog(@"hit 1001 error - probably token expired");
        self.syncTime = self.startTime = 0;
        self.partnerAuthToken = nil;
        self.userAuthToken = nil;
        [self startUserAuthentication:self.userName password:self.password success:nil authenticationFailure:nil];
        
        [self startUserAuthentication:self.userName password:self.password success:nil authenticationFailure:nil ];
       
    }
    
    NSDictionary *errorInfoDictionary = @{@(errorCode) : [self.errorDictionary valueForKey:[@(errorCode) stringValue] ] };
    NSError *responseError = [[NSError alloc]initWithDomain:actionString code:errorCode userInfo:errorInfoDictionary];
    return responseError;
}

- (NSString *) authenticationStringForAction:(NSString*) action{
    return [NSString stringWithFormat:pandoraJasonAuthenticationEndPoint,action,self.partnerID,[self urlEncoded: self.partnerAuthToken],self.userID ];
}

- (NSString *) requestStringForAction: (NSString*) action{
    return [NSString stringWithFormat:pandoraJasonRequestEndPoint,action,self.partnerID,[self urlEncoded: self.userAuthToken],self.userID];
}




- (void)setupPandoraErrorDictionary{
    
    self.errorDictionary = @{@"0" : @"Internal Pandora error",
                             @"1" : @"Pandora is in Maintenance Mode",
                             @"2" : @"URL parameter error",
                             @"3" : @"URL authentication token error",
                             @"4" : @"URL partner ID error",
                             @"5" : @"URL user ID error",
                             @"6" : @"secure protocol request error",
                             @"7" : @"certificate request error",
                             @"8" : @"Parameter mismatch error",
                             @"9" : @"missing Parameter error",
                            @"10" : @"Invalid Parameter Value",
                            @"11" : @"Invalid API Version",
                            @"12" : @"Country availability error",
                            @"13" : @"Bad sync time",
                            @"14" : @"Unknown method name",
                            @"15" : @"Wrong protocol used",
                          @"1000" : @"Read only mode",
                          @"1001" : @"Invalid authentication token",
                          @"1002" : @"Wrong user credentials",
                          @"1003" : @"Listener not authorized",
                          @"1004" : @"User not authorized",
                          @"1005" : @"Station limit reached",
                          @"1006" : @"Station does not exist",
                          @"1007" : @"Complimentary period already in use",
                          @"1008" : @"Call not allowed",
                          @"1009" : @"Device not found",
                          @"1010" : @"Partner not authorized",
                          @"1011" : @"Invalid username",
                          @"1012" : @"Invalid password",
                          @"1013" : @"Username already exists",
                          @"1014" : @"Device already associated to account",
                          @"1015" : @"Upgrade, device model is invalid",
                          @"1018" : @"Explicit PIN incorrect",
                          @"1020" : @"Explicit PIN malformed",
                          @"1023" : @"Device model invalid",
                          @"1024" : @"ZIP code invalid",
                          @"1025" : @"Birth year invalid",
                          @"1026" : @"Birth year too young",
                          @"1027" : @"Invalid country code",
                          @"1028" : @"Invalid gender",
                          @"1032" : @"Cannot remove all seeds",
                          @"1034" : @"Device disabled",
                          @"1035" : @"Daily trial limit reached",
                          @"1036" : @"Invalid sponsor",
                          @"1037" : @"User already used trial"
                                                            };
    
}



@end
