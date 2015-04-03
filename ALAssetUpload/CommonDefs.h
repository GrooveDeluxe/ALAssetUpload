//
//  CommonDefs.h
//  ALAssetUpload
//
//  Created by start on 03.04.15.
//  Copyright (c) 2015 Dmitry Sochnev. All rights reserved.
//

#ifndef ALAssetUpload_CommonDefs_h
#define ALAssetUpload_CommonDefs_h

#define NSLogExc(a) NSLog(@"%@",[NSString stringWithFormat:@"EXC: %@, line %d, %s >> EXCEPTION: %@ REASON: %@",[[NSString stringWithFormat:@"%s",__FILE__] lastPathComponent],__LINE__,__func__, [(a) name],[(a) reason]])

typedef void (^Block)();
typedef void (^Callback)(BOOL status);
typedef void (^CallbackWithError)(BOOL status, NSError* error);

#define UPLOAD_CHUNK_LENGTH     1024 * 1024 * 5

#pragma mark - Functions

inline
void CheckFolder(NSString *path)
{
    if( ![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        
        NSLog(@"PathSupport: path %@ not found. Creating. ", path);
        
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"Can not create folder. Error: %@", error.localizedDescription);
        }
    }
}

inline
NSString* AppCacheDirectory() {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

inline
NSString* TempFilesPath()
{
    NSString* path = [AppCacheDirectory() stringByAppendingPathComponent:@"files"];
    CheckFolder(path);
    return path;
}

#endif
