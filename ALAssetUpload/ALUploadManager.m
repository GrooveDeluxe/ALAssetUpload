//
//  ALUploadManager.m
//  ALAssetUpload
//
//  Created by start on 03.04.15.
//  Copyright (c) 2015 Dmitry Sochnev. All rights reserved.
//

#import "ALUploadManager.h"

#import "ALCreateFileCommand.h"

#import "FMAssetInputStream.h"

#import "NSURLSessionTask+Extras.h"

@implementation ALUploadManager

+ (void)uploadALAsset:(ALAsset *)asset completion:(CallbackWithError)completion
{
//    NSDictionary *params = @{
//                             @"AWSAccessKeyId": @"AKIAI56UENEU4WRBR6TA",
//                             @"Content-Type": @"application/octet-stream",
//                             @"Filename": @"__temp_1427919387104__.tmp",
//                             @"key": @"188_555c5d85566742b69ac44a960c667755",
//                             @"policy": @"eyJleHBpcmF0aW9uIjogIjIwMTUtMDQtMDJUMDg6MTY6MjdaIiwKImNvbmRpdGlvbnMiOiBbWyJzdGFydHMtd2l0aCIsICIkRmlsZW5hbWUiLCAiIl0sWyJzdGFydHMtd2l0aCIsICIkQ29udGVudC1UeXBlIiwgImFwcGxpY2F0aW9uL29jdGV0LXN0cmVhbSJdLHsic3VjY2Vzc19hY3Rpb25fc3RhdHVzIjogIjIwMSJ9LHsiYnVja2V0IjogImNsb3VkaWtlLXNhYXMifSx7ImtleSI6ICIxODhfNTU1YzVkODU1NjY3NDJiNjlhYzQ0YTk2MGM2Njc3NTUifSx7IngtYW16LXN0b3JhZ2UtY2xhc3MiOiAiU1RBTkRBUkQifV19",
//                             @"signature": @"mdeOJ6HDzqwUpoe2H5SWWDBhsu8=",
//                             @"success_action_status": @"201",
//                             @"x-amz-storage-class": @"STANDARD"
//                             };
//    
//    NSString *urlString = @"https://cloudike-saas.s3.amazonaws.com/";
    
//    NSURL *assetURL = asset.defaultRepresentation.url;
    
    FMAssetInputStream *inputStream = [[FMAssetInputStream alloc] initWithAsset:asset];
    
    __block ALCreateFileCommand *createFileCommand = [ALCreateFileCommand createWithSuccess:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSString *urlString = [createFileCommand.url absoluteString];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:createFileCommand.params];
        [parameters addEntriesFromDictionary:createFileCommand.headers];
        
        NSError *error = nil;
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        NSMutableURLRequest *request = [requestSerializer requestWithMethod:@"POST" URLString:urlString parameters:parameters error:&error];
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"background.test"];
        AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

        [manager uploadTaskWithRequest:request fromFile:<#(NSURL *)#> progress:<#(NSProgress *__autoreleasing *)#> completionHandler:<#^(NSURLResponse *response, id responseObject, NSError *error)completionHandler#>]
/*
        NSURLSessionDataTask *dataTask = [[AFHTTPSessionManager manager] POST:urlString parameters:parameters constructingBodyWithBlock:^(id <AFMultipartFormData>formData) {
            
            [formData appendPartWithInputStream:inputStream name:@"file" fileName:[urlString lastPathComponent] length:UPLOAD_CHUNK_LENGTH mimeType:@"application/octet-stream"];
            
        } success:^(NSURLSessionDataTask *task, id responseObject) {
            
            NSLog(@"response - %@", responseObject);
            
            [task log];
            
            if (completion) {
                completion(YES, nil);
            }
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            
            NSLog(@"error - %@", error);
            
            NSLog(@"task class - %@", NSStringFromClass([task class]));
            
            [task log];
            
            if (completion) {
                completion(NO, error);
            }
        }];
*/
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        [task log];
        NSLog(@"error - %@", error);
    }];
}

@end
