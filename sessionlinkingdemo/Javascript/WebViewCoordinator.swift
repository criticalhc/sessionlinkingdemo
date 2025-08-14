//
//  WebViewCoordinator.swift
//  sessionlinkingdemo
//
//  Created by Heydon Costello on 14/08/2025.
//


import SwiftUI
import WebKit

class WebViewCoordinator: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("JS sent message: \(message.body)")
    }
}

struct JSWebView: UIViewRepresentable {
    let webView = WKWebView()
    let coordinator = WebViewCoordinator()
    
    func makeUIView(context: Context) -> WKWebView {
        let contentController = webView.configuration.userContentController
        contentController.add(coordinator, name: "callbackHandler")
        
//        if let htmlPath = Bundle.main.path(forResource: "index", ofType: "html") {
//            let html = try? String(contentsOfFile: htmlPath, encoding: .utf8)
//            webView.loadHTMLString(html ?? "", baseURL: Bundle.main.bundleURL)
//        }
        
        webView.load(URLRequest(url: URL(string: "https://stronghold-test.onrender.com/m")!))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    // Call JS function
    func callJSFunction(_ function: String) {
        webView.evaluateJavaScript(function) { result, error in
            if let error = error {
                print("Error: \(error)")
            } else {
                print("Result: \(String(describing: result))")
            }
        }
    }
}
