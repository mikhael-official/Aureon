#!/bin/bash

mkdir -p Aureon/gradle
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/core/i18n
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/core/benchmark
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/core/util
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/platform
mkdir -p Aureon/composeApp/src/main/sqldelight/com/aureon/feature/nexusai/data
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/data
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/domain
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/presentation/components
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/di
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/feature/dashboard/widgets
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/feature/webforge/data
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/feature/webforge/domain
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/feature/webforge/presentation/components
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/feature/webforge/di
mkdir -p Aureon/composeApp/src/main/res/values

# Root build.gradle.kts – SEM org.jetbrains.compose
cat > Aureon/build.gradle.kts << 'EOF'
plugins {
    id("com.android.application") version "8.2.2" apply false
    id("org.jetbrains.kotlin.android") version "2.0.0" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.0" apply false
    id("app.cash.sqldelight") version "2.0.1" apply false
    id("org.jetbrains.kotlin.plugin.serialization") version "2.0.0" apply false
}
EOF

cat > Aureon/settings.gradle.kts << 'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "Aureon"
include(":composeApp")
EOF

cat > Aureon/gradle.properties << 'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
kotlin.code.style=official
android.nonTransitiveRClass=true
EOF

# composeApp/build.gradle.kts – APENAS ANDROID, SEM KMP, SEM ORG.JETBRAINS.COMPOSE
cat > Aureon/composeApp/build.gradle.kts << 'EOF'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("app.cash.sqldelight")
    id("org.jetbrains.kotlin.plugin.serialization")
}

android {
    namespace = "com.aureon"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.aureon"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildFeatures {
        compose = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation(platform("androidx.compose:compose-bom:2024.02.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose:1.8.2")
    implementation("io.ktor:ktor-client-core:2.3.7")
    implementation("io.ktor:ktor-client-okhttp:2.3.7")
    implementation("io.ktor:ktor-client-content-negotiation:2.3.7")
    implementation("io.ktor:ktor-serialization-kotlinx-json:2.3.7")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2")
    implementation("app.cash.sqldelight:runtime:2.0.1")
    implementation("app.cash.sqldelight:coroutines-extensions:2.0.1")
    implementation("app.cash.sqldelight:android-driver:2.0.1")
    implementation("io.insert-koin:koin-android:3.5.3")
    implementation("io.insert-koin:koin-androidx-compose:3.5.3")
    implementation("org.nanohttpd:nanohttpd:2.3.1")
}

sqldelight {
    databases {
        create("AureonDatabase") {
            packageName.set("com.aureon.feature.nexusai.data")
        }
    }
}
EOF

# App.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/App.kt << 'EOF'
package com.aureon

import androidx.compose.runtime.Composable
import com.aureon.core.i18n.Strings
import com.aureon.feature.dashboard.DashboardScreen

@Composable
fun App() {
    val strings = Strings.current
    AureonTheme {
        DashboardScreen(strings)
    }
}

@Composable
fun AureonTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = if (isSystemInDarkTheme()) darkColorScheme() else lightColorScheme(),
        typography = Typography(),
        content = content
    )
}
EOF

# Strings.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/core/i18n/Strings.kt << 'EOF'
package com.aureon.core.i18n

sealed class Strings {
    abstract val appTitle: String
    abstract val dashboardTitle: String
    abstract val chatPlaceholder: String
    abstract val send: String

    object En : Strings() {
        override val appTitle = "Aureon"
        override val dashboardTitle = "Dashboard"
        override val chatPlaceholder = "Ask NexusAI..."
        override val send = "Send"
    }
    object Pt : Strings() {
        override val appTitle = "Aureon"
        override val dashboardTitle = "Painel"
        override val chatPlaceholder = "Pergunte ao NexusAI..."
        override val send = "Enviar"
    }

    companion object {
        var current: Strings = En
    }
}
EOF

# BenchmarkManager.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/core/benchmark/BenchmarkManager.kt << 'EOF'
package com.aureon.core.benchmark

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlin.system.measureTimeMillis

