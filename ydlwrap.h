/*
 * ydlwrap.h --
 *
 * Definitions for dynamic modules and functions for Yorick.
 *
 *-----------------------------------------------------------------------------
 *
 * Copyright (C) 2011 Eric Thiébaut <thiebaut@obs.univ-lyon1.fr>
 *
 * This software is governed by the CeCILL-C license under French law and
 * abiding by the rules of distribution of free software.  You can use, modify
 * and/or redistribute the software under the terms of the CeCILL-C license as
 * circulated by CEA, CNRS and INRIA at the following URL
 * "http://www.cecill.info".
 *
 * As a counterpart to the access to the source code and rights to copy,
 * modify and redistribute granted by the license, users are provided only
 * with a limited warranty and the software's author, the holder of the
 * economic rights, and the successive licensors have only limited liability.
 *
 * In this respect, the user's attention is drawn to the risks associated with
 * loading, using, modifying and/or developing or reproducing the software by
 * the user in light of its specific status of free software, that may mean
 * that it is complicated to manipulate, and that also therefore means that it
 * is reserved for developers and experienced professionals having in-depth
 * computer knowledge. Users are therefore encouraged to load and test the
 * software's suitability as regards their requirements in conditions enabling
 * the security of their systems and/or data to be ensured and, more
 * generally, to use and operate it in the same conditions as regards
 * security.
 *
 * The fact that you are presently reading this means that you have had
 * knowledge of the CeCILL-C license and that you accept its terms.
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
 * fill-column: 78
 * coding: utf-8
 * End:
 */
