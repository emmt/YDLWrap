/*
 * ydlcall.c --
 *
 * Implementation of the dynamic function wrapper for Yorick.
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

#include <errno.h>
#include <stdio.h>
#include <string.h>
#if defined(HAVE_FFCALL)
# include <avcall.h>
#elif defined(HAVE_LIBFFI)
# error libffi not yet supported
#else
# error no dynamic fucntion call support defined
#endif
#include <yapi.h>
#include <pstdlib.h>
#include "ydlwrap.h"

static int last_error = 0;

static const struct {
  const char *c_name;
  int c_type;
  int y_type;
} type_table[] = {
  {"void",      C_VOID,           Y_VOID},
  {"char",      C_CHAR,           Y_CHAR},
  {"short",     C_SHORT,          Y_SHORT},
  {"int",       C_INT,            Y_INT},
  {"long",      C_LONG,           Y_LONG},
  {"float",     C_FLOAT,          Y_FLOAT},
  {"double",    C_DOUBLE,         Y_DOUBLE},
  {"complex",   C_COMPLEX,        Y_COMPLEX},
  {"string",    C_STRING,         Y_STRING},
  {"pointer",   C_POINTER,        Y_POINTER},
  {"char*",     C_CHAR_ARRAY,     Y_CHAR_ARRAY},
  {"short*",    C_SHORT_ARRAY,    Y_SHORT_ARRAY},
  {"int*",      C_INT_ARRAY,      Y_INT_ARRAY},
  {"long*",     C_LONG_ARRAY,     Y_LONG_ARRAY},
  {"float*",    C_FLOAT_ARRAY,    Y_FLOAT_ARRAY},
  {"double*",   C_DOUBLE_ARRAY,   Y_DOUBLE_ARRAY},
  {"complex*",  C_COMPLEX_ARRAY,  Y_COMPLEX_ARRAY},
  {"string*",   C_STRING_ARRAY,   Y_STRING_ARRAY},
  {"pointer*",  C_POINTER_ARRAY,  Y_POINTER_ARRAY},
};

typedef struct _yffc_instance yffc_instance_t;
struct _yffc_instance {
  void *func;    /* pointer to function */
  void *module;  /* NULL or address of loaded dynamic module */
  char *symbol;  /* name of function in the dynamic module */
  int   nargs;   /* number of arguments */
  short args[1]; /* array of nargs + 1 argument types */
};

static void yffc_free(void *);
static void yffc_print(void *);
static void yffc_eval(void *, int);
static void yffc_extract(void *, char *);

static y_userobj_t yffc_class = {
  "DLWrap",
  yffc_free,
  yffc_print,
  yffc_eval,
  yffc_extract,
  NULL
};

static void yffc_free(void *self)
{
  yffc_instance_t *obj = (yffc_instance_t *)self;
  if (obj->module != NULL) ydrop_use(obj->module);
  if (obj->symbol != NULL) p_free(obj->symbol);
}

static void yffc_print(void *self)
{
  yffc_instance_t *obj = (yffc_instance_t *)self;
  int j;
  char buf[100];
  y_print(yffc_class.type_name, 0);
  y_print(" object (dynamic function wrapper) to:", 1);
  sprintf(buf, "%s ", type_table[obj->args[0]].c_name);
  y_print(buf, 0);
  y_print(obj->symbol, 0);
  if (obj->nargs == 0) {
    y_print("(void);", 1);
  } else {
    for (j = 1; j <= obj->nargs; ++j) {
      sprintf(buf, (j == 1? "(%s" : ", %s"), type_table[obj->args[j]].c_name);
      y_print(buf, 0);
    }
    y_print(");", 1);
  }
}

