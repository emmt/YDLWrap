/*
 * ydlload.c --
 *
 * Implementation of the dynamic module loader for Yorick.
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

#include <stdio.h>
#include <string.h>
#if defined(HAVE_LIBTOOL)
# include <ltdl.h>
#elif defined(HAVE_DLOPEN)
# include <dlfcn.h>
#else
# warning no dynamic loader interface defined (perhaps use built-in one?)
#endif
#include <pstdlib.h>
#include "ydlwrap.h"

/* These bits must match the definitions in "dlwrap.i" */
#define YDL_LAZY       0x00001
#define YDL_NOW        0x00002
#define YDL_NOLOAD     0x00004 /* FIXME: not used */
#define YDL_DEEPBIND   0x00008
#define YDL_LOCAL      0x00100
#define YDL_GLOBAL     0x00200
#define YDL_RESIDENT   0x01000
#define YDL_EXTENSION  0x02000
#define YDL_PRELOAD    0x04000

#define STATEMENT(code) do { code; } while (0)

/* Definitions to hide the implementation details. */
#if defined(HAVE_LIBTOOL)

/* Use LIBTOOL */
static const char *my_variant = "ltdl";
# define MY_DLSYM(HANDLE,NAME) ((NAME) != NULL ? lt_dlsym(HANDLE,NAME) : NULL)
# define MY_DLCLOSE(HANDLE)    if ((HANDLE) == NULL) ; else lt_dlclose(HANDLE)

#elif defined(HAVE_DLOPEN)

/* Use DLOPEN */
static const char *my_variant = "dl";
# define MY_DLSYM(HANDLE,NAME) ((NAME) != NULL ? dlsym(HANDLE,NAME) : NULL)
# define MY_DLCLOSE(HANDLE)    if ((HANDLE) == NULL) ; else dlclose(HANDLE)
#else

/* Use own Yorick implementation in the Portability LAYer */
static const char *my_variant = "play";
# define MY_DLSYM(HANDLE,NAME) my_dlsym(HANDLE,NAME)
# define MY_DLCLOSE(HANDLE)
static void *my_dlsym(void *handle, const char *symbol)
{
  void *addr = NULL;
  if (symbol == NULL || p_dlsym(handle, symbol, 0, &addr)) {
    return NULL;
  }
  return addr;
}

#endif

/*-----------------------------------------------------------------------------
** Implementation of Yorick Object
** ===============================
*/

typedef struct _ydl_instance ydl_instance_t;
struct _ydl_instance {
  void *handle;
  const char *path;   /* path to dynamic module (can be NULL) */
  unsigned int hints;
};

static void ydl_free(void *);
static void ydl_print(void *);
static void ydl_eval(void *, int);
static void ydl_extract(void *, char *);

y_userobj_t ydl_class = {
  "DLModule",
  ydl_free,
  ydl_print,
  ydl_eval,
  ydl_extract,
  NULL
};

static void ydl_free(void *addr)
{
  ydl_instance_t *obj = (ydl_instance_t *)addr;
  if (obj->path != NULL) p_free((void *)obj->path);
  MY_DLCLOSE(obj->handle);
}

