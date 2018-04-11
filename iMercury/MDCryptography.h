//
//  MDCryptography.h
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MDCryptography : NSObject
+ (NSData *)pandoraEncrypt:(NSData*) data withPartnerEncryptKey: (unsigned char*) partnerEncryptKey;
+ (NSData *)pandoraDecrypt:(NSString*) string withPartnerDecryptKey: (unsigned char*) partnerDecryptKey;
@end
