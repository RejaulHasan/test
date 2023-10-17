//
//  InAppPurchaseInfo.swift
//  ReceiptValidator
//
//  Created by Admin on 17/10/23.
//

import Foundation

struct InAppPurchaseInfo {
     var quantity: UInt64?
     var productId: String?
     var transactionId: String?
     var originalTransactionId: String?
     var purchaseDate: Date?
     var originalPurchaseDate: Date?
     var expiresDate: Date?
     var isInIntroOfferPeriod: UInt64?
     var cancellationDate: Date?
     var webOrderLineItemId: UInt64?
}
