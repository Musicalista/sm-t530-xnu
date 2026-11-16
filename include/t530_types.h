#ifndef __T530_TYPES_H__
#define __T530_TYPES_H__

/*
 * Freestanding integer and boolean types for Darwin / XNU on Qualcomm Snapdragon 400 (ARMv7 Cortex-A7)
 */

typedef signed char        int8_t;
typedef short              int16_t;
typedef int                int32_t;
typedef long long          int64_t;

typedef unsigned char      uint8_t;
typedef unsigned short     uint16_t;
typedef unsigned int       uint32_t;
typedef unsigned long long uint64_t;

typedef unsigned long      uintptr_t;
typedef long               intptr_t;
typedef unsigned long      size_t;

#ifndef bool
typedef _Bool bool;
#define true 1
#define false 0
#endif

#ifndef NULL
#define NULL ((void *)0)
#endif

#endif /* __T530_TYPES_H__ */
