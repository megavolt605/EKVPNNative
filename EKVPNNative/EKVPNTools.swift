//
//  EKVPNTools.swift
//  EKVPNNative
//
//  Created by Igor Smirnov on 19/01/2017.
//  Copyright © 2017 Complex Numbers. All rights reserved.
//

import Foundation

extension Dictionary {

    /// Maps dictionary values to the another dictionary with same keys, using transform closure for values
    ///
    /// - Parameter f: Transform closure
    /// - Returns: Dictionary with the same keys and transformed values
    public func map(_ transform: (Key, Value) -> Value) -> [Key:Value] {
        var ret = [Key:Value]()
        for (key, value) in self {
            ret[key] = transform(key, value)
        }
        return ret
    }

}

private let SecMatchLimit: String! = kSecMatchLimit as String
private let SecReturnData: String! = kSecReturnData as String
private let SecReturnPersistentRef: String! = kSecReturnPersistentRef as String
private let SecValueData: String! = kSecValueData as String
private let SecAttrAccessible: String! = kSecAttrAccessible as String
private let SecClass: String! = kSecClass as String
private let SecAttrService: String! = kSecAttrService as String
private let SecAttrGeneric: String! = kSecAttrGeneric as String
private let SecAttrAccount: String! = kSecAttrAccount as String
private let SecAttrAccessGroup: String! = kSecAttrAccessGroup as String
private let SecReturnAttributes: String = kSecReturnAttributes as String

public struct EKVPNKeyChain {

    static let shared = EKVPNKeyChain(serviceName: "EKVPN")
    
    var serviceName: String
    var accessGroup: String?
    
    /// Update existing data associated with a specified key name. The existing data will be overwritten by the new data
    private func update(_ value: Data, forKey key: String) -> Bool {
        let keychainQueryDictionary: [String:Any] = setupKeychainQueryDictionary(forKey: key)
        let updateDictionary = [SecValueData:value]
        
        // Update
        let status: OSStatus = SecItemUpdate(keychainQueryDictionary as CFDictionary, updateDictionary as CFDictionary)
        
        if status == errSecSuccess {
            return true
        } else {
            return false
        }
    }
    
    /// Save a String value to the keychain associated with a specified key. If a String value already exists for the given key, the string will be overwritten with the new value.
    ///
    /// - parameter value: The String value to save.
    /// - parameter forKey: The key to save the String under.
    /// - parameter withAccessibility: Optional accessibility to use when setting the keychain item.
    /// - returns: True if the save was successful, false otherwise.
    @discardableResult func set(_ value: String, forKey key: String) -> Bool {
        if let data = value.data(using: .utf8) {
            return set(data, forKey: key)
        } else {
            return false
        }
    }
    
    /// Save a Data object to the keychain associated with a specified key. If data already exists for the given key, the data will be overwritten with the new value.
    ///
    /// - parameter value: The Data object to save.
    /// - parameter forKey: The key to save the object under.
    /// - parameter withAccessibility: Optional accessibility to use when setting the keychain item.
    /// - returns: True if the save was successful, false otherwise.
    @discardableResult func set(_ value: Data, forKey key: String) -> Bool {
        var keychainQueryDictionary: [String:Any] = setupKeychainQueryDictionary(forKey: key)
        
        keychainQueryDictionary[SecValueData] = value
        
        let status: OSStatus = SecItemAdd(keychainQueryDictionary as CFDictionary, nil)
        
        if status == errSecSuccess {
            return true
        } else if status == errSecDuplicateItem {
            return update(value, forKey: key)
        } else {
            return false
        }
    }
    
    /// Returns a persistent data reference object for a specified key.
    ///
    /// - parameter forKey: The key to lookup data for.
    /// - parameter withAccessibility: Optional accessibility to use when retrieving the keychain item.
    /// - returns: The persistent data reference object associated with the key if it exists. If no data exists, returns nil.
    func dataRef(forKey key: String) -> Data? {
        var keychainQueryDictionary = setupKeychainQueryDictionary(forKey: key)
        var result: AnyObject?
        
        // Limit search results to one
        keychainQueryDictionary[SecMatchLimit] = kSecMatchLimitOne
        
        // Specify we want persistent Data/CFData reference returned
        keychainQueryDictionary[SecReturnPersistentRef] = kCFBooleanTrue
        
        // Search
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(keychainQueryDictionary as CFDictionary, UnsafeMutablePointer($0))
        }
        
        return status == noErr ? result as? Data : nil
    }
    
    /// Setup the keychain query dictionary used to access the keychain on iOS for a specified key name. Takes into account the Service Name and Access Group if one is set.
    ///
    /// - parameter forKey: The key this query is for
    /// - parameter withAccessibility: Optional accessibility to use when setting the keychain item. If none is provided, will default to .WhenUnlocked
    /// - returns: A dictionary with all the needed properties setup to access the keychain on iOS
    private func setupKeychainQueryDictionary(forKey key: String) -> [String:Any] {
        // Setup default access as generic password (rather than a certificate, internet password, etc)
        var keychainQueryDictionary: [String:Any] = [SecClass:kSecClassGenericPassword]
        
        // Uniquely identify this keychain accessor
        keychainQueryDictionary[SecAttrService] = serviceName
        
        // Set the keychain access group if defined
        if let accessGroup = self.accessGroup {
            keychainQueryDictionary[SecAttrAccessGroup] = accessGroup
        }
        
        // Uniquely identify the account who will be accessing the keychain
        let encodedIdentifier: Data? = key.data(using: String.Encoding.utf8)
        
        keychainQueryDictionary[SecAttrGeneric] = encodedIdentifier
        
        keychainQueryDictionary[SecAttrAccount] = encodedIdentifier
        
        return keychainQueryDictionary
    }
 
    init(serviceName: String) {
        self.serviceName = serviceName
    }
    
}
