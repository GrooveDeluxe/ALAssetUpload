//
//  ALUploadManager.h
//  ALAssetUpload
//
//  Created by start on 03.04.15.
//  Copyright (c) 2015 Dmitry Sochnev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface ALUploadManager : NSObject

+ (void)uploadALAsset:(ALAsset *)asset completion:(CallbackWithError)completion;

@end
