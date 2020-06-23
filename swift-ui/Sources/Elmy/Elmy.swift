//
//  Elmy.swift
//  ElmyExample
//
//  Created by Agustín Zubiaga on 2/17/20.
//  Copyright © 2020 Agustín Zubiaga. All rights reserved.
//

import SwiftUI
import BinaryKit
import JavaScriptCore

@available(OSX 10.15, *)
final class ElmyApp : ObservableObject {
    @Published var state: [UInt8] = []
    
    let jsContext = JSContext()
    
    init(_ source: String) {
        jsContext?.exceptionHandler = {
            (ctx: JSContext!, value: JSValue!) in
            print(value ?? "Unknown error")
        }

        let consoleLog: @convention(block) (String) -> Void = { message in
            print("Elm > " + message)
        }
        
        jsContext?.setObject(consoleLog, forKeyedSubscript: "_consoleLog" as NSCopying & NSObjectProtocol)

        jsContext?.evaluateScript("var console = { log: _consoleLog, warn: _consoleLog, error: _consoleLog }")

        TimerJS.registerInto(jsContext: jsContext!)
        
        let tick: @convention(block) (JSValue) -> Void = {value in
             if let bytes = value.toArray() as? [UInt8] {
                DispatchQueue.main.async {
                    self.state = bytes
                }
            }
        }
        
        jsContext?.setObject(tick, forKeyedSubscript: "elmyTick" as NSCopying & NSObjectProtocol)

        jsContext?.evaluateScript(source)
    }
    
    func message(msg: UInt16) {
        jsContext?.evaluateScript("ElmyApp.ports.msg.send(\(msg))")
    }
}


@available(OSX 10.15, *)
struct Elmy : View {
    @ObservedObject private var app: ElmyApp;
    
    init (_ source: String) {
        app = ElmyApp(source);
    }
    
    var body: some View {
        var bin = Binary(bytes: self.app.state)
        
        return elmyElement(&bin, message: self.app.message)
    }
}


@available(OSX 10.15, *)
func elmyElement(_ bin: inout Binary, message: @escaping (UInt16) -> Void) -> some View {
    do {
        switch (try bin.readByte()) {
        case 0xA0: // Container
            return AnyView(elmyContainer(&bin, message: message))
        case 0xB0: // Text
            return AnyView(Text(try decodeString(&bin)))
        case 0xB3: // Button
            _ = try bin.readBytes(quantitiy: 2); // Skip attrs
            
            let msg = UInt16(bigEndian: Data(try bin.readBytes(quantitiy: 2)).withUnsafeBytes { $0.pointee })
                        
            return AnyView(Button(action: {
                message(msg)
            }) {
                elmyElement(&bin, message: message)
            })
        case let b:
            let x = String(format:"%02X", b)
            return AnyView(Text("Unknown element: \(x)"))
        }
    } catch {
        return AnyView(Text("Error!"))
    }
}

@available(OSX 10.15, *)
func elmyContainer(_ bin: inout Binary, message: @escaping (UInt16) -> Void) -> some View {
    do {
        let container = try bin.readByte();
        
        try bin.readBytes(quantitiy: 2);
        
        let children = try decodeList(decode: { bin in elmyElement(&bin, message: message)}, bin: &bin)
        
        let content = ForEach(children, id: \.self.key, content: { $0.value })
        
        switch (container) {
        case 0x00: // Row
            return AnyView(HStack { content })
        case 0x02: // Column
            return AnyView(VStack { content })
        case let b:
            let x = String(format:"%02X", b)
            return AnyView  (Text("Unknown container: \(x)"))
        }
    } catch {
        return AnyView(Text("Error: readContainer!"))
    }
}

typealias Decoder<T> = (_ bin: inout Binary) -> T;

struct Keyed<T> {
    let key: Int
    let value: T
}

func decodeList<T>(decode: Decoder<T>, bin: inout Binary) throws -> Array<Keyed<T>> {
    let data = Data(try bin.readBytes(quantitiy: 2))
    let size = Int(UInt16(bigEndian: data.withUnsafeBytes { $0.pointee }))

    var array: Array<Keyed<T>> = []

    for i in 0..<size {
        array.append(Keyed(key: i, value: decode(&bin)))
    }

    return array
}

func decodeString(_ bin: inout Binary) throws -> String {
    let data = Data(try bin.readBytes(quantitiy: 4))
    let size = UInt32(bigEndian: data.withUnsafeBytes { $0.pointee })
    return try bin.readString(quantitiyOfBytes: Int(size))
}

// JavaScript Timers

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
