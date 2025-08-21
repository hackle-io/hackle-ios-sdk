//
//  MimeTypeResolverSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/21/25.
//

import Quick
import Nimble
@testable import Hackle

class MimeTypeResolverSpec: QuickSpec {
    override func spec() {
        describe("MimeTypeResolver") {
            describe("preferredFileExtension(mimeType:)") {
                context("when given a valid MIME type") {
                    it("should return the correct extension for jpeg") {
                        expect(MimeTypeResolver.preferredFileExtension(mimeType: "image/jpeg")).to(equal("jpeg"))
                    }

                    it("should return the correct extension for png") {
                        expect(MimeTypeResolver.preferredFileExtension(mimeType: "image/png")).to(equal("png"))
                    }

                    it("should return the correct extension for gif") {
                        expect(MimeTypeResolver.preferredFileExtension(mimeType: "image/gif")).to(equal("gif"))
                    }
                    
                    it("should return the correct extension for a non-image type like pdf") {
                        expect(MimeTypeResolver.preferredFileExtension(mimeType: "application/pdf")).to(equal("pdf"))
                    }
                }
                
                context("when given an invalid or unknown MIME type") {
                    it("should return nil") {
                        expect(MimeTypeResolver.preferredFileExtension(mimeType: "application/unknown")).to(beNil())
                    }
                }
            }
            
            describe("isSupportedPushNotificationImage(mimeType:)") {
                context("when given a supported push image MIME type") {
                    it("should return true for jpeg") {
                        expect(MimeTypeResolver.isSupportedPushNotificationImage(mimeType: "image/jpeg")).to(beTrue())
                    }

                    it("should return true for png") {
                        expect(MimeTypeResolver.isSupportedPushNotificationImage(mimeType: "image/png")).to(beTrue())
                    }

                    it("should return true for gif") {
                        expect(MimeTypeResolver.isSupportedPushNotificationImage(mimeType: "image/gif")).to(beTrue())
                    }
                }
                
                context("when given an unsupported image MIME type") {
                    it("should return false for heic") {
                        // HEIC is an image but not supported in push notifications
                        expect(MimeTypeResolver.isSupportedPushNotificationImage(mimeType: "image/heic")).to(beFalse())
                    }
                    
                    it("should return false for tiff") {
                        expect(MimeTypeResolver.isSupportedPushNotificationImage(mimeType: "image/tiff")).to(beFalse())
                    }
                }

                context("when given a non-image MIME type") {
                    it("should return false for pdf") {
                        expect(MimeTypeResolver.isSupportedPushNotificationImage(mimeType: "application/pdf")).to(beFalse())
                    }
                }
                
                context("when given an invalid MIME type") {
                    it("should return false") {
                        expect(MimeTypeResolver.isSupportedPushNotificationImage(mimeType: "invalid/type")).to(beFalse())
                    }
                }
            }
        }
    }
}
