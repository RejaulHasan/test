//
//  X509Certificate.swift
//  ReceiptValidator
//
//  Created by Admin on 2/10/23.
//

import Foundation


func firstLeafValue(block: ASN1Object) -> Any? {
    if let sub = block.childs?.first {
        return firstLeafValue(block: sub)
    }
    return block.value
}
