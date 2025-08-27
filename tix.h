/*
 * tix.h - C header file for tix library FFI
 * 
 * This header is manually maintained until Zig's emit-h functionality
 * is fixed (currently broken in Zig 0.14)
 */

#ifndef TIX_H
#define TIX_H

#ifdef __cplusplus
extern "C" {
#endif

/* Error codes matching error.zig ErrorCode enum */

/* General errors (common across modules) */
#define TIX_OUT_OF_MEMORY                    -1
#define TIX_NOT_A_REPOSITORY                 -2
#define TIX_COMMAND_FAILED                   -3
#define TIX_FILE_SYSTEM_ERROR                -4
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
 * @param value_out Output string (must be freed by caller)
 * @return 0 = success, -20 = invalid key
 */
int tix_config_get(const char *key, char **value_out);

/* Ticket management */

/**
 * Add a new ticket
 * @param title Ticket title (required, non-empty)
 * @param body Ticket description  
 * @param priority Priority: 'a', 'b', 'c', 'z', or 0 for default (z)
 * @param id_out Output string containing ticket ID (must be freed by caller)
 * @return 0 = success, -50 = invalid priority, -51 = invalid title
 */
int tix_add(const char *title, const char *body, unsigned char priority, char **id_out);

/* Remote management */

/**
 * List remote repositories
 * @param output Output string (must be freed by caller)
 * @param verbose If non-zero, includes URLs in the output
 * @return 0 = success, negative = error
 */
int tix_remote(char **output, int verbose);

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


#ifdef __cplusplus
}
#endif

#endif /* TIX_H */