static void yffc_extract(void *addr, char *member)
{
  yffc_instance_t *obj = (yffc_instance_t *)addr;
  int c = (member != NULL ? member[0] : '\0');
  if (c == 'a' && strcmp(member, "atypes") == 0) {
    if (obj->nargs > 0) {
      long dims[2], *atypes;
      int j, n = obj->nargs;
      const short *args = obj->args + 1;
      dims[0] = 1;
      dims[1] = n;
      atypes = ypush_l(dims);
      for (j = 0; j < n; ++j) {
        atypes[j] = (long)(type_table[args[j]].y_type);
      }
    } else {
      ypush_nil();
    }
  } else if (c == 'n' && strcmp(member, "nargs") == 0) {
    ypush_long((long)obj->nargs);
  } else if (c == 'r' && strcmp(member, "rtype") == 0) {
    ypush_long((long)(type_table[obj->args[0]].y_type));
  } else if (c == 's' && strcmp(member, "symbol") == 0) {
    long dims = 0;
    ypush_q(&dims)[0] = p_strcpy(obj->symbol);
  } else if (c == 'm' && strcmp(member, "module") == 0) {
    ykeep_use(obj->module);
  } else {
    ERROR("bad member name");
  }
}

typedef union _yffc_value yffc_value_t;
union _yffc_value {
  char c;
  short s;
  int i;
  long l;
  float f;
  double d;
  double z[2];
  char *q;
  void *p;
};

typedef struct _complex complex_t;
struct _complex {
  double re, im;
};

static void yffc_eval(void *self, int argc)
{
  /* Note: we use switch statements here rather than a table of functions
     since the optimizer will adopt a fast solution ;-).  This assumption is
     confirmed by the measured overheads. */
  long dims[Y_DIMSIZE];
  yffc_instance_t *obj = (yffc_instance_t *)self;
  yffc_value_t result;
  av_alist alist;
  void *func;
  int j, nargs, iarg, c_type;

  func = obj->func;
  nargs = obj->nargs;
  if (nargs == 0) {
    if (argc != 0 && (argc > 1 || ! yarg_nil(0))) {
      y_error("expecting one nil argument");
    }
  } else if (argc != nargs) {
    y_error("bad number of arguments");
  }
  c_type = obj->args[0];
  switch (c_type) {
  case C_VOID:
    av_start_void(alist, func);
    break;
  case C_CHAR:
    av_start_char(alist, func, &result.c);
    break;
  case C_SHORT:
    av_start_short(alist, func, &result.s);
    break;
  case C_INT:
    av_start_int(alist, func, &result.i);
    break;
  case C_LONG:
    av_start_long(alist, func, &result.l);
    break;
  case C_FLOAT:
    av_start_float(alist, func, &result.f);
    break;
  case C_DOUBLE:
    av_start_double(alist, func, &result.d);
    break;
  case C_COMPLEX:
    av_start_struct(alist, func, complex_t,
                    av_word_splittable_2(double, double),
                    &result.z);
    break;
  case C_STRING:
    av_start_ptr(alist, func, char *, &result.q);
    break;
  default:
    ERROR("bad return type");
  }

  /* Build list of arguments (use temporay variable to store the value
     in case the macros use their arguments more than once). */
  for (j = 1; j <= nargs; ++j) {
    iarg = argc - j;
    c_type = obj->args[j];
    switch (c_type) {
#define CASE(TYPE, type, suffix)                \
    case C_##TYPE:                              \
      {                                         \
        type value = ygets_##suffix(iarg);      \
        av_##type(alist, value);                \
      }                                         \
      break
      CASE(CHAR, char, c);
      CASE(SHORT, short, s);
      CASE(INT, int, i);
      CASE(LONG, long, l);
      CASE(FLOAT, float, f);
      CASE(DOUBLE, double, d);
#undef CASE
    case C_COMPLEX:
      {
        complex_t value;
        const double *ptr = ygeta_z(iarg, NULL, dims);
        if (dims[0] != 0) y_error("expecting a scalar complex");
        value.re = ptr[0];
        value.im = ptr[1];
        av_struct(alist, complex_t, value);
      }
      break;
    case C_STRING:
      {
        char *value = ygets_q(iarg);
        av_ptr(alist, char *, value);
      }
      break;
    case C_POINTER:
      {
        void *value = ygets_p(iarg);
        av_ptr(alist, void *, value);
      }
      break;
#define CASE_ARRAY(TYPE, type, suffix)                  \
    case C_##TYPE##_ARRAY:                              \
      {                                                 \
        type *ptr = ygeta_##suffix(iarg, NULL, NULL);   \
        av_ptr(alist, type *, ptr);                     \
      }                                                 \
      break
      CASE_ARRAY(CHAR, char, c);
      CASE_ARRAY(SHORT, short, s);
      CASE_ARRAY(INT, int, i);
      CASE_ARRAY(LONG, long, l);
      CASE_ARRAY(FLOAT, float, f);
      CASE_ARRAY(DOUBLE, double, d);
      CASE_ARRAY(COMPLEX, double, z);
      CASE_ARRAY(STRING, char *, q);
      CASE_ARRAY(POINTER, void *, p);
#undef CASE_ARRAY
    default:
      y_error("bad argument type");
    }
  }

  /* Call the function and push result. */
  errno = 0;
  av_call(alist);
  last_error = errno;
  switch (obj->args[0]) {
  case C_VOID:
    ypush_nil();
    break;
  case C_CHAR:
    {
      long dims = 0;
      *ypush_c(&dims) = result.c;
    }
    break;
  case C_SHORT:
    {
      long dims = 0;
      *ypush_s(&dims) = result.s;
    }
    break;
  case C_INT:
    ypush_int(result.i);
    break;
  case C_LONG:
    ypush_long(result.l);
    break;
  case C_FLOAT:
    {
      long dims = 0;
      *ypush_f(&dims) = result.f;
    }
    break;
  case C_DOUBLE:
    ypush_double(result.d);
    break;
  case C_COMPLEX:
    {
      long dims = 0;
      double *dst = ypush_z(&dims);
      dst[0] = result.z[0];
      dst[1] = result.z[1];
    }
    break;
  case C_STRING:
    /* Assumes that a copy of the returned string must be done. */
    {
      long dims = 0;
      *ypush_q(&dims) = (result.q == NULL ? NULL : p_strcpy(result.q));
    }
    break;
  default:
    ERROR("unexpected return type (BUG)");
  }
}

