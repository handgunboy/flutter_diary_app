@echo off
chcp 65001 >nul
echo ==========================================
echo    Flutter 国内镜像配置脚本
echo ==========================================
echo.

:: 设置清华大学镜像（推荐）
echo [1/2] 正在配置清华大学镜像...
set PUB_HOSTED_URL=https://mirrors.tuna.tsinghua.edu.cn/dart-pub
set FLUTTER_STORAGE_BASE_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter

:: 可选：使用 Flutter 中国社区镜像（如果清华慢可以换这个）
:: set PUB_HOSTED_URL=https://pub.flutter-io.cn
:: set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

echo.
echo 已配置环境变量：
echo   PUB_HOSTED_URL=%PUB_HOSTED_URL%
echo   FLUTTER_STORAGE_BASE_URL=%FLUTTER_STORAGE_BASE_URL%
echo.

echo [2/2] 正在下载依赖...
flutter clean
flutter pub get

echo.
echo ==========================================
if %errorlevel% == 0 (
    echo    依赖下载完成！
) else (
    echo    下载失败，请检查网络连接
)
echo ==========================================
pause
