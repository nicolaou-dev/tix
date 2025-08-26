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
#define TIX_SUCCESS                           0
#define TIX_CREATED                           1

/* General errors */
#define TIX_OUT_OF_MEMORY                    -1
#define TIX_UNKNOWN_ERROR                    -99

/* Init errors */
#define TIX_INIT_WORKSPACE_CREATION_FAILED   -10
#define TIX_INIT_ACCESS_DENIED               -11


/** Config errors */
#define TIX_CONFIG_KEY_NOT_FOUND             -20

/* Remote errors */
#define TIX_REMOTE_ALREADY_EXISTS            -30
#define TIX_REMOTE_INVALID_NAME              -31
#define TIX_REMOTE_NOT_A_REPOSITORY          -32
#define TIX_REMOTE_FAILED                    -33

/* Switch errors */
#define TIX_SWITCH_PROJECT_NOT_FOUND         -40
#define TIX_SWITCH_PROJECT_ALREADY_EXISTS    -41
#define TIX_SWITCH_ALREADY_ON_PROJECT        -42
#define TIX_SWITCH_FAILED                    -43

/* Function declarations matching root.zig exports */

/* Workspace management */
/* Returns: 0 = initialized, 1 = reinitialized, negative = error (see error codes above) */
int tix_init(void);


/* Returns: 0 = success, negative = error */
int tix_config_set(const char *key, const char *value);

/* Returns: 0 = success, negative = error. Output string must be freed by caller. */
int tix_config_get(const char *key, char **value_out);


/* Remote management */
/* Returns: 0 = success, negative = error. Output string must be freed by caller.
   If verbose is non-zero, includes URLs in the output. */
int tix_remote(char **output, int verbose);

/* Project management */
/* Returns: 0 = switched, 1 = created, negative = error (see error codes above) */
int tix_switch_project(const char *project, int create);


/* Returns: 0 = success, negative = error */
int tix_remote_add(const char *name, const char *url);


#ifdef __cplusplus
}
#endif

#endif /* TIX_H */
