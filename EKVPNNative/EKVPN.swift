//
//  EKVPN.swift
//  EKVPNNative
//
//  Created by Igor Smirnov on 17/01/2017.
//  Copyright © 2017 Complex Numbers. All rights reserved.
//

import Foundation
import NetworkExtension

/// User Defaults storage key
fileprivate let EKVPNKeyChainPassword = "EKVPN Password"

/// Configuration info keys
fileprivate let EKVPNUserDefaultsKeyProfiles = "EKVPN Profiles"
fileprivate let EKVPNUserDefaultsKeyProfilesVPNProtocol = "VPN Protocol"
fileprivate let EKVPNUserDefaultsKeyProfilesAuthenticationMethod = "Authentication Method"
fileprivate let EKVPNUserDefaultsKeyProfilesUseExtendedAuthentication = "UseExtendedAuthentication"
fileprivate let EKVPNUserDefaultsKeyProfilesServerAddress = "ServerAddress"
fileprivate let EKVPNUserDefaultsKeyProfilesRemoteIdentifier = "RemoteIdentifier"
fileprivate let EKVPNUserDefaultsKeyProfilesDisconnectOnSleep = "DisconnectOnSleep"
fileprivate let EKVPNUserDefaultsKeyProfilesDeadPeerDetectionRate = "DeadPeerDetectionRate"
fileprivate let EKVPNUserDefaultsKeyProfilesLocalIdentifier = "LocalIdentifier"
fileprivate let EKVPNUserDefaultsKeyProfilesUsername = "Username"
fileprivate let EKVPNUserDefaultsKeyProfilesPassword = "Password"

/// Types of VPN protocol
///
/// - IKEv2: IKEv2
/// - IPSec: IPSec
public enum EKVPNProtocol: String {
    case IKEv2 = "IKEv2"
    //case IPSec = "IPSec"
}

/// VPN Delegate object
public protocol EKVPNDelegate {
    /// Calls when VPN status was changed
    ///
    /// - Parameters:
    ///   - vpn: VPN singletone
    ///   - status: New status
    func vpnStatusDidChange(_ vpn: EKVPN, status: NEVPNStatus)
}

/// VPN connection configuration profile
public struct EKVPNConfigurationProfile {

    /// Name of the profile. Used to lookup configuration from list (unique)
    public var name: String
    
    /// VPN protocol to use
    public var vpnProtocol: EKVPNProtocol
    
    public var authenticationMethod = NEVPNIKEAuthenticationMethod.none
    public var useExtendedAuthentication = true
    public var serverAddress: String
    public var remoteIdentifier: String
    public var disconnectOnSleep = false
    public var deadPeerDetectionRate = NEVPNIKEv2DeadPeerDetectionRate.medium
    public var localIdentifier = "EKVPN"
    public var username: String
    public var password: String

    fileprivate func createVPNProtocol() -> NEVPNProtocol {
        switch vpnProtocol {
        case .IKEv2:
            let p = NEVPNProtocolIKEv2()
            p.authenticationMethod = authenticationMethod
            p.useExtendedAuthentication = useExtendedAuthentication
            p.serverAddress = serverAddress
            p.remoteIdentifier = remoteIdentifier
            p.disconnectOnSleep = disconnectOnSleep
            p.deadPeerDetectionRate = deadPeerDetectionRate
            p.localIdentifier = localIdentifier
            p.username = username
            
            let passwordKey = "\(EKVPNKeyChainPassword) \(name)"
            EKVPNKeyChain.shared.set(password, forKey: passwordKey)
            let passwordRef = EKVPNKeyChain.shared.dataRef(forKey: passwordKey)

            p.passwordReference = passwordRef
            return p
        }
    }
    
    fileprivate func storeToDictionary() -> [String: Any] {
        var result: [String: Any] = [:]
        
        result[EKVPNUserDefaultsKeyProfilesAuthenticationMethod] = authenticationMethod.rawValue
        result[EKVPNUserDefaultsKeyProfilesUseExtendedAuthentication] = useExtendedAuthentication
        result[EKVPNUserDefaultsKeyProfilesServerAddress] = serverAddress
        result[EKVPNUserDefaultsKeyProfilesRemoteIdentifier] = remoteIdentifier
        result[EKVPNUserDefaultsKeyProfilesDisconnectOnSleep] = disconnectOnSleep
        result[EKVPNUserDefaultsKeyProfilesDeadPeerDetectionRate] = deadPeerDetectionRate.rawValue
        result[EKVPNUserDefaultsKeyProfilesLocalIdentifier] = localIdentifier
        result[EKVPNUserDefaultsKeyProfilesUsername] = username
        result[EKVPNUserDefaultsKeyProfilesPassword] = password
        
        return result
    }
    