/*-----------------------------------------------------------------------------
** Built-in Functions
** ==================
*/

void Y_dlwrap(int argc)
{
  static int needs_initialization = TRUE;
  long size, y_type;
  int j, iarg, nargs, c_type;
  void *func;
  char *symbol;
  short *args;
  yffc_instance_t *obj;

  /* Initialization and minimal checking. */
  if (needs_initialization) {
    yfunc_obj(&yffc_class);
    needs_initialization = FALSE;
  }
  nargs = argc - 3;
  if (nargs < 0) ERROR("too few arguments");

  /* Check that 1st argument is a dynamic module, fetch symbol name and find
     its address in the module. */
  if (! ydl_check(argc - 1)) ERROR("expecting dynamic module object");
  symbol = ygets_q(argc - 3);
  func = ydl_find(argc - 1, symbol);
  if (func == NULL) {
    ERROR("symbol not found in dynamic module object (see dlsym)");
  }

  /* Create the wrapper object. */
  size = OFFSET_OF(yffc_instance_t, args) + (nargs + 1)*sizeof(short);
  obj = (yffc_instance_t *)ypush_obj(&yffc_class, size);
  ++argc; /* stack has one more element */
  args = obj->args;
  for (j = 0; j <= nargs; ++j) {
    if (j == 0) {
      /* get stack index for return type */
      iarg = argc - 2;
    } else {
      /* get stack index for j-th argument type */
      iarg = nargs + 1 - j;
    }
    y_type = ygets_l(iarg);
    switch (y_type) {
#define CASE(a,b) case a: c_type = b; break
    CASE(Y_VOID,              C_VOID);
    CASE(Y_CHAR,              C_CHAR);
    CASE(Y_SHORT,             C_SHORT);
    CASE(Y_INT,               C_INT);
    CASE(Y_LONG,              C_LONG);
    CASE(Y_FLOAT,             C_FLOAT);
    CASE(Y_DOUBLE,            C_DOUBLE);
    CASE(Y_COMPLEX,           C_COMPLEX);
    CASE(Y_STRING,            C_STRING);
    CASE(Y_POINTER,           C_POINTER);
    case Y_STRUCT:
      ERROR("only pointer(s) to structure(s) are allowed");
      break;
    CASE(Y_CHAR_ARRAY,    C_CHAR_ARRAY);
    CASE(Y_SHORT_ARRAY,   C_SHORT_ARRAY);
    CASE(Y_INT_ARRAY,     C_INT_ARRAY);
    CASE(Y_LONG_ARRAY,    C_LONG_ARRAY);
    CASE(Y_FLOAT_ARRAY,   C_FLOAT_ARRAY);
    CASE(Y_DOUBLE_ARRAY,  C_DOUBLE_ARRAY);
    CASE(Y_COMPLEX_ARRAY, C_COMPLEX_ARRAY);
    CASE(Y_STRING_ARRAY,  C_STRING_ARRAY);
    CASE(Y_POINTER_ARRAY, C_POINTER_ARRAY);
#undef CASE
    default:
      ERROR("bad type value");
    }
    if (j == 0) {
      if (c_type >= C_POINTER) {
        if (c_type == C_POINTER) {
          ERROR("DL_POINTER is not a valid return type "
                "(use DL_LONG to fake pointers)");
        } else {
          ERROR("unsupported return type");
        }
      }
    } else if (c_type == C_VOID) {
      if (j == 1 && nargs == 1) {
        /* foo(void) is threated as if no arguments */
        --nargs;
      } else {
        ERROR("void type is only allowed for the return type "
              "or for a single argument");
      }
    }
    args[j] = c_type;
  }

  /* Instanciate the other members of the wrapper object.  The wrapper object
     keeps a reference on the dynamic module object. */
  obj->nargs = nargs;
  obj->func = func;
  obj->symbol = p_strcpy(symbol);
  obj->module = yget_use(argc - 1);
}