data class BenchmarkResult(
    val startupTimeMs: Long = 0,
    val memoryUsageMb: Double = 0.0,
    val cpuUsagePercent: Double = 0.0
)

object BenchmarkManager {
    private val _results = MutableStateFlow(BenchmarkResult())
    val results: StateFlow<BenchmarkResult> = _results

    suspend fun measureStartup(block: suspend () -> Unit) {
        val time = measureTimeMillis { block() }
        _results.value = _results.value.copy(startupTimeMs = time)
    }
}
EOF

# Markdown.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/core/util/Markdown.kt << 'EOF'
package com.aureon.core.util

import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle

fun String.markdownToAnnotatedString(): AnnotatedString = buildAnnotatedString {
    var remaining = this@markdownToAnnotatedString
    while (remaining.isNotEmpty()) {
        when {
            remaining.startsWith("**") -> {
                val end = remaining.indexOf("**", 2)
                if (end != -1) {
                    withStyle(SpanStyle(fontWeight = FontWeight.Bold)) { append(remaining.substring(2, end)) }
                    remaining = remaining.substring(end + 2)
                } else { append(remaining.first()); remaining = remaining.drop(1) }
            }
            remaining.startsWith("*") -> {
                val end = remaining.indexOf("*", 1)
                if (end != -1) {
                    withStyle(SpanStyle(fontStyle = FontStyle.Italic)) { append(remaining.substring(1, end)) }
                    remaining = remaining.substring(end + 1)
                } else { append(remaining.first()); remaining = remaining.drop(1) }
            }
            remaining.startsWith("`") -> {
                val end = remaining.indexOf("`", 1)
                if (end != -1) {
                    withStyle(SpanStyle(background = androidx.compose.ui.graphics.Color.LightGray)) { append(remaining.substring(1, end)) }
                    remaining = remaining.substring(end + 1)
                } else { append(remaining.first()); remaining = remaining.drop(1) }
            }
            remaining.startsWith("\n") -> { append('\n'); remaining = remaining.drop(1) }
            else -> { append(remaining.first()); remaining = remaining.drop(1) }
        }
    }
}
EOF

# Platform.android.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/platform/Platform.kt << 'EOF'
package com.aureon.platform

import android.content.Context
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.android.AndroidSqliteDriver
import com.aureon.AureonDatabase
import com.aureon.AureonApp
import com.aureon.core.i18n.Strings
import java.util.Locale

fun getPlatformName() = "Android ${android.os.Build.VERSION.SDK_INT}"

fun getLocalizedStrings(): Strings {
    val lang = Locale.getDefault().language
    return when (lang) {
        "pt" -> Strings.Pt
        else -> Strings.En
    }
}

fun createSqlDriver(): SqlDriver {
    return AndroidSqliteDriver(AureonDatabase.Schema, AureonApp.instance, "aureon.db")
}
EOF

# ChatMessage.sq
cat > Aureon/composeApp/src/main/sqldelight/com/aureon/feature/nexusai/data/ChatMessage.sq << 'EOF'
CREATE TABLE ChatMessageEntity (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    role TEXT NOT NULL,
    content TEXT NOT NULL,
    timestamp INTEGER NOT NULL
);

selectAll:
SELECT * FROM ChatMessageEntity ORDER BY timestamp ASC;

insertMessage:
INSERT INTO ChatMessageEntity (role, content, timestamp) VALUES (?, ?, ?);

deleteAll:
DELETE FROM ChatMessageEntity;
EOF

# ChatRepository.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/data/ChatRepository.kt << 'EOF'
package com.aureon.feature.nexusai.data

import com.aureon.AureonDatabase
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

data class ChatMessage(val id: Long = 0, val role: String, val content: String, val timestamp: Long)

class ChatRepository(private val database: AureonDatabase) {
    private val queries = database.chatMessageEntityQueries

