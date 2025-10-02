//
//  LifecycleProvider.m
//  Hackle
//
//  Created by sungwoo.yeo on 10/2/25.
//

#import <Foundation/Foundation.h>
#if __has_include("Hackle-Swift.h")
#import "Hackle-Swift.h"
#else

#import <Hackle/Hackle-Swift.h>

#endif

__attribute__((constructor))
static void initializeApplicationLifecycleObserver() {
    [ApplicationLifecycleProvider setupInitialObserver];
}
