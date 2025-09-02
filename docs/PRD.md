# PRD: Git-like API for Tix

## Executive Summary

Tix is a git-native project management tool designed to work with multiple interfaces (CLI, AI, etc).

Tix leverages git's powerful version control system as its foundation, with each project as a git branch. This architecture provides robust distributed version control, built-in synchronization, and familiar developer workflows while maintaining the simplicity of tickets as filesystem entities.

## Core Architecture

### Projects as Branches

Each project exists as a separate git branch, providing natural isolation and history tracking:

```
main branch (minimal/empty)
├── backend branch       # Backend project with its tickets
├── frontend branch      # Frontend project with its tickets
└── mobile branch        # Mobile project with its tickets
```

### Tix Structure

Tickets are directories with a ULID (Universally Unique Lexicographically Sortable Identifier).

ULIDs provide:

- **Time-ordered** - tickets naturally sort by creation time
- **No conflicts** - safe to create tickets in different branches
- **Direct access** - `$ulid` for immediate ticket access

Within each project branch:

```
backend branch/
├── .tix/
│   ├── 01HQXW5P7R8ZYFG9K3NMVBCXSD/    # Ticket directory
│   ├── 01HQXW6QA2TMDFE4H8RNJYWKPB/    # Another ticket
│   └── 01JR1234567890ABCDEFGHIJKL/    # Another ticket
```

```
backend branch/
├── .tix/
│   ├── 01HQXW5P7R8ZYFG9K3NMVBCXSD.../
│   │   ├── s=b             # Status: b=backlog, t=todo, w=doing, d=done
│   │   ├── p=z             # Priority: a=high, b=medium, c=low, z=default
│   │   ├── title.md        # Title of the ticket
│   │   └── body.md         # Description/content of the ticket
│   └── 01JR1234567890ABCDEFGHIJKL.../
│       └── ...
```

Priority: a (highest), b (medium), c (low), z (default)
Status: b (backlog, default), t (todo), w (doing), d (done)

**Important constraint**: Each ticket must have exactly one of each: `s=*`, `p=*`. Multiple values are not allowed (e.g., a ticket cannot have both `s=t` and `s=w`).

This design is infinitely extensible:

- Need labels? Add `label_frontend` or `label_backend`
- Need due dates? Add `due_2025-02-15`
- Need time tracking? Add `estimate_3h`

### Filesystem as Database

The filesystem structure enables:

- **Instant queries**: `find . -name "s=t"` finds all todo tickets
- **Atomic updates**: Each attribute is a separate file
- **No conflicts**: Different files = no merge conflicts
- **Extensibility**: Add new attributes without schema changes

### Version Control

```bash
# Every tix operation translates to git operations
tix pull                    → git pull origin <current-branch>
tix add -t "Fix bug"        → Creates directory + files + git commit
tix mv 01K454XJ012V30KBCG4QKPKDRR doing → Renames file + git commit
tix push                    → git push origin <current-branch>
```

**Every mutation is a git commit**, providing a complete history of changes. This means:

- `tix add` → creates ticket + commits immediately
- `tix mv` → changes state + commits immediately
- `tix amend` → edits content + commits immediately
- `tix rm` → removes/archives + commits immediately

No staging area, no uncommitted changes - every operation is atomic and immediately persisted.

### Commit Message Format

Every tix operation generates a structured commit message using the full ULID:

```bash
# Creating tickets
tix add -t "Fix login bug"
→ git commit -m "01HQXW5P7R8ZYFG9K3NMVBCXSD New: Fix login bug"

# Changing status (workflow)
tix mv 01HQXW5P7R8ZYFG9K3NMVBCXSD doing
→ git commit -m "01HQXW5P7R8ZYFG9K3NMVBCXSD Status: backlog → doing"

tix mv 01HQXW5P7R8ZYFG9K3NMVBCXSD done
→ git commit -m "01HQXW5P7R8ZYFG9K3NMVBCXSD Status: doing → done"

# Updating properties
tix amend 01HQXW5P7R8ZYFG9K3NMVBCXSD -p a
→ git commit -m "01HQXW5P7R8ZYFG9K3NMVBCXSD Priority: z → a"

tix amend 01HQXW5P7R8ZYFG9K3NMVBCXSD -t "Fix critical login bug"
→ git commit -m "01HQXW5P7R8ZYFG9K3NMVBCXSD Title: Fix login bug → Fix critical login bug"

tix amend 01HQXW5P7R8ZYFG9K3NMVBCXSD -b "Updated description"
→ git commit -m "01HQXW5P7R8ZYFG9K3NMVBCXSD Body: (updated)"

# Multiple changes in one amend
tix amend 01HQXW5P7R8ZYFG9K3NMVBCXSD -p a -t "Updated title"
→ git commit -m "01HQXW5P7R8ZYFG9K3NMVBCXSD Priority: z → a, Title: Fix login bug → Updated title"

# Removing/archiving (not implemented)
# tix rm 01HQXW5P7R8ZYFG9K3NMVBCXSD
# → git commit -m "01HQXW5P7R8ZYFG9K3NMVBCXSD Deleted"
```