    fun getAllMessages(): Flow<List<ChatMessage>> =
        queries.selectAll().asFlow().mapToList().map { list ->
            list.map { ChatMessage(it.id, it.role, it.content, it.timestamp) }
        }

    suspend fun insertMessage(role: String, content: String) {
        queries.insertMessage(role, content, kotlinx.datetime.Clock.System.now().toEpochMilliseconds())
    }

    suspend fun clearHistory() { queries.deleteAll() }
}
EOF

# MockAIEngine.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/data/MockAIEngine.kt << 'EOF'
package com.aureon.feature.nexusai.data

import kotlinx.coroutines.delay
import kotlin.random.Random

class MockAIEngine {
    suspend fun generateResponse(userMessage: String): String {
        delay(300)
        val greetings = listOf("Olá!", "Hello!", "Hola!")
        val base = if (userMessage.contains("língua", ignoreCase = true) ||
                       userMessage.contains("language", ignoreCase = true))
            "Posso ajudar você a aprender novos idiomas! Tente perguntar 'translate hello to Spanish'."
        else
            "Estou funcionando offline. Em breve serei alimentado por um modelo de IA real."
        return "${greetings.random()} $base"
    }
}
EOF

# ChatUseCase.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/domain/ChatUseCase.kt << 'EOF'
package com.aureon.feature.nexusai.domain

import com.aureon.feature.nexusai.data.ChatMessage
import com.aureon.feature.nexusai.data.ChatRepository
import com.aureon.feature.nexusai.data.MockAIEngine
import kotlinx.coroutines.flow.Flow

class ChatUseCase(
    private val repository: ChatRepository,
    private val aiEngine: MockAIEngine
) {
    val messages: Flow<List<ChatMessage>> = repository.getAllMessages()

    suspend fun sendMessage(text: String) {
        repository.insertMessage("user", text)
        val response = aiEngine.generateResponse(text)
        repository.insertMessage("assistant", response)
    }
}
EOF

# ChatScreen.kt (IMPORT CORRIGIDO)
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/presentation/ChatScreen.kt << 'EOF'
package com.aureon.feature.nexusai.presentation

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import com.aureon.core.i18n.Strings
import com.aureon.feature.nexusai.presentation.components.ChatInput
import com.aureon.feature.nexusai.presentation.components.MessageBubble
import org.koin.androidx.compose.koinInject

@Composable
fun ChatScreen(strings: Strings, viewModel: ChatViewModel = koinInject()) {
    val messages by viewModel.messages.collectAsState()
    Scaffold(
        topBar = { TopAppBar(title = { Text("NexusAI") }) },
        bottomBar = { ChatInput(placeholder = strings.chatPlaceholder, onSend = { viewModel.sendMessage(it) }) }
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(8.dp)
        ) {
            items(messages) { msg -> MessageBubble(message = msg) }
        }
    }
}
EOF

# ChatViewModel.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/presentation/ChatViewModel.kt << 'EOF'
package com.aureon.feature.nexusai.presentation

import com.aureon.feature.nexusai.data.ChatMessage
import com.aureon.feature.nexusai.domain.ChatUseCase
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class ChatViewModel(private val chatUseCase: ChatUseCase) {
    private val scope = CoroutineScope(Dispatchers.Default)
    val messages: StateFlow<List<ChatMessage>> = chatUseCase.messages.stateIn(
        scope, SharingStarted.WhileSubscribed(5000), emptyList()
    )

    fun sendMessage(text: String) {
        scope.launch { chatUseCase.sendMessage(text) }
    }
}
EOF

# MessageBubble.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/presentation/components/MessageBubble.kt << 'EOF'
package com.aureon.feature.nexusai.presentation.components

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.aureon.core.util.markdownToAnnotatedString
import com.aureon.feature.nexusai.data.ChatMessage

