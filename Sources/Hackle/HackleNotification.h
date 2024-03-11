#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@interface HackleNotifications : NSObject

+ (void)setPushToken:(NSData *)deviceToken;

+ (BOOL)userNotificationCenter:(UNUserNotificationCenter *)center
        willPresentNotification:(UNNotification *)notification
        withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler;

+ (BOOL)userNotificationCenter:(UNUserNotificationCenter *)center
        didReceiveResponse:(UNNotificationResponse *)response
        withCompletionHandler:(void (^)(void))completionHandler;

@end
