# Requirements Document

## Introduction

GhostB is a universal smart application remover — a cross-platform desktop application built with Flutter (frontend) and a native backend (Rust or Go). GhostB completely removes applications along with all associated caches, residual files, temporary data, logs, hidden folders, orphan dependencies, and unused configurations with a single click. The application supports Linux, Windows, and macOS, detecting installed applications from multiple package managers and installation systems on each platform.

## Glossary

- **GhostB_App**: The main GhostB desktop application that provides the user interface and orchestrates all removal operations
- **Core_Engine**: The native backend module (Rust or Go) responsible for executing system-level operations including scanning, detection, and file removal
- **Scanner**: The subsystem that detects installed applications and their associated files across the operating system
- **Residual_Scanner**: The intelligent scanning subsystem that identifies hidden leftover files, orphan dependencies, and unused configurations after standard uninstallation
- **Cache_Cleaner**: The module responsible for identifying and removing application cache files, temporary data, and log files
- **Uninstaller**: The module that executes the actual removal of applications using the appropriate package manager or system method
- **Protection_System**: The subsystem that manages protected applications and prevents accidental deletion of critical system apps
- **Restore_Point_System**: The subsystem that creates filesystem snapshots before removal operations to allow rollback
- **GhostB_Assistant**: The advisory component that displays space recovery statistics, warns about dangerous removals, and recommends cleanups
- **App_Registry**: The internal database that stores detected application metadata, categories, and protection status
- **Package_Manager_Adapter**: A platform-specific module that interfaces with a particular package manager (APT, Snap, Flatpak, Winget, Homebrew, etc.)
- **Ghost_Mode**: A silent removal mode that performs cleanup automatically without interactive prompts
- **Deep_Scan**: An extended scanning mode that searches for orphan files and old unused data beyond standard application directories
- **Protected_App**: An application marked by the user as locked, preventing accidental deletion
- **Advanced_Mode**: A user-enabled mode that unlocks the ability to remove system-protected applications

## Requirements

### Requirement 1: Cross-Platform Application Detection

**User Story:** As a user, I want GhostB to automatically detect all installed applications on my operating system, so that I can see a complete list of removable software.

#### Acceptance Criteria

1. WHEN GhostB_App is launched on a Linux system, THE Scanner SHALL detect applications installed via APT/DEB, DPKG, Snap, Flatpak, AppImage, Pacman, RPM, Yum/DNF, and tar-based installations
2. WHEN GhostB_App is launched on a Windows system, THE Scanner SHALL detect applications from the Windows registry, Winget, Chocolatey, Scoop, MSI installers, and portable app directories
3. WHEN GhostB_App is launched on a macOS system, THE Scanner SHALL detect .app packages, Homebrew packages, and MacPorts packages
4. WHEN the Scanner completes detection, THE App_Registry SHALL store application name, installation source, installation path, estimated size, and category for each detected application
5. IF a Package_Manager_Adapter fails to query a package manager, THEN THE Scanner SHALL log the error and continue detection with remaining package managers

### Requirement 2: One-Click Full Removal

**User Story:** As a user, I want to completely remove an application and all its related files with a single click, so that no residual data remains on my system.

#### Acceptance Criteria

1. WHEN the user selects an application and confirms removal, THE Uninstaller SHALL remove the application binary, configuration files, cache folders, log files, temporary data, hidden directories, and startup entries associated with that application
2. WHEN removal is initiated on Linux, THE Uninstaller SHALL invoke the appropriate Package_Manager_Adapter for the application's installation source and remove associated files from ~/.config, ~/.local, ~/.cache, and /tmp
3. WHEN removal is initiated on Windows, THE Uninstaller SHALL remove registry entries, AppData files, temp files, hidden caches, startup entries, and associated services
4. WHEN removal is initiated on macOS, THE Uninstaller SHALL remove Library caches, preferences, launch agents, application support files, and hidden residual data
5. WHEN the Uninstaller completes a removal operation, THE GhostB_App SHALL display a summary showing the number of files removed and total disk space recovered

### Requirement 3: Smart Residual Scanner

