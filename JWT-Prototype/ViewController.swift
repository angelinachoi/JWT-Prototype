//
//  ViewController.swift
//  JWT-Prototype
//
//  Created by Angelina Choi on 2015-08-11.
//  Copyright (c) 2015 Angelina Choi. All rights reserved.
//

import UIKit
import Security
import Foundation

// Identifiers
let serviceIdentifier = "MySerivice"
let userAccount = "authenticatedUser"
let accessGroup = "MySerivice"

// Arguments for the keychain queries
let kSecClassValue = NSString(format: kSecClass)
let kSecAttrAccountValue = NSString(format: kSecAttrAccount)
let kSecValueDataValue = NSString(format: kSecValueData)
let kSecClassGenericPasswordValue = NSString(format: kSecClassGenericPassword)
let kSecAttrServiceValue = NSString(format: kSecAttrService)
let kSecMatchLimitValue = NSString(format: kSecMatchLimit)
let kSecReturnDataValue = NSString(format: kSecReturnData)
let kSecMatchLimitOneValue = NSString(format: kSecMatchLimitOne)


let kSecAttrAccessibleValue = NSString(format: kSecAttrAccessible)
let ksConstantMap = [
    "kSecAttrAccessibleAfterFirstUnlock" : kSecAttrAccessibleAfterFirstUnlock,
    "kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly" : kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    "kSecAttrAccessibleAlways" : kSecAttrAccessibleAlways,
    "kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly" : kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
    "kSecAttrAccessibleAlwaysThisDeviceOnly" : kSecAttrAccessibleAlwaysThisDeviceOnly,
    "kSecAttrAccessibleWhenUnlocked" : kSecAttrAccessibleWhenUnlocked,
    "kSecAttrAccessibleWhenUnlockedThisDeviceOnly" : kSecAttrAccessibleWhenUnlockedThisDeviceOnly
]
var kSecAttrAccessibleConstant = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly


class ViewController: UIViewController {
    @IBOutlet weak var receiveJWTText: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //clear the view
        receiveJWTText.text = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveTokenFunction(sender: UIButton) {
        if receiveJWTText.text != "" {
            KeychainService.saveToken("\(receiveJWTText.text)") // Saves the token
            showAlert("Success", message: "Token saved!")
        } else {
            showAlert("No", message: "There is no token pasted to save!")
        }
    }
    
    @IBAction func loadToken(sender: UIButton) {
        receiveJWTText.text = ""
        receiveJWTText.text = KeychainService.loadToken() as! String// Loads the token
        
        //decodePayload(receiveJWTText.text) // Decodes the token payload and translates it into comprehensive text
        showAlert("Completed", message: "Token load completed!")
    }
    
    
    @IBAction func decodeToken(sender: UIButton) {
//test keychain saving
/*
        if receiveJWTText.text != "" {
            decodePayload(receiveJWTText.text)
        } else {
            showAlert("No", message: "There is no token pasted to decode!")
        }
*/
        testKeyChainSavingOptions()
        showAlert("Test Completed", message: "KeyChain save and load test completed")
    }
    
    private func testKeyChainSavingOptions() {
        var count = 0
        var loadSummary = ""
        
        for (kcAccessTypeName, kcConst)  in ksConstantMap {
            count += 1
            kSecAttrAccessibleConstant = kcConst
            
            var token: NSString = NSString.init(string: "jwt-\(count)")
            KeychainService.saveToken(token)
            var loadedToken: NSString = KeychainService.loadToken() ?? ""
            
            //println(tokenStr)
            //println(loaded as String)
            loadSummary += "\(kcAccessTypeName)  - \(loadedToken)\n"
            
        }
        receiveJWTText.text = loadSummary
        
    }
    
