/*
 * dlwrap.i --
 *
 * Interface for dynamic modules and functions for Yorick.
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

if (is_func(plug_in)) plug_in, "dlwrap";

extern dlopen;
/* DOCUMENT dl = dlopen();
         or dl = dlopen(filename);
         or dl = dlopen(filename, hints);

     This functions open a dynamic module and returns an opaque handle on it.
     FILENAME is the module file name, HINTS is an optional argument to
     specify how to load the module (see dlhints).  The default value for
     HINTS is (DL_LAZY | DL_LOCAL).  If FILENAME is omitted, the code of
     Yorick itself is used (this may not work with all implementations).

     The returned object has members:

       dl.path   gives the path of the module
       dl.hints  gives the value of hints

     You can use dlsym() to figure out whether a particular symbol exists in
     the module and dlwrap() to create wrappers to functions defined in the
     module.

     Call dlvariant() to figure out which implementation is used to load
     dynamic modules.

     There is no dlclose() function: when the dynamic module is no longer in
     use, it gets automatically unloaded (not all implementations can really
     unload a dynamic module).  Yorick variables and function wrappers can set
     a reference to the handle.


   SEE ALSO: dlsym, dlwrap, dlhints, dlvariant.
*/

local dlhints;
local DL_LAZY,DL_NOW,DL_LOCAL,DL_GLOBAL,DL_DEEPBIND,DL_RESIDENT,DL_PRELOAD;
/* DOCUMENT Hints for Loading Dynamic Modules

     The following bitwise hints can be set with dlopen():

       DL_LAZY - Perform lazy binding.  Only resolve symbols as the code that
              references them is executed.  If the symbol is never referenced,
              then it is never resolved.  (Lazy binding is only performed for
              function references; references to variables are always
              immediately bound when the library is loaded.)

       DL_NOW - If this value is specified, or the environment variable
              DL_BIND_NOW is set to a nonempty string, all undefined symbols
              in the module are resolved before dlopen() returns.  If this
              cannot be done, an error is returned.

       DL_LOCAL - Try to keep the loaded module's symbols hidden so that they
              are not visible to subsequently loaded modules.

       DL_GLOBAL - Try to make the loaded module's symbols globally available
              for resolving unresolved symbols in subsequently loaded modules.

       DL_DEEPBIND - Place the lookup scope of the symbols in this library
              ahead of the global scope.  This means that a self-contained
              library will use its own symbols in preference to global symbols
              with the same name contained in libraries that have already been
              loaded.

       DL_RESIDENT - Try to make the loaded module resident in memory, so that
              it cannot be unloaded.

       DL_EXTENSION - Try to append different file name extensions.

       DL_PRELOAD - Load only preloaded modules, so that if a suitable
              preloaded module is not found, dlopen() will fail.

    At most one of DL_LAZY or DL_NOW can be used at the same time (if none is
    set DL_LAZY is assumed).  At most one of DL_LOCAL or DL_GLOBAL can be used
    at the same time (if none is set DL_LOCAL is assumed).

   SEE ALSO: dlopen.
*/
DL_LAZY      = 0x00001;
DL_NOW       = 0x00002;
DL_DEEPBIND  = 0x00008;
DL_LOCAL     = 0x00100;
DL_GLOBAL    = 0x00200;
DL_RESIDENT  = 0x01000;
DL_EXTENSION = 0x02000;
DL_PRELOAD   = 0x04000;

extern dlvariant;
/* DOCUMENT dlvariant();
     This functions returns the name of the implementation used to load
     dynamic modules:
       "play" - Yorick implementation by the Portability LAYer;
       "dl"   - system interface to dynamic linking loader;
       "ltdl" - GNU Libtool library.

   SEE ALSO: dlopen.
*/

extern dlsym;
/* DOCUMENT addr = dlsym(dl, name);
     This functions searches for a symbol in a dynamic module and returns its
     address as a long integer or 0 if not found.  DL is the handle returned
     by dlopen, NAME is the name of the symbol.  The main purpose of this
     function is to check for the existence of a particular symbol in a
     dynamic module.

   SEE ALSO: dlopen, dlwrap.
*/

