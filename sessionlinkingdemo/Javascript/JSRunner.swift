//
//  JSRunner.swift
//  sessionlinkingdemo
//
//  Created by Heydon Costello on 14/08/2025.
//


import Foundation
import JavaScriptCore

class JSRunner {
    private let context = JSContext()!
    
    init() {
        // Handle JS exceptions
        context.exceptionHandler = { context, exception in
            print("JS Error: \(exception?.toString() ?? "unknown")")
        }
    }
    
    func loadJSFile(named filename: String) {
        if let path = Bundle.main.path(forResource: filename, ofType: "js") {
            do {
                let script = try String(contentsOfFile: path, encoding: .utf8)
                context.evaluateScript(script)
            } catch {
                print("Failed to load JS file: \(error)")
            }
        }
    }
    
    func callFunction(_ name: String, with arguments: [Any]) -> JSValue? {
        guard let function = context.objectForKeyedSubscript(name) else {
            print("Function \(name) not found.")
            return nil
        }
        return function.call(withArguments: arguments)
    }
}