    init(name: String, vpnProtocol: EKVPNProtocol, serverAddress: String, remoteIdentifier: String, username: String, password: String) {
        self.name = name
        self.vpnProtocol = vpnProtocol
        self.serverAddress = serverAddress
        self.remoteIdentifier = remoteIdentifier
        self.username = username
        self.password = password
    }
    
    init?(name: String, dictionary: [String: Any]) {
        self.name = name
        guard let sourceVPNProtocolLiteral = dictionary[EKVPNUserDefaultsKeyProfilesVPNProtocol] as? String else { return nil}
        
        guard let sourceAuthenticationMethodLiteral = dictionary[EKVPNUserDefaultsKeyProfilesAuthenticationMethod] as? Int else { return nil }
        guard let sourceUseExtendedAuthenticationLiteral = dictionary[EKVPNUserDefaultsKeyProfilesUseExtendedAuthentication] as? Bool else { return nil }
        guard let sourceServerAddressLiteral = dictionary[EKVPNUserDefaultsKeyProfilesServerAddress] as? String else { return nil }
        guard let sourceRemoteIdentifierLiteral = dictionary[EKVPNUserDefaultsKeyProfilesRemoteIdentifier] as? String else { return nil }
        guard let sourceDisconnectOnSleepLiteral = dictionary[EKVPNUserDefaultsKeyProfilesDisconnectOnSleep] as? Bool else { return nil }
        guard let sourceDeadPeerDetectionRateLiteral = dictionary[EKVPNUserDefaultsKeyProfilesDeadPeerDetectionRate] as? Int else { return nil }
        guard let sourceLocalIdentifierLiteral = dictionary[EKVPNUserDefaultsKeyProfilesLocalIdentifier] as? String else { return nil }
        guard let sourceUsernameLiteral = dictionary[EKVPNUserDefaultsKeyProfilesUsername] as? String else { return nil }
        guard let sourcePasswordLiteral = dictionary[EKVPNUserDefaultsKeyProfilesPassword] as? String else { return nil }

    
        if let sourceVPNProtocol = EKVPNProtocol(rawValue: sourceVPNProtocolLiteral) {
            vpnProtocol = sourceVPNProtocol
        } else { return nil }
        
        if let sourceAuthenticationMethod = NEVPNIKEAuthenticationMethod(rawValue: sourceAuthenticationMethodLiteral) {
            authenticationMethod = sourceAuthenticationMethod
        } else { return nil }
        
        useExtendedAuthentication = sourceUseExtendedAuthenticationLiteral
        serverAddress = sourceServerAddressLiteral
        remoteIdentifier = sourceRemoteIdentifierLiteral
        disconnectOnSleep = sourceDisconnectOnSleepLiteral
        
        if let sourceDeadPeerDetectionRate = NEVPNIKEv2DeadPeerDetectionRate(rawValue: sourceDeadPeerDetectionRateLiteral) {
            deadPeerDetectionRate = sourceDeadPeerDetectionRate
        } else { return nil }

        localIdentifier = sourceLocalIdentifierLiteral
        username = sourceUsernameLiteral
        password = sourcePasswordLiteral
    }
    
}

/// Shared singletone to VPN access
public class EKVPN {
    
    /// Instance of the class
    public static let shared = EKVPN()
    
    fileprivate let manager = NEVPNManager()
    
    /// Current status of VPN connection
    public var status: NEVPNStatus { return manager.connection.status }
    
    /// VPN Delegate
    public var delegate: EKVPNDelegate?
    
    public var configurationList: [String: EKVPNConfigurationProfile] = [:]
    
    /// Connection flag
    public var isConnected: Bool {
        return status == .connected
    }
    
    /// Disconnection flag
    public var isDisconneced: Bool {
        return !isConnected
    }
    