extern dlwrap;
/* DOCUMENT fn = dlwrap(dl, rtype, name, atype1, atype2, ..., atypeN);

     This functions creates a function-like object that can be called later.
     DL is the handle returned by dlopen, NAME is the name of the function,
     RTYPE is the return type of the function, ATYPE1, ..., ATYPEN are the
     types of the arguments (N can be zero for a function that takes no
     arguments).  The types are specified as integer identifiers (see
     dltype).

     The returned object can be used like a function or like a subroutine:

       res = fn(arg1, ..., argN);
       fn, arg1, ..., argN;

     The number and type of arguments must match the definition of the object
     (though authorized conversions are performed).

     The returned object can be queried for its members:

       fn.module --> the dynamic module;
       fn.symbol --> the name of the symbol;
       fn.nargs  --> the number of expected arguments;
       fn.rtype  --> the identifier of the return type;
       fn.atypes --> the identifiers of the arguments (as a vector of long
                     integer(s); or nil, if there are no arguments).

     To get textual information about the dynamic function object FN, you must
     use info or print built-in functions, e.g.:

       info, fn;

     Yorick warrants that it stores structures in memory like the compiler so
     you can exchange (arrays of) structures consistently between Yorick and a
     module.  However you'll have to use DL_POINTER or DL_POINTER_ARRAY for
     the corresponding argument type and take care of passing the address of
     the structure (&arg).  Of course you'll also have to take care of
     defining a Yorick structure matching its C counterpart.

     As a general rule, prefer to use Yorick to allocate memory for arrays so
     that Yorick will take care of freeing unused data for you.  This does not
     work if the called functions assume the persistency of the data between
     calls.  You may also want to use functions that allocate ressources
     themselves.  Then you'll have to take care yourself of allocationg and
     freeing ressources so do not loose the address of returned objects.

     For instance:

       p_malloc = dlwrap(dlopen(), DL_LONG, "p_malloc", DL_LONG);
       p_free = dlwrap(dlopen(), DL_VOID, "p_free", DL_LONG);

     gives you access to Yorick own memory management functions (pretending
     that the buffer address is a long integer).


   SEE ALSO: dlopen, dlsym, dltype, identof.
*/

