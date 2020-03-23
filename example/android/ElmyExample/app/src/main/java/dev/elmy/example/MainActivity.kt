package dev.elmy.example

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.ui.core.setContent
import androidx.ui.material.MaterialTheme

import dev.elmy.Elmy
import dev.elmy.ElmyApp
import dev.elmy.ElmyState


class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val script = resources.openRawResource(R.raw.app)
            .bufferedReader().use { it.readText() }

        setContent {
            MaterialTheme {
                Elmy(ElmyApp(this , script))
            }
        }
    }
}