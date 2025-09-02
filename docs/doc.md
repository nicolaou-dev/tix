# Tix C Library API Reference

Tix is a git-native project management library that stores tickets as filesystem directories. This document describes the C API for the tix library.

## Installation

Include `tix.h` and link against `libtix.a`:

```c
#include "tix.h"

// Compile with: gcc -ltix your_program.c
```

## Core Concepts

### Project Structure
A typical project using tix keeps tickets separate from code:

```
my-app/                    # Your actual project code
├── src/
├── package.json
├── README.md
└── .tix/                  # Ticket data (separate git repository)
    ├── .git/              # Git repository for ticket history
    ├── 01K3XXX.../
    │   ├── s=t
    │   ├── p=a  
    │   ├── title.md
    │   └── body.md
    └── 01K3YYY.../
```

### Tickets
Tickets are stored as directories under `.tix/` with ULID identifiers. Each ticket contains:
- `title.md` - Ticket title
- `body.md` - Ticket description  
- `s=X` - Status file where X is status character
- `p=X` - Priority file where X is priority character

### Status Values
- `'b'` - Backlog  
- `'t'` - Todo
- `'w'` - Doing (Working)
- `'d'` - Done

### Priority Values  
- `'a'` - High priority
- `'b'` - Medium priority
- `'c'` - Low priority
- `'z'` - Default/lowest priority

### Projects
Projects are implemented as git branches. Each branch contains its own set of tickets.

## API Reference

### Error Codes

All functions return `0` on success or negative error codes on failure:

```c
// General errors
#define TIX_OUT_OF_MEMORY                    -1
#define TIX_NOT_A_REPOSITORY                 -2
#define TIX_COMMAND_FAILED                   -3
#define TIX_FILE_SYSTEM_ERROR                -4
#define TIX_INVALID_TICKET_ID                -5
#define TIX_TICKET_NOT_FOUND                 -6

// Init-specific errors  
#define TIX_INIT_WORKSPACE_CREATION_FAILED   -10
#define TIX_INIT_ACCESS_DENIED               -11

// Config-specific errors
#define TIX_CONFIG_INVALID_KEY               -20

// Remote-specific errors
#define TIX_REMOTE_ALREADY_EXISTS            -30
#define TIX_REMOTE_INVALID_NAME              -31

// Switch-specific errors
#define TIX_SWITCH_PROJECT_NOT_FOUND         -40
#define TIX_SWITCH_PROJECT_ALREADY_EXISTS    -41
#define TIX_SWITCH_ALREADY_ON_PROJECT        -42

// Add-specific errors
#define TIX_INVALID_PRIORITY                 -50
#define TIX_INVALID_TITLE                    -51

// Move-specific errors  
#define TIX_INVALID_STATUS                   -60
```

### Workspace Management

#### Initialize Workspace

```c
int tix_init(void);
```

Creates a new tix workspace in the current directory.

**Returns:**
- `0` = initialized
- `1` = reinitialized  
- `-10` = workspace creation failed
- `-11` = access denied

**Example:**
```c
int result = tix_init();
if (result == 0) {
    printf("Workspace initialized\n");
} else if (result == 1) {
    printf("Workspace reinitialized\n"); 
} else {
    printf("Error: %d\n", result);
}
```

#### Configuration

```c
int tix_config_set(const char *key, const char *value);
int tix_config_get(const char *key, char **value_out);
void tix_config_get_free(char *str);
```

Set and get configuration values stored in git config.

**Parameters:**
- `key` - Configuration key (e.g., "user.name", "user.email")
- `value` - Value to set
- `value_out` - Output pointer for retrieved value (must be freed with `tix_config_get_free`)

**Returns:**
- `0` = success
- `-20` = invalid key

**Example:**
```c
// Set configuration
tix_config_set("user.name", "Alice Smith");
tix_config_set("user.email", "alice@example.com");

// Get configuration  
char *name;
if (tix_config_get("user.name", &name) == 0) {
    printf("User: %s\n", name);
    tix_config_get_free(name);
}
```

### Ticket Management

#### Create Tickets

```c
int tix_add(const char *title, const char *body, 
            unsigned char priority, unsigned char status, 
            char **id_out);
void tix_add_free(char *str);
```

Creates a new ticket with the specified properties.

