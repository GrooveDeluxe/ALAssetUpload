//
//  AFHTTPSessionManager+Private.h
//  ALAssetUpload
//
//  Created by start on 03.04.15.
//  Copyright (c) 2015 Dmitry Sochnev. All rights reserved.
//

#import "AFNetworking.h"

@interface AFHTTPSessionManager (Private)

- (NSURLSessionDataTask *)dataTaskWithHTTPMethod:(NSString *)method
                                       URLString:(NSString *)URLString
                                      parameters:(id)parameters
                                         success:(void (^)(NSURLSessionDataTask *, id))success
                                         failure:(void (^)(NSURLSessionDataTask *, NSError *))failure;

@end
