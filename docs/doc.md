# Tix Command Reference

## Initialization and Setup

```bash
tix init                       # Initialize new workspace
                               # Initialized tix workspace in /path/to/workspace

tix clone https://github.com/team/tickets
                               # Cloning into 'tickets'...
                               # Done. 47 tickets cloned.

tix remote add origin https://github.com/team/tickets
                               # Added remote: origin

tix remote -v                  # List remotes
                               # origin  https://github.com/team/tickets (push)
                               # origin  https://github.com/team/tickets (pull)

tix remote remove origin       # Remove remote
                               # Removed remote: origin

tix config user.name "Alice Smith"          # Set user name
tix config user.email "alice@example.com"   # Set email
tix config default.priority Z               # Set default priority
tix config default.status todo              # Set default status

tix config user.name                        # Get specific value
                                            # Alice Smith

tix config --list                           # List all config
                                            # user.name=Alice Smith
                                            # user.email=alice@example.com
                                            # default.priority=Z
                                            # default.status=todo

tix config --unset default.priority         # Remove a config value
                                            # Removed config: default.priority
```

## Project Management

```bash
tix projects                   # List all local projects
                               # * backend (current)
                               #   frontend
                               #   mobile

tix projects -a                # List all projects including remote
                               # * backend
                               #   frontend
                               #   mobile
                               #   remotes/origin/backend
                               #   remotes/origin/frontend

tix switch frontend            # Switch to different project
                               # Switched to project: frontend

tix switch -c mobile           # Create and switch to new project
                               # Created project: mobile
                               # Switched to project: mobile
```

## Creating Tickets

```bash
tix add                         # Opens editor for ticket creation
                                # ---
                                # Title: Fix login bug
                                # Priority: Z
                                # User:
                                # ---
                                # Detailed description here...

tix add -t "Fix login bug" -b "Details..." -p A -u alice
                                # Create ticket with flags:
                                # -t: title
                                # -b: body
                                # -p: priority (A|B|C|Z, default: Z)
                                # -u: user (assignee)
                                # Always creates with status=todo
```

## Viewing Tickets

```bash
tix ls                         # List all active tickets
                               # 01K3XXX... Fix login bug
                               # 01K3YYY... Add user profile
                               # 01K3ZZZ... Refactor auth

tix ls -l                      # Detailed view
                               # 01K3XXX  todo  A  Fix login bug        @alice
                               # 01K3YYY  doing C  Add user profile     @bob
                               # 01K3ZZZ  done  B  Refactor auth        @carol

tix ls --status todo           # Filter by status
                               # 01K3XXX... Fix login bug
                               # 01K3YYY... Add user profile

tix ls --priority A            # Filter by priority
                               # 01K3XXX... Fix login bug

tix ls --user @me              # Filter by assignee
                               # 01K3XXX... Fix login bug

tix ls --status todo --priority A  # Combined filters
                               # 01K3XXX... Fix login bug

tix ls --status todo --no-user  # Unassigned todos
                               # 01K3YYY... Add user profile

tix show 01K3XXX               # Shows everything about the ticket
                               # ID: 01K3XXX
                               # Title: Fix login bug
                               # Status: doing
                               # Priority: A
                               # User: alice
                               # Body: [full body content]
                               # History: [recent changes]

tix show 01K3XXX:body          # Shows just the body content
tix show 01K3XXX:status        # Shows just: doing
tix show 01K3XXX:title         # Shows just: Fix login bug
tix show 01K3XXX:priority      # Shows just: A
tix show 01K3XXX:user          # Shows just: alice

tix status                     # Project overview
                               # Project: backend
                               #
                               # Todo (5):
                               #   01K3XXX... Fix login bug (priority: A)
                               #   01K3YYY... Add user profile (priority: C)
                               #
                               # Doing (2):
                               #   01K3ZZZ... Refactor auth (3 days)
                               #
                               # Done (last 24h):
                               #   01K3AAA... Update deps
```

## Modifying Tickets

```bash
tix amend 01K3XXX              # Opens editor to modify all properties

tix amend 01K3XXX -t "New title"  # Change title
                               # Ticket 01K3XXX title updated

tix amend 01K3XXX -b "New body"   # Change body/description
                               # Ticket 01K3XXX body updated

tix amend 01K3XXX -p A         # Change priority
                               # 01K3XXX: priority C → A

tix amend 01K3XXX -u alice     # Assign to user
                               # 01K3XXX: assigned to alice

tix amend 01K3XXX -u @me       # Assign to self
                               # 01K3XXX: assigned to you

tix amend 01K3XXX -u ""        # Unassign
                               # 01K3XXX: unassigned

tix mv 01K3XXX doing           # Move through workflow (ONLY changes status)
                               # 01K3XXX: status todo → doing

tix mv 01K3XXX done            # Complete ticket
                               # 01K3XXX: status doing → done

tix copy 01K3XXX               # Duplicate ticket in current project
                               # Created 01K3YYY as copy of 01K3XXX

tix copy 01K3XXX --from frontend  # Copy ticket from another project
                               # Copied 01K3XXX from frontend to backend

tix undo                       # Undo the last tix operation
                               # Reverted: 01K3XXX status doing → todo
```