**User Story:** As a user, I want GhostB to find hidden leftover files from previously uninstalled applications, so that I can reclaim wasted disk space.

#### Acceptance Criteria

1. WHEN the user initiates a residual scan, THE Residual_Scanner SHALL search common application directories for files and folders that do not belong to any currently installed application
2. THE Residual_Scanner SHALL identify orphan configuration files, abandoned cache directories, unused log files, and leftover temporary data
3. WHEN the Residual_Scanner completes a scan, THE GhostB_App SHALL present a categorized list of residual files with their sizes and last-modified dates
4. WHEN residual files are identified, THE GhostB_App SHALL allow the user to select individual items or select all items for removal
5. IF the Residual_Scanner encounters a file with insufficient read permissions, THEN THE Residual_Scanner SHALL skip the file and include it in a "skipped items" report

### Requirement 4: Protected Apps System

**User Story:** As a user, I want to lock critical applications to prevent accidental deletion, so that I do not accidentally remove software I depend on.

#### Acceptance Criteria

1. WHEN the user marks an application as protected, THE Protection_System SHALL add the application to the protected list and prevent removal operations on that application
2. WHILE an application is marked as a Protected_App, THE Uninstaller SHALL reject removal requests for that application and display a protection notice
3. WHEN the user removes protection from an application, THE Protection_System SHALL allow normal removal operations on that application
4. THE Protection_System SHALL mark operating system core applications as protected by default
5. WHILE Advanced_Mode is disabled, THE Protection_System SHALL prevent removal of system-protected applications regardless of user action

### Requirement 5: Ghost Mode

**User Story:** As a user, I want a silent removal mode that cleans up applications automatically without interactive prompts, so that I can perform batch removals efficiently.

#### Acceptance Criteria

1. WHEN the user enables Ghost_Mode and selects applications for removal, THE Uninstaller SHALL execute removal of all selected applications sequentially without additional confirmation prompts
2. WHILE Ghost_Mode is active, THE Cache_Cleaner SHALL automatically remove associated caches and temporary files for each removed application
3. WHEN Ghost_Mode completes all removal operations, THE GhostB_App SHALL display a consolidated summary report showing all removed applications and total space recovered
4. WHILE Ghost_Mode is active, THE Protection_System SHALL continue to enforce protection rules and skip Protected_Apps without halting the batch operation
5. IF an error occurs during Ghost_Mode removal of an application, THEN THE Uninstaller SHALL log the error, skip the failed application, and continue with the remaining applications

### Requirement 6: Deep Scan

**User Story:** As a user, I want to perform a deep scan of my system to find orphan files and old unused data, so that I can maximize disk space recovery.

#### Acceptance Criteria

1. WHEN the user initiates a Deep_Scan, THE Scanner SHALL search the entire user directory tree for files and folders that match known application residual patterns
2. THE Deep_Scan SHALL identify orphan dependencies that are no longer required by any installed application
3. WHEN the Deep_Scan completes, THE GhostB_App SHALL present results grouped by category: orphan dependencies, unused configurations, abandoned caches, and old temporary files
4. THE Deep_Scan SHALL calculate and display the total reclaimable disk space for each category and for all categories combined
5. IF the Deep_Scan identifies a file that belongs to a Protected_App, THEN THE Scanner SHALL exclude that file from the results

### Requirement 7: Restore Point System

**User Story:** As a user, I want to create restore checkpoints before deleting applications, so that I can undo a removal if something goes wrong.

#### Acceptance Criteria

1. WHEN the user initiates a removal operation, THE Restore_Point_System SHALL offer to create a restore point before proceeding
2. WHEN a restore point is created, THE Restore_Point_System SHALL store a manifest of all files and registry entries that will be affected by the removal operation
3. WHEN the user requests a rollback, THE Restore_Point_System SHALL restore all files and registry entries from the selected restore point to their original locations
4. THE Restore_Point_System SHALL display the creation date, associated application name, and storage size for each restore point
5. WHEN available disk space falls below 500 MB, THE Restore_Point_System SHALL warn the user and suggest deleting old restore points
6. IF a restore point file is corrupted or missing, THEN THE Restore_Point_System SHALL notify the user that the restore point is invalid and cannot be used for rollback

