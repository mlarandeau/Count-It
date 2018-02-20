//
//  FridaManager.swift
//  Count_It
//
//  Created by Michael LaRandeau on 8/6/17.
//  Copyright © 2017 Michael LaRandeau. All rights reserved.
//

import Foundation
import Frida

protocol TraceManagerDelegate: class {
    func traceManger(_ traceManager: TraceManager, didReceive data: [Int])
    func traceManagerDidDetach(_ traceManager: TraceManager)
}

class TraceManager: Frida.ScriptDelegate {
    
    static func cleanUpHelpers() {
        guard let trashURL = try? FileManager.default.url(for: .trashDirectory, in: .userDomainMask, appropriateFor: nil, create: false),
            let contents = try? FileManager.default.contentsOfDirectory(at: trashURL, includingPropertiesForKeys: [.nameKey, .isDirectoryKey], options: [ .skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants]) else { return }
        for url in contents where url.absoluteString.range(of: trashURL.absoluteString + "frida-") != nil {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    var samplingRate: Int {
        didSet {
            guard let pid = session?.pid else { return }
            detach(silently: true) {
                self.attach(toPID: pid_t(pid))
            }
        }
    }
    
    weak var delegate: TraceManagerDelegate?
    
    private var deviceManager: Frida.DeviceManager?
    private var session: Frida.Session?
    private var script: Frida.Script?
    
    private var scriptString: String? {
        guard let traceURL = Bundle.main.url(forResource: "FridaTraceScript", withExtension: "js") else { return nil }
        guard let traceScript = try? String(contentsOf: traceURL) else {
            Supportive.alert(message: "Missing trace script")
            return nil
        }
        return "var options = { samplingRate : \(samplingRate) };" + traceScript
    }
    
    init(samplingRate: Int) {
        self.samplingRate = samplingRate
    }
    
    func attach(toPID pid: pid_t) {
        if session != nil { return }

        deviceManager = DeviceManager()
        deviceManager?.enumerateDevices { result in
            guard let devices = try? result() else {
                Supportive.alert(message: "Could not find devices")
                return
            }
            let localDevices = devices.filter { $0.kind == Device.Kind.local }
            guard let localDevice = localDevices.first else {
                Supportive.alert(message: "Could not find local device")
                return
            }
            self.attach(device: localDevice, toPID: pid)
        }
    }
    
    func detach(silently: Bool = false, didDetach: (() -> Void)? = nil) {
        session?.detach {
            self.session = nil
            if !silently { self.delegate?.traceManagerDidDetach(self) }
            didDetach?()
        }
    }
    
    private func attach(device: Device, toPID pid: pid_t) {
        device.attach(UInt(pid)) { result in
            guard let session = try? result() else { return }
            self.session = session
            self.createScript(withSession: session)
        }
    }
    
    private func createScript(withSession session: Frida.Session) {
        guard let traceString = scriptString else {
            Supportive.alert(message: "Could not find script")
            detach()
            return
        }
        session.createScript("", source: traceString) { result in
            do {
                let script = try result()
                self.script = script
                script.delegate = self
                self.load(script: script)
            } catch let err {
                Supportive.alert(message: err.localizedDescription)
                self.detach()
            }
        }
    }
    
    private func load(script: Frida.Script) {
        script.load { result in
            guard (try? result()) != nil else {
                Supportive.alert(message: "Could not load script")
                self.detach()
                return
            }
            TraceManager.cleanUpHelpers()
        }
    }
    
    // - MARK: ScriptDelegate
    func script(_ script: Script, didReceiveMessage message: Any, withData data: Data?) {
        guard let info = message as? [String:Any] else {
            Supportive.alert(message: "Unknown message received")
            detach()
            return
        }

        if let payload = info["payload"] as? String {
            Supportive.alert(message: payload)
            detach()
        } else if let payload = info["payload"] as? [Int] {
            delegate?.traceManger(self, didReceive: payload)
        } else if let desc = info["description"] as? String {
            Supportive.alert(message: desc)
            detach()
        }
    }
}
