/*
 * ydlwrap.h --
 *
 * Definitions for dynamic modules and functions for Yorick.
 *
 *-----------------------------------------------------------------------------
 *
 * Copyright (C) 2011-2015: Éric Thiébaut <https://github.com/emmt>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *-----------------------------------------------------------------------------
 */

#ifndef _YDLWRAP_H
#define _YDLWRAP_H 1

#include <yapi.h>

/*---------------------------------------------------------------------------*/
/* Yorick types and C types
** ========================
*/

/* The idea is to set the bit ARRAY_BIT of Yorick type constants to indicate
   an array of this type.  Note that this works because Yorick type constants
   are small numbers. */
#define ARRAY_BIT      (5) /* which bit is used to mark array types */
#define ARRAY_FLAG     (1 << ARRAY_BIT)
#define ARRAY_OF(type) ((type) | ARRAY_FLAG)
#define IS_ARRAY(type) (((type) & ARRAY_FLAG) != 0)
#define TYPE_OF(type)  ((type) & (~ARRAY_FLAG))
#define Y_NTYPES       (1 << (ARRAY_BIT + 1))

#define Y_CHAR_ARRAY       ARRAY_OF(Y_CHAR)
#define Y_SHORT_ARRAY      ARRAY_OF(Y_SHORT)
#define Y_INT_ARRAY        ARRAY_OF(Y_INT)
#define Y_LONG_ARRAY       ARRAY_OF(Y_LONG)
#define Y_FLOAT_ARRAY      ARRAY_OF(Y_FLOAT)
#define Y_DOUBLE_ARRAY     ARRAY_OF(Y_DOUBLE)
#define Y_COMPLEX_ARRAY    ARRAY_OF(Y_COMPLEX)
#define Y_STRING_ARRAY     ARRAY_OF(Y_STRING)
#define Y_POINTER_ARRAY    ARRAY_OF(Y_POINTER)

/* Constants (from 0 to C_NTYPES - 1 with no voids) to identify
   supported C types in tables or argument lists. */
#define C_VOID              0
#define C_CHAR              1
#define C_SHORT             2
#define C_INT               3
#define C_LONG              4
#define C_FLOAT             5
#define C_DOUBLE            6
#define C_COMPLEX           7
#define C_STRING            8 /* '\0' terminated array of char */
#define C_POINTER           9 /* void* */
#define C_CHAR_ARRAY       10
#define C_SHORT_ARRAY      11
#define C_INT_ARRAY        12
#define C_LONG_ARRAY       13
#define C_FLOAT_ARRAY      14
#define C_DOUBLE_ARRAY     15
#define C_COMPLEX_ARRAY    16
#define C_STRING_ARRAY     17
#define C_POINTER_ARRAY    18 /* void** */
#define C_NTYPES           19 /* must be the last one + 1 */


#define C_VOID_PTR  C_POINTER

/*---------------------------------------------------------------------------*/
/* A bunch of useful macros
** ========================
*/

#define TRUE  (1)
#define FALSE (0)

/* y_error is a no-return function.  This macro does explicit return
   to avoid compiler warnings.  Note that this macro is designed for
   built-in functions. */
#define ERROR(msg) do { y_error(msg); return; } while (0)

#define OFFSET_OF(s, m) ((char *)&((s *)0)->m - (char *)0)
#define HOW_MANY(n, m)  (((n) + ((m) - 1))/(m))
#define ROUND_UP(n, m)  (HOW_MANY(n, m)*(m))

/* Push a Yorick object on top of the stack.  TYPE is the C-type of an
   instance of this class, DEF is the structure with the class definition. */
#define PUSH_OBJ(type, def)        ((type *)ypush_obj(&def, sizeof(type)))

/* Get an instance of a Yorick object from the stack.  TYPE is the C-type of
   an instance of this class, DEF is the structure with the class definition
   and IARG is the index relative to the top of the stack. */
#define GET_OBJ(type, def, iarg)  ((type *)yget_obj(iarg, &def))


#define JOIN(a,b)  _JOIN(a,b)
#define _JOIN(a,b)  a##b


/*---------------------------------------------------------------------------*/
/* Public API for dynamic modules
** ==============================
*/

/* ydl_check returns whether stack element at position IARG is a dynamic
   module object. */
extern int ydl_check(int iarg);

/* ydl_get returns the address of the (opaque) dynamic module object at
   position IARG in the stack.  An error is raised if object at IARG is not a
   dynamic module object. */
extern void *ydl_get(int iarg);

/* ydl_find returns the address of the given symbol in the dynamic module
   object at position IARG in the stack.  NULL is returned if not found.  An
   error is raised if object at IARG is not a dynamic module object. */
extern void *ydl_find(int iarg, const char *symbol);

/* ydl_path returns the name of the dynamic module file of object at position
   IARG in the stack.  An error is raised if object at IARG is not a dynamic
   module object. */
extern const char *ydl_path(int iarg);

extern unsigned int ydl_hints(int iarg);
/* ydl_hints returns the flags used to load the dynamic module of object at
   position IARG in the stack.  An error is raised if object at IARG is not a
   dynamic module object. */

/*---------------------------------------------------------------------------*/

#endif /* _YDLWRAP_H */

/*
 * Local Variables:
 * mode: C
 * tab-width: 8
 * c-basic-offset: 2
 * indent-tabs-mode: nil
 * fill-column: 79
 * coding: utf-8
 * ispell-local-dictionary: "american"
 * End:
 */
