# Roadmap

This document is the working implementation plan for improving the repository from a good personal setup into a reproducible, self-contained workstation platform. It is intended to be the canonical reference for future work.

## Guiding Principles

- Prefer self-contained repo logic over hidden machine-local state.
- Prefer fail-fast installation over silent partial success.
- Keep the daily UX fast and intentional.
- Add automation only where it reduces future setup/debug time.
- Preserve what already makes the setup distinct: theme system, Niri workflow, Waybar actions, and modular install flow.

## Execution Order

Recommended sequence:

1. Doctor command and validation layer
2. Self-contained dependency cleanup
3. Installer hardening
4. Shell and dev runtime cleanup
5. One high-impact UX feature layer

This order is intentional. The first three items reduce ambiguity and make later work safer. The last two build on a more reliable base.

---

## 1. Doctor Command and Validation Layer

### Goal

Create a single command that audits the current machine against the repo's expectations and reports missing dependencies, broken paths, missing scripts, unresolved theme files, and integration drift.

Suggested entrypoint:

- `bash install/doctor.sh`

Optional future integration:

- `bash install/setup.sh --doctor`

### Why This Comes First

Right now the repo contains runtime assumptions spread across:

- Niri startup and keybinds
- Waybar module commands and scripts
- theme scripts
- installer modules
- external commands not declared in package manifests

Without a doctor command, setup issues are discovered only after login and only through manual debugging.

### Scope

The first version should validate:

- required commands referenced in `install/`, `niri/`, `themes/`, `waybar/`, and `zsh/`
- existence of files/scripts referenced via absolute or home-relative paths
- presence of required package managers and core tools
- presence and structure of `~/.config/omarchy/current`
- existence of declared theme directories and default theme files
- repo consistency issues such as stow packages listed in installer but absent in repo

The first version should not:

- mutate the system
- install packages automatically
- require root

### Deliverables

- new script: `install/doctor.sh`
- reusable shell helpers in `install/lib/common.sh` or a new `install/lib/doctor.sh`
- human-readable output with grouped checks and clear failure messages
- non-zero exit code if required checks fail
- optional `--json` mode for future automation

### Check Categories

#### A. Repo integrity checks

Validate internal consistency:

- every package in `STOW_PACKAGES` exists as a directory
- every installer module listed in `install/setup.sh` exists
- expected theme directories exist
- template render inputs exist where needed

#### B. Command dependency checks

Validate commands used by the repo, grouped by source:

- install scripts
- Niri binds
- Niri startup
- Waybar module actions
- theme scripts

Seed list based on current repo:

- `stow`
- `git`
- `curl`
- `yay`
- `fuzzel`
- `alacritty`
- `swaybg`
- `wl-paste`
- `cliphist`
- `wlsunset`
- `swaync-client`
- `swayosd-client`
- `playerctl`
- `pamixer`
- `grim`
- `slurp`
- `satty`
- `notify-send`
- `jq`
- `btop`
- `impala`
- `wiremix`
- `bluetui`

Optional dependencies should be marked separately from required ones.

#### C. File and script path checks

Validate all explicitly referenced paths, including:

- `~/.config/waybar/scripts/clock.sh`
- `~/.config/waybar/scripts/toggle-clock-mode.sh`
- `~/.config/waybar/scripts/evolution-calendar.py`
- `~/.config/waybar/scripts/swaync-status.sh`
- `~/.config/omarchy/current/background`
- `~/.config/omarchy/current/theme`
- `themes/*` scripts referenced by Niri binds

The report should distinguish:

- missing repo file
- missing generated file
- missing external file outside repo ownership

#### D. Theme system checks

Validate:

- current theme name exists
- theme directory can be resolved
- `set-theme` can locate inputs
- at least one background exists when expected
- generated theme directory contains expected outputs

#### E. Integration checks

Validate optional external layers:

- `omarchy-*` commands
- user-local Waybar scripts outside repo
- optional agent config such as `~/.pi/agent/settings.json`

These should be warnings, not hard failures, unless explicitly configured as required.

### Implementation Steps

1. Define output conventions.
   - `PASS`, `WARN`, `FAIL`
   - summary block with counts
   - non-zero exit on `FAIL`

2. Extract shared check helpers.
   - `check_cmd`
   - `check_file`
   - `check_dir`
   - `check_symlink_target`
   - `report_pass/report_warn/report_fail`

3. Implement static repo integrity checks.
   - compare installer-declared stow packages with actual directories
   - compare module list with module files

4. Implement command checks.
   - start with curated command list
   - future version can parse commands automatically from configs

5. Implement file/path checks.
   - home-relative path resolution
   - generated vs source path labeling

6. Add theme checks.
   - inspect `theme.name`
   - validate current theme resolution
   - validate generated outputs