**Parameters:**
- `title` - Ticket title (required, non-empty)
- `body` - Ticket description (can be empty)
- `priority` - Priority character: `'a'`, `'b'`, `'c'`, `'z'`, or `0` for default (`'z'`)
- `status` - Status character: `'b'`, `'t'`, `'w'`, `'d'`, or `0` for default (`'b'`)
- `id_out` - Output pointer for generated ticket ID (must be freed with `tix_add_free`)

**Returns:**
- `0` = success
- `-50` = invalid priority
- `-51` = invalid title  
- `-60` = invalid status

**Example:**
```c
char *ticket_id;
int result = tix_add("Fix login bug", 
                     "Users cannot log in after password reset", 
                     'a',  // High priority
                     't',  // Todo status
                     &ticket_id);

if (result == 0) {
    printf("Created ticket: %s\n", ticket_id);
    tix_add_free(ticket_id);
} else {
    printf("Error creating ticket: %d\n", result);
}
```

#### List Tickets

```c
typedef struct CTicket {
    const char *id;
    const char *title; 
    const char *body;
    unsigned char priority;
    unsigned char status;
} CTicket;

int tix_list(const char *statuses, const char *priorities, 
             CTicket **output, size_t *count);
void tix_list_free(CTicket *tickets, size_t count);
```

Lists tickets with optional filtering by status and priority.

**Parameters:**
- `statuses` - String of status characters to filter (e.g., "bt" for backlog and todo), or `NULL` for all
- `priorities` - String of priority characters to filter (e.g., "ab" for high and medium), or `NULL` for all  
- `output` - Output pointer for array of CTicket structs (must be freed with `tix_list_free`)
- `count` - Output pointer for number of tickets

**Returns:**
- `0` = success
- `-60` = invalid status
- `-50` = invalid priority
- `-1` = out of memory

**Example:**
```c
// List all todo and doing tickets with high priority
CTicket *tickets;
size_t count;
int result = tix_list("tw", "a", &tickets, &count);

if (result == 0) {
    printf("Found %zu tickets:\n", count);
    for (size_t i = 0; i < count; i++) {
        printf("  %s: %s (priority: %c, status: %c)\n", 
               tickets[i].id, tickets[i].title,
               tickets[i].priority, tickets[i].status);
    }
    tix_list_free(tickets, count);
}
```

#### Show Ticket Details

```c
int tix_show(const char *ticket_id, CTicket **output);
void tix_show_free(CTicket *ticket);

int tix_show_title(const char *ticket_id, char **output);
void tix_show_title_free(char *str);

int tix_show_body(const char *ticket_id, char **output);
void tix_show_body_free(char *str);

int tix_show_status(const char *ticket_id);
int tix_show_priority(const char *ticket_id);
```

Show complete ticket details or individual fields.

**Parameters:**
- `ticket_id` - ULID of the ticket
- `output` - Output pointer (varies by function)

**Returns:**
- `0` = success (or status/priority character for `tix_show_status/priority`)
- `-5` = invalid ticket ID
- `-6` = ticket not found
- `-1` = out of memory

**Example:**
```c
// Show full ticket
CTicket *ticket;
if (tix_show("01K3PFG1J9KYSTX36BJQ0VFQC0", &ticket) == 0) {
    printf("Title: %s\n", ticket->title);
    printf("Body: %s\n", ticket->body);
    printf("Status: %c\n", ticket->status);
    printf("Priority: %c\n", ticket->priority);
    tix_show_free(ticket);
}

// Show just the title
char *title;
if (tix_show_title("01K3PFG1J9KYSTX36BJQ0VFQC0", &title) == 0) {
    printf("Title: %s\n", title);
    tix_show_title_free(title);
}

// Show just status (returns character directly)
int status = tix_show_status("01K3PFG1J9KYSTX36BJQ0VFQC0");
if (status >= 0) {
    printf("Status: %c\n", (char)status);
}
```

#### Move Tickets Through Workflow

```c
int tix_move(const char *ticket_id, unsigned char status);
```

Changes a ticket's status by moving it through the workflow.

**Parameters:**
- `ticket_id` - ULID of the ticket
- `status` - New status character: `'b'`=backlog, `'t'`=todo, `'w'`=doing, `'d'`=done