This consistent format makes history readable and searchable:

- Always starts with full ticket ULID for easy filtering
- Field changes show transitions clearly (old → new)
- Body changes shown as "(updated)" since content is too long

## Conflict Resolution

Conflicts are rare due to ticket structure:

### Why Conflicts Are Rare

1. **Different tickets**: Most changes are to different tickets (no conflict)
2. **Different fields**: Changes to different sentinel files (no conflict)
3. **No uncommitted state**: All changes are immediate (no working directory)

### When Conflicts Occur

```bash
# Both users changed same field of same ticket
Local:  .tix/01K454XJ012V30KBCG4QKPKDRR/s=w
Remote: .tix/01K454XJ012V30KBCG4QKPKDRR/s=d

# Resolution (simple choice):
Conflict in 01K454XJ012V30KBCG4QKPKDRR status: [l]ocal doing or [r]emote done?
```

## Initialization and Setup

### **init / clone**

```bash
git init                    → tix init
git clone <repo>            → tix clone <workspace>
```

### **remote**

```bash
git remote add origin <url> → tix remote add origin <url>
                              # Add remote repository
git remote -v               → tix remote -v
                              # List remotes with URLs
git remote remove origin    → tix remote remove origin
                              # Remove remote
```

### **config**

```bash
git config user.name "John"   → tix config user.name "John Doe"
git config user.email "j@e"    → tix config user.email "john@example.com"
git config default.priority z  → tix config default.priority z
git config default.status backlog → tix config default.status backlog

git config user.name           → tix config user.name
                                  # John Doe

git config --list              → tix config --list
                                  # user.name=John Doe
                                  # user.email=john@example.com
                                  # default.priority=z
                                  # default.status=backlog

git config --unset user.name   → tix config --unset default.priority
                                  # Removed config: default.priority
```

## Project Management

### **projects** (List projects)

```bash
git branch                 → tix projects
                              # List all local projects
                              # * backend (current)
                              #   frontend
                              #   mobile

git branch -a              → tix projects -a
                              # List all projects including remote
```

### **switch** (Change project context)

```bash
git switch <branch>        → tix switch <project>
                              # Switch to different project
git switch -c <branch>     → tix switch -c <project>
                              # Create and switch to new project
```

## Creating Tickets

### **add** (Create ticket)

```bash
git add <file>              → tix add
                              # Opens editor:
                              # ---
                              # Title: Fix login bug
                              # Priority: Z
                              # User:
                              # ---
                              # Detailed description here...

git commit -m "msg"         → tix add -t "title" -b "body" -p a -u alice
                              # -t: title
                              # -b: body
                              # -p: priority (a|b|c|z, default: z)
                              # -u: user (assignee, default: none)
                              # Always creates with status=todo
```

## Viewing Tickets

### **ls** (List tickets)

```bash
git ls-files               → tix ls
                              # List all active tickets
git ls-files -s            → tix ls -l
                              # Detailed view (status, priority, title, user)
                            → tix ls -la
                              # Include archived/done tickets

# Filtering
                            → tix ls --status todo
                              # Filter by status
                            → tix ls --priority a
                              # Filter by priority
                            → tix ls --user @me
                              # Filter by assignee

# Combined filters (AND logic)
                            → tix ls --status todo --priority a
                              # High priority todos
                            → tix ls --status doing --user @me
                              # My in-progress work
                            → tix ls --status todo --no-user
                              # Unassigned todos

# Output formats
                            → tix ls --oneline
                              # Just IDs and titles
                            → tix ls --json
                              # Machine readable
```

### **show**

```bash
git show <commit>          → tix show <ticket>
                              # Shows everything about the ticket:
                              # - ID, Title, Status, Priority, User
                              # - Full body content
                              # - Recent history/changes

git show HEAD:file         → tix show <ticket>:field
                              # Shows only specific field:
                            → tix show <ticket>:body     # Just body content
                            → tix show <ticket>:status   # Just status (e.g., "doing")
                            → tix show <ticket>:title    # Just title text
                            → tix show <ticket>:priority # Just priority (e.g., "a")
                            → tix show <ticket>:user     # Just assignee
```

### **status**

```bash
git status                  → tix status
                              # Project: backend
                              #
                              # Todo (5):
                              #   01K454XJ012V30KBCG4QKPKDRR... Fix login bug (priority: a)
                              #   01HQXW5P7R8ZYFG9K3NMVBCXSD... Add user profile (priority: c)
                              #   ...
                              #
                              # Doing (2):
                              #   01K3ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ... Refactor auth (3 days)
                              #   ...
                              #
                              # Done (last 24h):
                              #   01K3AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA... Update deps
                              #   ...
```

## Modifying Tickets

### **amend** (Edit ticket content)

```bash
git commit --amend         → tix amend <ticket>
                              # Opens editor to modify all properties
git commit --amend -m      → tix amend <ticket> -t "new title" -b "new body" -p b -u bob
                              # Can update any/all properties:
                              # -t: title
                              # -b: body
                              # -p: priority (a|b|c|z)
                              # -u: user (assignee)
```

