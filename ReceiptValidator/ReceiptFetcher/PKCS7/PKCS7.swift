//
//  PKCS7.swift
//  ReceiptValidator
//
//  Created by Admin on 2/10/23.
//

import Foundation

enum PKCS7Error: Error {
    case notSupported
    case parseError
}

class PKCS7 {
    let mainBlock: ASN1Object
    let decoder: ASN1DERDecoder
    
    init(data: Data, decoder: ASN1DERDecoder = ASN1DERDecoder()) throws {
        self.decoder = decoder
        let asn1 = try self.decoder.decode(data: data)
        
        guard let firstBlock = asn1.first,
              let mainBlock = firstBlock.childASN1Object(at: 1)?.childASN1Object(at: 0) else {
            throw PKCS7Error.parseError
        }
        
        self.mainBlock = mainBlock
        
        guard firstBlock.childASN1Object(at: 0)?.value as? String == OID.pkcs7signedData.rawValue else {
            throw PKCS7Error.notSupported
        }
    }
    
}
