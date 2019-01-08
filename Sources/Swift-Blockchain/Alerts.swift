//
//  Alerts.swift
//  Swift-Blockchain
//
//  Created by Harsh ENO8 on 08/01/19.
//

import Foundation

enum Alerts {
    
    func notify() {
        let process = Process()
        process.launchPath = launchPath
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
    }
    
    private var launchPath: String {
        #if os(Linux)
        return "notify-send"
        #else
        return "/usr/bin/osascript"
        #endif
    }
    
    private var arguments: [String] {
        #if os(Linux)
        return ["Swift Blockchain", self.description]
        #else
        return ["-e", "display notification \"Server started on port: 5000\" with title \"Swift Blockchain\""]
        #endif
    }
    
    case serverStarted(onPort: Int)
    case serverStopped
    
    private var description: String {
        switch self {
        case .serverStarted(let onPort):
            return "Server started on port:\(onPort)"
        case .serverStopped:
            return "Server stopped"
        }
    }
}