    private func loadProfiles() {
        let userDefaults = UserDefaults.standard
        if let profilesData = userDefaults.dictionary(forKey: EKVPNUserDefaultsKeyProfiles) as? [String: [String: Any]] {
            profilesData.forEach { key, value in
                if let profile = EKVPNConfigurationProfile(name: key, dictionary: value) {
                    self.configurationList[key] = profile
                } else {
                    print("EKVPN Warning: Error loading configuration \(key), skipped")
                }
            }
        }
    }
    
    private func saveProfiles() {
        let userDefaults = UserDefaults.standard
        var profilesData: [String: [String: Any]] = [:]
        configurationList.forEach { key, value in
            profilesData[key] = value.storeToDictionary()
        }
        userDefaults.setValue(profilesData, forKey: EKVPNUserDefaultsKeyProfiles)
        userDefaults.synchronize()
    }
    
    @objc private func statusDidChange(_: NSNotification?){
        delegate?.vpnStatusDidChange(self, status: status)
    }
    
    private func loadProfile(callback: ((Bool)->Void)? = nil) {
        manager.protocolConfiguration = nil
        manager.loadFromPreferences { error in
            if let error = error {
                NSLog("Failed to load preferences: \(error.localizedDescription)")
                callback?(false)
            } else {
                callback?(self.manager.protocolConfiguration != nil)
            }
        }
    }
    
    private func saveProfile(callback: ((Bool)->Void)? = nil) {
        manager.saveToPreferences { error in
            if let error = error {
                NSLog("Failed to save profile: \(error.localizedDescription)")
                callback?(false)
            } else {
                callback?(true)
            }
        }
    }
    
    /// Adds (replaces) profile
    ///
    /// - Parameter profile: profile structure
    public func addProfile(_ profile: EKVPNConfigurationProfile) {
        configurationList[profile.name] = profile
        saveProfiles()
    }
    
    /// Removes profile
    ///
    /// - Parameter profile: profile structure
    public func removeProfile(_ name: String) {
        configurationList[name] = nil
        saveProfiles()
    }
    
    /// Connects to the VPN with spefic options
    ///
    /// - Parameters:
    ///   - server: server name
    ///   - withProtocol: VPN protocol to use
    ///   - userName: user name
    ///   - passwordRef: reference to password from key chain
    ///   - enableDemand: enables "on demand" connection behavior
    ///   - success: success callback
    ///   - error: error callback
    public func connectTo(serverAddress: String, configurationName: String, enableDemand: Bool = false, success: @escaping (String) -> Void, error: @escaping (String) -> Void) {

        guard let configuration = configurationList[configurationName] else {
            error("Configuration not found")
            return
        }
        
        manager.protocolConfiguration = nil

        let connect: () -> Void = {
            self.manager.protocolConfiguration = configuration.createVPNProtocol()
            if enableDemand {
                self.manager.onDemandRules = [NEOnDemandRuleConnect()]
                self.manager.isOnDemandEnabled = true
            }
            self.saveProfile { success in
                if !success {
                    error("Unable to save vpn profile")
                    return
                }
                self.loadProfile() { success in
                    if !success {
                        error("Unable to load profile")
                        return
                    }
                    let result = self.startVPNTunnel()
                    if !result {
                        error("Can't connect")
                    }
                }
            }
        }
        
        if isConnected {
            disconnect() { connect() }
        } else {
            connect()
        }
        
    }
    
    
    /// Disconnect current VPN connection
    ///
    /// - Parameter completed: calls when completed
    public func disconnect(_ completed: (() -> Void)? = nil) {
        manager.onDemandRules = []
        manager.isOnDemandEnabled = false
        manager.saveToPreferences { error in
            self.manager.connection.stopVPNTunnel()
            completed?()
        }
    }
    
    private func startVPNTunnel() -> Bool {
        do {
            try manager.connection.startVPNTunnel()
            return true
        } catch NEVPNError.configurationInvalid {
            NSLog("Failed to start tunnel (configuration invalid)")
        } catch NEVPNError.configurationDisabled {
            NSLog("Failed to start tunnel (configuration disabled)")
        } catch {
            NSLog("Failed to start tunnel (other error)")
        }
        return false
    }
    
    private init() {
        loadProfiles()
        manager.localizedDescription = Bundle.main.infoDictionary![kCFBundleNameKey as String] as? String
        manager.isEnabled = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(EKVPN.statusDidChange(_:)),
            name: NSNotification.Name.NEVPNStatusDidChange,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}