**Returns:**
- `0` = success
- `-5` = invalid ticket ID
- `-60` = invalid status
- `-3` = command failed

**Example:**
```c
// Move ticket to doing status
int result = tix_move("01K3PFG1J9KYSTX36BJQ0VFQC0", 'w');
if (result == 0) {
    printf("Ticket moved to doing\n");
} else {
    printf("Error moving ticket: %d\n", result);
}
```

#### Modify Tickets

```c
int tix_amend(const char *ticket_id, const char *title, 
              const char *body, unsigned char priority);
```

Modifies ticket properties. Pass empty string to leave a field unchanged, or `0` for priority to leave unchanged.

**Parameters:**
- `ticket_id` - ULID of the ticket
- `title` - New title (empty string to leave unchanged)
- `body` - New body (empty string to leave unchanged) 
- `priority` - New priority (`0` to leave unchanged)

**Returns:**
- `0` = success
- `-5` = invalid ticket ID
- `-50` = invalid priority

**Example:**
```c
// Change only the title
tix_amend("01K3PFG1J9KYSTX36BJQ0VFQC0", "Updated title", "", 0);

// Change priority only
tix_amend("01K3PFG1J9KYSTX36BJQ0VFQC0", "", "", 'a');

// Change multiple properties
tix_amend("01K3PFG1J9KYSTX36BJQ0VFQC0", 
          "New title", "New description", 'b');
```

### Project Management

#### Switch Projects

```c
int tix_switch_project(const char *project, int create);
```

Switches to a different project (git branch), optionally creating it.

**Parameters:**
- `project` - Project/branch name
- `create` - Non-zero to create project if it doesn't exist

**Returns:**
- `0` = switched to existing project
- `1` = created new project
- `-40` = project not found
- `-41` = project already exists (when trying to create)
- `-42` = already on that project

**Example:**
```c
// Switch to existing project
int result = tix_switch_project("backend", 0);
if (result == 0) {
    printf("Switched to backend project\n");
} else if (result == -40) {
    printf("Backend project does not exist\n");
}

// Create and switch to new project
result = tix_switch_project("mobile", 1);
if (result == 1) {
    printf("Created and switched to mobile project\n");
}
```

#### List Projects

```c
int tix_projects(char ***output, size_t *count);
void tix_projects_free(char **output, size_t count);
```

Lists all local projects (git branches). The first element is always the current project.

**Parameters:**
- `output` - Output pointer for array of project names (must be freed with `tix_projects_free`)
- `count` - Output pointer for number of projects

**Returns:**
- `0` = success
- `-2` = not a repository
- `-3` = command failed

**Example:**
```c
char **projects;
size_t count;
int result = tix_projects(&projects, &count);

if (result == 0) {
    printf("Projects:\n");
    for (size_t i = 0; i < count; i++) {
        printf("  %s%s\n", projects[i], (i == 0) ? " (current)" : "");
    }
    tix_projects_free(projects, count);
}
```

### Remote Management

#### List Remotes

```c
int tix_remote(int verbose, char **output);
void tix_remote_free(char *str);
```

Lists configured remote repositories.

**Parameters:**
- `verbose` - Non-zero to include URLs in output
- `output` - Output string (must be freed with `tix_remote_free`)

**Returns:**
- `0` = success
- Negative = error

**Example:**
```c
char *remotes;

// List remote names only
if (tix_remote(0, &remotes) == 0) {
    printf("Remotes: %s", remotes);
    tix_remote_free(remotes);
}

// List remotes with URLs
if (tix_remote(1, &remotes) == 0) {
    printf("Remotes with URLs:\n%s", remotes);
    tix_remote_free(remotes);
}
```

#### Add Remote

```c
int tix_remote_add(const char *url);
```

Adds a remote repository (always named "origin").

**Parameters:**
- `url` - Remote repository URL

**Returns:**
- `0` = success
- `-30` = remote already exists
- `-31` = invalid name

**Example:**
```c
int result = tix_remote_add("https://github.com/team/tickets.git");
if (result == 0) {
    printf("Remote added\n");
} else if (result == -30) {
    printf("Remote already exists\n");
}
```

### History and Version Control

#### View History

```c
int tix_log(char **output, int oneline, int limit, const char *since);
void tix_log_free(char *str);
```

Shows git commit history for the current project.

