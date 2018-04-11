//
//  MDRequestSerializer.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright (c) 2015 Marino di Barbora. All rights reserved.
//

#import "MDPandoraRequestSerializer.h"
#import "AFURLRequestSerialization+Encryption.h"
#include "MDCryptography.h"
#include "MDConstants.h"

@implementation MDPandoraRequestSerializer

- (NSURLRequest*)requestBySerializingRequest:(NSURLRequest *)request withParameters:(NSDictionary *)parameters error:(NSError *__autoreleasing *)error
{
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:request.URL
                                                resolvingAgainstBaseURL:NO];
    
    NSArray *queryItems = urlComponents.queryItems;
    NSPredicate *partnerPredictate = [NSPredicate predicateWithFormat:@"name=%@",@"partner_id"];
    NSURLQueryItem *queryItem = [[queryItems filteredArrayUsingPredicate:partnerPredictate]firstObject];
    NSString *partner_id = queryItem.value;

    if ([partner_id isEqualToString:@"(null)"]) {
        return [super requestBySerializingRequest:request withParameters:parameters error:error];
    } else{
        NSData *tmpData =  [NSJSONSerialization dataWithJSONObject:parameters options:0 error:error];
        NSData *encryptedData = [MDCryptography pandoraEncrypt:tmpData withPartnerEncryptKey:(unsigned char*)PARTNER_ENCRYPT];
        return [super requestBySerializingRequestForEncryptedData:request withParameters:encryptedData error:error];
    }
}

@end