7. Add summary and exit behavior.

8. Add documentation.
   - how to run
   - how to interpret warnings vs failures

### Acceptance Criteria

- Running `bash install/doctor.sh` on a healthy system clearly reports success.
- Running it on a machine missing dependencies produces actionable failures.
- It catches current repo drift such as missing `mango` stow package.
- It identifies currently referenced but undeclared dependencies like `swaybg`, `playerctl`, and `pamixer`.

### Risks

- Too much noise if optional integrations are treated as failures.
- Manual dependency list may drift if not maintained.

### Mitigation

- classify checks into required vs optional
- keep one manifest file for doctor-owned dependency declarations

### Nice-to-Have Follow-ups

- `--json` output
- `--strict` mode
- parse configs automatically for command extraction
- integrate with CI or pre-commit later

---

## 2. Self-Contained Dependency Cleanup

### Goal

Reduce or eliminate hidden dependencies on external machine-local scripts, commands, and environment conventions so the repo can reproduce the intended UX with minimal undocumented setup.

### Current Problem Areas

Known classes of drift:

- Waybar invokes scripts in `~/.config/waybar/scripts/` that are not present in this repo
- some actions invoke `omarchy-*` commands that are not present in this repo
- Niri binds and startup reference commands not declared in package lists
- personal integrations exist but are not clearly marked as optional

### Desired End State

Every dependency should fall into one of these buckets:

- owned by this repo
- installed by this repo
- explicitly documented as optional external integration

No critical interaction should fail silently due to hidden assumptions.

### Deliverables

- inventory of external dependencies
- local replacements or wrappers for missing scripts
- optional integration layer with graceful fallback
- updated package manifests
- updated docs describing owned vs optional components

### Workstreams

#### A. Inventory external references

Build a concrete list of:

- commands not installed by package manifests
- files/scripts referenced outside repo
- non-repo commands under custom namespaces such as `omarchy-*`

Output should be a tracked checklist in this roadmap or a dedicated manifest.

#### B. Decide ownership boundary

For each dependency, decide one:

- move it into this repo
- add it to package manifests
- keep external but mark optional
- remove it entirely

Recommended bias:

- if it is part of core daily UX, own it in the repo
- if it is a niche personal integration, keep it optional with a wrapper

#### C. Replace brittle calls with wrappers

Introduce local wrapper scripts for actions currently delegated to unknown commands.

Examples:

- `scripts/open-power-menu.sh`
- `scripts/open-timezone-selector.sh`
- `scripts/open-bluetooth-ui.sh`

The wrapper can:

- call a local implementation if available
- fallback to external command if present
- show a notification if unavailable

This keeps configs stable while making behavior explicit.

#### D. Move Waybar helper scripts under repo ownership

Recommended target:

- `waybar/.config/waybar/scripts/`

Bring these scripts into the repo or replace them with repo-owned equivalents:

- `clock.sh`
- `toggle-clock-mode.sh`
- `evolution-calendar.py`
- `swaync-status.sh`

#### E. Align package manifests with actual runtime

Add missing packages that are clearly required for current behavior.

Likely candidates:

- `swaybg`
- `playerctl`
- `pamixer`

Potentially:

- `wev` for bind discovery
- `upower` if battery tooling ends up depending on it directly

### Implementation Steps

1. Create a dependency inventory.
2. Mark each dependency as `core`, `optional`, or `remove`.
3. Add repo-owned wrappers for core UX actions.
4. Move or recreate missing helper scripts under repo control.
5. Update package manifests.
6. Update configs to call repo-owned wrappers rather than undocumented external commands.
7. Add doctor checks to enforce the new ownership rules.

### Acceptance Criteria

- A fresh machine can reproduce the core desktop UX from this repo alone.
- Missing optional integrations degrade gracefully with a visible message.
- There are no critical bar or keybind actions that point to unknown commands.

### Risks

- pulling too much personal logic into the repo too early
- overengineering wrappers for one-off actions

### Mitigation

- define `core UX` narrowly
- keep wrappers small and shell-native

### Nice-to-Have Follow-ups

- separate `integrations/` directory for optional add-ons
- host-specific overlay file ignored by git

---

## 3. Installer Hardening

### Goal

Make the installer more trustworthy by surfacing errors clearly, reducing silent partial success, improving idempotency, and adding safe diagnostics.

### Current Problem Areas

- `stow` failures are suppressed
- dependency declarations are split across multiple places with no validation
- bootstrap steps use network installers directly with limited guardrails
- setup flow does not produce a structured summary of what failed

### Desired End State

Installer behavior should be:

- explicit
- idempotent
- diagnosable
- safe to rerun

### Deliverables