@Composable
fun MessageBubble(message: ChatMessage) {
    val isUser = message.role == "user"
    Column(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 4.dp),
        horizontalAlignment = if (isUser) Alignment.End else Alignment.Start
    ) {
        Surface(
            color = if (isUser) MaterialTheme.colorScheme.primaryContainer
                    else MaterialTheme.colorScheme.secondaryContainer,
            shape = MaterialTheme.shapes.medium
        ) {
            Text(text = message.content.markdownToAnnotatedString(), modifier = Modifier.padding(12.dp))
        }
    }
}
EOF

# ChatInput.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/presentation/components/ChatInput.kt << 'EOF'
package com.aureon.feature.nexusai.presentation.components

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.aureon.core.i18n.Strings

@Composable
fun ChatInput(placeholder: String, onSend: (String) -> Unit) {
    var text by remember { mutableStateOf("") }
    Row(modifier = Modifier.fillMaxWidth().padding(8.dp)) {
        OutlinedTextField(
            value = text,
            onValueChange = { text = it },
            placeholder = { Text(placeholder) },
            modifier = Modifier.weight(1f)
        )
        Spacer(Modifier.width(8.dp))
        Button(onClick = { if (text.isNotBlank()) { onSend(text); text = "" } }) {
            Text(Strings.current.send)
        }
    }
}
EOF

# NexusAiModule.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/di/NexusAiModule.kt << 'EOF'
package com.aureon.feature.nexusai.di

import com.aureon.feature.nexusai.data.ChatRepository
import com.aureon.feature.nexusai.data.MockAIEngine
import com.aureon.feature.nexusai.domain.ChatUseCase
import com.aureon.feature.nexusai.presentation.ChatViewModel
import org.koin.dsl.module

val nexusAiModule = module {
    single { MockAIEngine() }
    single { ChatRepository(get()) }
    single { ChatUseCase(get(), get()) }
    single { ChatViewModel(get()) }
}
EOF

# DashboardScreen.kt (IMPORT CORRIGIDO)
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/dashboard/DashboardScreen.kt << 'EOF'
package com.aureon.feature.dashboard

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.aureon.core.i18n.Strings
import com.aureon.feature.dashboard.widgets.SystemStatusWidget
import com.aureon.feature.dashboard.widgets.WidgetGrid
import org.koin.androidx.compose.koinInject

@Composable
fun DashboardScreen(strings: Strings, viewModel: DashboardViewModel = koinInject()) {
    val widgets by viewModel.widgets.collectAsState()
    Scaffold(
        topBar = { TopAppBar(title = { Text(strings.dashboardTitle) }) }
    ) { padding ->
        WidgetGrid(
            modifier = Modifier.padding(padding),
            widgets = widgets,
            onReorder = { viewModel.reorderWidgets(it) }
        )
        SystemStatusWidget()
    }
}
EOF

# DashboardViewModel.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/dashboard/DashboardViewModel.kt << 'EOF'
package com.aureon.feature.dashboard

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

data class DashboardWidget(val id: String, val title: String, val contentDescription: String)

class DashboardViewModel {
    private val _widgets = MutableStateFlow(
        listOf(
            DashboardWidget("nexusai", "NexusAI", "Your offline assistant"),
            DashboardWidget("webforge", "WebForge", "Local web IDE"),
            DashboardWidget("creativestudio", "CreativeStudio", "Media editing")
        )
    )
    val widgets: StateFlow<List<DashboardWidget>> = _widgets

    fun reorderWidgets(newOrder: List<DashboardWidget>) { _widgets.value = newOrder }
}
EOF

# WidgetGrid.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/dashboard/widgets/WidgetGrid.kt << 'EOF'
package com.aureon.feature.dashboard.widgets

import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import com.aureon.feature.dashboard.DashboardWidget