**Parameters:**
- `output` - Output string with log (must be freed with `tix_log_free`)
- `oneline` - Non-zero for compact one-line format
- `limit` - Maximum number of commits (`0` for no limit)
- `since` - Show commits since date (e.g., "2 days ago"), or `NULL` for all

**Returns:**
- `0` = success
- `-2` = not a repository
- `-3` = command failed

**Example:**
```c
char *log_output;

// Show last 10 commits in oneline format
if (tix_log(&log_output, 1, 10, NULL) == 0) {
    printf("Recent commits:\n%s", log_output);
    tix_log_free(log_output);
}

// Show commits from last 2 days
if (tix_log(&log_output, 0, 0, "2 days ago") == 0) {
    printf("Recent activity:\n%s", log_output);
    tix_log_free(log_output);
}
```

#### Undo/Redo Operations

```c
int tix_undo(void);
int tix_redo(void);
```

Undo or redo the last git operation.

**Returns:**
- `0` = success
- `-2` = not a repository
- `-3` = command failed

**Example:**
```c
// Undo last operation
if (tix_undo() == 0) {
    printf("Last operation undone\n");
}

// Redo last undone operation  
if (tix_redo() == 0) {
    printf("Operation redone\n");
}
```

### Synchronization

#### Pull Changes

```c
int tix_pull(void);
```

Pulls changes from the remote repository.

**Returns:**
- `0` = success
- `-2` = not a repository
- `-3` = command failed

#### Push Changes

```c
int tix_push(int force, int force_with_lease);
```

Pushes changes to the remote repository.

**Parameters:**
- `force` - Non-zero to force push (`--force`)
- `force_with_lease` - Non-zero to force with lease (`--force-with-lease`)

**Returns:**
- `0` = success
- `-2` = not a repository
- `-3` = command failed

#### Clone Repository

```c
int tix_clone(const char *repo_url);
```

Clones a remote tix repository.

**Parameters:**
- `repo_url` - URL of the remote repository to clone

**Returns:**
- `0` = success
- `-3` = command failed
- `-1` = out of memory or workspace already exists

**Example:**
```c
// Clone a repository
int result = tix_clone("https://github.com/team/tickets.git");
if (result == 0) {
    printf("Repository cloned successfully\n");
} else {
    printf("Error cloning repository: %d\n", result);
}
```

## File Structure Example

A typical tix workspace looks like this:

```
project_root/
├── .gitignore          # Contains ".tix" entry
└── .tix/               # Tix workspace (git repository)
    ├── .git/           # Git repository data
    ├── README.md       # Auto-generated workspace README
    ├── 01K3PFG1J9KYST.../  # Ticket directory (ULID)
    │   ├── title.md    # "Fix login bug"
    │   ├── body.md     # "Users cannot log in after..."
    │   ├── s=t         # Status: todo (empty file)
    │   └── p=a         # Priority: high (empty file)
    └── 01K3RG280H1G1Z.../  # Another ticket
        ├── title.md
        ├── body.md  
        ├── s=w         # Status: doing
        └── p=z         # Priority: default
```

## Error Handling Best Practices

Always check return values and handle errors appropriately:

```c
#include <stdio.h>
#include "tix.h"

int main() {
    // Initialize workspace
    int result = tix_init();
    if (result < 0) {
        fprintf(stderr, "Failed to initialize workspace: %d\n", result);
        return 1;
    }
    
    // Create a ticket
    char *ticket_id;
    result = tix_add("Sample ticket", "Description here", 'z', 'b', &ticket_id);
    if (result != 0) {
        fprintf(stderr, "Failed to create ticket: %d\n", result);
        return 1;
    }
    
    printf("Created ticket: %s\n", ticket_id);
    
    // Clean up
    tix_add_free(ticket_id);
    
    return 0;
}
```

## Limitations and Unimplemented Features

The following features mentioned in other documentation are **NOT implemented** in the current C API:

- CLI commands (this is a C library, not a CLI tool)
- Search functionality (`tix grep`)
- Status overview (`tix status`)
- Ticket assignment to users  
- Labels or tags
- Blame functionality
- Copy/duplicate tickets
- Archive/delete tickets
- Milestones
- Timeline views
- Board views
- Keyboard shortcuts (UI-specific)

This documentation reflects the actual implemented C API as of the current version.