//
//  MDLoginViewController.m
//  iMercury
//
//  Created by Marino di Barbora on 2/8/16..
//  Copyright © 2016 Marino di Barbora. All rights reserved.
//

#import "MDLoginViewController.h"
#import "MDPandoraPlayerManager.h"
#import "MDPlayViewController.h"
#import "MDCrossDissolveAnimation.h"
#import "MDCryptography.h"
#import "MDConstants.h"

@interface MDLoginViewController () <UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *loginName;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

- (IBAction)Authenticate:(id)sender;
@end

@implementation MDLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // UI Tweeks
    self.loginName.layer.borderColor = [UIColor whiteColor].CGColor;
    self.loginName.layer.borderWidth = 0.6f;
    self.password.layer.borderColor = [UIColor whiteColor].CGColor;
    self.password.layer.borderWidth = 0.6f;
    self.loginButton.layer.borderWidth = 0.6f;
    self.loginButton.layer.cornerRadius = 12.0f;
    self.loginButton.layer.borderColor = [UIColor whiteColor].CGColor;
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
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)proceedOnValidAuthentication{
    [self setUserLoginDefaults];
    self.loginButton.enabled = YES;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [self performSegueWithIdentifier:@"playerSegue" sender:self];
   
}

- (void)showAuthenticationFailedAlert{
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Authentication error" message:@"Authentication Failed \n Check your credentials and try again"  preferredStyle: UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [errorAlert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [errorAlert addAction:okAction];
    [self presentViewController:errorAlert animated:YES completion:nil];

    self.loginButton.enabled = YES;
}


- (IBAction)Authenticate:(id)sender {
    self.loginButton.enabled = NO;
    [[MDPandoraPlayerManager client]authenticateUser:self.loginName.text password:self.password.text  success:^(BOOL * _Nullable success) {
        if (success) {
            [self proceedOnValidAuthentication];
         }
    } failure:^(NSError * _Nullable error) {
        [self showAuthenticationFailedAlert];
    }];
    
}


-(void) setUserLoginDefaults{
    
    if ([[self.loginName text]length] > 1)  {
        NSString *loginName = self.loginName.text;
        NSData *encryptedLoginName =[MDCryptography pandoraEncrypt:[loginName dataUsingEncoding:NSUTF8StringEncoding] withPartnerEncryptKey:(unsigned char*)PARTNER_DECRYPT] ;
        
        NSString *password = self.password.text;
        NSData *encryptedPassword =[MDCryptography pandoraEncrypt:[password dataUsingEncoding:NSUTF8StringEncoding] withPartnerEncryptKey:(unsigned char*)PARTNER_DECRYPT] ;

        [[NSUserDefaults standardUserDefaults]setValue:[[NSString alloc]initWithData:encryptedLoginName encoding:NSUTF8StringEncoding] forKey:@"userName"];
        [[NSUserDefaults standardUserDefaults]setValue:[[NSString alloc]initWithData:encryptedPassword encoding:NSUTF8StringEncoding] forKey:@"password"];
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
