/*
 * tix.h - C header file for tix library FFI
 * 
 * This header is manually maintained until Zig's emit-h functionality
 * is fixed (currently broken in Zig 0.14)
 */

#ifndef TIX_H
#define TIX_H

#include <stddef.h>  /* for size_t */

#ifdef __cplusplus
extern "C" {
#endif

/* Error codes matching error.zig ErrorCode enum */

/* General errors (common across modules) */
#define TIX_OUT_OF_MEMORY                    -1
#define TIX_NOT_A_REPOSITORY                 -2
#define TIX_COMMAND_FAILED                   -3
#define TIX_FILE_SYSTEM_ERROR                -4
#define TIX_INVALID_TICKET_ID                -5
#define TIX_TICKET_NOT_FOUND                 -6
#define TIX_UNKNOWN_ERROR                    -99

/* Init-specific errors */
#define TIX_INIT_WORKSPACE_CREATION_FAILED   -10
#define TIX_INIT_ACCESS_DENIED               -11

/* Config-specific errors */
#define TIX_CONFIG_INVALID_KEY               -20

/* Remote-specific errors */
#define TIX_REMOTE_ALREADY_EXISTS            -30
#define TIX_REMOTE_INVALID_NAME              -31

/* Switch-specific errors */
#define TIX_SWITCH_PROJECT_NOT_FOUND         -40
#define TIX_SWITCH_PROJECT_ALREADY_EXISTS    -41
#define TIX_SWITCH_ALREADY_ON_PROJECT        -42

/* Add-specific errors */
#define TIX_INVALID_PRIORITY                 -50
#define TIX_INVALID_TITLE                    -51

/* Move-specific errors */
#define TIX_INVALID_STATUS                   -60

/* Function declarations matching root.zig exports */

/* Workspace management */

/**
 * Initialize a new tix workspace
 * @return 0 = initialized, 1 = reinitialized, -10 = workspace creation failed, -11 = access denied
 */
int tix_init(void);

/**
 * Set a configuration key-value pair
 * @param key Configuration key  
 * @param value Configuration value
 * @return 0 = success, -20 = invalid key
 */
int tix_config_set(const char *key, const char *value);

/**
 * Get a configuration value
 * @param key Configuration key
 * @param value_out Output string (must be freed by caller using tix_config_get_free)
 * @return 0 = success, -20 = invalid key
 */
int tix_config_get(const char *key, char **value_out);

/**
 * Free a string returned by tix_config_get
 * @param str String to free
 */
void tix_config_get_free(char *str);

/* Ticket management */

/**
 * Add a new ticket
 * @param title Ticket title (required, non-empty)
 * @param body Ticket description  
 * @param priority Priority: 'a', 'b', 'c', 'z', or 0 for default (z)
 * @param id_out Output string containing ticket ID (must be freed by caller using tix_add_free)
 * @return 0 = success, -50 = invalid priority, -51 = invalid title
 */
int tix_add(const char *title, const char *body, unsigned char priority, char **id_out);

/**
 * Free a string returned by tix_add
 * @param str String to free
 */
void tix_add_free(char *str);

/* Remote management */

/**
 * List remote repositories
 * @param verbose If non-zero, includes URLs in the output
 * @param output Output string (must be freed by caller using tix_remote_free)
 * @return 0 = success, negative = error
 */
int tix_remote(int verbose, char **output);

/**
 * Free a string returned by tix_remote
 * @param str String to free
 */
void tix_remote_free(char *str);

/**
 * Add a remote repository
 * @param name Remote name
 * @param url Remote URL
 * @return 0 = success, -30 = remote already exists, -31 = invalid name
 */
int tix_remote_add(const char *name, const char *url);

/* Project management */

/**
 * Switch to a different project (branch)
 * @param project Project name
 * @param create If non-zero, create project if it doesn't exist
 * @return 0 = switched, 1 = created, -40 = project not found, -41 = project already exists, -42 = already on project
 */
int tix_switch_project(const char *project, int create);

/* Ticket management */

/**
 * Move ticket to a different status
 * @param ticket_id ULID of the ticket
 * @param status Status character ('b'=backlog, 't'=todo, 'w'=doing, 'd'=done)
 * @return 0 = success, -5 = invalid ticket ID, -60 = invalid status, -3 = command failed
 */
int tix_move(const char *ticket_id, unsigned char status);

/* CTicket structure for list output */
typedef struct CTicket {
    const char *id;
    const char *title;
    const char *body;
    unsigned char priority;
    unsigned char status;
} CTicket;

/**
 * List tickets with optional filters
 * @param statuses String of status characters to filter ('b', 't', 'w', 'd'), NULL for all
 * @param priorities String of priority characters to filter ('a', 'b', 'c', 'z'), NULL for all
 * @param output Pointer to receive array of CTicket structs (must be freed by caller)
 * @param count Pointer to receive number of tickets
 * @return 0 = success, -60 = invalid status, -50 = invalid priority, -1 = out of memory
 */
int tix_list(const char *statuses, const char *priorities, CTicket **output, size_t *count);

/**
 * Show full ticket details
 * @param ticket_id ULID of the ticket to show
 * @param output Pointer to receive a CTicket struct (must be freed by caller)
 * @return 0 = success, -5 = invalid ticket ID, -6 = ticket not found, -1 = out of memory
 */
int tix_show(const char *ticket_id, CTicket **output);

/**
 * Free a CTicket returned by tix_show
 * @param ticket Pointer to CTicket to free
 */
void tix_show_free(CTicket *ticket);

/**
 * Show only the title of a ticket
 * @param ticket_id ULID of the ticket to show
 * @param output Pointer to receive the title string (must be freed by caller using tix_show_title_free)
 * @return 0 = success, -5 = invalid ticket ID, -6 = ticket not found, -1 = out of memory
 */
int tix_show_title(const char *ticket_id, char **output);

/**
 * Free a string returned by tix_show_title
 * @param str String to free
 */
void tix_show_title_free(char *str);

/**
 * Show only the body of a ticket
 * @param ticket_id ULID of the ticket to show
 * @param output Pointer to receive the body string (must be freed by caller using tix_show_body_free)
 * @return 0 = success, -5 = invalid ticket ID, -6 = ticket not found, -1 = out of memory
 */
int tix_show_body(const char *ticket_id, char **output);

/**
 * Free a string returned by tix_show_body
 * @param str String to free
 */
void tix_show_body_free(char *str);

/**
 * Show only the status of a ticket
 * @param ticket_id ULID of the ticket to show
 * @return Status character ('b', 't', 'w', 'd') on success, negative error code on failure
 */
int tix_show_status(const char *ticket_id);

/**
 * Show only the priority of a ticket
 * @param ticket_id ULID of the ticket to show
 * @return Priority character ('a', 'b', 'c', 'z') on success, negative error code on failure
 */
int tix_show_priority(const char *ticket_id);

/**
 * Amend ticket properties (title, body, priority)
 * @param ticket_id ULID of the ticket to amend
 * @param title New title (empty string to leave unchanged)
 * @param body New body (empty string to leave unchanged)
 * @param priority New priority (0 to leave unchanged)
 * @return 0 = success, -5 = invalid ticket ID, -50 = invalid priority
 */
int tix_amend(const char *ticket_id, const char *title, const char *body, unsigned char priority);

/**
 * Undo the last change
 * @return 0 = success, -2 = not a repository, -3 = command failed
 */
int tix_undo(void);

/**
 * Redo the last undone change
 * @return 0 = success, -2 = not a repository, -3 = command failed
 */
int tix_redo(void);

/**
 * List all local projects (branches)
 * @param output Array of branch names, first element is current branch (must be freed by caller using tix_projects_free)
 * @param count Number of branches
 * @return 0 = success, -2 = not a repository, -3 = command failed
 */
int tix_projects(char ***output, size_t *count);

/**
 * Free an array returned by tix_projects
 * @param output Array to free
 * @param count Number of elements
 */
void tix_projects_free(char **output, size_t count);

/**
 * Show commit history
 * @param output Output string with log (must be freed by caller using tix_log_free)
 * @param oneline Non-zero for oneline format
 * @param limit Maximum number of commits (0 for no limit)
 * @param since Show commits since date (e.g. "2 days ago"), NULL for all
 * @return 0 = success, -2 = not a repository, -3 = command failed
 */
int tix_log(char **output, int oneline, int limit, const char *since);

/**
 * Free a string returned by tix_log
 * @param str String to free
 */
void tix_log_free(char *str);

/**
 * Clone a remote repository
 * @param repo_url URL of the remote repository to clone
 * @return 0 = success, -3 = command failed, -1 = out of memory, workspace already exists
 */
int tix_clone(const char *repo_url);

/**
 * Free a CTicket array returned by tix_list
 * @param tickets Pointer to CTicket array to free
 * @param count Number of tickets in the array
 */
void tix_list_free(CTicket *tickets, size_t count);

#ifdef __cplusplus
}
#endif

#endif /* TIX_H */