@Composable
fun WidgetGrid(
    modifier: Modifier = Modifier,
    widgets: List<DashboardWidget>,
    onReorder: (List<DashboardWidget>) -> Unit
) {
    var items by remember { mutableStateOf(widgets) }
    LaunchedEffect(widgets) { items = widgets }

    LazyVerticalGrid(
        columns = GridCells.Adaptive(150.dp),
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(8.dp)
    ) {
        items(items.size, key = { items[it].id }) { index ->
            Card(
                modifier = Modifier.padding(4.dp).pointerInput(Unit) {
                    detectDragGestures(
                        onDragEnd = {
                            val mutable = items.toMutableList()
                            if (index < mutable.lastIndex) {
                                val temp = mutable[index]
                                mutable[index] = mutable[index + 1]
                                mutable[index + 1] = temp
                                items = mutable
                                onReorder(mutable)
                            }
                        }
                    )
                },
                elevation = CardDefaults.cardElevation(4.dp)
            ) {
                Column(modifier = Modifier.padding(12.dp)) {
                    Text(text = items[index].title, style = MaterialTheme.typography.titleMedium)
                    Text(text = items[index].contentDescription, style = MaterialTheme.typography.bodySmall)
                }
            }
        }
    }
}
EOF

# SystemStatusWidget.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/dashboard/widgets/SystemStatusWidget.kt << 'EOF'
package com.aureon.feature.dashboard.widgets

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable

@Composable
fun SystemStatusWidget() {
    Column {
        Text("Battery: 85%")
        Text("Storage: 23.1 GB free")
    }
}
EOF

# LocalServer.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/webforge/data/LocalServer.kt << 'EOF'
package com.aureon.feature.webforge.data

import fi.iki.elonen.NanoHTTPD
import java.io.File
import java.io.FileInputStream

class LocalServer(private val port: Int = 8080) {
    private var server: NanoHTTPD? = null

    fun start(webRoot: String) {
        server = object : NanoHTTPD(port) {
            override fun serve(session: IHTTPSession): Response {
                val uri = session.uri.let { if (it == "/") "/index.html" else it }
                val file = File(webRoot, uri)
                return if (file.exists()) {
                    val mime = when {
                        uri.endsWith(".html") -> "text/html"
                        uri.endsWith(".css") -> "text/css"
                        uri.endsWith(".js") -> "application/javascript"
                        else -> "application/octet-stream"
                    }
                    Response(Response.Status.OK, mime, FileInputStream(file))
                } else Response(Response.Status.NOT_FOUND, "text/plain", "Not Found")
            }
        }
        server?.start()
    }

    fun stop() { server?.stop() }
}
EOF

# ProjectManager.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/webforge/domain/ProjectManager.kt << 'EOF'
package com.aureon.feature.webforge.domain

class ProjectManager {
    fun createNewProject(name: String) { /* scaffold files */ }
    fun exportToZip(): ByteArray = byteArrayOf()
}
EOF

# CodeEditorScreen.kt (IMPORT CORRIGIDO)
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/webforge/presentation/CodeEditorScreen.kt << 'EOF'
package com.aureon.feature.webforge.presentation

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import com.aureon.feature.webforge.presentation.components.CodeEditorField
import org.koin.androidx.compose.koinInject

@Composable
fun CodeEditorScreen(viewModel: CodeEditorViewModel = koinInject()) {
    Scaffold(
        topBar = { TopAppBar(title = { Text("WebForge") }) }
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            Button(onClick = { viewModel.toggleServer() }) {
                Text(if (viewModel.isServerRunning) "Stop Server" else "Start Server")
            }
            CodeEditorField(
                code = viewModel.code,
                onCodeChange = { viewModel.updateCode(it) },
                language = "html"
            )
        }
    }
}
EOF

# CodeEditorViewModel.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/webforge/presentation/CodeEditorViewModel.kt << 'EOF'
package com.aureon.feature.webforge.presentation

import com.aureon.feature.webforge.data.LocalServer
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class CodeEditorViewModel(private val localServer: LocalServer) {
    private val _code = MutableStateFlow("<html><body><h1>Hello</h1></body></html>")
    val code: StateFlow<String> = _code

    private val _isServerRunning = MutableStateFlow(false)
    val isServerRunning: StateFlow<Boolean> = _isServerRunning

    fun updateCode(newCode: String) { _code.value = newCode }

    fun toggleServer() {
        if (_isServerRunning.value) localServer.stop()
        else localServer.start("/data/webforge")
        _isServerRunning.value = !_isServerRunning.value
    }
}
EOF

