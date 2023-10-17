//
//  ViewController.swift
//  ReceiptValidator
//
//  Created by Admin on 25/9/23.
//

import UIKit

class ViewController: UIViewController {

    /*
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // ASN.1 Object using Long Form Length Encoding
        let longFormASN1Object: [UInt8] = [0x30, 0x84, 0x00, 0x00, 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF]
        
        // ASN.1 Object using short Form Length Encoding
        let shortFromASN1Object = [0x0C, 0x05, 0x4A, 0x6F, 0x68, 0x6E, 0x6E]
        let encodedData: Data = Data(longFormASN1Object)
        let decoder = ASN1DERDecoder()
        do{
            let test = try decoder.decode(data: encodedData)
        }catch{
            print(error)
        }
    }
    */
    
    var fetch: FetchReceipt!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetch = FetchReceipt()
        self.fetch.fetchReceipt()
    }

    

}

