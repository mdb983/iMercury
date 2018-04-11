//
//  initialViewController.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16.
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDInitialViewController.h"
#import "MDCryptography.h"
#import "MDPandoraPlayerManager.h"
#import "MDCrossDissolveAnimation.h"
#import "MDPlayViewController.h"
#import "MDConstants.h"

@interface MDInitialViewController () <UINavigationControllerDelegate>

@end

@implementation MDInitialViewController 

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    return self;
}


- (void)viewDidLoad{
    [super viewDidLoad];
    [self autoAuthenticate];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.navigationController.delegate = self;
}


-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (self.navigationController.delegate == self) {
        self.navigationController.delegate = nil;
    }
}


- (BOOL)prefersStatusBarHidden
{
    return YES;
}
- (void) autoAuthenticate{
    
    NSString *encryptedLoginName = [[NSUserDefaults standardUserDefaults]valueForKey:@"userName"] ;
    
    if (encryptedLoginName) {
        // Login Name
        NSData *unencryptedLoginNameData = [MDCryptography pandoraDecrypt:encryptedLoginName withPartnerDecryptKey:(unsigned char *)PARTNER_DECRYPT];
        NSString *loginName = [NSString stringWithUTF8String:[unencryptedLoginNameData bytes]];
        //Password
        NSString *encryptedPassword = [[NSUserDefaults standardUserDefaults]valueForKey:@"password"] ;
        NSData *unencryptedPasswordData =  [MDCryptography pandoraDecrypt:encryptedPassword withPartnerDecryptKey:(unsigned char *)PARTNER_DECRYPT];
        NSString *password = [NSString stringWithUTF8String:[unencryptedPasswordData bytes]];
        
        [[MDPandoraPlayerManager client]authenticateUser:loginName password:password  success:^(BOOL * _Nullable success) {
            if (success) {
                [[NSNotificationCenter defaultCenter]removeObserver:self];
                [self performSegueWithIdentifier:@"playerSegue" sender:self];
            }else{
                 [self performSegueWithIdentifier:@"loginSegue" sender:self];
            }
            
        } failure:^(NSError * _Nullable error) {
           
            [self performSegueWithIdentifier:@"loginSegue" sender:self];
        }];
    }else{
       [self performSegueWithIdentifier:@"loginSegue" sender:self];   
    }
    
}

#pragma mark UINavigationControllerDelegate methods

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC {

    if (fromVC == self && [toVC isKindOfClass:[MDPlayViewController class]]) {
        return [[MDCrossDissolveAnimation alloc] init];
    }
    
    return nil;
}


@end


