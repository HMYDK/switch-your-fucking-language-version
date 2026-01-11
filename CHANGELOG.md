# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
- Version installation via Homebrew
- Version uninstallation with safety protection (active version cannot be deleted)
- Real-time download progress display
- System notifications for installation completion
- Shell integration via `~/.config/devmanager/*_env.sh`
- Quick Start guide in Dashboard

### Technical
- Built with SwiftUI for native macOS experience
- Protocol-oriented design with type erasure for extensibility
- Unified version management from Info.plist
