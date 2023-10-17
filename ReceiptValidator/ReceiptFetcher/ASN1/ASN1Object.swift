//
//  ASN1Object.swift
//  ReceiptValidator
//
//  Created by Admin on 29/9/23.
//

import Foundation

class ASN1Object: CustomStringConvertible{
    /// This property contains the DER encoded object
    /// - Source - https://www.oss.com/asn1/resources/asn1-made-simple/encoding-rules.html
    var rawValue: Data?
    
    /// This property contains the decoded Swift object whenever is possible
    var value: Any?
    
    var identifier: ASN1Identifier?
    var childs: [ASN1Object]?
    weak var parent: ASN1Object?
    var description: String {
        return printAsn1()
    }
    
    var asString: String? {
        if let string = value as? String {
            return string
        }
        
        for item in childs ?? [] {
            if let string = item.asString {
                return string
            }
        }
        return nil
    }
    
    func childASN1Object(at index: Int) -> ASN1Object? {
        if let childASN1Objs = self.childs, index >= 0, index < childASN1Objs.count{
            return childASN1Objs[index]
        }
        return nil
    }
    
    func numberOfChilds() -> Int {
        return self.childs?.count ?? 0
    }
    
    func findASN1Object(of oid: OID) -> ASN1Object? {
        for child in childs ?? [] {
            if child.identifier?.tagNumber() == .objectIdentifier {
                if child.value as? String == oid.rawValue {
                    return child
                }
            } else {
                if let result = child.findASN1Object(of: oid) {
                    return result
                }
            }
        }
        return nil
    }
    
    func findOid(_ oid: OID) -> ASN1Object? {
        for child in childs ?? [] {
            if child.identifier?.tagNumber() == .objectIdentifier {
                if child.value as? String == oid.rawValue {
                    return child
                }
            } else {
                if let result = child.findOid(oid) {
                    return result
                }
            }
        }
        return nil
    }
    
    func printAsn1(insets: String = "") -> String {
        var output = insets
        output.append(identifier?.description.uppercased() ?? "")
        output.append(value != nil ? ": \(value!)": "")
        if identifier?.typeClass() == .universal, identifier?.tagNumber() == .objectIdentifier {
            if let oidName = OID.description(of: value as? String ?? "") {
                output.append(" (\(oidName))")
            }
        }
        output.append(childs != nil && childs!.count > 0 ? " {": "")
        output.append("\n")
        for item in childs ?? [] {
            output.append(item.printAsn1(insets: insets + "    "))
        }
        output.append(childs != nil && childs!.count > 0 ? insets + "}\n": "")
        return output
    }
}
