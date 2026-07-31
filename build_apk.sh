#!/bin/bash
set -e

echo "Installing dependencies..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y -qq curl git unzip xz-utils zip libglu1-mesa openjdk-17-jdk > /dev/null

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

WORKSPACE=/workspaces/Jacponge
echo "Setting up Android SDK..."
mkdir -p $WORKSPACE/android_sdk/cmdline-tools
cd $WORKSPACE/android_sdk/cmdline-tools
wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip
unzip -q cmdline-tools.zip
rm cmdline-tools.zip
mv cmdline-tools latest

export ANDROID_HOME=$WORKSPACE/android_sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH

echo "Accepting Android licenses..."
yes | sdkmanager --licenses > /dev/null

echo "Installing Android platform-tools & build-tools..."
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" > /dev/null

echo "Setting up Flutter..."
cd $WORKSPACE
if [ ! -d "flutter" ]; then
  wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz
  tar xf flutter_linux_3.24.0-stable.tar.xz
  rm flutter_linux_3.24.0-stable.tar.xz
fi

export PATH=$WORKSPACE/flutter/bin:$PATH

flutter config --android-sdk $ANDROID_HOME > /dev/null
yes | flutter doctor --android-licenses > /dev/null

echo "Running flutter doctor..."
flutter doctor -v

echo "Building APK..."
cd $WORKSPACE/liquid_clean_flutter
flutter pub get
flutter build apk --release

echo "Build complete! APK should be in build/app/outputs/flutter-apk/"
