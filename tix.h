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
#define TIX_INIT_SUCCESS                      0
#define TIX_REINIT_SUCCESS                    1
#define TIX_INIT_WORKSPACE_CREATION_FAILED   -1
#define TIX_INIT_ACCESS_DENIED               -2
#define TIX_SWITCH_PROJECT_NOT_FOUND         -3
#define TIX_SWITCH_PROJECT_ALREADY_EXISTS    -4
#define TIX_SWITCH_ALREADY_ON_PROJECT        -5
#define TIX_SWITCH_FAILED                    -6
#define TIX_UNKNOWN_ERROR                    -99

/* Function declarations matching root.zig exports */

/* Workspace management */
/* Returns: 0 = initialized, 1 = reinitialized, negative = error (see error codes above) */
int tix_init(void);

/* Project management */
/* Returns: 0 = switched, 1 = created, negative = error (see error codes above) */
int tix_switch_project(const char *project, int create);


#ifdef __cplusplus
}
#endif

#endif /* TIX_H */
