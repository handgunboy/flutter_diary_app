# Gradle 构建问题记录

## 问题描述

Flutter 项目在使用 `flutter build apk --release` 命令构建时，Gradle 报错无法启动构建。

## 错误信息

```
FAILURE: Build failed with an exception.

* What went wrong:
Gradle could not start your build.
> Could not create service of type DaemonDir using DaemonRegistryServices.createDaemonDir().
   > Cannot invoke "java.io.File.exists()" because "parent" is null
```

或

```
FAILURE: Build failed with an exception.

* What went wrong:
Gradle could not start your build.
> Could not initialize native services.
   > Failed to load native library 'native-platform.dll' for Windows 11 amd64.
```

## 环境信息

- **操作系统**: Windows 11
- **Flutter 版本**: 3.32.6
- **Gradle 版本**: 8.12 (wrapper)
- **Java 版本**: OpenJDK 17.0.2 / OpenJDK 21.0.6
- **项目路径**: `h:\PROJECT\flutter\logs\diary_app`

## 问题原因

1. **GRADLE_USER_HOME 环境变量问题**: Gradle wrapper 脚本无法正确识别或创建 GRADLE_USER_HOME 目录
2. **Gradle 本地库加载失败**: `native-platform.dll` 加载失败，可能与权限或环境配置有关
3. **PowerShell 环境变量传递问题**: 通过 PowerShell 设置的环境变量可能没有正确传递给 Gradle wrapper

## 已尝试的解决方案

### 1. 清理 Gradle 缓存
```powershell
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle"
flutter clean
```
**结果**: 无效

### 2. 设置 GRADLE_USER_HOME 环境变量
```powershell
[Environment]::SetEnvironmentVariable("GRADLE_USER_HOME", "$env:USERPROFILE\.gradle", "Process")
```
**结果**: 无效

### 3. 修改 gradlew.bat 脚本
在 `gradlew.bat` 中添加：
```batch
@rem Set GRADLE_USER_HOME if not defined
if not defined GRADLE_USER_HOME (
    set "GRADLE_USER_HOME=%USERPROFILE%\.gradle"
)
```
**结果**: 部分有效，但 wrapper 仍有其他问题

### 4. 降级 Gradle 版本
将 `gradle-wrapper.properties` 中的 Gradle 版本从 8.12 降级到 8.11.1
**结果**: 无效

### 5. 禁用 Gradle Native 服务
```powershell
[Environment]::SetEnvironmentVariable("GRADLE_OPTS", "-Dorg.gradle.native=false", "Process")
```
**结果**: 导致其他错误

## 最终解决方案

使用本地 Gradle 直接构建，绕过 wrapper：

```powershell
& "$env:USERPROFILE\.gradle\wrapper\dists\gradle-8.12-all\5xz8zfvr8cydg32e8t979sl6f\gradle-8.12\bin\gradle.bat" -p android assembleRelease --no-daemon
```

### 构建成功输出
```
BUILD SUCCESSFUL in 11s
373 actionable tasks: 16 executed, 1 from cache, 356 up-to-date
```

## APK 输出位置

构建成功的 APK 文件位于：
```
h:\PROJECT\flutter\logs\diary_app\build\app\outputs\flutter-apk\app-release.apk
```

## 后续建议

1. **修复 wrapper 脚本**: 需要进一步调查为什么 wrapper 脚本在 PowerShell 环境下无法正常工作
2. **环境变量配置**: 考虑在系统级别设置 GRADLE_USER_HOME 环境变量
3. **Gradle 版本**: 考虑升级到更新的 Gradle 版本，或回退到更稳定的版本
4. **替代方案**: 可以配置 IDE (Android Studio/VS Code) 使用本地 Gradle 而不是 wrapper

## 相关文件

- `android/gradlew.bat` - Gradle wrapper 启动脚本
- `android/gradle/wrapper/gradle-wrapper.properties` - Gradle wrapper 配置
- `android/build.gradle.kts` - 项目级 Gradle 配置

## 记录时间

2026-04-12
