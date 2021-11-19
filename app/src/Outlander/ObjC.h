//
//  ObjC.h
//  Outlander
//
//  Created by Joe McBride on 11/18/21.
//  Copyright © 2021 Joe McBride. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_INLINE NSException * _Nullable ExecuteWithObjCExceptionHandling(void(NS_NOESCAPE^_Nonnull tryBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        return exception;
    }
    return nil;
}

NS_ASSUME_NONNULL_END
