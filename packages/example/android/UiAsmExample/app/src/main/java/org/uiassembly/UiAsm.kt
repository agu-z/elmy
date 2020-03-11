package org.uiassembly

import android.util.Log
import androidx.compose.Composable
import androidx.ui.core.Text
import androidx.ui.layout.Column
import androidx.ui.layout.Row
import androidx.ui.material.Button
import androidx.ui.toHexString

data class UiAsmBinary(var bytes: Iterator<Int>) {
    fun uInt8(): Int {
        return bytes.next()
    }

    fun uInt16(): Int {
        val left = uInt8()
        val right = uInt8()
        Log.d("UInt16", "$left  $right")
        return left shl 8 or right
    }

    fun uInt32(): Int {
        return uInt16() shl 16 or uInt16()
    }

    fun string(len: Int): String {
        var string = ""
        for (i in 0 until len) {
            val byte = uInt8()

            when  {
                byte in 0..128 ->
                    string += byte.toChar()
//                (byte and 0xE0 == 0xC0) ->
//                    string += (byte and 0x1F) shl 6 or
            }
        }

        return string
    }

    fun skip(count: UInt) {
        for (i in 0u until count) {
            bytes.next()
        }
    }
};


@Composable
fun element(bin: UiAsmBinary) {
    if (!bin.bytes.hasNext()) {
        Text("nada")
        return
    }

    when (val element = bin.uInt8()) {
        0xA0 -> container(bin)
        0xB0 -> Text(bin.string(bin.uInt32()))
        0xB3 -> {
            bin.skip(3u) // Skip Button Msg for now
            Button {
                element(bin)
            }
        }
        else -> Text("Unknown element ${element.toInt().toHexString()}")
    }
}

@Composable
fun container(bin: UiAsmBinary) {
    val container = bin.uInt8()

    bin.skip(2u)  // Skip Attributes for now

    when (container) {
        0x00 -> Row {
            children(bin)
        }
        0x02 -> Column {
            children(bin)
        }
        else -> Text("Unknown container ${container.toInt().toHexString()}")
    }
}


@Composable
fun children(bin: UiAsmBinary) {
    val len = bin.uInt16()
    for (i in 0 until len) {
        element(bin)
    }
}
