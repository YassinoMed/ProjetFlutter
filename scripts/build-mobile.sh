#!/usr/bin/env bash

set -e

# --- Configuration ---
FLUTTER_CMD="flutter"
BUILD_DIR="build_output"
export APP_ENV=${APP_ENV:-production}

echo "=========================================="
echo "📱 Début du script de build mobile Flutter"
echo "Environnement : $APP_ENV"
echo "=========================================="

mkdir -p $BUILD_DIR

# --- 1. Installation des dépendances ---
echo "📦 Installation des paquets..."
$FLUTTER_CMD pub get

# --- 2. Build Android (APK & AAB) ---
echo "🤖 Compilation de la version Android..."
if [ "$APP_ENV" == "production" ]; then
    # --obfuscate permet de cacher le code source Dart
    # --split-debug-info pour la trace de crash
    $FLUTTER_CMD build apk --release --obfuscate --split-debug-info=$BUILD_DIR/debug_info
    $FLUTTER_CMD build appbundle --release --obfuscate --split-debug-info=$BUILD_DIR/debug_info
    
    # Déplacement des artefacts Android
    cp build/app/outputs/flutter-apk/app-release.apk $BUILD_DIR/mediconnect-release.apk
    cp build/app/outputs/bundle/release/app-release.aab $BUILD_DIR/mediconnect-release.aab
    echo "✅ Build Android (Release/Prod) terminé."
else
    # Build de développement
    $FLUTTER_CMD build apk --debug
    cp build/app/outputs/flutter-apk/app-debug.apk $BUILD_DIR/mediconnect-debug.apk
    echo "✅ Build Android (Debug) terminé."
fi

# --- 3. Build iOS (IPA) ---
# Le build iOS nécessite xcodebuild, qui ne fonctionne que sur MacOS
echo "🍏 Vérification de l'environnement pour iOS..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🔨 Compilation de la version iOS..."
    if [ "$APP_ENV" == "production" ]; then
        # Assurez-vous d'avoir exportOptions.plist bien configuré à la racine "frontend/ios/ExportOptions.plist"
        # pour la signature automatique par CI/CD Jenkins
        $FLUTTER_CMD build ipa --release --export-options-plist=ios/ExportOptions.plist --obfuscate --split-debug-info=$BUILD_DIR/debug_info
        cp build/ios/ipa/*.ipa $BUILD_DIR/mediconnect-release.ipa
        echo "✅ Build iOS (Release) terminé."
    else
        $FLUTTER_CMD build ios --debug --no-codesign
        echo "✅ Build iOS (Debug Simulé) terminé."
    fi
else
    echo "⚠️  Ignoré : Le build iOS nécessite un environnement macOS (Darwin). Ce nœud est $(uname -s)."
fi

echo "=========================================="
echo "🎉 Tous les artefacts générés sont dans : ./$BUILD_DIR/"
ls -lh $BUILD_DIR/
echo "=========================================="
