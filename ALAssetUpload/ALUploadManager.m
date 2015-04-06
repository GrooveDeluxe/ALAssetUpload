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


#define TEST_FILE_PATH [TempFilesPath() stringByAppendingPathComponent:@"Animation.zip"]

@interface ALUploadManager ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@property (nonatomic, strong) __block ALCreateFileCommand *createFileCommand;

@property (nonatomic, strong) ALAsset *asset;

@end

@implementation ALUploadManager

+ (instancetype)manager
{
    static ALUploadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ALUploadManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"background.test"];
        self.sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:nil sessionConfiguration:configuration];
    }
    return self;
}

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
    
    [[self manager] setAsset:asset];
    
    [[self manager] uploadFileWithCompletion:^(BOOL status, NSError *error) {
        if (status) {
            NSLog(@"File uploading was done successfully.");
        }
        else {
            NSLog(@"File uploading was failed with error - %@", error);
        }
    }];
}

- (void)uploadFileWithCompletion:(CallbackWithError)completion
{
    __weak __typeof(self) weakSelf = self;
    self.createFileCommand = [ALCreateFileCommand createWithSuccess:^(NSURLSessionDataTask *task, id responseObject) {
        
        [weakSelf uploadFileInBackgroundWithCompletion:completion];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        [task logTask];
        NSLog(@"error - %@", error);
    }];
}

#pragma mark - Upload file via NSURLSession

- (void)uploadFileInBackgroundWithCompletion:(CallbackWithError)completion
{
    NSString *urlString = [self.createFileCommand.url absoluteString];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:self.createFileCommand.params];
    [parameters addEntriesFromDictionary:self.createFileCommand.headers];
    
    NSError *error = nil;
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [requestSerializer requestWithMethod:@"POST" URLString:urlString parameters:parameters error:&error];
    
    [self.sessionManager setDidFinishEventsForBackgroundURLSessionBlock:^(NSURLSession *session) {
        NSLog(@"session - %@", session);
    }];
    
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:TEST_FILE_PATH];
    
    __block NSURLSessionUploadTask *uploadTask = [self.sessionManager uploadTaskWithRequest:request fromFile:fileURL progress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        
        [self logTask:uploadTask];
        
        NSLog(@"responseObject - %@", responseObject);
        
        if (completion) {
            completion( !error, error);
        }
    }];
    
    [uploadTask resume];
}

#pragma mark - Upload streamed asset with multipart via NSURLSession

- (void)uploadStreamMultipartFileInBackgroundWithCompletion:(CallbackWithError)completion
{
    NSString *urlString = [self.createFileCommand.url absoluteString];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:self.createFileCommand.params];
    [parameters addEntriesFromDictionary:self.createFileCommand.headers];
    
//    NSURL *assetURL = self.asset.defaultRepresentation.url;

    FMAssetInputStream *inputStream = [[FMAssetInputStream alloc] initWithAsset:self.asset];
    
    [[AFHTTPSessionManager manager] POST:urlString parameters:parameters constructingBodyWithBlock:^(id <AFMultipartFormData>formData) {
        
        [formData appendPartWithInputStream:inputStream name:@"file" fileName:[urlString lastPathComponent] length:UPLOAD_CHUNK_LENGTH mimeType:@"application/octet-stream"];
        
    } success:^(NSURLSessionDataTask *task, id responseObject) {
        
        NSLog(@"response - %@", responseObject);
        
        [self logTask:task];
        
        if (completion) {
            completion(YES, nil);
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        NSLog(@"error - %@", error);
        
        NSLog(@"task class - %@", NSStringFromClass([task class]));
        
        [self logTask:task];
        
        if (completion) {
            completion(NO, error);
        }
    }];
}

#pragma mark - Debug

- (void)logTask:(NSURLSessionTask *)task
{
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
    NSString *str = [[NSString alloc] initWithData:task.originalRequest.HTTPBody encoding:NSUTF8StringEncoding];
    NSLog(@"==========BEGIN============\n"
          @"method: %@\n"
          @"request URL: %@\n"
          @"request body: %@\n"
          @"request headers: %@\n"
          @"response status code: %d\n"
          @"response headers: %@\n"
          @"==========END============\n", task.originalRequest.HTTPMethod, task.originalRequest.URL, str, [task.originalRequest allHTTPHeaderFields], response.statusCode, [response allHeaderFields]);
}

@end