    private func showAlert(tilte: String, message: String) {
        let alert: UIAlertController = UIAlertController(title: tilte, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //code to decode all 3 parts, most code copied from decodePayload function
    private func decodeAll(tokenstr: String) {
        
        // Splitting JWT to extract payload
        let arr = split(tokenstr) {$0 == "."}
        var counter = 0
        
        
        var decodeResult = ""
        //loop through all 3 parts of JWT, will fail on 3rd part - signature piece
        for eachElement in arr {
            counter += 1
            var base64String = eachElement as String
            if count(base64String) % 4 != 0 {
                let padlen = 4 - count(base64String) % 4
                base64String += String(count: padlen, repeatedValue: Character("="))
                
                if counter == 3 {
                    println(base64decode(eachElement))
                }
                
            }
            
            println("\(base64String)")

            
            if let data = NSData(base64EncodedString: base64String, options: nil) {
                let str = NSString(data: data, encoding: NSUTF8StringEncoding)!
                println(str) // Example: {"exp":1426822163,"id":"550b07738895600e99000001"}
                decodeResult += "\(str)\n"
                
                
                
            } else { // adminright is not true or another error occurred.
                println("Something went wrong. Doesn't look like a proper web token.")
            }
        }
        //run decoding algorithm (third part is encoded)
        showAlert("Decode All", message: "\(decodeResult)")
        
    }
    
    /// URI Safe base64 decode
    private func base64decode(input:String) -> NSData? {
        let rem = count(input) % 4
        
        var ending = ""
        if rem > 0 {
            let amount = 4 - rem
            ending = String(count: amount, repeatedValue: Character("="))
        }
        
        let base64 = input.stringByReplacingOccurrencesOfString("-", withString: "+", options: NSStringCompareOptions(0), range: nil)
            .stringByReplacingOccurrencesOfString("_", withString: "/", options: NSStringCompareOptions(0), range: nil) + ending
        
        return NSData(base64EncodedString: base64, options: NSDataBase64DecodingOptions(0))
    }

    
    
    private func decodePayload(tokenstr: String) {
        
        // Splitting JWT to extract payload
        let arr = split(tokenstr) {$0 == "."}
        
        var base64String = arr[1] as String
        if count(base64String) % 4 != 0 {
            let padlen = 4 - count(base64String) % 4
            base64String += String(count: padlen, repeatedValue: Character("="))
        }
        if let data = NSData(base64EncodedString: base64String, options: nil) {
            let str = NSString(data: data, encoding: NSUTF8StringEncoding)!
            println(str) // Example: {"exp":1426822163,"id":"550b07738895600e99000001"}
            
            
            let tokenJSON = (str as NSString).dataUsingEncoding(NSUTF8StringEncoding)
            let tokenDict: NSDictionary = retrieveJsonFromData(tokenJSON!) // Use JSON to parse patient code
            
            let adminright = tokenDict["admin"] as! Bool
            let username = tokenDict["name"] as! String
            let password = tokenDict["password"] as! String // This code of validation is specific to the token received.
            
            if adminright == true { // If adminright is true and the JWT token is legitimate
                
                // Display message box to display username and password
                showAlert("Success", message: "This token is valid\n\nUsername: \(username)\nPassword: \(password)")
            }

        } else { // adminright is not true or another error occurred.
            println("Something went wrong. Doesn't look like a proper web token.")
        }
        
    }
    
    
    func retrieveJsonFromData(data: NSData) -> NSDictionary { // Now deserialize JSON object into dictionary
        var error: NSError?
        let jsonObject: AnyObject? = NSJSONSerialization.JSONObjectWithData(data,
            options: .AllowFragments,
            error: &error)
        if  error == nil {
            println("Successfully deserialized...")
            if jsonObject is NSDictionary{
                let deserializedDictionary = jsonObject as! NSDictionary
                println("Deserialized JSON Dictionary = \(deserializedDictionary)")
                return deserializedDictionary
            } else {
                /* Some other object was returned. We don't know how to
                deal with this situation because the deserializer only
                returns dictionaries or arrays */
            }
        } else if error != nil {
            println("An error happened while deserializing the JSON data.")
        }
        return NSDictionary()
    }
    


}

class KeychainService: NSObject {
    
    // Exposed methods to perform queries.
    internal class func saveToken(token: NSString) {
        self.save(serviceIdentifier, data: token)
    }
    
    internal class func loadToken() -> NSString? {
        var token = self.load(serviceIdentifier)
        
        return token
    }
    
    
    // Internal methods for querying the keychain.
    private class func save(service: NSString, data: NSString) {
        var dataFromString: NSData = data.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        
        // Instantiate a new default keychain query

        var keychainQuery: NSMutableDictionary = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, userAccount, dataFromString, kSecAttrAccessibleConstant], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecValueDataValue, kSecAttrAccessibleValue])

        
        // Delete any existing items
        SecItemDelete(keychainQuery as CFDictionaryRef)

        
        // Add the new keychain item
        var status: OSStatus = SecItemAdd(keychainQuery as CFDictionaryRef, nil)
        println("save completed")
    }
    
    private class func load(service: NSString) -> NSString? {
        // Instantiate a new default keychain query
        // Tell the query to return a result
        // Limit our results to one item

        var keychainQuery: NSMutableDictionary = NSMutableDictionary(objects: [kSecClassGenericPasswordValue, service, userAccount, kCFBooleanTrue, kSecMatchLimitOneValue, kSecAttrAccessibleConstant], forKeys: [kSecClassValue, kSecAttrServiceValue, kSecAttrAccountValue, kSecReturnDataValue, kSecMatchLimitValue, kSecAttrAccessibleValue])

        
        var kcResult :Unmanaged<AnyObject>?
        
        // Search for the keychain items
        let status: OSStatus = SecItemCopyMatching(keychainQuery, &kcResult)
    
        
        var contentsOfKeychain: NSString?
        
        if let op = kcResult?.toOpaque() {
            let retrievedData = Unmanaged<NSData>.fromOpaque(op).takeUnretainedValue()
            
            // Convert the data retrieved from the keychain into a string
            contentsOfKeychain = NSString(data: retrievedData, encoding: NSUTF8StringEncoding)
            println("load completed")
        } else {
            println("Nothing was retrieved from the keychain. Status code \(status)")
            contentsOfKeychain = "failed" //test
        }

        return contentsOfKeychain
    }
}