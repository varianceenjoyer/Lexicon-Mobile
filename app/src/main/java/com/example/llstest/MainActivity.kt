package com.example.llstest

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import kotlinx.coroutines.*
import uniffi.lexicon.*
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.sqrt

class MainActivity : ComponentActivity() {

    companion object {
        private const val TAG = "LexiconTest"
        private const val SAMPLE_RATE = 16000
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
        private const val MIN_AUDIO_MS = 500
        private const val MAX_AUDIO_MS = 10000
        private const val SILENCE_THRESHOLD = 0.01f
        private const val SILENCE_DURATION_MS = 300
        private const val MIN_TRANSCRIPTION_ENERGY = 0.005f
    }

    // UI State
    private val transcriptionText = mutableStateOf("")
    private val isRecording = mutableStateOf(false)
    private val audioLevel = mutableStateOf(0f)
    private val statusMessage = mutableStateOf("Ready")
    private val modelLoaded = mutableStateOf(false)
    private val charCount = mutableStateOf(0)

    // Transcription components
    private var transcriber: Transcriber? = null
    private var audioRecord: AudioRecord? = null
    private var recordingJob: Job? = null
    private val audioBuffer = mutableListOf<Float>()
    private var silenceStartTime = 0L

    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) initializeLexicon()
        else statusMessage.value = "Microphone permission denied"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme(colorScheme = darkColorScheme()) { LexiconUI() }
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            == PackageManager.PERMISSION_GRANTED) {
            initializeLexicon()
        } else {
            permissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopRecording()
        transcriber?.close()
    }

    private fun initializeLexicon() {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                statusMessage.value = "Initializing..."
                transcriber = Transcriber()

                val modelPath = findModel()
                if (modelPath != null) {
                    statusMessage.value = "Loading model..."
                    transcriber?.loadModel(modelPath)
                    modelLoaded.value = true
                    statusMessage.value = "Ready - ${transcriber?.getModelName()}"
                } else {
                    statusMessage.value = "No model found - copy .bin to app files"
                }
            } catch (e: Exception) {
                Log.e(TAG, "Init failed", e)
                statusMessage.value = "Error: ${e.message}"
            }
        }
    }

    private fun findModel(): String? {
        listOf(filesDir, File(filesDir, "models")).forEach { dir ->
            dir.listFiles { f -> f.name.endsWith(".bin") }
                ?.firstOrNull()?.let { return it.absolutePath }
        }
        return null
    }

    private fun toggleRecording() {
        if (isRecording.value) stopRecording() else startRecording()
    }

    private fun startRecording() {
        if (!modelLoaded.value) {
            statusMessage.value = "No model loaded"
            return
        }
        val bufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)

        try {
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC, SAMPLE_RATE,
                CHANNEL_CONFIG, AUDIO_FORMAT, bufferSize * 2
            )
            audioRecord?.startRecording()
            isRecording.value = true
            statusMessage.value = "Recording..."
            audioBuffer.clear()

            recordingJob = CoroutineScope(Dispatchers.IO).launch {
                val buffer = ShortArray(bufferSize / 2)
                while (isActive && isRecording.value) {
                    val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    if (read > 0) {
                        val samples = buffer.take(read).map { it.toFloat() / 32768f }
                        val rms = sqrt(samples.sumOf { (it * it).toDouble() } / samples.size).toFloat()
                        audioLevel.value = (rms * 8f).coerceIn(0f, 1f)
                        synchronized(audioBuffer) { audioBuffer.addAll(samples) }
                        checkTranscriptionTrigger(rms)
                    }
                }
            }
        } catch (e: Exception) {
            statusMessage.value = "Recording error: ${e.message}"
        }
    }

    private fun stopRecording() {
        isRecording.value = false
        recordingJob?.cancel()
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        audioLevel.value = 0f
        if (audioBuffer.isNotEmpty()) processAudioBuffer()
        statusMessage.value = "Stopped"
    }

    private fun checkTranscriptionTrigger(rms: Float) {
        val audioMs = (audioBuffer.size * 1000) / SAMPLE_RATE
        val now = System.currentTimeMillis()

        if (rms < SILENCE_THRESHOLD) {
            if (silenceStartTime == 0L) silenceStartTime = now
            if (audioMs >= MIN_AUDIO_MS && (now - silenceStartTime) >= SILENCE_DURATION_MS) {
                processAudioBuffer()
                silenceStartTime = 0L
            }
        } else {
            silenceStartTime = 0L
        }
        if (audioMs >= MAX_AUDIO_MS) processAudioBuffer()
    }

    private fun processAudioBuffer() {
        val samples: List<Float>
        synchronized(audioBuffer) {
            if (audioBuffer.isEmpty()) return
            samples = audioBuffer.toList()
            audioBuffer.clear()
        }

        val energy = sqrt(samples.sumOf { (it * it).toDouble() } / samples.size).toFloat()
        if (energy < MIN_TRANSCRIPTION_ENERGY) return

        CoroutineScope(Dispatchers.IO).launch {
            try {
                statusMessage.value = "Transcribing..."

                val audioData = ByteBuffer.allocate(samples.size * 2).apply {
                    order(ByteOrder.LITTLE_ENDIAN)
                    samples.forEach { putShort((it * 32767f).toInt().coerceIn(-32768, 32767).toShort()) }
                }.array()

                val config = TranscriptionFfiConfig(
                    language = "en", translate = false,
                    numThreads = 4u, initialPrompt = null, temperature = 0.0f
                )
                val result = transcriber?.transcribe(audioData, config)

                withContext(Dispatchers.Main) {
                    val text = result?.segments?.joinToString(" ") { it.text.trim() } ?: ""
                    if (text.isNotBlank()) {
                        transcriptionText.value = (transcriptionText.value + " " + text).trim()
                        charCount.value = transcriptionText.value.length
                    }
                    statusMessage.value = if (isRecording.value) "Recording..." else "Ready"
                }
            } catch (e: Exception) {
                Log.e(TAG, "Transcription failed", e)
                statusMessage.value = "Error: ${e.message}"
            }
        }
    }

    @Composable
    fun LexiconUI() {
        val scrollState = rememberScrollState()
        Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
            Column(Modifier.fillMaxSize().padding(16.dp)) {
                Header()
                Spacer(Modifier.height(8.dp))
                Toolbar()
                Spacer(Modifier.height(8.dp))
                TranscriptionArea(Modifier.weight(1f), scrollState)
                Spacer(Modifier.height(8.dp))
                ControlButtons()
                Spacer(Modifier.height(8.dp))
                Footer()
            }
        }
    }

    @Composable
    fun Header() {
        Row(
            Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.primaryContainer).padding(12.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Lexicon Transcriber", style = MaterialTheme.typography.titleLarge)
            Text(
                if (modelLoaded.value) "Model Ready" else "No Model",
                color = if (modelLoaded.value) Color.Green else Color.Red
            )
        }
    }

    @Composable
    fun Toolbar() {
        Row(
            Modifier.fillMaxWidth().background(MaterialTheme.colorScheme.surfaceVariant).padding(8.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            LevelMeter(audioLevel.value, Modifier.width(120.dp))
            Text("${charCount.value} chars", fontFamily = FontFamily.Monospace, fontSize = 12.sp)
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(12.dp).background(
                    if (isRecording.value) Color.Red else Color.Gray,
                    androidx.compose.foundation.shape.CircleShape
                ))
                Spacer(Modifier.width(4.dp))
                Text(if (isRecording.value) "REC" else "STOP", fontFamily = FontFamily.Monospace, fontSize = 12.sp)
            }
        }
    }

    @Composable
    fun LevelMeter(level: Float, modifier: Modifier) {
        Row(modifier.background(Color.Black).padding(2.dp)) {
            repeat(20) { i ->
                val filled = (level * 20).toInt()
                val color = when {
                    i >= filled -> Color.DarkGray
                    i < 14 -> Color.Green
                    i < 18 -> Color.Yellow
                    else -> Color.Red
                }
                Box(Modifier.width(4.dp).height(16.dp).padding(horizontal = 0.5.dp).background(color))
            }
        }
    }

    @Composable
    fun TranscriptionArea(modifier: Modifier, scrollState: androidx.compose.foundation.ScrollState) {
        Card(modifier.fillMaxWidth()) {
            Box(Modifier.fillMaxSize().padding(12.dp).verticalScroll(scrollState)) {
                Text(
                    transcriptionText.value.ifEmpty { "Tap Record to start transcription..." },
                    fontFamily = FontFamily.Monospace,
                    color = if (transcriptionText.value.isEmpty())
                        MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                    else MaterialTheme.colorScheme.onSurface
                )
            }
        }
        LaunchedEffect(transcriptionText.value) { scrollState.animateScrollTo(scrollState.maxValue) }
    }

    @Composable
    fun ControlButtons() {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
            Button(
                onClick = { toggleRecording() },
                enabled = modelLoaded.value,
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (isRecording.value) Color.Red else MaterialTheme.colorScheme.primary
                )
            ) { Text(if (isRecording.value) "Stop" else "Record") }

            OutlinedButton(onClick = { transcriptionText.value = ""; charCount.value = 0 }) { Text("Clear") }
        }
    }

    @Composable
    fun Footer() {
        Surface(Modifier.fillMaxWidth(), color = MaterialTheme.colorScheme.surfaceVariant) {
            Text(statusMessage.value, Modifier.padding(8.dp), style = MaterialTheme.typography.bodySmall)
        }
    }
}