local DL_VOID,DL_CHAR,DL_SHORT,DL_INT,DL_LONG,DL_FLOAT,DL_DOUBLE,DL_COMPLEX;
local DL_STRING,DL_POINTER,DL_CHAR_ARRAY,DL_SHORT_ARRAY,DL_INT_ARRAY;
local DL_LONG_ARRAY,DL_FLOAT_ARRAY,DL_DOUBLE_ARRAY,DL_COMPLEX_ARRAY;
local DL_STRING_ARRAY,DL_POINTER_ARRAY;
func dltype(arg, arr)
/* DOCUMENT dltype(arg);
         or dltype(arg, arr);
         
     The function dltype() returns the type identifier suitable for an
     argument prototyped by ARG which can be a Yorick scalar or array or a
     type definition (one of the basic types or a structure).  Optional
     argument ARR can be specified to indicate whether the argument will be an
     array (ARR is true) or a scalar (ARR is false).  If ARR is not specified,
     then the returned argument type is for a scalar if ARG is a scalar or a
     type definition; otherwise, the returned argument type is for an array
     (ARG is a Yorick array with at least one dimension).

     The following table lists the available type constants and their C
     counterparts.  The column "Ret." indicates whether the type can be used
     as a return type for a wrapped function.  For convenience, the type
     constants for scalars are the same as those used by Yorick and returned
     by identof(), these values can have their 5th bit set (bitwise or'ed with
     value 32) to indicate an array of this type.

     +--------------------------------------------+
     | Identifier         C Type    Ret.  Remarks |
     +--------------------------------------------+
     | DL_VOID            void      yes   (a)     |
     | DL_CHAR            char      yes           |
     | DL_SHORT           short     yes           |
     | DL_INT             int       yes           |
     | DL_LONG            long      yes   (b)     |
     | DL_FLOAT           float     yes           |
     | DL_DOUBLE          double    yes           |
     | DL_COMPLEX         complex   yes   (c)     |
     | DL_STRING          char*     yes   (d)     |
     | DL_ADDRESS         void*     yes   (b)     |
     | DL_POINTER         void*     no    (b)     |
     | DL_CHAR_ARRAY      char*     no    (e)     |
     | DL_SHORT_ARRAY     short*    no    (e)     |
     | DL_INT_ARRAY       int*      no    (e)     |
     | DL_LONG_ARRAY      long*     no    (e)     |
     | DL_FLOAT_ARRAY     float*    no    (e)     |
     | DL_DOUBLE_ARRAY    double*   no    (e)     |
     | DL_COMPLEX_ARRAY   double*   no    (e)     |
     | DL_STRING_ARRAY    char**    no    (e)     |
     | DL_POINTER_ARRAY   void**    no    (e)     |
     +--------------------------------------------+

     (a) DL_VOID is only allowed for the return type.  It is sufficient to
         specify no argument types for a function which takes no arguments.         
     (b) DL_ADDRESS and DL_POINTER correspond to a pointer argument for the
         wrapped function but a DL_ADDRESS is mapped as a Yorick integer
         (likely a long) while a DL_POINTER is really a Yorick pointer which
         cannot be used as a returned type.  When using an integer to store an
         address and fake pointers, you'll have to manage the related
         ressources yourself.
     (c) A complex is an array of 2 double's.
     (d) A string is an array of char terminated by a '\0'.
     (e) An array of any dimensionality is stored as a "flat" array by Yorick
         and its length is given, by numberof().  Without the "_ARRAY" suffix,
         a Yorick scalar is meant.

     For convenience and if a corresponding primitive type is found at
     runtime, DL_INT_8, DL_INT_16, DL_INT_32, DL_INT_64 and their *_ARRAY
     counterparts are also defined to represent integer arguments of size 8,
     16, 32 and 64 bits.


   SEE ALSO: dlwrap, identof, numberof, dimsof, array.
*/
{
  ident = identof(arg);
  if (ident <= Y_POINTER) {
    if (is_void(arr)) arr = (! is_scalar(arg));
    return (arr ? (ident | 32) : ident);
  }
  if (ident == Y_STRUCTDEF) {
    if (arg == long)    return (arr ? DL_LONG_ARRAY    : DL_LONG);
    if (arg == int)     return (arr ? DL_INT_ARRAY     : DL_INT);
    if (arg == char)    return (arr ? DL_CHAR_ARRAY    : DL_CHAR);
    if (arg == short)   return (arr ? DL_SHORT_ARRAY   : DL_SHORT);
    if (arg == float)   return (arr ? DL_FLOAT_ARRAY   : DL_FLOAT);
    if (arg == double)  return (arr ? DL_DOUBLE_ARRAY  : DL_DOUBLE);
    if (arg == complex) return (arr ? DL_COMPLEX_ARRAY : DL_COMPLEX);
    if (arg == string)  return (arr ? DL_STRING_ARRAY  : DL_STRING);
    if (arg == pointer) return (arr ? DL_POINTER_ARRAY : DL_POINTER);
  }
  error, "not a primitive type";
}
DL_VOID = identof();
DL_CHAR = identof(char(0));
DL_SHORT = identof(short(0));
DL_INT = identof(int(0));
DL_LONG = identof(long(0));
DL_FLOAT = identof(float(0));
DL_DOUBLE = identof(double(0));
DL_COMPLEX = identof(complex(0));
DL_STRING = identof(string(0));
DL_POINTER = identof(pointer(0));
DL_INT_8 = (sizeof(char) == 1 ? DL_CHAR : []);
DL_INT_16 = (sizeof(short) == 2 ? DL_SHORT : []);
DL_INT_32 = (sizeof(int) == 4 ? DL_INT : (sizeof(long) == 4 ? DL_LONG : []));
DL_INT_64 = (sizeof(long) == 8 ? DL_LONG : (sizeof(int) == 8 ? DL_INT : []));
DL_CHAR_ARRAY = DL_CHAR | 32;
DL_SHORT_ARRAY = DL_SHORT | 32;
DL_INT_ARRAY = DL_INT | 32;
DL_LONG_ARRAY = DL_LONG | 32;
DL_FLOAT_ARRAY = DL_FLOAT | 32;
DL_DOUBLE_ARRAY = DL_DOUBLE | 32;
DL_COMPLEX_ARRAY = DL_COMPLEX | 32;
DL_STRING_ARRAY = DL_STRING | 32;
DL_POINTER_ARRAY = DL_POINTER | 32;
if (! is_void(DL_INT_8)) DL_INT_8_ARRAY = DL_INT_8 | 32;
if (! is_void(DL_INT_16)) DL_INT_16_ARRAY = DL_INT_16 | 32;
if (! is_void(DL_INT_32)) DL_INT_32_ARRAY = DL_INT_32 | 32;
if (! is_void(DL_INT_64)) DL_INT_64_ARRAY = DL_INT_64 | 32;
if (sizeof(pointer) == sizeof(long)) {
  DL_ADDRESS = DL_LONG;
} else if (sizeof(pointer) == sizeof(int)) {
  DL_ADDRESS = DL_INT;
} else {
  error, "expecting that 'long' or 'int' have the same size as a 'pointer'";
}

