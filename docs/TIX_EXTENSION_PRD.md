# Product Requirements Document: Tix Extension System

## Executive Summary

Tix will adopt a Unix-philosophy extension model similar to Git, where functionality is extended through standalone executables that follow filesystem conventions rather than through a traditional plugin API. This approach maintains simplicity in the core while enabling unlimited extensibility.

## Vision

Create an infinitely extensible ticket system where:

- The core remains simple and stable
- Extensions are just programs that read/write files
- No central coordination or API versioning is needed
- Installation is as simple as copying a binary to PATH
- Extensions compose naturally through Unix pipes

## Core Principles

### 1. Everything is a File

All ticket metadata is stored as files within `.tix/TICKET_ID/`. No databases, no JSON manifests, just files whose existence and names convey meaning.

### 2. Convention Over Configuration

Extensions agree on naming conventions rather than schemas. If multiple tools understand `assigned_*` files, they interoperate automatically.

### 3. Do One Thing Well

Core tix only manages: title, body, status (s=_), and priority (p=_). Everything else is an extension.

### 4. Text Streams

Extensions communicate through stdin/stdout, enabling pipeline composition.

### 5. No Plugin System

There is no plugin manager, no plugin API, no version negotiation. Extensions are just executables named `tix-*`.

## Architecture

### Command Discovery

When a user types `tix <command> <args>`, tix follows this logic:

1. If `<command>` is a core command (add, show, list, etc.), execute it
2. Otherwise, look for `tix-<command>` in PATH and execute it with `<args>`
3. If not found, show error

This is identical to Git's model where `git flow` executes `git-flow`.

### Filesystem Conventions

```
.tix/
├── TICKET_ID/
│   ├── title.md                 # Core: ticket title
│   ├── body.md                  # Core: ticket description
│   ├── s=b                      # Core: status (backlog/todo/doing/done)
│   ├── p=a                      # Core: priority (a/b/c/z)
│   ├── assigned_alice           # Extension: tix-team
│   ├── epic_EPIC_ID             # Extension: tix-project
│   ├── label_security           # Extension: tix-label
│   ├── label_backend            # Extension: tix-label
│   ├── due_2024-01-15          # Extension: tix-deadline
│   ├── workflow_in-review       # Extension: tix-workflow
│   ├── blocked_by_TICKET_ID     # Extension: tix-deps
│   └── sla_4h                   # Extension: tix-sla
```

### File Naming Conventions

| Pattern            | Meaning            | Example                   |
| ------------------ | ------------------ | ------------------------- |
| `assigned_<user>`  | Assigned to user   | `assigned_alice`          |
| `label_<name>`     | Has label          | `label_security`          |
| `epic_<id>`        | Belongs to epic    | `epic_01K3M3XXX`          |
| `due_<date>`       | Due date           | `due_2024-01-15`          |
| `blocked_by_<id>`  | Dependency         | `blocked_by_01K3M2XXX`    |
| `<custom>_<value>` | Extension-specific | `salesforce_case_5003XXX` |

### Core Commands (Built into tix)

See [doc.md](./doc.md) for the complete command reference. Core tix provides ticket management, project switching, syncing, history, and search functionality. Everything else is an extension.

### Extension Interface

Extensions must:

1. Accept input via command line args or stdin
2. Output to stdout (TSV format for lists)
3. Exit with 0 on success, non-zero on error
4. Respect `.git` boundaries (only modify tracked files)
5. Create atomic commits when changing state

## Common Extension Patterns

Extensions should **read and analyze** rather than duplicate core functionality. Use core commands for modifications.

### 1. Analytics & Reporting (tix-stats)

```bash
tix-stats burndown
# Reads ticket history and generates burndown chart

tix-stats velocity --weeks 4
# Analyzes completion rate over time

tix-stats user alice
# Shows alice's ticket metrics
```

### 2. Validation & Workflow (tix-workflow)

```bash
tix-workflow validate
# Checks all tickets against workflow rules
# Returns non-zero if violations found

tix mv 01K3M2 in-review
# Core command changes status
tix-workflow validate 01K3M2
# Extension validates the transition was legal
```

### 3. Dependency Visualization (tix-deps)

```bash
# First create dependencies using files
echo "01K3ABC" > .tix/01K3M2/blocks
echo "01K3XYZ" > .tix/01K3M2/blocked_by

# Then visualize
tix-deps graph | dot -Tpng > deps.png
# Reads all blocks/blocked_by files and generates graph

tix-deps check
# Warns about circular dependencies
```

## Composability Examples

```bash
# Validate workflow before push
tix-workflow validate || exit 1
tix push

# Generate weekly report
tix log --since "1 week ago" | tix-stats summary > report.md

# Check for blocked tickets
tix ls --status doing | tix-deps check --blocked

# Sync with external system
tix-jira sync --bidirectional
```

## Installation and Distribution

### For Users

```bash
# Install extension
curl -L https://github.com/user/tix-team/releases/latest/tix-team > ~/.local/bin/tix-team
chmod +x ~/.local/bin/tix-team

# Or via package manager (future)
tix-get install tix-team
```

### For Extension Authors

Requirements:

1. Binary named `tix-<command>`
2. Follows file conventions
3. Provides `--help` output
4. Optional: man page as `tix-<command>.1`

No registration, no central repository required. Can distribute via:

- GitHub releases
- Package managers (brew, apt, etc.)
- Direct download
- Company internal repositories

## Migration Path

### Phase 1: Core Stability

- Freeze core tix at current functionality
- Document file conventions
- Create `tix-example` reference implementation

### Phase 2: Extract Features

- Move any non-essential features to extensions
- Maintain backwards compatibility via default extensions

### Phase 3: Ecosystem Growth

- Community creates extensions
- Curated awesome-tix list
- Optional registry for discovery (not required for operation)

## Success Metrics

- Core tix remains under 1000 lines of code
- Extensions can be written in any language
- Zero API versioning issues
- Extension installation takes < 30 seconds
- Extensions compose without knowing about each other

## Risks and Mitigations

| Risk                   | Mitigation                               |
| ---------------------- | ---------------------------------------- |
| Convention conflicts   | Document common patterns early           |
| Filesystem performance | Extensions can maintain indices          |
| Discovery problem      | Curated list, optional registry          |
| Quality variance       | Reference implementations, testing guide |

## Example Implementation Timeline

- Week 1-2: Document and freeze conventions
- Week 3-4: Create reference extension (tix-team)
- Week 5-6: Create 2-3 more examples (tix-workflow, tix-label)
- Week 7-8: Documentation and ecosystem setup
- Week 9+: Community adoption

## Conclusion

By following Git's extension model and Unix philosophy, tix can remain simple while becoming infinitely extensible. The filesystem becomes the API, conventions become the schema, and programs become the plugins. This approach has proven successful for Git, enabling a massive ecosystem without complicating the core.