### Requirement 8: GhostB Assistant

**User Story:** As a user, I want an intelligent assistant that shows me space recovery statistics and recommends cleanups, so that I can make informed decisions about what to remove.

#### Acceptance Criteria

1. THE GhostB_Assistant SHALL display the total disk space recovered across all removal operations in the current session
2. WHEN the user selects an application for removal, THE GhostB_Assistant SHALL indicate the risk level (low, medium, high) based on whether the application has system dependencies
3. THE GhostB_Assistant SHALL recommend applications and residual files for cleanup based on last-used date and disk space consumption
4. WHEN the user attempts to remove a high-risk application, THE GhostB_Assistant SHALL display a warning with details about potential system impact
5. THE GhostB_Assistant SHALL display a dashboard summary showing total installed applications, total disk usage by applications, and potential reclaimable space

### Requirement 9: App Categories

**User Story:** As a user, I want applications organized into categories, so that I can quickly find and manage specific types of software.

#### Acceptance Criteria

1. WHEN the Scanner detects applications, THE App_Registry SHALL categorize each application into one of the following categories: System, Development, Games, Utilities, or Unknown
2. THE GhostB_App SHALL display applications grouped by category with the ability to filter by a single category
3. WHEN an application cannot be categorized automatically, THE App_Registry SHALL assign it to the Unknown category
4. THE GhostB_App SHALL display the count of applications and total disk usage for each category
5. WHEN the user assigns a custom category to an application, THE App_Registry SHALL persist that categorization across sessions

### Requirement 10: Security and Advanced Mode

**User Story:** As a user, I want system applications protected by default with an advanced mode for power users, so that critical system components are safe from accidental removal.

#### Acceptance Criteria

1. THE Protection_System SHALL identify and protect operating system core components, system services, and critical runtime dependencies by default
2. WHILE Advanced_Mode is disabled, THE GhostB_App SHALL hide system-protected applications from the removal interface
3. WHEN the user enables Advanced_Mode, THE GhostB_App SHALL display system-protected applications with a visible warning indicator
4. WHEN the user enables Advanced_Mode, THE GhostB_App SHALL require explicit confirmation with a typed acknowledgment phrase before allowing removal of system-protected applications
5. IF the user attempts to remove a system-protected application without Advanced_Mode enabled, THEN THE Protection_System SHALL block the operation and display instructions for enabling Advanced_Mode

### Requirement 11: Modern UI with Glassmorphism Design

**User Story:** As a user, I want a beautiful macOS-inspired interface with translucent panels and smooth animations, so that the application feels modern and pleasant to use.

#### Acceptance Criteria

1. THE GhostB_App SHALL render the interface using translucent panels with backdrop blur effects, soft shadows, and rounded corners
2. THE GhostB_App SHALL support dark mode and light mode with smooth transition animations between themes
3. THE GhostB_App SHALL display application cards as floating elements with hover animations and glassmorphism styling
4. THE GhostB_App SHALL use minimal typography with SF Pro-inspired font choices and consistent spacing throughout the interface
5. THE GhostB_App SHALL provide smooth page transitions and micro-interactions for all user actions including button presses, list scrolling, and panel navigation

### Requirement 12: Native Backend Communication

**User Story:** As a developer, I want the Flutter frontend to communicate with native system modules efficiently, so that system-level operations execute with optimal performance and safety.

#### Acceptance Criteria

1. THE GhostB_App SHALL communicate with the Core_Engine through a defined inter-process communication channel using platform channels or FFI
2. WHEN the Core_Engine receives a scan request, THE Core_Engine SHALL execute the scan operation asynchronously and stream progress updates to the GhostB_App
3. WHEN the Core_Engine receives a removal request, THE Core_Engine SHALL validate file permissions before attempting deletion and report permission errors to the GhostB_App
4. IF the Core_Engine process crashes or becomes unresponsive, THEN THE GhostB_App SHALL detect the failure within 5 seconds and display an error recovery dialog
5. THE Core_Engine SHALL execute file system operations with the minimum required privilege level for each operation
