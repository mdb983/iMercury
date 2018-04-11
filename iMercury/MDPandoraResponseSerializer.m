//
//  MDPandoraResponseSerializer.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright (c) 2016 Marino di Barbora. All rights reserved.
//

#import "MDPandoraResponseSerializer.h"

@implementation MDPandoraResponseSerializer 



- (NSDictionary*)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    NSError *jsonError;
    NSString * __unused repStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
   // NSLog(@"response data string: %@",repStr);
    NSDictionary  *respObject = [NSJSONSerialization JSONObjectWithData:data options: kNilOptions error:&jsonError];
    return respObject;
}
@end