void Y_dlwrap_errno(int argc)
{
  ypush_int(last_error);
}

void Y_dlwrap_strerror(int argc)
{
  long dims = 0;
  const char *msg;
  int code;
  if (argc != 1) ERROR("expecting exactly one argument");
  if (yarg_nil(0)) {
    code = last_error;
  } else {
    code = ygets_i(0);
  }
  msg = strerror(code);
  *ypush_q(&dims) = (msg != NULL ? p_strcpy(msg) : NULL);
}

void Y_dlwrap_strlen(int argc)
{
  const char *str;
  if (argc != 1 || yarg_rank(0) != 0 || yarg_typeid(0) != Y_LONG) {
    ERROR("expecting a single address (as a long integer)");
  }
  str = (char *)ygets_l(0);
  ypush_long((str != NULL ? strlen(str) : 0));
}

void Y_dlwrap_strcpy(int argc)
{
  long dims = 0;
  const char *src, *str;
  char *dst;
  long n;
  if (argc == 1) {
    /* mimics strdup */
    if (yarg_rank(0) != 0 || yarg_typeid(0) != Y_LONG) {
      goto bad_address;
    }
    str = (const char *)ygets_l(0);
    ypush_q(&dims)[0] = (str != NULL ? p_strcpy(str) : NULL);
    return;
  } else if (argc == 2 || argc == 3) {
    /* mimics strcpy or strncpy */
    if (yarg_rank(argc - 1) != 0 || yarg_typeid(argc - 1) != Y_LONG ||
        yarg_rank(argc - 2) != 0 || yarg_typeid(argc - 2) != Y_LONG) {
      goto bad_address;
    }
    dst = (char *)ygets_l(argc - 1);
    src = (const char *)ygets_l(argc - 2);
    if (argc == 2) {
      if (src != dst) {
        if (dst == NULL || src == NULL) goto unexpected_null;
        strcpy(dst, src);
      }
    } else {
      n = ygets_l(0);
      if (n != 0 && dst != src) {
        if (dst == NULL || src == NULL) goto unexpected_null;
        strncpy(dst, src, n);
      }
    }
    ypush_long((long)dst);
  } else {
    ERROR("bad number of arguments");
  }
 bad_address:
  ERROR("expecting an address (as a long integer)");
 unexpected_null:
  ERROR("unexpected NULL address");
}

#undef USE_YPUSH_PTR /* I suspect that ypush_ptr has a bug,
                        or I mis-use it ;-) */

