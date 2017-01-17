//
//  EKVPN.swift
//  EKVPNNative
//
//  Created by Igor Smirnov on 17/01/2017.
//  Copyright © 2017 Complex Numbers. All rights reserved.
//

import Foundation
import NetworkExtension

/// Types of VPN protocol
///
/// - IKEv2: IKEv2
/// - IPSec: IPSec
public enum EKVPNProtocol {
    case IKEv2//, IPSec
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

/// |Shared singletone to VPN access
public class EKVPN {
    
    /// Instance of the class
    public static let shared = EKVPN()
    
    fileprivate let manager = NEVPNManager()
    
    /// Current status of VPN connection
    public var status: NEVPNStatus { return manager.connection.status }
    
    /// VPN Delegate
    public var delegate: EKVPNDelegate?
    
    /// Connection flag
    public var isConnected: Bool {
        return status == .connected
    }
    
    /// Disconnection flag
    public var isDisconneced: Bool {
        return !isConnected
    }
    
    private func loadProfiles() {
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
    public func connectTo(server: String, withProtocol: EKVPNProtocol, userName: String, passwordRef: Data, enableDemand: Bool = true, success: @escaping (String) -> Void, error: @escaping (String) -> Void) {
        
        manager.protocolConfiguration = nil

        let connect: () -> Void = {
            switch withProtocol {
            case .IKEv2 :
                let p = NEVPNProtocolIKEv2()
                p.authenticationMethod = NEVPNIKEAuthenticationMethod.none
                p.useExtendedAuthentication = true
                p.serverAddress = server
                p.remoteIdentifier = server
                p.disconnectOnSleep = false
                p.deadPeerDetectionRate = NEVPNIKEv2DeadPeerDetectionRate.medium
                p.localIdentifier = "EKVPN"
                p.username = userName
                p.passwordReference = passwordRef
                self.manager.protocolConfiguration = p
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
