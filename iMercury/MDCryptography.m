//
//  MDCryptography.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDCryptography.h"
#import "MDConstants.h"
#import "blowfish.h"






@implementation MDCryptography

static char i2h[16] = "0123456789abcdef";
static char h2i[256] = {
    ['0'] = 0, ['1'] = 1, ['2'] = 2, ['3'] = 3, ['4'] = 4, ['5'] = 5, ['6'] = 6,
    ['7'] = 7, ['8'] = 8, ['9'] = 9, ['a'] = 10, ['b'] = 11, ['c'] = 12,
    ['d'] = 13, ['e'] = 14, ['f'] = 15
};

static void appendByte(unsigned char byte, void *_data) {
    NSMutableData *data = (__bridge NSMutableData*) _data;
    [data appendBytes:&byte length:1];
}

static void appendHex(unsigned char byte, void *_data) {
    NSMutableData *data = (__bridge NSMutableData*) _data;
    char bytes[2];
    bytes[1] = i2h[byte % 16];
    bytes[0] = i2h[byte / 16];
    [data appendBytes:bytes length:2];
}


+ (NSData*) pandoraDecrypt:(NSString*) string  withPartnerDecryptKey: (unsigned char*) partnerDecryptKey{
    struct blf_ecb_ctx ctx;
    NSMutableData *mut = [[NSMutableData alloc] init];

  
    Blowfish_ecb_start(&ctx, FALSE, (const unsigned char*) partnerDecryptKey,
                      (int) strlen((char*)partnerDecryptKey) , appendByte,
                      (__bridge void*) mut);
    
    const char *bytes = [string cStringUsingEncoding:NSUTF8StringEncoding];
    NSUInteger len = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    int i;
      for (i = 0; i < len  ; i += 2) {
        Blowfish_ecb_feed(&ctx, h2i[(int) bytes[i]] * 16 + h2i[(int) bytes[i + 1]]);
    }
    Blowfish_ecb_stop(&ctx);
    
    return mut;
}

+(NSData*) pandoraEncrypt:(NSData* )data withPartnerEncryptKey: (unsigned char*) partnerEncryptKey{
    struct blf_ecb_ctx ctx;
    NSMutableData *mut = [[NSMutableData alloc] init];


    Blowfish_ecb_start(&ctx, TRUE, (const unsigned char*) partnerEncryptKey,
                      (int) strlen((char*)partnerEncryptKey) , appendHex,
                      (__bridge void*) mut);

    const unsigned char *bytes = [data bytes];
    NSUInteger len = [data length];
    int i;
    for (i = 0; i < len; i++) {
        Blowfish_ecb_feed(&ctx, bytes[i]);
    }
    Blowfish_ecb_stop(&ctx);
    
    return mut;
}


@end
