- [ ] Allow compilation of different plugins with different implementations.
   For instance:
    - `dlwrap-ffcall-play.${DLL}`  for FFCALL + PLAY;
    - `dlwrap-ffcall-dl.${DLL}`    for FFCALL + system DL;
    - `dlwrap-ffcall-ltdl.${DLL}`  for FFCALL + GNU Libtool;

- [ ] Try other dynamic function calling system like LIBFFI (fix the `SIGFPE`
   issue), CINVOKE, etc.

   To dynamically call compiled functions, I have tried to use
   [LIBFFI](http://sourceware.org/libffi) but `ffi_prep_cif()` raises a
   `SIGFPE` (perhaps it lefts some dirt in the floating-point registers)
   which interrupts Yorick.  I can try using the new `p_fpehandling` in
   Yorick API to temporarily ignore `SIGFPE`.  The advantage of LIBFFI
   would be that it may speedup calling functions (argument parsing can be
   done only once).

- [ ] Implement callback system for object destruction.

- [ ] Hide structure definitions in the SYS object.

- [x] Write a (pseudo) `configure` script to edit the Makefile.

- [ ] For the moment only functions can be obtained, global variables remain inaccessible.

- [ ] Add other *types* to allow for Yorick variables definition:
   `C_INT_OUT`, `C_LONG_OUT`, *etc.* to mean that the argument is the name
   of a Yorick variable set with an int, a long, etc. on return, the called
   function takes a pointer to the corresponding type.

