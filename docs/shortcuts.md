# Tix Keyboard Shortcuts Reference

## Navigation & Selection

```
j/↓         Move down one ticket
k/↑         Move up one ticket
g           Go to first ticket
G           Go to last ticket
/           Search tickets
n           Next search result
N           Previous search result
<number>g   Go to ticket number (e.g., 5g goes to 5th ticket)
Tab         Next field/section
Shift+Tab   Previous field/section
```

## Viewing & Display

```
Enter       Show ticket details
Space       Quick preview (popup)
v           Toggle view mode (list/board/timeline)
l           Toggle detailed/compact list
s           Sort menu (then: p=priority, s=status, d=date, t=title)
f           Filter menu (then: s=status, p=priority, u=user, l=label)
r           Refresh/reload
z           Zoom/focus current ticket (hide sidebar)
Esc         Exit detail view/cancel operation
```

## Creating & Editing

```
c           Create new ticket (opens editor)
e           Edit current ticket (opens editor)
a           Amend ticket properties (inline)
t           Edit title only
b           Edit body only
p           Cycle priority (Z→C→B→A→Z)
u           Assign user (opens selector)
@           Assign to self (@me)
d           Set due date
```

## Workflow & Status

```
m           Move ticket (then: t=todo, w=doing, d=done, b=backlog)
→/l         Move to next status
←/h         Move to previous status
1           Move to backlog
2           Move to todo
3           Move to doing
4           Move to done
x           Mark as done (quick complete)
X           Archive ticket
```

## Project Management

```
P           Projects menu (list all projects)
[           Previous project
]           Next project
\           Switch to last project (toggle)
Ctrl+1-9    Switch to project by number
```

## History & Version Control

```
H           Show history/log for current ticket
L           Show project log
B           Blame view (who changed what)
u           Undo last operation
Ctrl+r      Redo
D           Diff view (local vs remote)
```

## Sync & Collaboration

```
S           Sync (pull + push)
Ctrl+p      Pull changes
Ctrl+s      Push changes
Ctrl+d      Show diff before sync
```

## Copy & Duplicate

```
y           Yank/copy ticket ID
Y           Yank/copy full ticket
p           Paste/duplicate ticket
Ctrl+c      Copy selection
Ctrl+v      Paste
```

## Delete & Archive

```
dd          Delete ticket (with confirmation)
da          Archive ticket
Ctrl+z      Undo delete
```

## Search & Filter

```
/text       Search in all tickets
:status     Filter by status (:todo, :doing, :done)
:priority   Filter by priority (:a, :b, :c, :z)
:@user      Filter by user
:label      Filter by label
:!          Clear all filters
*           Search for similar tickets
#           Search by ticket ID
```

## Command Mode

```
:           Enter command mode
:q          Quit
:w          Save/commit changes
:wq         Save and quit
:e <id>     Edit specific ticket
:new        Create new ticket
:mv <id> <status>   Move ticket
:config     Open configuration
:help       Show help
!<cmd>      Execute shell command
```

## Quick Actions

```
.           Repeat last action
,           Command palette (fuzzy finder)
?           Help/shortcuts reference
Ctrl+j      Quick jump to ticket (fuzzy search)
Ctrl+k      Command palette
Ctrl+o      Open in browser (if remote configured)
Ctrl+l      Clear/redraw screen
```

## Multi-Select Mode

```
V           Enter visual/multi-select mode
Space       Toggle selection in visual mode
A           Select all
Ctrl+a      Select all visible
I           Invert selection
M           Move selected tickets
D           Delete selected tickets
P           Change priority for selected
U           Assign user to selected
```

## Board View Specific

```
h/←         Move to previous column
l/→         Move to next column
j/↓         Move down in column
k/↑         Move up in column
Enter       Select ticket
Space       Move ticket to this column
Tab         Next column
Shift+Tab   Previous column
```

## Timeline View Specific

```
h/←         Scroll left (earlier)
l/→         Scroll right (later)
-           Zoom out (show more time)
+/=         Zoom in (show less time)
t           Today (center on today)
w           Week view
m           Month view
q           Quarter view
```

## Tags & Milestones

```
T           Tag current state
Ctrl+t      List all tags
Alt+t       Jump to tag
```

## Global Shortcuts

```
Ctrl+h      Show/hide help sidebar
Ctrl+b      Show/hide sidebar
Ctrl+f      Full screen
Ctrl+n      New ticket (from anywhere)
Ctrl+/      Show keyboard shortcuts
Ctrl+q      Quit application
F1          Context-sensitive help
F5          Refresh
F11         Toggle fullscreen
```

## Vim Mode (Optional)

When vim mode is enabled, normal vim motions work:

```
hjkl        Movement
w/b         Word forward/backward
0/$         Beginning/end of line
gg/G        First/last ticket
i           Insert mode (editing)
v           Visual mode (selection)
:           Command mode
/           Search mode
```

## Customization

Most shortcuts can be customized via:

```
tix config keybindings.<action> <key>
```

Example:

```
tix config keybindings.create "ctrl+n"
tix config keybindings.move-done "x"
```

## Platform-Specific

### macOS

- `Cmd` instead of `Ctrl` for most shortcuts
- `Cmd+,` for preferences

### Windows/Linux

- `Ctrl` as shown
- `F10` to activate menu bar

## Notes

- Shortcuts are inspired by vim, GitHub, and common terminal applications
- Modal interface: different shortcuts in different contexts
- Case-sensitive: `p` vs `P` do different things
- Combinations: `dd` requires pressing `d` twice quickly
- Command mode (`:`) accepts full tix commands
- Most destructive operations require confirmation

