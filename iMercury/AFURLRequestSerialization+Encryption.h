//
//  AFURLRequestSerialization+Encryption.h
//  iMercury
//
//  Created by Marino di Barbora on  2/8/16.
//  Copyright (c) 2015 Marino di Barbora. All rights reserved.
//

#import "AFURLRequestSerialization.h"

@interface  AFJSONRequestSerializer(Encryption)
- (NSURLRequest *)requestBySerializingRequestForEncryptedData:(NSURLRequest *)request
                                               withParameters:(id)parameters
                                                        error:(NSError *__autoreleasing *)error;
@end
