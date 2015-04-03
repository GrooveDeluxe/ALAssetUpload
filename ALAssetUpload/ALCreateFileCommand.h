//
//  ALCreateFileCommand.h
//  ALAssetUpload
//
//  Created by start on 03.04.15.
//  Copyright (c) 2015 Dmitry Sochnev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ALCreateFileCommand : NSObject

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSDictionary *params;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic, strong) NSURL *confirmURL;

+ (instancetype)createWithSuccess:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure;

@end
