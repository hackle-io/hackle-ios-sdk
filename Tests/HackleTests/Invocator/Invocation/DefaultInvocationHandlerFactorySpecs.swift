import Foundation
@testable import Hackle
import MockingKit
import Nimble
import Quick

class DefaultInvocationHandlerFactorySpecs: QuickSpec {
    override class func spec() {
        it("get") {
            let sut = DefaultInvocationHandlerFactory(core: MockHackleAppCore())

            for command in InvocationCommand.allCases {
                let handler = try! sut.get(command: command)
                switch command {
                    case .getSessionId:
                        expect(handler).to(beAnInstanceOf(GetSessionIdInvocationHandler.self))
                    case .getUser:
                        expect(handler).to(beAnInstanceOf(GetUserInvocationHandler.self))
                    case .setUser:
                        expect(handler).to(beAnInstanceOf(SetUserInvocationHandler.self))
                    case .resetUser:
                        expect(handler).to(beAnInstanceOf(ResetUserInvocationHandler.self))
                    case .setUserId:
                        expect(handler).to(beAnInstanceOf(SetUserIdInvocationHandler.self))
                    case .setDeviceId:
                        expect(handler).to(beAnInstanceOf(SetDeviceIdInvocationHandler.self))
                    case .setUserProperty:
                        expect(handler).to(beAnInstanceOf(SetUserPropertyInvocationHandler.self))
                    case .updateUserProperties:
                        expect(handler).to(beAnInstanceOf(UpdateUserPropertiesInvocationHandler.self))
                    case .setPhoneNumber:
                        expect(handler).to(beAnInstanceOf(SetPhoneNumberInvocationHandler.self))
                    case .unsetPhoneNumber:
                        expect(handler).to(beAnInstanceOf(UnsetPhoneNumberInvocationHandler.self))
                    case .updatePushSubscriptions:
                        expect(handler).to(beAnInstanceOf(UpdatePushSubscriptionsInvocationHandler.self))
                    case .updateSmsSubscriptions:
                        expect(handler).to(beAnInstanceOf(UpdateSmsSubscriptionsInvocationHandler.self))
                    case .updateKakaoSubscriptions:
                        expect(handler).to(beAnInstanceOf(UpdateKakaoSubscriptionsInvocationHandler.self))
                    case .variation:
                        expect(handler).to(beAnInstanceOf(VariationInvocationHandler.self))
                    case .variationDetail:
                        expect(handler).to(beAnInstanceOf(VariationDetailInvocationHandler.self))
                    case .isFeatureOn:
                        expect(handler).to(beAnInstanceOf(IsFeatureOnInvocationHandler.self))
                    case .featureFlagDetail:
                        expect(handler).to(beAnInstanceOf(FeatureFlagDetailInvocationHandler.self))
                    case .remoteConfig:
                        expect(handler).to(beAnInstanceOf(RemoteConfigInvocationHandler.self))
                    case .track:
                        expect(handler).to(beAnInstanceOf(TrackInvocationHandler.self))
                    case .getCurrentInAppMessageView:
                        expect(handler).to(beAnInstanceOf(GetCurrentInAppMessageViewInvocationHandler.self))
                    case .closeInAppMessageView:
                        expect(handler).to(beAnInstanceOf(CloseInAppMessageViewInvocationHandler.self))
                    case .handleInAppMessageView:
                        expect(handler).to(beAnInstanceOf(HandleInAppMessageViewInvocationHandler.self))
                    case .setCurrentScreen:
                        expect(handler).to(beAnInstanceOf(SetCurrentScreenInvocationHandler.self))
                    case .setOptOutTracking:
                        expect(handler).to(beAnInstanceOf(SetOptOutTrackingInvocationHandler.self))
                    case .isOptOutTracking:
                        expect(handler).to(beAnInstanceOf(IsOptOutTrackingInvocationHandler.self))
                    case .showUserExplorer:
                        expect(handler).to(beAnInstanceOf(ShowUserExplorerInvocationHandler.self))
                    case .hideUserExplorer:
                        expect(handler).to(beAnInstanceOf(HideUserExplorerInvocationHandler.self))
                }
            }
        }
    }
}