# CodeEditorField.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/webforge/presentation/components/CodeEditorField.kt << 'EOF'
package com.aureon.feature.webforge.presentation.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun CodeEditorField(code: String, onCodeChange: (String) -> Unit, language: String) {
    var textFieldValue by remember { mutableStateOf(TextFieldValue(code)) }
    BasicTextField(
        value = textFieldValue,
        onValueChange = { textFieldValue = it; onCodeChange(it.text) },
        textStyle = TextStyle(fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace, fontSize = 14.sp, color = Color.White),
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 300.dp)
            .background(Color.DarkGray)
            .padding(8.dp)
    )
}
EOF

# WebForgeModule.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/webforge/di/WebForgeModule.kt << 'EOF'
package com.aureon.feature.webforge.di

import com.aureon.feature.webforge.data.LocalServer
import com.aureon.feature.webforge.presentation.CodeEditorViewModel
import org.koin.dsl.module

val webForgeModule = module {
    single { LocalServer() }
    single { CodeEditorViewModel(get()) }
}
EOF

# AppModule.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/core/di/AppModule.kt << 'EOF'
package com.aureon.core.di

import com.aureon.feature.dashboard.DashboardViewModel
import com.aureon.feature.nexusai.di.nexusAiModule
import com.aureon.feature.webforge.di.webForgeModule
import org.koin.core.context.startKoin
import org.koin.dsl.module

val appModule = module {
    single { DashboardViewModel() }
}

fun initKoin() {
    startKoin {
        modules(appModule, nexusAiModule, webForgeModule)
    }
}
EOF

# AndroidManifest.xml
cat > Aureon/composeApp/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application
        android:name=".AureonApp"
        android:allowBackup="true"
        android:label="Aureon"
        android:supportsRtl="true"
        android:theme="@style/Theme.Aureon">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# AureonApp.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/AureonApp.kt << 'EOF'
package com.aureon

import android.app.Application
import com.aureon.core.di.initKoin

class AureonApp : Application() {
    companion object { lateinit var instance: AureonApp }
    override fun onCreate() {
        super.onCreate()
        instance = this
        initKoin()
    }
}
EOF

# MainActivity.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/MainActivity.kt << 'EOF'
package com.aureon

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { App() }
    }
}
EOF

# strings.xml
cat > Aureon/composeApp/src/main/res/values/strings.xml << 'EOF'
<resources>
    <string name="app_name">Aureon</string>
</resources>
EOF

# themes.xml
cat > Aureon/composeApp/src/main/res/values/themes.xml << 'EOF'
<resources>
    <style name="Theme.Aureon" parent="android:Theme.Material.Light.NoActionBar" />
</resources>
EOF

# Gradle wrapper properties
mkdir -p Aureon/gradle/wrapper
cat > Aureon/gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

# Workflow atualizado
mkdir -p .github/workflows
cat > .github/workflows/build.yml << 'EOF'
name: Build Aureon APK

on:
  push:
    paths:
      - 'setup.sh'
      - '.github/workflows/build.yml'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Generate project files
      run: chmod +x setup.sh && ./setup.sh
    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        distribution: temurin
        java-version: 17
    - name: Setup Gradle
      uses: gradle/actions/setup-gradle@v3
      with:
        gradle-version: 8.4
    - name: Build APK
      run: |
        cd Aureon
        gradle :composeApp:assembleRelease
    - name: Upload APK
      uses: actions/upload-artifact@v4
      with:
        name: Aureon-APK
        path: Aureon/composeApp/build/outputs/apk/release/*.apk
EOF

echo "Projeto Aureon (Android puro, sem KMP) gerado com sucesso."