### **mv** (Move ticket through workflow)

```bash
git mv old.txt new.txt     → tix mv <ticket> todo|doing|done
                              # Move through workflow states
                              # This is the ONLY way to change status
```

### **copy** (Duplicate ticket)

```bash
git cherry-pick <commit>   → tix copy <ticket>
                              # Duplicate ticket in current project

                            → tix copy <ticket> --from <project>
                              # Copy ticket from another project
```

### **undo** (Undo last operation)

```bash
git reset HEAD~1           → tix undo
                              # Undo the last tix operation
                              # Reverts the last git commit made by tix
```

## Searching

### **grep** (Search)

```bash
git grep "pattern"         → tix grep "pattern"
git grep -i "login"        → tix grep -i "login"
```

## History

### **log**

```bash
git log                     → tix log
                              # Show current project's history
git log --all               → tix log --all
                              # Show ALL projects' history
git log --oneline           → tix log --oneline
git log --since="2 days"    → tix log --since="2 days"
git log --author=john       → tix log --assigned=john
git log --follow <file>     → tix log --follow <ticket>
                              # Show full history of specific ticket
```

### **blame** (Who created/modified)

```bash
git blame <file>           → tix blame <ticket>
                              # Show who modified ticket and when
```

### **summary** (Work summary)

```bash
git shortlog               → tix summary
                              # Summary of tickets by user
                              # alice (12):
                              #   01K3XXXXXXXXXXXXXXXXXXXXX New: Fix login bug
                              #   01K3YYYYYYYYYYYYYYYYYYY Status: todo → doing
                              #   ...
                              # bob (8):
                              #   01K3ZZZZZZZZZZZZZZZZZZZ New: Add feature
                              #   ...

git shortlog -sn           → tix summary --count
                              # Just counts by user
                              # 12  alice
                              # 8   bob
                              # 5   carol
```

## Syncing

### **diff**

```bash
git diff                    → tix diff
                              # Local changes (not pushed):
                              #   01K3XXXXXXXXXXXXXXXXXXXXX: status todo → doing
                              #   01K454XJ012V30KBCG4QKPKDRR: priority c → a
                              #   01K3ZZZZZZZZZZZZZZZZZZZ: created "New feature"
                              #
                              # Remote changes (not pulled):
                              #   01K3AAAAAAAAAAAAAAAAAAA: status doing → done
                              #
                              # Use 'tix push' to upload your changes
                              # Use 'tix pull' to get remote changes
```

### **pull / push**

```bash
git pull                    → tix pull
                              # Get and apply remote changes
git push                    → tix push
                              # Send local changes to remote
```

## Archiving

### **rm** (Remove/archive)

```bash
git rm <file>              → tix rm <ticket>
                              # Delete ticket from disk (history remains)
git rm --cached            → tix rm --archive <ticket>
                              # Archive ticket (consolidate to .md file)
```

## Milestones

### **tag** (Milestone markers)

```bash
git tag v1.0               → tix tag v1.0-release
                              # Mark a milestone
git tag -a v1.0 -m "msg"   → tix tag -a v1.0-release -m "Completed 15 tickets"
                              # Annotated tag with message
git tag -l                 → tix tag -l
                              # List all tags:
                              # v0.9-beta
                              # v1.0-release
                              # week-23-review

# Query between tags
                            → tix log --since-tag v0.9-beta --until-tag v1.0-release
                              # Show work completed between milestones

# Per-project tags (if needed)
                            → tix tag backend-v2-shipped
                              # Tag just backend's state
```

### **describe** (Position relative to tags)

```bash
git describe               → tix describe
                              # Shows position relative to latest tag
                              # v1.0-release-47
                              # (47 commits/changes since v1.0-release)

git describe --long        → tix describe --long
                              # More detailed output
                              # v1.0-release-47-01K3XXXXXXXXXXXXXXXXXXXXX
                              # (47 changes since v1.0, latest: 01K3XXXXXXXXXXXXXXXXXXXXX)
```

## Key Insights

1. **`tix add`** - Creates new tickets (default status=backlog), can set title, body, priority, status
2. **`tix amend`** - Edits ticket properties (title, body, priority, user) - but NOT status
3. **`tix mv`** - Changes ticket status ONLY (todo → doing → done) - the workflow transition
4. **`tix status`** - Shows semantic ticket info, not just file changes
5. **`tix ls`** - Provides powerful filtering - find exactly what you need
6. **Editor integration** - Like `git commit`, opening editor for rich ticket creation

The separation is clean:

- **Creation**: `tix add` (always creates as todo)
- **Content/Properties**: `tix amend` (what the ticket IS)
- **Workflow**: `tix mv` (WHERE the ticket is in the process)

The best part: developers already know these commands! The mental model transfers perfectly.

## Important Design Decisions

### No Work-In-Progress State

Unlike git with its staging area and uncommitted changes, tix has **no WIP state**:

- No `git stash` equivalent - tickets are always committed
- No staging area - all operations are immediate
- No uncommitted tickets - everything is persisted instantly

This is intentional: tickets are lightweight and should always be saved.
