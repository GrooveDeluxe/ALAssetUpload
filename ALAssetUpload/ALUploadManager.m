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

static void *ProgressObserverContext = &ProgressObserverContext;

@interface ALUploadManager ()

@property (nonatomic, strong) AFHTTPSessionManager *sessionManager;

@property (nonatomic, strong) __block ALCreateFileCommand *createFileCommand;

@property (nonatomic, strong) ALAsset *asset;

@property (nonatomic, strong) NSProgress *progress;

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
//        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"background.test"];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
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
        
        [weakSelf uploadFileInBackgroundPUTWithCompletion:completion];
//        [weakSelf uploadMultipartViaOperationWithCompletion:completion];
//        [weakSelf uploadFileViaAWSS3TransferManager];
//        [weakSelf uploadFileViaSessionWithCompletion:completion];
//        [weakSelf uploadFileViaOperationWithCompletion:completion];
//        [weakSelf uploadFileInBackgroundPOSTWithCompletion:completion];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        [NSURLSessionTask logTask:task];
        NSLog(@"error - %@", error);
    }];
}

#pragma mark - Upload file via AFHTTPOperationManager

- (void)uploadFileViaOperationWithCompletion:(CallbackWithError)completion
{
    NSString *urlString = [self.createFileCommand.url absoluteString];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:self.createFileCommand.params];
    [parameters addEntriesFromDictionary:self.createFileCommand.headers];
    
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:TEST_FILE_PATH];
    
    __block NSError *error = nil;
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [serializer multipartFormRequestWithMethod:@"POST" URLString:urlString parameters:parameters constructingBodyWithBlock:^(id <AFMultipartFormData>formData) {

        [formData appendPartWithFileURL:fileURL name:@"file" error:&error];

        if (error) {
            NSLog(@"Error occured while appending part of file. Error - %@", error);
        }
    } error:&error];
    
    AFHTTPRequestOperation *uploadOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [uploadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        [self confirmUploadWithCompletion:completion];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (completion) {
            completion(NO, error);
        }
    }];
    
    [uploadOperation start];
}

#pragma mark - Upload file via AWSS3TransferManager

- (void)uploadFileViaAWSS3TransferManager
{
    AWSS3GetPreSignedURLRequest *getPreSignedURLRequest = [AWSS3GetPreSignedURLRequest new];
    getPreSignedURLRequest.bucket = @"myBucket";
    getPreSignedURLRequest.key = @"myFile";
    getPreSignedURLRequest.HTTPMethod = AWSHTTPMethodPUT;
    getPreSignedURLRequest.expires = [NSDate dateWithTimeIntervalSinceNow:3600];
    
    //Important: set contentType for a PUT request.
    NSString *fileContentTypeStr = @"text/plain";
    getPreSignedURLRequest.contentType = fileContentTypeStr;
    
    [[[AWSS3PreSignedURLBuilder defaultS3PreSignedURLBuilder] getPreSignedURL:getPreSignedURLRequest]
     continueWithBlock:^id(BFTask *task) {
         
         if (task.error) {
             NSLog(@"Error: %@",task.error);
         } else {
             
             NSURL *presignedURL = task.result;
             NSLog(@"upload presignedURL is: \n%@", presignedURL);
             
             NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:presignedURL];
             request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
             [request setHTTPMethod:@"PUT"];
             [request setValue:fileContentTypeStr forHTTPHeaderField:@"Content-Type"];
             
//             self.uploadTask = [self.session uploadTaskWithRequest:request fromFile:self.uploadFileURL];
             //uploadTask is an instance of NSURLSessionDownloadTask.
             //session is an instance of NSURLSession.
//             [self.uploadTask resume];
             
         }
         
         return nil;
     }];
}

#pragma mark - Upload file via AFHTTPSessionManager

