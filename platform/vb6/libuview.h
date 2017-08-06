#ifndef LIBUVIEW_H_
#define LIBUVIEW_H_

#include <assert.h>

/* calling protocol */
#define DECL_CALL __stdcall
#define VBF_CALL __stdcall

#ifdef __GNUC__
# define UV_EXPORT DECL_CALL __attribute__((visibility("default")))
#else
# define UV_EXPORT DECL_CALL __declspec(dllexport)
#endif

/**def DECL
 * Define a exported function.
 * @param t Returning type of this function.
 */
#define DECL(t) UV_EXPORT t

/**def VBF
 * Define a callback function.
 * @param t Returning type of this function.
 */
#define VBF(t) VBF_CALL t

/**
 * the following macros are used to ensure that
 * the pointer passed to us is valid. In particular, developing
 * with vb, to use a null or invalid value as parameter is usual to occur.
 */
#define VALIDATE_PTR(p) (p && (unsigned long)p > 0x000000000000ffff)
#ifndef CHECK_LOOSE
# define CHECK_STRICT_PTR(p) do { if (!VALIDATE_PTR(p)) return ERR_INVALID_PARAMETER; } while(0);
# define CHECKR_STRICT_PTR(p) do { if (!VALIDATE_PTR(p)) return; } while(0);
# define RETURN_STRICT_PTR(p) do { if (!VALIDATE_PTR(p)) return p; } while(0);
# define BREAK_STRICT_PTR(p) if (!VALIDATE_PTR(p)) break;
# define ASSERT_STRICT_PTR(p) do { assert(VALIDATE_PTR(p)); } while(0);
#else
# define CHECK_STRICT_PTR(p) (void)0
# define CHECKR_STRICT_PTR(p) (void)0
# define RETURN_STRICT_PTR(p) (void)0
# define BREAK_STRICT_PTR(p) (void)0
# define ASSERT_STRICT_PTR(p) (void)0
#endif

/**
 * the global magic used by uview.
 * It's helpful for memory dump debugging, in this way we can find
 * the uview_s struct easily and analyze the fields next moment.
 */
#define UVIEW_MAGIC (0x55564557) // 'UVEW' in little endian
#define PIXMAP_MAGIC (0x5049584d) // 'PIXM' in little endian

#define CHECK_MAGIC(m) do { if(m != UVIEW_MAGIC) return ERR_INVALID_MAGIC; } while(0);
#define CHECKR_MAGIC(m) do { if(m != UVIEW_MAGIC) return; } while(0);
#define RETURN_NULL_CHECK_MAGIC do { if(m != UVIEW_MAGIC) return NULL; } while(0);

/**
 * Error definitions
 */

/** Operation succeeded. */
#define OK_SUCCEEDED (0)
/** Operation failed. */
#define ERR_FAILED (-1)
/** Failed on validating the magic number */
#define ERR_INVALID_MAGIC (-2)
/** Failed on counting the pages */
#define ERR_COUNT_PAGES (-3)
/** The parameters passed in is invalid */
#define ERR_INVALID_PARAMETER (-4)
/** The document has not been opened/ */
#define ERR_NOT_OPENED (-5)
/** Failed on allocating memory */
#define ERR_ALLOC_MEMORY (-6)
/** The page specified is invalid */
#define ERR_INVALID_PAGE (-7)
/** Failed on getting the outline of document */
#define ERR_GET_OUTLINE (-8)
/** Failed on resolving links */
#define ERR_RESOLVE_LINKS (-9)
/** No enough infomation to do this operation */
#define ERR_NO_ENOUGH_INFOMATION (-10)


#define V_SUCCESS(rc) (rc >= 0)
#define V_FAILURE(rc) (rc < 0)

/**
 * Message for debugging
 */
#define MSG(fmt, ...) (void)0

#endif //!defined(LIBUVIEW_H_)
