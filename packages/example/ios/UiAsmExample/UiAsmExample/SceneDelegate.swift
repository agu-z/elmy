//
//  SceneDelegate.swift
//  UiAsmExample
//
//  Created by Agustín Zubiaga on 2/14/20.
//  Copyright © 2020 Agustín Zubiaga. All rights reserved.
//

import UIKit
import SwiftUI
import JavaScriptCore
import BinaryKit
 
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).

        
        let render : @convention(block) (JSValue) -> Void = { value in
            do {
                if let bytes = value.toArray() as? [UInt8] {
                    var binary = Binary(bytes: bytes)
                    
                    // Use a UIHostingController as window root view controller.
                    if let windowScene = scene as? UIWindowScene {
                        let window = UIWindow(windowScene: windowScene)
                        window.rootViewController = UIHostingController(rootView: decodeElement(&binary))
                        self.window = window
                        window.makeKeyAndVisible()
                    }
               }
            } catch  {
                print("Error info: \(error)")
            }
            
            
        }
                
        let jsContext = JSContext()
        
        jsContext?.exceptionHandler = {
            (ctx: JSContext!, value: JSValue!) in
            print(value)
        }
        
        TimerJS.registerInto(jsContext: jsContext!)
        
        jsContext?.setObject(render, forKeyedSubscript: "swiftUiAsmRender" as NSCopying & NSObjectProtocol)

        if let filepath = Bundle.main.path(forResource: "app", ofType: "js") {
            do {
                let script = try String(contentsOfFile: filepath)
                jsContext?.evaluateScript(script)
            } catch {
                print("Failed to read app.js \(error)")
            }
        } else {
            print("app.js not found")
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}




let timerJSSharedInstance = TimerJS()

@objc protocol TimerJSExport : JSExport {

    func setTimeout(_ callback : JSValue,_ ms : Double) -> String

    func clearTimeout(_ identifier: String)

    func setInterval(_ callback : JSValue,_ ms : Double) -> String

}

// Custom class must inherit from `NSObject`
@objc class TimerJS: NSObject, TimerJSExport {
    var timers = [String: Timer]()

    static func registerInto(jsContext: JSContext, forKeyedSubscript: String = "timerJS") {
        jsContext.setObject(timerJSSharedInstance,
                            forKeyedSubscript: forKeyedSubscript as (NSCopying & NSObjectProtocol))
        jsContext.evaluateScript(
            "function setTimeout(callback, ms) {" +
            "    return timerJS.setTimeout(callback, ms)" +
            "}" +
            "function clearTimeout(indentifier) {" +
            "    timerJS.clearTimeout(indentifier)" +
            "}" +
            "function setInterval(callback, ms) {" +
            "    return timerJS.setInterval(callback, ms)" +
            "}"
        )
    }

    func clearTimeout(_ identifier: String) {
        let timer = timers.removeValue(forKey: identifier)

        timer?.invalidate()
    }


    func setInterval(_ callback: JSValue,_ ms: Double) -> String {
        return createTimer(callback: callback, ms: ms, repeats: true)
    }

    func setTimeout(_ callback: JSValue, _ ms: Double) -> String {
        return createTimer(callback: callback, ms: ms , repeats: false)
    }

    func createTimer(callback: JSValue, ms: Double, repeats : Bool) -> String {
        let timeInterval  = ms/1000.0

        let uuid = NSUUID().uuidString

        // make sure that we are queueing it all in the same executable queue...
        // JS calls are getting lost if the queue is not specified... that's what we believe... ;)
        DispatchQueue.main.async(execute: {
            let timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                             target: self,
                                             selector: #selector(self.callJsCallback),
                                             userInfo: callback,
                                             repeats: repeats)
            self.timers[uuid] = timer
        })


        return uuid
    }

    @objc func callJsCallback(_ timer: Timer) {
        let callback = (timer.userInfo as! JSValue)

        callback.call(withArguments: nil)
    }
}
