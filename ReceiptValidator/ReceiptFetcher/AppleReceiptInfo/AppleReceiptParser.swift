//
//  PKCS7_AppleReceipt.swift
//  ReceiptValidator
//
//  Created by Admin on 3/10/23.
//

import Foundation

//extension PKCS7{
class AppleReceiptParser {
    let mainBlock: ASN1Object
    
    init(mainBlock: ASN1Object) {
        self.mainBlock = mainBlock
    }
    
    func parseDate(_ dateString: String) -> Date? {
        return ReceiptDateFormatter.date(from: dateString)
    }
    
    func getReceiptBlock() -> ASN1Object? {
        guard let block = mainBlock.findOid(.pkcs7data) else { return nil }
        guard var receiptBlock = block.parent?.childs?.last?.childASN1Object(at: 0)?.childASN1Object(at: 0) else { return nil }
        if receiptBlock.asString == "Xcode" {
            receiptBlock = receiptBlock.childASN1Object(at: 0)!
        }
        return receiptBlock
    }
    
    
    func receipt() -> ReceiptInfo? {
        guard let receiptBlock = getReceiptBlock() else {return nil}
        var receiptInfo = ReceiptInfo()
        
        for item in receiptBlock.childs ?? [] {
            let fieldType = (item.childASN1Object(at: 0)?.value as? Data)?.uint64Value ?? 0
            let fieldValueString = item.childASN1Object(at: 2)?.asString
            switch fieldType {
            case 2:
                receiptInfo.bundleIdentifier = fieldValueString
                receiptInfo.bundleIdentifierData = item.childASN1Object(at: 2)?.rawValue

            case 3:
                receiptInfo.bundleVersion = fieldValueString

            case 4:
                receiptInfo.opaqueValue = item.childASN1Object(at: 2)?.rawValue

            case 5:
                receiptInfo.sha1 = item.childASN1Object(at: 2)?.rawValue

            case 19:
                receiptInfo.originalApplicationVersion = fieldValueString

            case 12:
                guard let fieldValueString = fieldValueString else { continue }
                receiptInfo.receiptCreationDateString = fieldValueString
                receiptInfo.receiptCreationDate = parseDate(fieldValueString)

            case 21:
                guard let fieldValueString = fieldValueString else { continue }
                receiptInfo.receiptExpirationDateString = fieldValueString
                receiptInfo.receiptExpirationDate = parseDate(fieldValueString)

            case 17:
                let subItems = item.childASN1Object(at: 2)?.childs?.first?.childs ?? []
                if receiptInfo.inAppPurchases == nil {
                    receiptInfo.inAppPurchases = []
                }
                receiptInfo.inAppPurchases?.append(inAppPurchase(subItems))

            default:
                break
            }
        }
        return receiptInfo
    }
    
    func inAppPurchase(_ subItems: [ASN1Object]) -> InAppPurchaseInfo {
        var inAppPurchaseInfo = InAppPurchaseInfo()
        subItems.forEach { item in
            let fieldType = (item.childASN1Object(at: 0)?.value as? Data)?.uint64Value ?? 0
            let fieldValue = item.childASN1Object(at: 2)?.childs?.first?.value
            switch fieldType {
            case 1701:
                inAppPurchaseInfo.quantity = (fieldValue as? Data)?.uint64Value
            case 1702:
                inAppPurchaseInfo.productId = fieldValue as? String
            case 1703:
                inAppPurchaseInfo.transactionId = fieldValue as? String
            case 1705:
                inAppPurchaseInfo.originalTransactionId = fieldValue as? String
            case 1704:
                if let fieldValueString = fieldValue as? String {
                    inAppPurchaseInfo.purchaseDate = parseDate(fieldValueString)
                }
            case 1706:
                if let fieldValueString = fieldValue as? String {
                    inAppPurchaseInfo.originalPurchaseDate = parseDate(fieldValueString)
                }
            case 1708:
                if let fieldValueString = fieldValue as? String {
                    inAppPurchaseInfo.expiresDate = parseDate(fieldValueString)
                }
            case 1719:
                inAppPurchaseInfo.isInIntroOfferPeriod = (fieldValue as? Data)?.uint64Value
            case 1712:
                if let fieldValueString = fieldValue as? String {
                    inAppPurchaseInfo.cancellationDate = parseDate(fieldValueString)
                }
            case 1711:
                inAppPurchaseInfo.webOrderLineItemId = (fieldValue as? Data)?.uint64Value
            default:
                break
            }
        }
        return inAppPurchaseInfo
    }
    
}