## Searching

```bash
tix grep "login"               # Search all tickets
                               # 01K3XXX/body.md: Login fails when...
                               # 01K3AAA/title.md: improve-login-performance

tix grep -i "TODO"             # Case-insensitive search
                               # 01K3XXX/body.md: TODO: Add validation
                               # 01K3YYY/body.md: todo: refactor this
```

## History

```bash
tix log                         # Current project history
                               # 2024-01-15 10:00  01K3XXX New: Fix login bug
                               # 2024-01-15 11:00  01K3XXX Status: todo → doing
                               # 2024-01-15 14:00  01K3YYY Priority: C → A
                               # 2024-01-16 09:00  01K3ZZZ Status: doing → done

tix log --all                  # ALL projects history
                               # [backend]  2024-01-15 10:00  01K3XXX New: Fix login bug
                               # [frontend] 2024-01-15 10:30  01K3AAA New: Add navbar
                               # [backend]  2024-01-15 11:00  01K3XXX Status: todo → doing
                               # [mobile]   2024-01-15 11:30  01K3BBB New: Push notifications

tix log --oneline              # Compact view
                               # 01K3XXX  Fix login bug
                               # 01K3YYY  Add user profile
                               # 01K3ZZZ  Refactor auth

tix log --since="2 days"       # Recent history
                               # 2024-01-15 14:00  01K3YYY Priority: C → A
                               # 2024-01-16 09:00  01K3ZZZ Status: doing → done

tix log --assigned=alice       # Filter by user
                               # 2024-01-15 10:00  01K3XXX New: Fix login bug
                               # 2024-01-15 11:00  01K3XXX Status: todo → doing
                               # 2024-01-15 16:00  01K3XXX User: → alice

tix log --follow 01K3XXX       # Single ticket history
                               # 2024-01-15 10:00  New: Fix login bug
                               # 2024-01-15 11:00  Status: todo → doing
                               # 2024-01-15 14:00  Priority: C → A
                               # 2024-01-15 16:00  User: → alice

tix blame 01K3XXX              # Who set each field
                               # title:    "Fix login bug"  (alice, 2024-01-15 10:00)
                               # status:   doing            (bob,   2024-01-15 11:00)
                               # priority: A                (alice, 2024-01-15 14:00)
                               # body:     "Login fails..." (carol, 2024-01-15 16:00)
                               # user:     alice            (dave,  2024-01-15 17:00)

tix summary                    # Summary of tickets by user
                               # alice (12):
                               #   01K3XXX New: Fix login bug
                               #   01K3YYY Status: todo → doing
                               #   ...
                               # bob (8):
                               #   01K3ZZZ New: Add feature
                               #   ...

tix summary --count            # Just counts by user
                               # 12  alice
                               # 8   bob
                               # 5   carol
```

## Syncing

```bash
tix diff                        # Local vs remote changes
                               # Local changes (not pushed):
                               #   01K3XXX: status todo → doing
                               #   01K3YYY: priority C → A
                               #   01K3ZZZ: created "New feature"
                               #
                               # Remote changes (not pulled):
                               #   01K3AAA: status doing → done
                               #
                               # Use 'tix push' to upload your changes
                               # Use 'tix pull' to get remote changes

tix pull                        # Get and apply remote changes
                               # Pulling from origin...
                               # 1 change applied
                               # 01K3AAA: status doing → done

tix push                        # Send local changes to remote
                               # Pushing to origin...
                               # 3 changes pushed successfully
```

## Archiving

```bash
tix rm 01K3XXX                 # Delete ticket from disk
                               # Ticket 01K3XXX deleted (history preserved)

tix rm --archive 01K3XXX       # Archive ticket
                               # Ticket 01K3XXX archived to 01K3XXX.md
```

## Milestones

```bash
tix tag v1.0-release           # Mark a milestone
                               # Tagged current state as: v1.0-release

tix tag -a v1.0-release -m "Completed 15 tickets"
                               # Annotated tag with message

tix tag -l                     # List all tags
                               # v0.9-beta
                               # v1.0-release
                               # week-23-review
                               # week-24-review
                               # week-25-review

tix log --since-tag v0.9-beta --until-tag v1.0-release
                               # Show work completed between milestones:
                               # 01K3XXX: New: Fix login
                               # 01K3XXX: Status: todo → done
                               # 01K3YYY: Priority: C → A
                               # ...

tix describe                   # Shows position relative to latest tag
                               # v1.0-release-47
                               # (47 commits/changes since v1.0-release)

tix describe --long            # More detailed output
                               # v1.0-release-47-01K3XXX
                               # (47 changes since v1.0, latest: 01K3XXX)

tix tag -l | grep release | wc -l
                               # Count releases: 3

# Per-project tags (if teams work separately)
tix switch backend
tix tag backend-v2-shipped     # Backend team's milestone

tix switch frontend
tix tag frontend-redesign-done # Frontend team's milestone
```