- fail-fast stow behavior
- clearer per-module success/failure reporting
- optional dry-run mode
- preflight validation beyond “internet works”
- better handling of network-based installs

### Workstreams

#### A. Fix silent stow failures

Current behavior hides deployment conflicts. Replace it with:

- visible error output
- clear indication of which package failed
- optional continue-on-error mode only if explicitly requested

#### B. Add structured setup summary

At the end of `install/setup.sh`, show:

- modules completed
- modules skipped
- warnings
- failures
- manual follow-up actions

#### C. Add `--dry-run`

Support previewing:

- which modules will run
- which packages will be installed
- which stow targets will be applied

This is especially useful before touching a non-disposable machine.

#### D. Strengthen preflight checks

Expand module `00-preflight` to include:

- required commands for installer itself
- disk space sanity check
- package manager availability
- optional warning when user config files will conflict with stow targets

#### E. Improve network install robustness

Direct curl-pipe installers are convenient, but should have better reporting.

Possible improvements:

- explicit download then execute
- version pinning where practical
- checksum or release tag pinning where available
- clearer failure messages when downloads fail

#### F. Separate machine-safe vs invasive steps

Some actions modify system paths and services. Make those boundaries clearer:

- display manager enable/disable
- Chrome policy path modifications
- shell change via `chsh`

Longer-term option:

- interactive confirmation mode for invasive steps

### Implementation Steps

1. Remove `|| true` from stow deployment and handle errors explicitly.
2. Add result tracking to `run_module`.
3. Add setup summary at the end.
4. Implement `--dry-run`.
5. Expand preflight checks.
6. Review each network installer for better failure handling.
7. Separate invasive steps with clearer messaging or flags.

### Acceptance Criteria

- Installer stops clearly on hard failures.
- Stow conflicts are visible and actionable.
- A rerun after a partial failure behaves predictably.
- Dry-run gives a useful preview without changing the system.

### Risks

- stricter behavior may feel less convenient initially
- dry-run coverage may be incomplete if every module is not adapted

### Mitigation

- start with strict defaults for obvious failures only
- document dry-run limitations honestly

### Nice-to-Have Follow-ups

- module dependency graph
- module timing output
- log file under `~/.local/state/...`

---

## 4. Shell and Dev Runtime Cleanup

### Goal

Reduce shell startup overhead, separate portable config from machine-local config, and make language/runtime setup more intentional and maintainable.

### Current Problem Areas

- `zshrc` mixes framework config, env vars, aliases, Android/Java paths, and runtime switching
- `nvm` is loaded eagerly on every shell startup
- shell config has no clear separation between portable and host-specific concerns
- dev tool installation is convenient but not yet organized as a coherent runtime strategy

### Desired End State

Shell should be:

- fast to start
- easy to reason about
- portable across machines
- able to support multiple language runtimes without clutter

### Deliverables

- refactored shell config structure
- lazy-loaded Node runtime setup
- clear host-local override mechanism
- expanded dev runtime install strategy

### Workstreams

#### A. Restructure shell config

Split current `zsh/.zshrc` into logical files, for example:

- `.zshrc`
- `.zsh/env.zsh`
- `.zsh/aliases.zsh`
- `.zsh/path.zsh`
- `.zsh/lang-runtimes.zsh`
- `.zsh/local.zsh` ignored by git

The goal is not complexity for its own sake; it is to separate stable repo-owned behavior from machine-local details.

#### B. Lazy-load Node tooling

Current eager `nvm` loading likely costs noticeable startup time.

Recommended options:

- keep `nvm`, but lazy-load it on first `node/npm/npx/nvm` call
- or migrate to `fnm`/`mise` if desired later

First iteration should optimize without changing your workflow semantics.

#### C. Normalize PATH management

Avoid repeated `export PATH=...:$PATH` scatter.

Move all path logic into one place and define order intentionally:

- local bin
- language managers
- SDK/tooling paths

#### D. Separate machine-local environment

Items like `ANDROID_HOME`, `JAVA_HOME`, and machine-specific aliases should not need to live in the portable core.

Recommended approach:

- keep sane defaults in repo if broadly useful
- move machine-specific overrides to `local.zsh`
- include a tracked `local.zsh.example`

#### E. Expand dev runtime strategy

Decide what the repo officially manages:

- Node via `nvm` or future replacement
- Bun
- Java
- Android SDK path assumptions
- possibly `uv`, `pnpm`, `rustup`, `go`, `mise`

This likely belongs in a dedicated installer module later.

### Implementation Steps

1. Measure current shell startup time.
2. Split shell config into focused files.
3. Implement lazy-load for `nvm`.
4. Centralize PATH logic.
5. Introduce optional `local.zsh`.
6. Decide which runtimes are first-class in installer scope.
7. Update install docs accordingly.