#ifdef USE_YPUSH_PTR
static void *get_address(int iarg, long *size)
#else
static void *get_address(int iarg)
#endif
{
  void *ptr;
#ifdef USE_YPUSH_PTR
  long number;
#endif
  int type;

  if (yarg_rank(iarg) == 0) {
    /* got a scalar */
    type = yarg_typeid(iarg);
    if (type == Y_LONG) {
      ptr = (void *)ygets_l(iarg);
#ifdef USE_YPUSH_PTR
      if (size != NULL) {
        *size = (ptr == NULL ? 0L : -1L);
      }
#endif /* USE_YPUSH_PTR */
      return ptr;
    }
    if (type == Y_POINTER) {
      ptr = ygets_p(iarg);
#ifdef USE_YPUSH_PTR
      if (size != NULL) {
        if (ptr == NULL) {
          *size = 0L;
        } else {
          type = ypush_ptr(ptr, &number);
          fprintf(stderr, "type[%d] = %d\n", iarg, type);
          yarg_drop(1);
          switch (type) {
          case Y_CHAR:    *size = number*sizeof(char); break;
          case Y_SHORT:   *size = number*sizeof(short); break;
          case Y_INT:     *size = number*sizeof(int); break;
          case Y_LONG:    *size = number*sizeof(long); break;
          case Y_FLOAT:   *size = number*sizeof(float); break;
          case Y_DOUBLE:  *size = number*sizeof(double); break;
          case Y_COMPLEX: *size = number*(2*sizeof(double)); break;
          default:        *size = -1L; /* size only known for primitive types */
          }
        }
      }
#endif /* USE_YPUSH_PTR */
      return ptr;
    }
  }
  y_error("expecting an address (a long integer or a pointer)");
  return NULL;
}

static void memcpy_or_memmove(const int argc, const int move)
{
  const void *src_ptr;
  void *dst_ptr;
  long size;
#ifdef USE_YPUSH_PTR
  long src_size, dst_size;
  if (argc < 2 || argc > 3) ERROR("expecting 2 or 3 arguments");
  dst_ptr = get_address(argc - 1, &dst_size);
  src_ptr = get_address(argc - 2, &src_size);
  fprintf(stderr, "%s(0x%lx[%ld], 0x%lx[%ld], %ld)\n",
          (move ? "memmove" : "memcpy"),
          (unsigned long)dst_ptr, dst_size,
          (unsigned long)src_ptr, src_size,
          (argc < 3 ? -1L : ygets_l(argc - 3)));
  if (argc < 3) {
    if (src_size == -1L || dst_size == -1L) {
      ERROR("the number of bytes must be specified in this context");
    }
    if ((size = src_size) > dst_size) {
      ERROR("source size is larger than destination");
    }
  } else {
    size = ygets_l(argc - 3);
    if (size < 0L)
      ERROR("invalid number of bytes");
    if (src_size != -1L && size > src_size)
      ERROR("number of bytes is larger than source");
    if (dst_size != -1L && size > dst_size)
      ERROR("number of bytes is larger than destination");
  }
#else /* not USE_YPUSH_PTR */
  if (argc != 3) ERROR("expecting 3 arguments");
  dst_ptr = get_address(argc - 1);
  src_ptr = get_address(argc - 2);
  size = ygets_l(argc - 3);
  if (size < 0L) ERROR("invalid number of bytes");
#endif /* USE_YPUSH_PTR */
  if (size > 0L && dst_ptr != src_ptr) {
    if (move) {
      memmove(dst_ptr, src_ptr, size);
    } else {
      memcpy(dst_ptr, src_ptr, size);
    }
  }
  ypush_long((long)dst_ptr);
}

void Y_dlwrap_memcpy(int argc)
{
  memcpy_or_memmove(argc, 0);
}

void Y_dlwrap_memmove(int argc)
{
  memcpy_or_memmove(argc, 1);
}

void Y_dlwrap_addressof(int argc)
{
  void *ptr;
  int type;
  if (argc != 1) ERROR("expecting a single argument");
  if (yget_ref(0) == -1L) ERROR("argument must not be an expression");
  ptr = ygeta_any(0, NULL, NULL, &type);
  /*if (type > Y_COMPLEX) ERROR("expecting an array of primitive type");*/
  ypush_long((long)ptr);
}

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
