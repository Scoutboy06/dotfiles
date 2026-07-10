# Agents Guide (dotfiles)

**IMPORTANT** - You MUST ALWAYS follow the instruction in this file.

## CODE.md files

### Description

`CODE.md` files define hard requirements on folder and file structure.
For example; local conventions, patterns, constraints, and technical decisions.
The scope for each `CODE.md` file is the folder it is located in and all sub-folders.

### Actions

Before creating or modifying ANY file, locate all `CODE.md` files in scope:
1. Start by looking in the affected file's folder.
2. Traverse up to repository root, locating `CODE.md` files along the way
You MUST ALWAYS read `CODE.md` files fresh using the Read tool - never rely on content from earlier in the conversation.
You MUST ALWAYS look in EVERY folder along the path. You may NOT skip any folder.

Combine all found `CODE.md` files into a single instruction block.
If there are conflicting instructions, those that came from a file deeper in the structure take precedence.

You are NOT allowed to modify `CODE.md` files unless EXPLICITY instructed to do so.

## Git

- **NEVER** add yourself as a co-author to any commit.