extern dlwrap_strlen;
extern dlwrap_strcpy;
/* DOCUMENT len = dlwrap_strlen(addr);
         or str = dlwrap_strcpy(addr);
         or dlwrap_strcpy, dst, src;
         or dlwrap_strcpy, dst, src, nmax;

     These functions bypass Yorick's control to deal with strings stored in
     memory.  Addresses are here provided as long scalar integers and, it goes
     without saying, they must be correct (though 0L is a valid address).  For
     these functions to behave correctly, strings must be null terminated
     (last inclusive character is a '\0').

     dlwrap_strlen() returns the length (not counting the terminating '\0') of
     the string starting at address ADDR.

     With a single argument, dlwrap_strcpy() returns a copy of the scalar
     string starting at address ADDR.  This behaviour mimics the semantics of
     the strdup() function in the standard C library except that the result is
     a regular Yorick string.

     With two arguments, dlwrap_strcpy() copies the string starting at address
     SRC to address DST (including the terminating '\0') and returns the
     address DST.

     With tree arguments, dlwrap_strcpy() copies the string starting at
     address SRC to address DST (including the terminating '\0') but no more
     than N bytes and returns the address DST.  This behaviour mimics the
     semantics of the strncpy() function in the standard C library.

  SEE ALSO:
     dlwrap, dlwrap_memcpy, dlwrap_addressof.
*/

extern dlwrap_memcpy;
extern dlwrap_memmove;
/* DOCUMENT dlwrap_memcpy, dst, src, nbytes;
         or dlwrap_memmove, dst, src, nbytes;
     These functions bypass Yorick's control to copy raw binary data.  The
     function dlwrap_memcpy() copies NBYTES bytes from address SRC to address
     DST.  The function dlwrap_memmove() behaves like dlwrap_memcpy() except
     that the memory areas may averlap.  The destination address DST and the
     source address SRC may be specified either as a long integer or as a
     pointer.  In any cases, make sure that the memory is really accessible
     (0L is handled specially); these functions have no means to check for
     you.  When called as functions, these routines return the destination
     address (as a long integer).

   SEE ALSO: dlwrap, dlwrap_strcpy, dlwrap_addressof.
 */

