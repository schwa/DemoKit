# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Test Commands

- **Build**: `swift build`
- **Test**: `swift test`
- **Run specific test**: `swift test --filter TestName`

## Architecture Overview

DemoKit is a SwiftUI library for creating demonstration/sample views with metadata and navigation support. The library provides:

### Core Components

- **`DemoMetadata`**: Identifiable struct containing demo metadata including name, icon, description, group, keywords, color, and variants
- **`DemoView` protocol**: Protocol for demo views requiring `static var metadata` and a parameterless `@MainActor init()`
- **`DemoPickerView`**: Public entry point that displays a navigation split view of available demos
- **`DemosNavigationSplitView`**: Internal navigation component that renders demo list in sidebar with detail view

### Package Structure

- Swift Package Manager project targeting iOS 18+ and macOS 15+
- Uses Swift Testing framework (not XCTest) with `#expect` assertions
- Single library product: `DemoKit`

### Development Notes

- The project uses Jujutsu (`.jj`) for version control in addition to git
- Access control is declared for library targets (`public`/`internal`/`private`)
- SwiftUI views use modern patterns like `@Observable` over `ObservableObject`