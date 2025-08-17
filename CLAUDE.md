# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PuffTrack is an iOS SwiftUI application designed to help users track their vaping habits and support withdrawal. The app has no external dependencies and uses Swift Package Manager for any future package management needs.

## Build and Development Commands

### Building the Project
- Open `PuffTrack.xcodeproj` in Xcode
- Use Xcode's build system (⌘+B) to build the project
- Run the app using Xcode's simulator or connected device (⌘+R)

### Dependencies
The project currently has no external dependencies. If you need to add Swift packages in the future:
- In Xcode: File → Add Package Dependencies
- Or use Xcode's Package.swift integration

### Testing
```bash
# Run tests in Xcode using ⌘+U
# Or use xcodebuild from command line:
xcodebuild test -project PuffTrack.xcodeproj -scheme PuffTrackReal -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

## Architecture

### Core Components

**Data Layer:**
- `PuffTrackData`: ObservableObject managing core data (puffs, settings) with UserDefaults persistence
- `DataModels.swift`: Defines `Puff`, `UserSettings`, `Milestone` structs

**Business Logic:**
- `CalculationEngine`: Static utility class handling streak calculations, withdrawal status, and financial metrics
- `PuffTrackViewModel`: Main view model coordinating data, calculations, and UI state

**Views (SwiftUI):**
- `ContentView`: Main app interface with puff tracking, withdrawal status, and statistics
- `SettingsView`: User configuration for vape cost, puff limits, etc.
- `StatisticsView`: Detailed usage analytics and trends
- `GraphView`: Visual charts of puff data over time
- `WithdrawalTrackerView`: Detailed withdrawal progress and support
- `MilestonesView`: Achievement tracking for milestone rewards
- `OnboardingView`: First-time user setup flow

### Dependencies
The project has no external dependencies and uses only iOS system frameworks.

### Data Flow
1. User actions trigger methods in `PuffTrackViewModel`
2. ViewModel updates `PuffTrackData` model
3. `CalculationEngine` processes raw data into metrics
4. SwiftUI views observe published properties for automatic UI updates
5. Data persists to UserDefaults through `PuffTrackData`

### Important Files
- `PuffTrackRealApp.swift`: App entry point
- `ContentView.swift:77-146`: Main puff tracking interface with half-circle progress indicator
- `ViewModel.swift:154-159`: Core puff addition logic
- `CalculationEngine.swift:21-42`: Withdrawal status calculation algorithm
- `DataModels.swift:40-45`: Puff recording and data management

The app is currently open source and no longer actively maintained, but remains functional for tracking vaping habits and supporting cessation efforts.