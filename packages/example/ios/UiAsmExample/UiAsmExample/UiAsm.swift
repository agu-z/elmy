//
//  UiAsm.swift
//  UiAsmExample
//
//  Created by Agustín Zubiaga on 2/17/20.
//  Copyright © 2020 Agustín Zubiaga. All rights reserved.
//

import SwiftUI
import BinaryKit

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

func decodeElement(_ bin: inout Binary) -> some View {
    do {
        switch (try bin.readByte()) {
        case 0xA0: // Container
            return AnyView(decodeContainer(&bin))
        case 0xB0: // Text
            return AnyView(Text(try decodeString(&bin)))
        case 0xB3: // Button
            try bin.readBytes(quantitiy: 3); // Skip attrs
            
            return AnyView(Button(action: { }) {
                 decodeElement(&bin)
            })
        case let b:
            let x = String(format:"%02X", b)
            return AnyView(Text("Unknown element: \(x)"))
        }
    } catch {
        return AnyView(Text("Error!"))
    }
}

func decodeContainer(_ bin: inout Binary) -> some View {
    do {
        let container = try bin.readByte();
        
        try bin.readBytes(quantitiy: 2);
        
        let children = try decodeList(decode: decodeElement, bin: &bin)
        
        let content = ForEach(children, id: \.self.key, content: { $0.value })
        
        switch (container) {
        case 0x00: // Row
            return AnyView(HStack { content })
        case 0x02: // Column
            return AnyView(VStack { content })
        case let b:
            let x = String(format:"%02X", b)
            return AnyView(Text("Unknown container: \(x)"))
        }
    } catch {
        return AnyView(Text("Error: readContainer!"))
    }
}
