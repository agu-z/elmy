package dev.elmy

import android.app.Activity
import android.util.Log
import androidx.compose.Composable
import androidx.compose.Model
import androidx.ui.core.Text
import androidx.ui.layout.Column
import androidx.ui.layout.Row
import androidx.ui.material.Button
import androidx.ui.toHexString
import org.liquidplayer.javascript.JSContext
import org.liquidplayer.javascript.JSFunction

class ElmyApp(activity: Activity, source: String) {
    val state = ElmyState.empty()
    private val jsContext = JSContext()

    init {
        jsContext.setExceptionHandler { Log.e("Elmy", it.stack()) }
        val tick: JSFunction = object : JSFunction(jsContext, "elmyTick") {
            fun elmyTick(bytes: Array<Int>): Unit {
                activity.runOnUiThread {
                    state.update(bytes)
                }
            }
        }
        jsContext.property("elmyTick", tick)
        jsContext.evaluateScript(source)
    }

    fun message(msg: StateByte) : Unit {
        jsContext.evaluateScript("ElmyApp.ports.msg.send($msg)")
    }
}

@Composable
fun Elmy(app: ElmyApp) {
    Column {
        ElmyElement(app.state) { app.message(it) }
    }
}

@Composable
fun ElmyElement(bin: ElmyState, sendMsg: (msg: StateByte) -> Unit) {
    if (!bin.hasNext()) {
        return
    }

    when (val element = bin.uInt8()) {
        0xA0 -> ElmyContainer(bin, sendMsg)
        0xB0 -> Text(bin.string(bin.uInt32()))
        0xB3 -> {
            bin.skip(2u) // Skip Button attrs for now

            val msg = bin.uInt16()

            Button ({
                sendMsg(msg)
            }) {
                ElmyElement(bin, sendMsg)
            }
        }
        else -> Text("Unknown element ${element.toInt().toHexString()}")
    }
}

@Composable
fun ElmyContainer(bin: ElmyState, sendMsg: (msg: StateByte) -> Unit) {
    val container = bin.uInt8()

    bin.skip(2u)  // Skip Attributes for now

    @Composable
    fun children(bin: ElmyState) {
        val len = bin.uInt16()
        for (i in 0 until len) {
            ElmyElement(bin, sendMsg)
        }
    }

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

typealias StateByte = Int
typealias StateUpdate = Array<StateByte>

@Model
class ElmyState(private var bytes: Iterator<StateByte>) {
    companion object {
        fun empty(): ElmyState {
           return ElmyState(IntArray(0).iterator());
        }
    }

    fun update(bytes: StateUpdate) {
        this.bytes = bytes.iterator()
    }

    fun hasNext(): Boolean {
        return bytes.hasNext()
    }

    fun uInt8(): Int {
        return bytes.next()
    }

    fun uInt16(): Int {
        val left = uInt8()
        val right = uInt8()
        return left shl 8 or right
    }

    fun uInt32(): Int {
        return uInt16() shl 16 or uInt16()
    }

    fun string(len: Int): String {
        var string = ""
        for (i in 0 until len) {

            val byte = uInt8()

            when {
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