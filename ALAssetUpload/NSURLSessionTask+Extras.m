//
//  NSURLSessionTask+Extras.m
//  ALAssetUpload
//
//  Created by Dmitry Sochnev on 01.04.15.
//  Copyright (c) 2015 Dmitry Sochnev. All rights reserved.
//

#import "NSURLSessionTask+Extras.h"

@implementation NSURLSessionTask (Extras)

+ (void)logTask:(NSURLSessionTask *)task
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
