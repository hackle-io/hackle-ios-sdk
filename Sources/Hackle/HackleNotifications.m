#import "HackleNotifications.h"

#if __has_include("Hackle-Swift.h")
#import "Hackle-Swift.h"
#else

#import <Hackle/Hackle-Swift.h>

#endif

@implementation HackleNotifications

+ (void)setPushToken:(NSData *)deviceToken {
    [Hackle setPushToken:deviceToken];
}

+ (BOOL)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    return [Hackle userNotificationCenterWithCenter:center willPresent:notification withCompletionHandler:completionHandler];
}

+ (BOOL)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    return [Hackle userNotificationCenterWithCenter:center didReceive:response withCompletionHandler:completionHandler];
}

@end
