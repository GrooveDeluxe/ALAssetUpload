//
//  ViewController.m
//  ALAssetUpload
//
//  Created by Dmitry Sochnev on 31.03.15.
//  Copyright (c) 2015 Dmitry Sochnev. All rights reserved.
//

#import "ViewController.h"

#import <CTAssetsPickerController.h>

#import "ALUploadManager.h"

@interface ViewController () <CTAssetsPickerControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onTestButton:(id)sender
{
    CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - CTAssetsPickerControllerDelegate

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets
{
    NSLog(@"assets - %@", assets);
    
    [ALUploadManager uploadALAsset:assets[0] completion:^(BOOL status, NSError *error) {
        
        if (status) {
            NSLog(@"UPLOAD: upload completed successfully");
        }
        else {
            NSLog(@"UPLOAD: upload completed with error - %@", error);
        }
    }];
}

- (BOOL)assetsPickerController:(CTAssetsPickerController *)picker shouldSelectAsset:(ALAsset *)asset
{
    if (picker.selectedAssets && picker.selectedAssets.count) {
        return NO;
    }
    return YES;
}

@end
