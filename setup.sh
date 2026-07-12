
#!/bin/bash
set -e  # Para o script se qualquer comando falhar

echo "Criando estrutura do projeto Aureon..."

# Cria diretório principal
mkdir -p Aureon || { echo "Falha ao criar diretório Aureon"; exit 1; }

# Cria todos os subdiretórios
mkdir -p Aureon/gradle/wrapper
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/core/i18n
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/core/util
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/data
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/domain
mkdir -p Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/presentation/components
mkdir -p Aureon/composeApp/src/main/res/values

# Root build.gradle.kts
cat > Aureon/build.gradle.kts << 'EOF'
plugins {
    id("com.android.application") version "8.2.2" apply false
    id("org.jetbrains.kotlin.android") version "2.0.0" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.0" apply false
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

# composeApp/build.gradle.kts
cat > Aureon/composeApp/build.gradle.kts << 'EOF'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
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
}
EOF

# App.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/App.kt << 'EOF'
package com.aureon

import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import com.aureon.feature.nexusai.presentation.ChatScreen

@Composable
fun App() {
    MaterialTheme {
        ChatScreen()
    }
}
EOF

# Strings.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/core/i18n/Strings.kt << 'EOF'
package com.aureon.core.i18n

object Strings {
    val chatPlaceholder = "Pergunte ao NexusAI..."
    val send = "Enviar"
}
EOF

# Markdown.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/core/util/Markdown.kt << 'EOF'
package com.aureon.core.util

import androidx.compose.ui.graphics.Color
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
                    withStyle(SpanStyle(background = Color.LightGray)) { append(remaining.substring(1, end)) }
                    remaining = remaining.substring(end + 1)
                } else { append(remaining.first()); remaining = remaining.drop(1) }
            }
            remaining.startsWith("\n") -> { append('\n'); remaining = remaining.drop(1) }
            else -> { append(remaining.first()); remaining = remaining.drop(1) }
        }
    }
}
EOF

# ChatMessage data class
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/data/ChatMessage.kt << 'EOF'
package com.aureon.feature.nexusai.data

data class ChatMessage(val role: String, val content: String)
EOF

# ChatRepository (in-memory)
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/data/ChatRepository.kt << 'EOF'
package com.aureon.feature.nexusai.data

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

object ChatRepository {
    private val _messages = MutableStateFlow<List<ChatMessage>>(emptyList())
    val messages: StateFlow<List<ChatMessage>> = _messages

    fun addMessage(role: String, content: String) {
        _messages.value = _messages.value + ChatMessage(role, content)
    }
}
EOF

# MockAIEngine.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/data/MockAIEngine.kt << 'EOF'
package com.aureon.feature.nexusai.data

import kotlinx.coroutines.delay

object MockAIEngine {
    suspend fun generateResponse(userMessage: String): String {
        delay(300)
        if (userMessage.contains("língua", ignoreCase = true) ||
            userMessage.contains("language", ignoreCase = true))
            return "Posso ajudar você a aprender novos idiomas! Tente perguntar 'translate hello to Spanish'."
        return "Estou funcionando offline. Em breve serei alimentado por um modelo de IA real."
    }
}
EOF

# ChatUseCase.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/domain/ChatUseCase.kt << 'EOF'
package com.aureon.feature.nexusai.domain

import com.aureon.feature.nexusai.data.ChatMessage
import com.aureon.feature.nexusai.data.ChatRepository
import com.aureon.feature.nexusai.data.MockAIEngine
import kotlinx.coroutines.flow.StateFlow

class ChatUseCase {
    val messages: StateFlow<List<ChatMessage>> = ChatRepository.messages

    suspend fun sendMessage(text: String) {
        ChatRepository.addMessage("user", text)
        val response = MockAIEngine.generateResponse(text)
        ChatRepository.addMessage("assistant", response)
    }
}
EOF

# ChatScreen.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/presentation/ChatScreen.kt << 'EOF'
package com.aureon.feature.nexusai.presentation

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.aureon.core.i18n.Strings
import com.aureon.feature.nexusai.domain.ChatUseCase
import com.aureon.feature.nexusai.presentation.components.ChatInput
import com.aureon.feature.nexusai.presentation.components.MessageBubble
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen() {
    val useCase = remember { ChatUseCase() }
    val messages by useCase.messages.collectAsState()
    val scope = rememberCoroutineScope()

    Scaffold(
        topBar = { TopAppBar(title = { Text("NexusAI") }) },
        bottomBar = {
            ChatInput(
                placeholder = Strings.chatPlaceholder,
                onSend = { text -> scope.launch { useCase.sendMessage(text) } }
            )
        }
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

# MessageBubble.kt
cat > Aureon/composeApp/src/main/kotlin/com/aureon/feature/nexusai/presentation/components/MessageBubble.kt << 'EOF'
package com.aureon.feature.nexusai.presentation.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
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

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
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
            Text(Strings.send)
        }
    }
}
EOF

# AndroidManifest.xml
cat > Aureon/composeApp/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
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
cat > Aureon/gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-bin.zip
networkTimeout=10000
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF

echo "Projeto Aureon gerado com sucesso."
# Lista os arquivos criados para debug
ls -la Aureon/
