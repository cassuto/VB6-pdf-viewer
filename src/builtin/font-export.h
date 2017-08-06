#ifndef FONT_EXPORT

#ifdef __GNUC__
# define FONT_EXPORT _cdecl __attribute__((visibility("default")))
#else
# define FONT_EXPORT _cdecl _declspec(dllexport)
#endif

#endif