static void ydl_print(void *addr)
{
  ydl_instance_t *obj = (ydl_instance_t *)addr;
  int first = TRUE;
  y_print(ydl_class.type_name, 0);
  y_print(" (dynamic module object: hints = ", 0);
#define PRT(BIT)                                        \
  if ((obj->hints & YDL_##BIT) == YDL_##BIT) {          \
    y_print((first ? "DL_" #BIT : "|DL_" #BIT), 0);     \
    first = FALSE;                                      \
  } else /* <-- hack */
  PRT(LAZY);
  PRT(NOW);
  PRT(LOCAL);
  PRT(GLOBAL);
  PRT(RESIDENT);
  PRT(EXTENSION);
  PRT(PRELOAD);
  PRT(DEEPBIND);
#undef PRT
  if (first) {
    y_print("0", 0);
  }
  if (obj->path != NULL) {
    y_print(", path = \"", 0);
    y_print(obj->path, 0);
    y_print("\")", 1);
  } else {
    y_print(", path = NULL)", 1);
  }
}

static void ydl_eval(void *addr, int argc)
{
  ydl_instance_t *obj = (ydl_instance_t *)addr;
  const char *symbol;
  void *ptr;

  if (argc != 1) ERROR("bad number of arguments");
  symbol = ygets_q(0);
  ptr = MY_DLSYM(obj->handle, symbol);
  ypush_long((long)ptr);
}

static void ydl_extract(void *addr, char *member)
{
  ydl_instance_t *obj = (ydl_instance_t *)addr;
  if (member != NULL && member[0] != '\0') {
    if (strcmp(member, "path") == 0) {
      long dims = 0;
      ypush_q(&dims)[0] = p_strcpy(obj->path);
      return;
    } else if (strcmp(member, "hints") == 0) {
      ypush_long(obj->hints);
      return;
    }
  }
  ERROR("bad member name");
}

/*-----------------------------------------------------------------------------
** Built-in Functions
** ==================
*/

void Y_dlvariant(int argc)
{
  long dims = 0;
  if (argc != 0 && (argc > 1 || ! yarg_nil(0))) {
    y_error("expecting a single nil argument");
  }
  ypush_q(&dims)[0] = p_strcpy(my_variant);
}

void Y_dlopen(int argc)
{
  ydl_instance_t *obj;
  const char *msg, *name;
  unsigned int hints;

  if (argc < 1 || argc > 2) ERROR("bad number of arguments");
  if (yarg_nil(argc - 1)) {
    name = NULL;
  } else {
    name = ygets_q(argc - 1);
  }
  hints = (argc >= 2 ? ygets_i(argc - 2) : 0);
  if ((hints & (YDL_NOW | YDL_LAZY)) == 0) {
    hints |= YDL_LAZY;
  } else if ((hints & (YDL_NOW | YDL_LAZY)) == (YDL_NOW | YDL_LAZY)) {
    y_error("hints DL_NOW and DL_LAZY are exclusive");
  }
  if ((hints & (YDL_LOCAL | YDL_GLOBAL)) == 0) {
    hints |= YDL_LOCAL;
  } else if ((hints & (YDL_LOCAL | YDL_GLOBAL)) == (YDL_LOCAL | YDL_GLOBAL)) {
    y_error("hints DL_LOCAL and DL_GLOBAL are exclusive");
  }
  obj = PUSH_OBJ(ydl_instance_t, ydl_class);
  obj->path = (name != NULL ? p_native(name) : NULL);
  obj->hints = 0;
#if defined(HAVE_LIBTOOL)
  {
    static int needs_initialization = TRUE;
    lt_dladvise advise;
    int destroy_advise = FALSE;
    if (needs_initialization) {
      if (lt_dlinit() != 0) {
        y_error("lt_dlinit() failure");
      }
      needs_initialization = FALSE;
    }
    if ((hints & (YDL_NOW | YDL_LAZY)) == YDL_NOW) {
      y_error("flag DL_NOW not supported on this implementation");
      obj->hints = YDL_NOW;
    } else {
      /* This is the default for libltdl. */
      obj->hints = YDL_LAZY;
    }
    if (lt_dladvise_init(&advise) != 0) {
      goto failure;
    }
    destroy_advise = TRUE;
    if ((hints & (YDL_GLOBAL | YDL_LOCAL)) == YDL_GLOBAL) {
      if (lt_dladvise_global(&advise) != 0) {
        goto failure;
      }
      obj->hints |= YDL_GLOBAL;
    } else {
      if (lt_dladvise_local(&advise) != 0) {
        goto failure;
      }
      obj->hints |= YDL_LOCAL;
    }
    if ((hints & YDL_RESIDENT) != 0) {
      if (lt_dladvise_resident(&advise) != 0) {
        goto failure;
      }
      obj->hints |= YDL_RESIDENT;
    }
    if ((hints & YDL_EXTENSION) != 0) {
      if (lt_dladvise_ext(&advise) != 0) {
        goto failure;
      }
      obj->hints |= YDL_EXTENSION;
    }
    if ((hints & YDL_PRELOAD) != 0) {
      if (lt_dladvise_preload(&advise) != 0) {
        goto failure;
      }
      obj->hints |= YDL_PRELOAD;
    }
    if ((hints & YDL_DEEPBIND) != 0) {
      if (destroy_advise) lt_dladvise_destroy(&advise);
      y_error("flag DL_DEEPBIND not supported on this implementation");
    }
    obj->handle = lt_dlopenadvise(obj->path, advise);
    if (obj->handle == NULL) {
    failure:
      msg = lt_dlerror(); /* get message first */
      if (destroy_advise) lt_dladvise_destroy(&advise);
      if (msg == NULL) msg = "failed to open dynamic library (unknown reason)";
      y_error(msg);
    }
    if (lt_dladvise_destroy(&advise) != 0) {
      destroy_advise = FALSE;
      goto failure;
    }
  }
#elif defined(HAVE_DLOPEN)
  {
    int flags;
    if ((hints & (YDL_NOW | YDL_LAZY)) == YDL_NOW) {
      obj->hints = YDL_NOW;
      flags = RTLD_NOW;
    } else {
      obj->hints = YDL_LAZY;
      flags = RTLD_LAZY;
    }
    if ((hints & (YDL_GLOBAL | YDL_LOCAL)) == YDL_GLOBAL) {
      obj->hints |= YDL_GLOBAL;
      flags |= RTLD_GLOBAL;
    } else {
      obj->hints |= YDL_LOCAL;
      flags |= RTLD_LOCAL;
    }
    if ((hints & YDL_RESIDENT) != 0) {
#    ifdef RTLD_NODELETE
      obj->hints |= YDL_RESIDENT;
      flags |= RTLD_NODELETE;
#    else
      y_error("flag DL_RESIDENT not supported on this implementation");
#    endif
    }
    if ((hints & YDL_DEEPBIND) != 0) {
#    ifdef RTLD_DEEPBIND
      obj->hints |=  YDL_DEEPBIND;
      flags |= RTLD_DEEPBIND;
#    else
      y_error("flag DL_DEEPBIND not supported on this implementation");
#    endif
    }
    if ((hints & YDL_EXTENSION) != 0) {
      y_error("flag DL_REXTENSION not supported on this implementation");
    }
    if ((hints & YDL_PRELOAD) != 0) {
      y_error("flag DL_PRELOAD not supported on this implementation");
    }
    obj->handle = dlopen(obj->path, flags);
    if (obj->handle == NULL) {
      msg = dlerror();
      if (msg == NULL) msg = "failed to open dynamic library (unknown reason)";
      y_error(msg);
    }
  }
#else
  obj->handle = p_dlopen(obj->path);
  if (obj->handle == NULL) {
    msg = "failed to open dynamic module \"%s\"";
    y_errorq(msg, obj->path);
  }
#endif
}

void Y_dlsym(int argc)
{
  ydl_instance_t *obj;
  const char *symbol;
  void *ptr;

  if (argc != 2) ERROR("bad number of arguments");
  obj = GET_OBJ(ydl_instance_t, ydl_class, 1);
  symbol = ygets_q(0);
  ptr = MY_DLSYM(obj->handle, symbol);
  ypush_long((long)ptr);
}

/*-----------------------------------------------------------------------------
** Public Functions
** ================
*/

int ydl_check(int iarg)
{
  return (yget_obj(iarg, NULL) == (void *)ydl_class.type_name);
}

void *ydl_get(int iarg)
{
  return yget_obj(iarg, &ydl_class);
}

const char *ydl_path(int iarg)
{
  ydl_instance_t *obj = (ydl_instance_t *)yget_obj(iarg, &ydl_class);
  return obj->path;
}

unsigned int ydl_hints(int iarg)
{
  ydl_instance_t *obj = (ydl_instance_t *)yget_obj(iarg, &ydl_class);
  return obj->hints;
}

void *ydl_find(int iarg, const char *symbol)
{
  ydl_instance_t *obj = yget_obj(iarg, &ydl_class);
  return MY_DLSYM(obj->handle, symbol);
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
