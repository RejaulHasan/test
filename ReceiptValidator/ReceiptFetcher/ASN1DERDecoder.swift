//
//  ASN1DERDecoder.swift
//  ReceiptValidator
//
//  Created by Admin on 29/9/23.
//

import Foundation

enum ASN1Error: Error {
    case parseError
    case outOfBuffer
}

extension Data {
    /**
     Example - [0x4A, 0x6F, 0x68, 0x6E, 0x6E]
     0x4A = 01001010
     value += 01001010 means
     value = 00000000 00000000 00000000 00000000 00000000 00000000 00000000 01001010
     now left shift << UInt64(8*(count-index-1)) means = << 8*(5-0-1) = <<32
     updated value = 00000000 00000000 00000000 01001010 00000000 00000000 00000000 00000000
     After finish for loop the value will be.
     value = 00000000  00000000  00000000  01001010  01101111  01101000  01101110  01101110
     */
    public var uint64Value: UInt64? {
        guard count <= 8, !isEmpty else { // check if suitable for UInt64
            return nil
        }

        var value: UInt64 = 0
        for (index, byte) in self.enumerated() {
            value += UInt64(byte) << UInt64(8*(count-index-1))
        }
        return value
    }
}


class ASN1DERDecoder{
    func decode(data: Data) throws -> [ASN1Object] {
        var iterator = data.makeIterator()
        return try parse(iterator: &iterator)
    }
    
    func parse(iterator: inout Data.Iterator) throws -> [ASN1Object] {
        var result: [ASN1Object] = []
        
        while let nextValue = iterator.next() {
            var asn1obj = ASN1Object()
            asn1obj.identifier = ASN1Identifier(rawValue: nextValue)
            
            if let identifire = asn1obj.identifier,
                identifire.isConstructed(){
                
                let contentData = try loadChildContent(iterator: &iterator)
                if contentData.isEmpty {
                    asn1obj.childs = try parse(iterator: &iterator)
                }else{
                    var subIterator = contentData.makeIterator()
                    asn1obj.childs = try parse(iterator: &subIterator)
                }
                asn1obj.value = nil
                asn1obj.rawValue = Data(contentData)
                
                asn1obj.childs?.forEach({
                    $0.parent = asn1obj
                })
            }else{
                if asn1obj.identifier!.typeClass() == .universal {
                    var contentData = try loadChildContent(iterator: &iterator)
                    asn1obj.rawValue = Data(contentData)
                    
                    // decode the content data with come more convenient format
                    switch asn1obj.identifier!.tagNumber() {
    
                    case .endOfContent:
                        return result
                        
                    case .boolean:
                        if let value = contentData.first {
                            asn1obj.value = value > 0 ? true : false
                            
                        }
                        
                    case .integer:
                        while contentData.first == 0 {
                            contentData.remove(at: 0) // remove all zeros which appear in first
                        }
                        asn1obj.value = contentData
                        
                    case .null:
                        asn1obj.value = nil
                        
                    case .objectIdentifier:
                        asn1obj.value = decodeOid(contentData: &contentData)
                        
                    case .utf8String,
                            .printableString,
                            .numericString,
                            .generalString,
                            .universalString,
                            .characterString,
                            .t61String:
                        
                        asn1obj.value = String(data: contentData, encoding: .utf8)
                        
                    case .bmpString:
                        asn1obj.value = String(data: contentData, encoding: .unicode)
                        
                    case .visibleString,
                            .ia5String:
                        asn1obj.value = String(data: contentData, encoding: .ascii)
                        
                    case .utcTime:
                        asn1obj.value = dateFormatter(contentData: &contentData,
                                                      formats: ["yyMMddHHmmssZ", "yyMMddHHmmZ"])
                        
                    case .generalizedTime:
                        asn1obj.value = dateFormatter(contentData: &contentData,
                                                      formats: ["yyyyMMddHHmmssZ"])
                        
                    case .bitString:
                        if contentData.count > 0 {
                            _ = contentData.remove(at: 0) // unused bits
                        }
                        asn1obj.value = contentData
                        
                    case .octetString:
                        do {
                            var subIterator = contentData.makeIterator()
                            asn1obj.childs = try parse(iterator: &subIterator)
                        } catch {
                            if let str = String(data: contentData, encoding: .utf8) {
                                asn1obj.value = str
                            } else {
                                asn1obj.value = contentData
                            }
                        }
                        
                    default:
                        print("unsupported tag: \(asn1obj.identifier!.tagNumber())")
                        asn1obj.value = contentData
                    }
                }else{
                    try handleOthersIdentifire(asn1obj: &asn1obj, atIteratio: &iterator)
                }
            }
            result.append(asn1obj)
        }
        return result
    }
    
    func handleOthersIdentifire(asn1obj: inout ASN1Object, atIteratio iterator: inout Data.Iterator) throws {
        // custom/private tag
        let contentData = try loadChildContent(iterator: &iterator)
        asn1obj.rawValue = Data(contentData)
        if let str = String(data: contentData, encoding: .utf8) {
            asn1obj.value = str
        } else {
            asn1obj.value = contentData
        }
    }

}