### Acceptance Criteria

- Interactive shell startup is visibly faster.
- Portable config is clearly distinct from machine-local config.
- Node version switching still works correctly in project directories.
- Future runtime additions have an obvious home.

### Risks

- lazy-loading can break edge-case shell scripts or completions
- over-splitting config can make navigation worse

### Mitigation

- keep file count low
- preserve behavior first, optimize second

### Nice-to-Have Follow-ups

- `zoxide`
- `atuin`
- `eza` aliases
- `mise` evaluation branch

---

## 5. High-Impact UX Feature Layer

### Goal

Add one polished system feature that materially improves everyday use and reinforces the identity of the setup.

### Recommendation

Build `Focus mode` first.

It fits the current architecture better than the alternatives because you already have:

- theme switching
- notifications
- idle inhibitor
- night light
- Waybar
- keybind infrastructure

This gives a lot of leverage with relatively little new infrastructure.

### Feature Concept: Focus Mode

One toggle should switch the system into a distraction-reduced state optimized for deep work, meetings, or writing.

Possible effects:

- enable Do Not Disturb in `swaync`
- enable idle inhibitor
- optionally enable or tune night light
- reduce bar noise or swap to a simplified bar mode
- send a notification describing the active mode
- optionally apply a focus theme accent or wallpaper variant

### Desired Characteristics

- one hotkey to toggle
- explicit visual state
- idempotent
- reversible
- graceful if optional integrations are missing

### Deliverables

- `scripts/focus-mode.sh` or similar repo-owned script
- state file under `~/.local/state/` or `~/.config/omarchy/current/`
- Niri bind for toggle
- Waybar indicator module
- docs describing behavior

### Functional Design

#### A. State model

Use a simple state file:

- `on`
- `off`

Optional future extension:

- `focus`
- `meeting`
- `writing`

#### B. Actions on enable

Suggested first version:

- enable `swaync` Do Not Disturb
- enable idle inhibitor
- optionally enable a warmer night light profile
- show notification: `Focus mode enabled`

#### C. Actions on disable

- restore previous `swaync` state if tracked
- disable idle inhibitor if it was enabled by focus mode
- restore normal night light state
- show notification: `Focus mode disabled`

#### D. Bar integration

Add a small indicator to Waybar showing:

- current focus state
- click to toggle
- tooltip with active effects

### Alternative Feature Backlog

If Focus mode is done well, next candidates:

- workspace scenes
- automatic day/night theme scheduling
- screenshot and recording hub

### Implementation Steps

1. Define exact behavior for v1.
2. Create repo-owned script with simple state handling.
3. Add toggle bind in Niri.
4. Add Waybar module/indicator.
5. Test interaction with existing idle inhibitor and notification behavior.
6. Document usage.

### Acceptance Criteria

- Focus mode can be toggled reliably from a hotkey.
- The current state is visible without guessing.
- It does not leave the system in a confused partial state after repeated toggles.

### Risks

- state drift if external toggles modify DND or idle inhibitor independently
- overcomplicating v1 with too many side effects

### Mitigation

- keep v1 narrow
- track only the state this feature directly controls

### Nice-to-Have Follow-ups

- multiple focus profiles
- automatic activation by calendar status
- theme variant integration

---

## Cross-Cutting Tasks

These tasks support multiple roadmap items and should be kept visible:

- create a single dependency manifest for repo-owned command expectations
- document ownership boundaries for optional integrations
- introduce lightweight state storage conventions
- improve README/docs so a future machine can be bootstrapped without memory work

## Suggested Milestones

### Milestone 1: Reliability Baseline

- doctor command implemented
- missing runtime dependencies identified
- self-contained ownership decisions made

### Milestone 2: Reproducible Core UX

- Waybar/Niri no longer depend on undocumented external pieces
- package manifests aligned with actual usage
- installer fails clearly and predictably

### Milestone 3: Faster Daily Driver

- shell config refactored
- startup improved
- machine-local customization separated cleanly

### Milestone 4: Signature System Feature

- Focus mode shipped
- visible UX polish layered on top of reliable base

## Definition of Done for This Roadmap

This roadmap should be considered meaningfully complete when:

- the repo can bootstrap the core workflow onto a new Arch machine with minimal undocumented manual work
- setup failures are visible and diagnosable
- personal integrations are clearly separated from portable core logic
- one additional signature feature has been implemented cleanly

## Next Recommended Action

Start with item 1 and implement:

1. `install/doctor.sh`
2. shared doctor helpers
3. initial dependency manifest
4. first pass checks for repo drift, commands, and file paths

Once that is in place, use the doctor report to drive items 2 and 3 with real data instead of assumptions.
