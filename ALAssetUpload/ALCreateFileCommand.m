//
//  ALCreateFileCommand.m
//  ALAssetUpload
//
//  Created by start on 03.04.15.
//  Copyright (c) 2015 Dmitry Sochnev. All rights reserved.
//

#import "ALCreateFileCommand.h"

@interface ALCreateFileCommand ()

@property (nonatomic, strong) NSString *requestURLString;
@property (nonatomic, strong) NSDictionary *requestHeaders;
@property (nonatomic, strong) NSDictionary *requestParams;

@end

@implementation ALCreateFileCommand

+ (instancetype)createWithSuccess:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    ALCreateFileCommand *command = [[ALCreateFileCommand alloc] init];
    [command createWithSuccess:success failure:failure];
    return command;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        self.requestURLString = @"https://be-saas.cloudike.com/api/1/files/create/";
        
        self.requestHeaders = @{@"Accept-Language": @"en;q=1",
                                @"Content-Type": @"application/x-www-form-urlencoded",
                                @"Mountbit-Auth": @"5f5ce306e4aa4eb99a9ffae83c774f25",
                                @"User-Agent": @"Cloudike/1.1.113 (iPhone Simulator; iOS x86_64; Scale/2.00)"};
        
        self.requestParams = @{@"path": @"/3/Animation.zip",
                               @"created": @"1405312096000",
                               @"device_id": @"35142FDB-EA69-4C25-8830-70E200679D62",
                               @"device_reference": @"assets-library://asset/asset.JPG?id=6E5438ED-9A8C-4ED0-9DEA-AB2D8F8A9360&ext=JPG",
                               @"modified": @"1405312096000"};
    }
    return self;
}

- (void)createWithSuccess:(void (^)(NSURLSessionDataTask *task, id responseObject))success failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSError *error = nil;
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [requestSerializer requestWithMethod:@"POST" URLString:self.requestURLString parameters:self.requestParams error:&error];
    NSLog(@"[request allHTTPHeaderFields] - %@", [request allHTTPHeaderFields]);
    request.allHTTPHeaderFields = self.requestHeaders;
    __block NSURLSessionDataTask *dataTask = [[AFHTTPSessionManager manager] dataTaskWithRequest:request completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(dataTask, error);
            }
        }
        else {
            if (success) {
                
                @try {
                    self.url = [NSURL URLWithString:responseObject[@"url"]];
                    self.params = responseObject[@"parameters"];
                    self.headers = responseObject[@"headers"];
                    self.confirmURL = [NSURL URLWithString:responseObject[@"confirm_url"]];
                }
                @catch (NSException *exception) {
                    NSLogExc(exception);
                }
                
                success(dataTask, responseObject);
            }
        }
    }];
    
    [dataTask resume];
}

@end