extern dlwrap_addressof;
/* DOCUMENT addr = dlwrap_addressof(arr);

     This function returns the address of array ARR as a long integer.  ARR
     must be an array stored in a variable and not an expression (which may be
     temporary).  The result should be used before the array get destroyed
     (e.g., the variable is undefined or redefined).  This function can be
     used to pass arguments to dlwrap_memcpy or dlwrap_memmove (possibly with
     some offset).

     For instance:
       a = random(15);
       s = sizeof(a(1)); // get the size of one element
       addr = dlwrap_addressof(a);
       dlwrap_memmove, addr + 1*s, addr + 7*s, 2*s;
     will copy 2 elements of A, the 8th and 9th into 2nd and 3rd locations;
     this is same as:
       a(2:3) = a(8:9)

   SEE ALSO: dlwrap, dlwrap_strcpy.
 */

local DL_SWAP_BYTES, DL_BIG_ENDIAN, DL_LITTLE_ENDIAN;
local DL_NATIVE_ORDER, DL_NETWORK_ORDER;
func dlwrap_fetch(address, type, dimlist, order=)
/* DOCUMENT dlwrap_fetch(address, type, dimlist)

     This function returns an array of given type and dimension list extracted
     from ADDRESS (either an integer or a Yorick pointer).  If ADDRESS is an
     integer (e.g.- a long), the caller is responsible for assuring that the
     data at ADDRESS is valid.

     Keyword ORDER can be set to specify the byte order of the source.  If
     this order does not match the byte order of the machine, bytes get
     swapped appropriately.  Possible values for ORDER are:

        DL_BIG_ENDIAN      most significant byte first;
        DL_LITTLE_ENDIAN   least significant byte first;
        DL_SWAP_BYTES      force byte swapping;
        DL_NATIVE_ORDER    the machine byte order;
        DL_NETWORK_ORDER   same as DL_BIG_ENDIAN.

     Note that if ORDER is false (e.g. nil or zero) the machine byte order is
     assumed.

   SEE ALSO: reshape, dlwrap_memcpy.
 */
{
  local lvalue1, lvalue2;
  if (! order || order == DL_NATIVE_ORDER) {
    reshape, lvalue1, address, type, dimlist;
    return lvalue1;
  }
  if (identof(type) == Y_STRUCTDEF &&
      (ident = identof(type(0))) <= Y_COMPLEX) {
    if (ident == Y_COMPLEX) {
      reshape, lvalue1, address, char, sizeof(double), 2, dimlist;
    } else {
      reshape, lvalue1, address, char, sizeof(type), dimlist;
    }
    data = unref(lvalue1)(::-1,..);
    reshape, lvalue2, &data, type, dimlist;
    return lvalue2;
  }
  error, "expecting a primary type (for byte swapping)";
}
DL_LITTLE_ENDIAN = 1n;
DL_BIG_ENDIAN = 2n;
DL_SWAP_BYTES = 3n;
DL_NETWORK_ORDER = DL_BIG_ENDIAN;
DL_NATIVE_ORDER = int(dlwrap_fetch(&(1 | (1 << (8*sizeof(int) - 7))),
                                   char, sizeof(int))(1));
if (DL_NATIVE_ORDER != DL_LITTLE_ENDIAN &&
    DL_NATIVE_ORDER != DL_BIG_ENDIAN) {
  error, "unknown native byte order";
}

extern dlwrap_errno;
extern dlwrap_strerror;
/* DOCUMENT code = dlwrap_errno();
         or dlwrap_strerror(code);
         or dlwrap_strerror();
     These functions deal with system error.  The function dlwrap_errno()
     returns the code of the last system error caused by a dynamic function
     created by dlwrap().  The function dlwrap_strerror() returns a string
     describing an error given its number; or for the last error (caused by a
     wrapped dynamic function), if CODE is omitted.

   SEE ALSO: dlwrap.
 */

/*
 * Local Variables:
 * mode: Yorick
 * tab-width: 8
 * c-basic-offset: 2
 * indent-tabs-mode: nil
 * fill-column: 78
 * coding: utf-8
 * End:
 */
