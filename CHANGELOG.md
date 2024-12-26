# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.2]

### Added

### Changed

- Relaxed `live_view_native` constraint

### Fixed

- fix live reload pattern for the sheet file https://github.com/liveview-native/live_view_native_stylesheet/pull/83

## [0.3.0] 2024-08-21

### Added

- capture and log raises within `class/1` call when compiling stylesheet
- removed `_interface` argument from the `class/2` now it is `class/1`
- added parsing of `style` attribute from all templates (single template files and withing ~LVN templates) to be passed into the respective format's RulesParser

### Changed

- fixed line numbers for `~SHEET`
- refactor `lvn.stylsheet.setup.config` to use `live_view_native`'s updated codegen api

### Fixed

- resolved issue where pattern matched class names were matching `nil` and `""`