- (void)uploadFileStreamedMultipartViaSessionWithCompletion:(CallbackWithError)completion
{
    NSString *urlString = [self.createFileCommand.url absoluteString];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:self.createFileCommand.params];
    [parameters addEntriesFromDictionary:self.createFileCommand.headers];
    
    __block NSError *error = nil;
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [requestSerializer requestWithMethod:@"POST" URLString:urlString parameters:parameters error:&error];
    
    [self.sessionManager setDidFinishEventsForBackgroundURLSessionBlock:^(NSURLSession *session) {
        NSLog(@"session - %@", session);
    }];
    
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:TEST_FILE_PATH];
    
    //    [self.sessionManager POST:urlString parameters:parameters constructingBodyWithBlock:^(id <AFMultipartFormData>formData) {
    //
    //        [formData appendPartWithFileURL:fileURL name:@"file" error:&error];
    //
    //        if (error) {
    //            NSLog(@"Error occured while appending part of file.");
    //        }
    //
    //    } success:^(NSURLSessionDataTask *task, id responseObject) {
    //
    //        [self logTask:task];
    //
    //        [self confirmUploadWithCompletion:completion];
    //
    //    } failure:^(NSURLSessionDataTask *task, NSError *error) {
    //
    //        [self logTask:task];
    //
    //        if (completion) {
    //            completion(NO, error);
    //        }
    //    }];
    
    
    __block NSURLSessionUploadTask *uploadTask = [self.sessionManager uploadTaskWithRequest:request fromFile:fileURL progress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        
        [self logTask:uploadTask];
        
        NSLog(@"responseObject - %@", responseObject);
        
        if ( !error) {
            [self confirmUploadWithCompletion:completion];
        }
        else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
    
    [uploadTask resume];
}

#pragma mark - Upload file via AFHTTPSessionManager

- (void)uploadFileViaSessionWithCompletion:(CallbackWithError)completion
{
    NSString *urlString = [self.createFileCommand.url absoluteString];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:self.createFileCommand.params];
    [parameters addEntriesFromDictionary:self.createFileCommand.headers];
    
    __block NSError *error = nil;
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [requestSerializer requestWithMethod:@"POST" URLString:urlString parameters:parameters error:&error];
    request.allHTTPHeaderFields = self.createFileCommand.headers;
    [self.sessionManager setDidFinishEventsForBackgroundURLSessionBlock:^(NSURLSession *session) {
        NSLog(@"session - %@", session);
    }];
    
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:TEST_FILE_PATH];
    
    [self.sessionManager POST:urlString parameters:parameters constructingBodyWithBlock:^(id <AFMultipartFormData>formData) {
        
        [formData appendPartWithFileURL:fileURL name:@"file" error:&error];
        
        if (error) {
            NSLog(@"Error occured while appending part of file.");
        }
        
    } success:^(NSURLSessionDataTask *task, id responseObject) {
        
        [self logTask:task];
        
        [self confirmUploadWithCompletion:completion];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        [self logTask:task];
        
        if (completion) {
            completion(NO, error);
        }
    }];
    
    
//    __block NSURLSessionUploadTask *uploadTask = [self.sessionManager uploadTaskWithRequest:request fromFile:fileURL progress:nil completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
//        
//        [self logTask:uploadTask];
//        
//        NSLog(@"responseObject - %@", responseObject);
//        
//        if ( !error) {
//            [self confirmUploadWithCompletion:completion];
//        }
//        else {
//            if (completion) {
//                completion(NO, error);
//            }
//        }
//    }];
//    
//    [uploadTask resume];
}

#pragma mark - Upload file via AFHTTPSessionManager (POST)

- (void)uploadFileInBackgroundPOSTWithCompletion:(CallbackWithError)completion
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
        
        if ( !error) {
            [self confirmUploadWithCompletion:completion];
        }
        else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
    
    [uploadTask resume];
}

#pragma mark - Upload file via AFHTTPSessionManager (PUT)