extension ASN1DERDecoder{
    /**
     The first byte represents the first two components of the OID. The first component is obtained by dividing the byte by 40, and the second component is obtained by taking the remainder when the byte is divided by 40. These two components are separated by a dot (".") and appended to the oid string.
     
     for remaining bytes calculation:
     1st bit = 0/1 represent is it continious or end. If it's continious you have to consider the next bit also and so on.
     2nd - 8th bit = represent the data
     (n & 0x7F) = get the 2nd - 8th bit contents
     t  << 7 = represent left shift t in 7 bit
     t = (t << 7) | (n & 0x7F) so here we get the previous t and new 2nd to 8th bit data of n
     (n & 0x80) == 0  check the last bit set or not. If not continious the we apend it and set  t = 0
     
     EX:-
     Suppose you have the encoded OID: 0x2A 0x86 0x48 0xCE 0x3D, which decodes to the string "1.2.840.10045.3.1.7".
     let's decode using our function
     */
    
    func decodeOid(contentData: inout Data) -> String? {
        if contentData.isEmpty {
            return nil
        }

        var oid: String = ""

        let first = Int(contentData.remove(at: 0))
        oid.append("\(first / 40).\(first % 40)")

        var t = 0
        while contentData.count > 0 {
            let n = Int(contentData.remove(at: 0))
            t = (t << 7) | (n & 0x7F)
            if (n & 0x80) == 0 {
                oid.append(".\(t)")
                t = 0
            }
        }
        return oid
    }
    
    func dateFormatter(contentData: inout Data, formats: [String]) -> Date? {
        guard let str = String(data: contentData, encoding: .utf8) else { return nil }
        for format in formats {
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "en_US_POSIX")
            fmt.dateFormat = format
            if let dt = fmt.date(from: str) {
                return dt
            }
        }
        return nil
    }
}


extension ASN1DERDecoder{
    /**
     it returns the length value as a UInt64, which represents the number of bytes needed to represent the content within the ASN.1 object
     
     1. In ASN.1 encoding, the length field can be encoded in one of two forms: short form and long form.
        
        - Short Form: If the length can be represented in a single byte (i.e., the length is less than or equal to 127), it is encoded in the short form.
        - Long Form: If the length requires more than one byte to represent (i.e., the length is 128 or greater), it is encoded in the long form.

     2. In the long form, the first byte (the length byte) has a special bit pattern: bit 8 (the high-order bit) is set to 1, and the remaining bits (7 through 1) indicate how many subsequent bytes should be used to represent the actual length.

     3. To determine the number of bytes used to represent the length in the long form, you subtract `0x80` (which is 128 in decimal) from the value of the first length byte. This subtraction gives you the count of additional bytes used for the length.

     For example, let's say the first length byte is `0x87`. Here's how the calculation works:

     - The value of `0x87` in decimal is `135`.
     - Subtracting `0x80` from `0x87` results in `0x07`, which is `7` in decimal.
     - This means that there are `7` additional bytes following the first length byte to represent the actual length.

     So, in the code `let octetsToRead = first! - 0x80`, the subtraction of `0x80` is a way to extract the count of additional bytes used in the long form to represent the length. This value (`octetsToRead`) is then used to read the actual bytes representing the length from the iterator.

     I hope this clarifies the purpose of that line in the code.
     */
    
    func getContentLength(iterator: inout Data.Iterator) -> UInt64 {
        let first = iterator.next() // we will get the 2nd element
        guard first != nil else {
            return 0
        }
        if (first! & 0x80) != 0 {
            let octetsToRead = first! - 0x80
            var data = Data()
            for _ in 0..<octetsToRead {
                if let n = iterator.next() {
                    data.append(n)
                }
            }
            // after this for loop iterator.next() pointed out to the actual data in the ASN1Object
            return data.uint64Value ?? 0
        } else { // short
            return UInt64(first!)
        }
    }
    
    func loadChildContent(iterator: inout Data.Iterator) throws -> Data {
        let len = getContentLength(iterator: &iterator)
        guard len < Int.max else {
            return Data()
        }
        var byteArray: [UInt8] = []
        for _ in 0..<Int(len) {
            if let n = iterator.next() {
                byteArray.append(n)
            } else {
                throw ASN1Error.outOfBuffer
            }
        }
        return Data(byteArray)
    }
}



/**
 first = ASN1Identifire
 second = length of the data
 remain = actual data/ message
 ex- 0x0C, 0x05, 0x4A, 0x6F, 0x68, 0x6E, 0x6E,
 0x0C = 00001100
    - first two bits (00) represent the Identifire class
    - remaining 6 digit 001100 represent TagNumber
 0x05 = 00000101 indicating that the UTF8String is 5 bytes long
 0x4A, 0x6F, 0x68, 0x6E, 0x6E = represent the actual data which is John
 */
 
/*
 let encodedData: Data = Data([
     0x30, 0x26, // Sequence, total length 38 bytes

     // First element
     0x30, 0x0D, // Sequence, length 13 bytes
     0x0C, 0x05, 0x4A, 0x6F, 0x68, 0x6E, 0x6E, // UTF8String "Johnn"
     0x02, 0x02, 0x25, 0x30, // INTEGER 9536

     // Second element
     0x30, 0x0E, // Sequence, length 14 bytes
     0x0C, 0x06, 0x4D, 0x61, 0x72, 0x79, 0x20, 0x53, // UTF8String "Mary S"
     0x02, 0x02, 0x2A, 0x35 // INTEGER 10741
 ])
 print(encodedData)
 */
