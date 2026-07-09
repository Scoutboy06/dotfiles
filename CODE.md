# CODE.md - dotfiles

## Project Overview

Custom dotfiles for personal use, including configurations for various tools and applications. Used on a variety of computers and operating systems to maintain a consistent development environment.

## Repository Structure

```
.
├── README.md                     # Project documentation and overview
├── dot_agents/                   # Configurations for various agents and tools
│   └── skills/                   # Skills and configurations for different agents
├── dot_claude/                   # Configurations specific to the Claude agent
│   └── symlink_skills/           # A direct symlink of dot_agents/skills/
├── dot_config/                   # Configuration files
├── dot_local/                    # Local configuration files and scripts
│   ├── bin/                      # Custom scripts and executables
│   └── share/                    # Shared resources and data files
│       └── applications/         # Desktop entry files for applications
├── dot_zshrc.tmpl                # Zsh configuration
└── install-windows-packages.ps1  # PowerShell script for installing Windows packages
```

## Agent Behavior

- Do not read files to verify changes you just made, trust the edit.
- Batch independent tool calls in parallel to minimize round-trips.
