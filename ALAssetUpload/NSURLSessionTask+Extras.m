//
//  NSURLSessionTask+Extras.m
//  ALAssetUpload
//
//  Created by Dmitry Sochnev on 01.04.15.
//  Copyright (c) 2015 Dmitry Sochnev. All rights reserved.
//

#import "NSURLSessionTask+Extras.h"

@implementation NSURLSessionTask (Extras)

- (void)logTask
{
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)self.response;
    NSString *str = [[NSString alloc] initWithData:self.originalRequest.HTTPBody encoding:NSUTF8StringEncoding];
    NSLog(@"==========BEGIN============\n"
          @"method: %@\n"
          @"request URL: %@\n"
          @"request body: %@\n"
          @"request headers: %@\n"
          @"response status code: %d\n"
          @"response headers: %@\n"
          @"==========END============\n", self.originalRequest.HTTPMethod, self.originalRequest.URL, str, [self.originalRequest allHTTPHeaderFields], response.statusCode, [response allHeaderFields]);
}

@end
