# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Novakey is a macOS keyboard input monitoring and logging service that captures keyboard input, converts romaji to hiragana, and uses Ollama AI to convert hiragana to kanji. The application monitors keyboard events in real-time and processes Japanese text input.

## Architecture

The project is structured with two main targets:
- **Novakey**: Executable CLI application using ArgumentParser
- **NovakeyCore**: Core functionality library containing:
  - `KeyboardMonitor`: Handles low-level keyboard event monitoring using CoreGraphics event taps
  - `InputBuffer`: Manages text buffering and triggers AI conversion
  - `OllamaClient`: Communicates with local Ollama API for text conversion

The flow: KeyboardMonitor captures keystrokes → converts romaji to hiragana → InputBuffer accumulates text → OllamaClient converts to kanji using local LLM.

## Common Commands

### Build and Run
```bash
swift build -c release
.build/release/novakey
```

### With Options
```bash
# Log to file
.build/release/novakey --log-file /path/to/log.txt

# Debug mode
.build/release/novakey --debug
```

### Testing
```bash
swift test
```

## Key Dependencies

- **swift-log**: Logging framework
- **swift-argument-parser**: CLI argument parsing
- **CoreGraphics/ApplicationServices**: macOS keyboard event monitoring
- **Ollama**: Local LLM API (default: gemma3:1b model on localhost:11434)

## Important Notes

- Requires macOS 13.0+ and accessibility permissions
- Uses event taps that require system-level permissions
- Default conversion delay is 2 seconds with immediate flush on punctuation
- Buffer size limit is 100 characters with 5-second auto-flush