# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Core test runner `RuntimePilotChecks` covering version parsing/sorting, script generation, config validation and migration rules
- GitHub Actions workflow to run core checks on pushes and pull requests

## [1.0.0] - 2026-11-14

### Fixed
- Packaged app now includes SwiftPM resource bundle, preventing launch crashes on other Macs
- Replaced 100ms polling with event-driven manager updates and removed per-render wrapper recreation
- Do not mark a version as active until it has been explicitly selected and its env script was written
- Show a failure alert when switching versions fails instead of always reporting success
- Corrected Flutter, .NET, Rust and Go (asdf) version detection and PATH/env generation
- Migrated old Rust configs away from the invalid RUSTUP_HOME usage
- Fixed background-thread SwiftUI publishing in scan path status checks
- Deleting a language now updates the registry, removes its env script and persisted active version
- Custom SF Symbol icons now render in Dashboard and language detail views
- Validate identifiers and environment variable names; escape paths written to shell scripts
- Use security-scoped bookmarks on the authorized root directory
- Updated README config directory and added signing/notarization notes

## [0.0.2] - 2026-01-11

### Added
- GitHub Actions CI/CD for automated releases
- In-app update checker with GitHub API integration
- Version status display in Dashboard header
- CHANGELOG.md for tracking version history

### Changed
- Project renamed from DevManager to RuntimePilot
- Unified version management from Info.plist
- Improved error handling for update checks (silent 404 handling)

## [0.0.1] - 2026-01-11

### Added
- Initial release
- Support for Java, Node.js, Python, and Go runtime management
- Dashboard with environment overview
- Version scanning and switching
- Shell integration via `~/.config/runtimepilot/*_env.sh`
- Quick Start guide in Dashboard

### Technical
- Built with SwiftUI for native macOS experience
- Protocol-oriented design with type erasure for extensibility
- Unified version management from Info.plist