- (void)uploadFileInBackgroundPUTWithCompletion:(CallbackWithError)completion
{
    NSString *urlString = @"https://mountbit-s3-test.s3.amazonaws.com/file.txt?Signature=kG9BP4L8T2uazN3pTy9W6YgGcZw%3D&Expires=1429099358&AWSAccessKeyId=AKIAI56UENEU4WRBR6TA";
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:self.createFileCommand.params];
    [parameters addEntriesFromDictionary:self.createFileCommand.headers];
    
    NSError *error = nil;
    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [requestSerializer requestWithMethod:@"PUT" URLString:urlString parameters:nil error:&error];
    [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    NSLog(@"request.allHTTPHeaderFields - %@", request.allHTTPHeaderFields);
    [self.sessionManager setDidFinishEventsForBackgroundURLSessionBlock:^(NSURLSession *session) {
        NSLog(@"session - %@", session);
    }];
    
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:TEST_FILE_PATH];
    
    NSProgress *progress = nil;
    
    __block NSURLSessionUploadTask *uploadTask = [self.sessionManager uploadTaskWithRequest:request fromFile:fileURL progress:&progress completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        
        [self logTask:uploadTask];
        
        NSLog(@"responseObject - %@", responseObject);
        
        if ( !error) {
            [self confirmUploadWithCompletion:completion];
        }
        else {
            if (completion) {
                completion(NO, error);
            }
        }
    }];
    
    self.progress = progress;
    
    [self.progress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionInitial context:ProgressObserverContext];
    
    [uploadTask resume];
}

#pragma mark - Upload streamed asset with multipart via AFHTTPSessionManager

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
        
        [self confirmUploadWithCompletion:completion];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        
        NSLog(@"task class - %@", NSStringFromClass([task class]));
        
        [self logTask:task];
        
        if (completion) {
            completion(NO, error);
        }
    }];
}

#pragma mark - Upload file with multipart request via AFHTTPOperationManager (WORK)

- (void)uploadMultipartViaOperationWithCompletion:(CallbackWithError)completion
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:self.createFileCommand.params];
    [parameters addEntriesFromDictionary:self.createFileCommand.headers];
    
    __block NSError *error = nil;
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [serializer multipartFormRequestWithMethod:@"POST" URLString:[self.createFileCommand.url absoluteString] parameters:parameters constructingBodyWithBlock:^(id <AFMultipartFormData>formData) {
        
        [formData appendPartWithFileURL:[NSURL fileURLWithPath:TEST_FILE_PATH] name:@"file" error:&error];
        
    } error:&error];
    
    AFHTTPRequestOperation *uploadOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    uploadOperation.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    [uploadOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString *responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSLog(@"responseString - %@", responseString);
        
        [self confirmUploadWithCompletion:completion];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (completion) {
            completion(NO, error);
        }
    }];
    [uploadOperation start];
}

#pragma mark - Confirm upload

- (void)confirmUploadWithCompletion:(CallbackWithError)completion
{
    NSError *error = nil;
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    NSMutableURLRequest *request = [serializer requestWithMethod:@"POST" URLString:[self.createFileCommand.confirmURL absoluteString] parameters:nil error:&error];

    AFHTTPRequestOperation *confirmOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [confirmOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (completion) {
            completion(YES, nil);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (completion) {
            completion(NO, error);
        }
    }];
    
    [confirmOperation start];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == ProgressObserverContext) {
        NSProgress *progress = object;
        
         NSLog(@"fraction completed: %f", progress.fractionCompleted);
        
        if (progress.fractionCompleted == 1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"NSProgress fractionCompleted");
                [self.progress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) context:ProgressObserverContext];
            });
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Debug

- (void)logTask:(NSURLSessionTask *)task
{
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
    NSString *str = [[NSString alloc] initWithData:task.originalRequest.HTTPBody encoding:NSUTF8StringEncoding];
    NSLog(@"==========BEGIN============\n"
          @"request method: %@\n"
          @"request URL: %@\n"
          @"request body: %@\n"
          @"request headers: %@\n"
          @"response status code: %d\n"
          @"response headers: %@\n"
          @"==========END============\n", task.originalRequest.HTTPMethod, task.originalRequest.URL, str, [task.originalRequest allHTTPHeaderFields], response.statusCode, [response allHeaderFields]);
}

@end
