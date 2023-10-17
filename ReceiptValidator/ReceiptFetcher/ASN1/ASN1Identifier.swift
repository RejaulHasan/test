//
//  ASN1Identifier.swift
//  ReceiptValidator
//
//  Created by Admin on 29/9/23.
//


import Foundation

/**
 The ASN.1 identifier specifies the data type of the value component within the ASN.1 object. It serves as a way to identify and categorize the data within the ASN1 object.

The ASN.1 identifier typically consists of two parts
- parameters:
 - Class: Specifies the encoding class of the ASN.1 object. The class can have one of the following values
 - Tag : Specifies the type of the ASN.1 object within the class. The tag value is typically a numeric value assigned to a specific data type. For example, the tag value for INTEGER is 2
 */

class ASN1Identifier: CustomStringConvertible{
    
    enum Class: UInt8 {
        case universal = 0x00
        case application = 0x40
        case contextSpecific = 0x80
        case `private` = 0xC0
    }
    
    enum TagNumber: UInt8 {
        case endOfContent = 0x00
        case boolean = 0x01
        case integer = 0x02
        case bitString = 0x03
        case octetString = 0x04
        case null = 0x05
        case objectIdentifier = 0x06
        case objectDescriptor = 0x07
        case external = 0x08
        case read = 0x09
        case enumerated = 0x0A
        case embeddedPdv = 0x0B
        case utf8String = 0x0C
        case relativeOid = 0x0D
        case sequence = 0x10
        case set = 0x11
        case numericString = 0x12
        case printableString = 0x13
        case t61String = 0x14
        case videotexString = 0x15
        case ia5String = 0x16
        case utcTime = 0x17
        case generalizedTime = 0x18
        case graphicString = 0x19
        case visibleString = 0x1A
        case generalString = 0x1B
        case universalString = 0x1C
        case characterString = 0x1D
        case bmpString = 0x1E
    }
    
    var rawValue: UInt8
    let constructedTag: UInt8 = 0x20
    
    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    func typeClass() -> Class {
        for tc in [Class.application, Class.contextSpecific, Class.private] where (rawValue & tc.rawValue) == tc.rawValue {
            return tc
        }
        return .universal
    }
    
    /**
     Get the 6th digit of the rawvalue. If it's  set then it's primitive
     */
    func isPrimitive() -> Bool {
        return (rawValue & self.constructedTag) == 0
    }
    
    /**
     Get the 6th digit of the rawvalue. If it's not set then it's constructed
     */
    func isConstructed() -> Bool {
        return (rawValue & self.constructedTag) != 0
    }
    
    /**
     Get last 5 digit. As the maximum tag number 0x1E = 00011110. Set upto 5 digit from right.
     */
    func tagNumber() -> TagNumber {
        return TagNumber(rawValue: rawValue & 0x1F) ?? .endOfContent
    }
    
    var description: String {
        if typeClass() == .universal {
            return String(describing: tagNumber())
        } else {
            return "\(typeClass())(\(tagNumber().rawValue))"
        }
    }
    
}
