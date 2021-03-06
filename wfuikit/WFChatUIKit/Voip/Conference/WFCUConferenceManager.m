//
//  WFCUConferenceManager.m
//  WFChatUIKit
//
//  Created by Tom Lee on 2021/2/15.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#import "WFCUConferenceManager.h"
#import <WFChatClient/WFCChatClient.h>
#if WFCU_SUPPORT_VOIP
#import <WFAVEngineKit/WFAVEngineKit.h>
#endif
#import "WFCUConferenceChangeModelContent.h"


static WFCUConferenceManager *sharedSingleton = nil;
@implementation WFCUConferenceManager
+ (WFCUConferenceManager *)sharedInstance {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[WFCUConferenceManager alloc] init];
                [[NSNotificationCenter defaultCenter] addObserver:sharedSingleton selector:@selector(onReceiveMessages:) name:kReceiveMessages object:nil];
            }
        }
    }

    return sharedSingleton;
}

- (void)onReceiveMessages:(NSNotification *)notification {
#if WFCU_SUPPORT_VOIP
    NSArray<WFCCMessage *> *messages = notification.object;
    if([WFAVEngineKit sharedEngineKit].currentSession.state == kWFAVEngineStateConnected && [WFAVEngineKit sharedEngineKit].currentSession.isConference) {
        for (WFCCMessage *msg in messages) {
            if([msg.content isKindOfClass:[WFCUConferenceChangeModelContent class]]) {
                WFCUConferenceChangeModelContent *changeModelCnt = (WFCUConferenceChangeModelContent *)msg.content;
                if([changeModelCnt.conferenceId isEqualToString:[WFAVEngineKit sharedEngineKit].currentSession.callId]) {
                    [self.delegate onChangeModeRequest:changeModelCnt.isAudience];
                }
            }
        }
    }
#endif
}

- (void)request:(NSString *)userId changeModel:(BOOL)isAudience inConference:(NSString *)conferenceId {
    WFCUConferenceChangeModelContent *cnt = [[WFCUConferenceChangeModelContent alloc] init];
    cnt.conferenceId = conferenceId;
    cnt.isAudience = isAudience;
    WFCCConversation *conv = [WFCCConversation conversationWithType:Single_Type target:userId line:0];
    [[WFCCIMService sharedWFCIMService] send:conv content:cnt success:^(long long messageUid, long long timestamp) {
            
        } error:^(int error_code) {
            
        }];
}

- (void)requestChangeModel:(BOOL)isAudience inConference:(NSString *)conferenceId {
#if WFCU_SUPPORT_VOIP
    if([conferenceId isEqualToString:[WFAVEngineKit sharedEngineKit].currentSession.callId]) {
        [[WFAVEngineKit sharedEngineKit].currentSession switchAudience:isAudience];
    }
#endif
}
@end
