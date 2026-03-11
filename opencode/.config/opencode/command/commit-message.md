---
description: Create a git commit message based on staged changes
model: ollama/kimi-k2.5:cloud
---

## Context

- Current git status: !`git status`
- Staged changes: !`git diff --cached`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

**IMPORTANT**: You MUST first check if there are any staged changes by examining the "Staged changes" output above.

- If the staged changes output is empty, you MUST respond with an error message: "Error: No staged changes found. Please stage your changes with 'git add' before generating a commit message."
- If there are staged changes, create a single git commit message based ONLY on the staged changes. Use Conventional Commits format.

Return only the commit message itself (or error message) without any additional text. The commit message should be ready for copy-paste.
