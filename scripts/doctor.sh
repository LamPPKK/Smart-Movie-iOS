#!/usr/bin/env bash

set -u

failures=0

pass() {
  printf 'PASS  %s\n' "$1"
}

fail() {
  printf 'FAIL  %s\n' "$1"
  failures=$((failures + 1))
}

require_command() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "$1 is available"
  else
    fail "$1 is required"
  fi
}

developer_dir="$(xcode-select -p 2>/dev/null || true)"
if [[ "$developer_dir" == */Xcode.app/Contents/Developer ]]; then
  pass "full Xcode toolchain is selected ($developer_dir)"
else
  fail "select the full Xcode toolchain; current developer directory is '${developer_dir:-unavailable}'"
fi

require_command xcodebuild
require_command swift
require_command xcodegen
require_command swiftlint
require_command node
require_command npm
require_command java

swift_version="$(swift --version 2>/dev/null | head -n 1 || true)"
if [[ "$swift_version" =~ Swift[[:space:]]version[[:space:]]6\. ]]; then
  pass "$swift_version"
else
  fail "Swift 6 is required; detected '${swift_version:-unavailable}'"
fi

node_major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || true)"
if [[ "$node_major" == "24" ]]; then
  pass "Node.js $(node --version)"
else
  fail "Node.js 24 is required; detected '${node_major:-unavailable}'"
fi

java_major="$(java -version 2>&1 | sed -n 's/.*version "\([0-9][0-9]*\).*/\1/p' | head -n 1)"
if [[ "$java_major" == "17" ]]; then
  pass "JDK 17 is selected for Android"
else
  fail "JDK 17 is required for Android; detected '${java_major:-unavailable}'"
fi

if [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME" ]]; then
  pass "Android SDK is available ($ANDROID_HOME)"
elif [[ -n "${ANDROID_SDK_ROOT:-}" && -d "$ANDROID_SDK_ROOT" ]]; then
  pass "Android SDK is available ($ANDROID_SDK_ROOT)"
else
  fail "ANDROID_HOME or ANDROID_SDK_ROOT must point to the Android SDK"
fi

kmp_java_home="${KMP_JAVA_HOME:-}"
if [[ -z "$kmp_java_home" ]] && command -v /usr/libexec/java_home >/dev/null 2>&1; then
  kmp_java_home="$(/usr/libexec/java_home -v 21 2>/dev/null || true)"
fi
if [[ -n "$kmp_java_home" && -x "$kmp_java_home/bin/java" ]]; then
  kmp_java_version="$("$kmp_java_home/bin/java" -version 2>&1 | sed -n 's/.*version "\([0-9][0-9]*\).*/\1/p' | head -n 1)"
  if [[ "$kmp_java_version" == "21" ]]; then
    pass "JDK 21 is available for KMP ($kmp_java_home)"
  else
    fail "JDK 21 is required for KMP; detected '${kmp_java_version:-unavailable}'"
  fi
else
  fail "JDK 21 is required for KMP; set KMP_JAVA_HOME or install JDK 21"
fi

if (( failures > 0 )); then
  printf '\nDoctor found %d blocking issue(s). No system changes were made.\n' "$failures"
  exit 1
fi

printf '\nSmartMovie Apple/Worker development environment is ready.\n'
