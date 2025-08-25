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
#define TIX_UNKNOWN_ERROR                    -99

/* Function declarations matching root.zig exports */

/* Workspace management */
int tix_init(void);


#ifdef __cplusplus
}
#endif

#endif /* TIX_H */
