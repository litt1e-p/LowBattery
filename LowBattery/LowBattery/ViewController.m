//
//  ViewController.m
//  LowBattery
//
//  Created by litt1e-p on 2017/3/22.
//  Copyright © 2017年 litt1e-p. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>
#import "MBProgressHUD.h"

#define kScreenW [UIScreen mainScreen].bounds.size.width
#define kScreenH [UIScreen mainScreen].bounds.size.height
#define kScreenX1p4 kScreenW * 0.25f
#define kScreenX3p4 kScreenW * 0.75f
#define kHaddleBtnL (150.f * kScreenW / 750.f)
#define kHaddleBtnY (1050.f * kScreenH / 1334.f)

@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *addBtn;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *resetBtn;
@property (nonatomic, strong) UIButton *saveBtn;
@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.imageView];
    [self.view addSubview:self.resetBtn];
    [self.view addSubview:self.saveBtn];
}

- (void)authorizeIfNeed
{
    if ([self authorized]) {
        return;
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"您尚未开启相册权限" message:@"无法存入图片" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *actionOK = [UIAlertAction actionWithTitle:@"去开启" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if([[UIApplication sharedApplication] canOpenURL:url]){
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Privacy&path=PHOTOS"] options:@{UIApplicationOpenURLOptionUniversalLinksOnly:@NO} completionHandler:nil];
        }
    }];
    UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"不了" style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:actionOK];
    [alertController addAction:actionCancel];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (BOOL)authorized
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    return status == PHAuthorizationStatusAuthorized;
}

- (IBAction)addBtnEvent:(UIButton *)sender
{
    if (![self authorized]) {
        [self authorizeIfNeed];
        return;
    }
    self.imageView.hidden                        = YES;
    self.resetBtn.hidden                         = YES;
    self.saveBtn.hidden                          = YES;
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    UIImagePickerController *imagePicker         = [[UIImagePickerController alloc] init];
    imagePicker.delegate                         = self;
    imagePicker.allowsEditing                    = NO;
    imagePicker.sourceType                       = sourceType;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image                      = [info objectForKey:UIImagePickerControllerOriginalImage];
    UIImageOrientation imageOrientation = image.imageOrientation;
    if(imageOrientation != UIImageOrientationUp)
    {
        UIGraphicsBeginImageContext(image.size);
        [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    self.imageView.image  = [self doSomeTrick:image];
    self.imageView.hidden = NO;
    self.resetBtn.hidden  = NO;
    self.saveBtn.hidden   = NO;
    self.addBtn.enabled   = NO;
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (UIImage *)doSomeTrick:(UIImage *)img
{
    UIImage *trickImg = [UIImage imageNamed:@"fake_battary_1"];
    UIGraphicsBeginImageContext(img.size);
    [img drawInRect:CGRectMake(0, 0, img.size.width, img.size.height)];
    [trickImg drawInRect:CGRectMake(kScreenW * 2 - 220, 10, 220, 23)];
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return outputImage;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)saveBtnEvent
{
    if (![self authorized]) {
        [self authorizeIfNeed];
        return;
    }
    [self showLoadingText:@"正在保存..."];
    SEL selector = @selector(onCompleteCapture:didFinishSavingWithError:contextInfo:);
    UIImageWriteToSavedPhotosAlbum(self.imageView.image, self, selector, NULL);
}

- (void)onCompleteCapture:(UIImage *)screenImage didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error){
        [self showText:@"保存失败"];
    }else {
        [self showText:@"保存成功"];
        [self resetBtnEvent];
    }
}

- (void)showLoadingText:(NSString *)text
{
    [_hud removeFromSuperview];
    _hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_hud];
    [self.view bringSubviewToFront:_hud];
    _hud.label.text = text;
    __weak typeof(self)weakSelf = self;
    [_hud showAnimated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf.hud removeFromSuperview];
    });
}

- (void)showText:(NSString *)text
{
    [_hud removeFromSuperview];
    _hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:_hud];
    [self.view bringSubviewToFront:_hud];
    _hud.label.text = text;
    _hud.mode = MBProgressHUDModeText;
    __weak typeof(self)weakSelf = self;
    [_hud showAnimated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf.hud removeFromSuperview];
    });
}

- (void)resetBtnEvent
{
    self.imageView.image  = nil;
    self.imageView.hidden = YES;
    self.resetBtn.hidden  = YES;
    self.saveBtn.hidden   = YES;
    self.addBtn.enabled   = YES;
}

- (UIButton *)saveBtn
{
    if (!_saveBtn) {
        _saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_saveBtn setBackgroundImage:[UIImage imageNamed:@"save_icon"] forState:UIControlStateNormal];
        _saveBtn.frame = CGRectMake(kScreenX3p4 - kHaddleBtnL * 0.5, kHaddleBtnY, kHaddleBtnL, kHaddleBtnL);
        _saveBtn.hidden = YES;
        [_saveBtn addTarget:self action:@selector(saveBtnEvent) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveBtn;
}

- (UIButton *)resetBtn
{
    if (!_resetBtn) {
        _resetBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_resetBtn setBackgroundImage:[UIImage imageNamed:@"reset_icon"] forState:UIControlStateNormal];
        _resetBtn.frame = CGRectMake(kScreenX1p4 - kHaddleBtnL * 0.25, kHaddleBtnY, kHaddleBtnL, kHaddleBtnL);
        _resetBtn.hidden = YES;
        [_resetBtn addTarget:self action:@selector(resetBtnEvent) forControlEvents:UIControlEventTouchUpInside];
    }
    return _resetBtn;
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.hidden = YES;
    }
    return _imageView;
}

@end
