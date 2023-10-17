//
//  ReceiptInfo.swift
//  ReceiptValidator
//
//  Created by Admin on 17/10/23.
//

import Foundation

/*
 This extension allow to parse the content of an Apple receipt from the AppStore.
 
 Reference documentation
 https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html
 */
struct ReceiptInfo {
    /// CFBundleIdentifier in Info.plist
     var bundleIdentifier: String?

    /// CFBundleIdentifier in Info.plist as bytes, used, with other data, to compute the SHA-1 hash during validation.
     var bundleIdentifierData: Data?

    /// CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in Info.plist
     var bundleVersion: String?

    /// CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in Info.plist
     var originalApplicationVersion: String?

    /// Opaque value used, with other data, to compute the SHA-1 hash during validation.
     var opaqueValue: Data?

    /// SHA-1 hash, used to validate the receipt.
     var sha1: Data?

     var receiptCreationDate: Date?
     var receiptCreationDateString: String?
     var receiptExpirationDate: Date?
     var receiptExpirationDateString: String?
     var inAppPurchases: [InAppPurchaseInfo]?
}
