/*
 * dlsys.i --
 *
 * Dynamic wrapper around C-library functions for Yorick.
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

require, "dlwrap.i";

func sys_cast(address, type, dimlist)
/* DOCUMENT sys_cast(address, type, dimlist)

     This function returns an array of given type and dimension list extracted
     from ADDRESS (either an integer or a Yorick pointer).  If ADDRESS is an
     integer (e.g.- a long), the caller is responsible for ensuring that the
     data at ADDRESS is valid.

   SEE ALSO: reshape.
 */
{
  local lvalue;
  reshape, lvalue, address, type, dimlist;
  return lvalue;
}


/* ----------------------------------------------------------------------------
** Basic Data Types
** ================
**
** ANSI-C warrants that sizeof(short) >= 2 and sizeof(int) >= 4, hence
** short are used for 16_bit integers and int are used for 32-bit integers.
*/

if (sizeof(char) != 1) {
  error, "expecting that 'char' be an 8-bit integer";
}

if (sizeof(short) == 2) {
  sys_int16_t = short;
} else {
  error, "expecting that 'short' be a 16-bit integer";
}

if (sizeof(int) == 4) {
  sys_int32_t = int;
} else {
  error, "expecting that 'int' be a 32-bit integer";
}

if (sizeof(long) == 8) {
  sys_int64_t = long;
} else {
  write, format = "WARNING - %s\n", "no 64-bit integer";
}

/* ptrdiff_t is the signed integer type of an object that you declare to store
   the result of subtracting two pointers. */
if (sizeof(pointer) == sizeof(long)) {
  sys_ptrdiff_t = long;
} else if (sizeof(pointer) == sizeof(int)) {
  sys_ptrdiff_t = int;
} else {
  error, "expecting that 'long' or 'int' have the same size as a 'pointer'";
}

/* There is no unsigned integers in Yorick (except maybe 'char').  For
   building the structures, signed integers will do. */
sys_size_t = sys_ssize_t = sys_address_t = sys_offset_t = sys_ptrdiff_t;
sys_uint8_t = sys_int8_t = char; /* signedness of 'char' is unspecified */
sys_uint16_t = sys_int16_t;
sys_uint32_t = sys_int32_t;
sys_uint64_t = sys_int64_t;
sys_socklen_t = sys_uint32_t; /* socklen_t is the data type to store the
                                 length of a sockaddr structure it is an
                                 unsigned 32-bit integer */

/* ----------------------------------------------------------------------------
** Byte Ordering Routines
** ======================
**
** ANSI-C warrants that sizeof(short) >= 2 and sizeof(int) >= 4, hence
** short are used for 16_bit integers and int are used for 32-bit integers.
*/

BYTE_ORDER_LITTLE_ENDIAN = 1n;
BYTE_ORDER_BIG_ENDIAN = 2n;
BYTE_ORDER_SWAP = 3n;
BYTE_ORDER_NATIVE = int(sys_cast(&(BYTE_ORDER_NATIVE = 0x02000001n),
                                 char,sizeof(int))(1));
BYTE_ORDER_NETWORK = BYTE_ORDER_BIG_ENDIAN;

func binary_unpack_int16(buf, offset, order)
{
  if (is_void(order)) {
    order = BYTE_ORDER_NATIVE;
  } else if (order == BYTE_ORDER_SWAP) {
    order = 3n - order;
  }
  byte1 = int(buf(offset + 1));
  byte2 = int(buf(offset + 2));
  if (order == BYTE_ORDER_BIG_ENDIAN) {
    return short(((byte1 << 8) & 0xff00n) | (byte2 & 0x00ffn));
  } else {
    return short(((byte2 << 8) & 0xff00n) | (byte1 & 0x00ffn));
  }
}
func binary_pack_int16(buf, offset, value, order)
{
  if (is_void(order)) {
    order = BYTE_ORDER_NATIVE;
  } else if (order == BYTE_ORDER_SWAP) {
    order = 3 - order;
  }
  value = int(value);
  if (order ==  BYTE_ORDER_BIG_ENDIAN) {
    buf(offset + 1) = ((value >> 8) & 0xffn);
    buf(offset + 2) = ( value       & 0xffn);
  } else {
    buf(offset + 1) = ( value       & 0xffn);
    buf(offset + 2) = ((value >> 8) & 0xffn);
  }
}
func binary_unpack_int32(buf, offset, order)
{
  if (is_void(order)) {
    order = BYTE_ORDER_NATIVE;
  } else if (order == BYTE_ORDER_SWAP) {
    order = 3n - order;
  }
  byte1 = int(buf(offset + 1));
  byte2 = int(buf(offset + 2));
  byte3 = int(buf(offset + 3));
  byte4 = int(buf(offset + 4));
  if (order == BYTE_ORDER_BIG_ENDIAN) {
    return int(((byte1 << 24) & 0xff000000n) | ((byte2 <<  16) & 0x00ff0000n) |
               ((byte3 <<  8) & 0x0000ff00n) | ( byte4         & 0x000000ffn));
  } else {
    return int(((byte4 << 24) & 0xff000000n) | ((byte3 <<  16) & 0x00ff0000n) |
               ((byte2 <<  8) & 0x0000ff00n) | ( byte1         & 0x000000ffn));
  }
}
func binary_pack_int32(buf, offset, value, order)
{
  if (is_void(order)) {
    order = BYTE_ORDER_NATIVE;
  } else if (order == BYTE_ORDER_SWAP) {
    order = 3 - order;
  }
  value = int(value);
  if (order ==  BYTE_ORDER_BIG_ENDIAN) {
    buf(offset + 1) = ((value >> 24) & 0xffn);
    buf(offset + 2) = ((value >> 16) & 0xffn);
    buf(offset + 3) = ((value >>  8) & 0xffn);
    buf(offset + 4) = ( value        & 0xffn);
  } else {
    buf(offset + 1) = ( value        & 0xffn);
    buf(offset + 2) = ((value >>  8) & 0xffn);
    buf(offset + 3) = ((value >> 24) & 0xffn);
    buf(offset + 4) = ((value >> 16) & 0xffn);
  }
}

local swap_int16, swap_int32;
local ntohs, htons, ntohl, htonl;
/* DOCUMENT swap_int16(s)
         or swap_int32(i)
         or htons(s)
         or ntohs(s)
         or htonl(i)
         or ntohl(i)

     Swap bytes or convert between host and network byte orders integer
     values. S is an array of short, I is an array of int (this is not checked
     for efficiency reasons, though conversion is performed).
 */
func swap_int16(value)
{
  value = short(value);
  return (((value << 8) & 0xff00s) | ((value >> 8) & 0x00ffs));
}
func swap_int32(value)
{
  value = int(value);
  return (((value << 24) & 0xff000000n) | ((value <<  8) & 0x00ff0000n) |
          ((value >>  8) & 0x0000ff00n) | ((value >> 24) & 0x000000ffn));
}
if (BYTE_ORDER_BIG_NATIVE == BYTE_ORDER_NETWORK) {
  htons = short;
  htonl = int;
} else {
  htons = swap_int16;
  htonl = swap_int32;
}
ntohs = htons;
ntohl = htonl;

/* ----------------------------------------------------------------------------
** Low-level System Routines
** =========================
**
** ANSI-C warrants that sizeof(short) >= 2 and sizeof(int) >= 4, hence
** short are used for 16_bit integers and int are used for 32-bit integers.
*/

func _sys_link(rt,nm,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15)
/* DOCUMENT  _sys_link, rtype, fname, atype1, atype2, ...
      Private subroutine to add a function wrapper in the global SYS table.
      RTYPE is the return type, FNAME the function name, and ATYPE1, ... the
      type(s) of the arguments of the function.
     
   SEE ALSO: _sys_init, dlwrap.
 */
{
  extern SYS;
  dl = SYS.__handle__;
  if (is_void(a1)) {
    fn = dlwrap(dl,rt,nm);
  } else if (is_void(a2)) {
    fn = dlwrap(dl,rt,nm,a1);
  } else if (is_void(a3)) {
    fn = dlwrap(dl,rt,nm,a1,a2);
  } else if (is_void(a4)) {
    fn = dlwrap(dl,rt,nm,a1,a2,a3);
  } else if (is_void(a5)) {
    fn = dlwrap(dl,rt,nm,a1,a2,a3,a4);
  } else if (is_void(a6)) {
    fn = dlwrap(dl,rt,nm,a1,a2,a3,a4,a5);
  } else if (is_void(a7)) {
    fn = dlwrap(dl,rt,nm,a1,a2,a3,a4,a5,a6);
  } else if (is_void(a8)) {
    fn = dlwrap(dl,rt,nm,a1,a2,a3,a4,a5,a6,a7);
  } else if (is_void(a9)) {
    fn = dlwrap(dl,rt,nm,a1,a2,a3,a4,a5,a6,a7,a8);
  } else if (is_void(a10)) {
    fn = dlwrap(dl,rt,nm,a1,a2,a3,a4,a5,a6,a7,a8,a9);
  } else if (is_void(a11)) {
    fn = dlwrap(dl,rt,nm,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10);
  } else if (is_void(a12)) {
    fn = dlwrap(dl,rt,nm,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11);
  } else if (is_void(a13)) {
    fn = dlwrap(dl,rt,nm,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12);
  } else if (is_void(a14)) {
    fn = dlwrap(dl,rt,nm,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13);
  } else if (is_void(a15)) {
    fn = dlwrap(dl,rt,nm,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14);
  } else {
    fn = dlwrap(dl,rt,nm,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15);
  }
  h_set, SYS, nm, fn;
}

func _sys_swallow(..)
/* DOCUMENT _sys_swallow, sn1, sn2, ...;
   
     This private subroutine swallows the definition of the symbols named SN1,
     SN2, etc.  The symbol is removed form the global namespace while its
     definition is stored into hash table SYS.  If a symbol is the name of a
     structure definition, its name is prefixed with "struct_".  For instance:

     struct foo {long index; double value; }
     func bar(x) { return sqrt(x*x + 2.0); }
     _sys_swallow, "foo", "bar";
     info, foo, bar;
     obj = SYS.struct_foo(index = -1; value = 7.2; );
     SYS.bar(obj.value);

   SEE ALSO: _sys_init, dlwrap.
 */
{
  while (more_args()) {
    local __n, __v, __t;
    eq_nocopy, __n, next_arg(); // get the name of the symbol
    __v = symbol_def(__n);      // get the value of the symbol
    __t = identof(__v);         // get the type of the symbol
    /* Store the symbol definition in the global hash table SYS. */
    if (__t == Y_STRUCTDEF && identof(__v()) == Y_STRUCT) {
      h_set, SYS, "struct_" + __n, __v;
    } else {
      h_set, SYS, __n, __v;
    }
    symbol_set, __n, []; // destroy the global definition
  }
}

func _sys_init(nil)
/* DOCUMENT _sys_init;
     This private subroutine initializes the global SYS table.

   SEE ALSO: _sys_init, dlwrap.
 */
{
  extern SYS;
  NULL = sys_address_t(0);
  TRUE = 1n;
  FALSE = 0n;
  SYS = h_new(__handle__ = dlopen(),
              TRUE = TRUE,
              FALSE = FALSE,
              NULL = NULL);

  USE_FILE_OFFSET64 = FALSE;

  /* Some shorcuts. */
  VOID = DL_VOID;
  CHAR = DL_CHAR;
  SHORT = DL_SHORT;
  INT = DL_INT;
  LONG = DL_LONG;
  FLOAT = DL_FLOAT;
  DOUBLE = DL_DOUBLE;
  COMPLEX = DL_COMPLEX;
  STRING = DL_STRING;
  POINTER = DL_POINTER;
  CHAR_ARRAY = DL_CHAR_ARRAY;
  SHORT_ARRAY = DL_SHORT_ARRAY;
  INT_ARRAY = DL_INT_ARRAY;
  LONG_ARRAY = DL_LONG_ARRAY;
  FLOAT_ARRAY = DL_FLOAT_ARRAY;
  DOUBLE_ARRAY = DL_DOUBLE_ARRAY;
  COMPLEX_ARRAY = DL_COMPLEX_ARRAY;
  STRING_ARRAY = DL_STRING_ARRAY;
  POINTER_ARRAY = DL_POINTER_ARRAY;
  FD = INT;     /* data type for a file descriptor */
  SOCKFD = INT; /* data type for a socket descriptor */
  SOCKLEN = dltype(sys_socklen_t); /* data type to store the length of a
                                      sockaddr structure */
  SIZE = dltype(sys_size_t);
  ADDRESS = dltype(sys_address_t);
  WORDSIZE = 8*sizeof(pointer); /* size of a 'word' in bits */
  INT16 = dltype(sys_int16_t);
  INT32 = dltype(sys_int32_t);
  if (! is_void(sys_int64_t)) {
    INT64 = dltype(sys_int64_t);
  }

  _sys_link, ADDRESS, "memcpy", ADDRESS, ADDRESS, SIZE;

  _sys_link, INT,  "open", STRING, INT, INT;
  _sys_link, INT,  "close", INT;
  _sys_link, LONG, "read", INT, POINTER, LONG;
  _sys_link, LONG, "write", INT, POINTER, LONG;

  _sys_link, INT32, "htonl", INT32;
  _sys_link, INT32, "ntohl", INT32;
  _sys_link, INT16, "htons", INT16;
  _sys_link, INT16, "ntohs", INT16;

  _sys_link, INT, "socket", INT, INT, INT;
  _sys_link, INT, "bind", INT, POINTER, LONG;
  _sys_link, INT, "connect", INT, ADDRESS, LONG;
  _sys_link, INT, "accept", INT, ADDRESS, POINTER;
  _sys_link, INT, "listen", INT, INT;
  _sys_link, INT, "shutdown", INT, INT;
  _sys_link, LONG, "send", INT, POINTER, LONG, INT;
  _sys_link, LONG, "recv", INT, POINTER, LONG, INT;
  _sys_link, INT, "getpeername", INT, POINTER, POINTER;
  _sys_link, INT, "getsockname", INT, POINTER, POINTER;

  /* poll - wait for some event on a file descriptor. */
  _sys_link, INT, "poll", POINTER, LONG, INT;
  h_set, SYS,
    POLLIN     = 0x001, /* There is data to read.  */
    POLLPRI    = 0x002, /* There is urgent data to read.  */
    POLLOUT    = 0x004, /* Writing now will not block.  */
    /* These values are defined in XPG4.2.  */
    POLLRDNORM = 0x040, /* Normal data may be read.  */
    POLLRDBAND = 0x080, /* Priority data may be read.  */
    POLLWRNORM = 0x100, /* Writing now will not block.  */
    POLLWRBAND = 0x200, /* Priority data may be written.  */
    /* These are extensions for Linux.  */
    POLLMSG    = 0x400,
    POLLREMOVE = 0x1000,
    POLLRDHUP  = 0x2000,
    /* Event types always implicitly polled for.  These bits need not be set in
       `events', but they will appear in `revents' to indicate the status of
       the file descriptor.  */
    POLLERR    = 0x008, /* Error condition.  */
    POLLHUP    = 0x010, /* Hung up.  */
    POLLNVAL   = 0x020; /* Invalid polling request.  */

  /* lseek - reposition read/write file offset. */
  _sys_link, LONG, "lseek", INT, LONG, INT;
  h_set, SYS,
    SEEK_SET = 0, /* seek relative to beginning of file */
    SEEK_CUR = 1, /* seek relative to current file position */
    SEEK_END = 2; /* seek relative to end of file */

  /* open/fcntl - O_SYNC is only implemented on blocks devices and on files
     located on a few file systems.  */
  h_set, SYS,
    O_ACCMODE  =      0003,
    O_RDONLY   =        00,
    O_WRONLY   =        01,
    O_RDWR     =        02,
    O_CREAT    =      0100,
    O_EXCL     =      0200,
    O_NOCTTY   =      0400,
    O_TRUNC    =     01000,
    O_APPEND   =     02000,
    O_NONBLOCK =     04000,
    O_SYNC     =  04010000,
    O_ASYNC    =    020000;
  h_set, SYS, /* Some aliases. */
    O_NDELAY   = SYS.O_NONBLOCK,
    O_FSYNC    = SYS.O_SYNC;
  h_set, SYS, /* Specific to XOPEN2K8. */
    O_DIRECTORY =  0200000, /* Must be a directory.  */
    O_NOFOLLOW  =  0400000, /* Do not follow links.  */
    O_CLOEXEC   = 02000000; /* Set close_on_exec.  */
  h_set, SYS, /* GNU extensions. */
    O_DIRECT   =    040000, /* Direct disk access.  */
    O_NOATIME  =  01000000; /* Do not set atime.  */
  h_set, SYS, /* Linux extensions. */
    O_DSYNC    =    010000,  /* Synchronize data.  */
    O_RSYNC    = SYS.O_SYNC,  /* Synchronize read operations.  */
    O_LARGEFILE=   0100000;

  /* Values for the second argument to `fcntl'.  */
  if (WORDSIZE == 64) {
    c32 = c64 = 0;
  } else {
    c64 = 7;
    c32 = (USE_FILE_OFFSET64 ? 0 : c64);
  }
  h_set, SYS,
    F_DUPFD         =    0,       /* Duplicate file descriptor.  */
    F_GETFD         =    1,       /* Get file descriptor flags.  */
    F_SETFD         =    2,       /* Set file descriptor flags.  */
    F_GETFL         =    3,       /* Get file status flags.  */
    F_SETFL         =    4,       /* Set file status flags.  */
    F_GETLK         =    5 + c32, /* Get record locking info.  */
    F_SETLK         =    6 + c32, /* Set record locking info (non-blocking).  */
    F_SETLKW        =    7 + c32, /* Set record locking info (blocking).  */
    F_GETLK64       =    5 + c64, /* Get record locking info.  */
    F_SETLK64       =    6 + c64, /* Set record locking info (non-blocking).  */
    F_SETLKW64      =    7 + c64, /* Set record locking info (blocking).  */
    F_SETOWN        =    8,       /* Get owner (process receiving SIGIO).  */
    F_GETOWN        =    9,       /* Set owner (process receiving SIGIO).  */
    F_SETSIG        =   10,       /* Set number of signal to be sent.  */
    F_GETSIG        =   11,       /* Get number of signal to be sent.  */
    F_SETOWN_EX     =   15,       /* Get owner (thread receiving SIGIO).  */
    F_GETOWN_EX     =   16,       /* Set owner (thread receiving SIGIO).  */
    F_SETLEASE      = 1024,       /* Set a lease.  */
    F_GETLEASE      = 1025,       /* Enquire what lease is active.  */
    F_NOTIFY        = 1026,       /* Request notfications on a directory.  */
    F_DUPFD_CLOEXEC = 1030;       /* Duplicate file descriptor with
                                     close-on-exit set.  */

  /* Types of sockets. */
  h_set, SYS,
    SOCK_STREAM = 1,          /* Sequenced, reliable, connection-based byte
                                 streams. */
    SOCK_DGRAM = 2,           /* Connectionless, unreliable datagrams of fixed
                                 maximum length. */
    SOCK_RAW = 3,             /* Raw protocol interface. */
    SOCK_RDM = 4,             /* Reliably-delivered messages. */
    SOCK_SEQPACKET = 5,       /* Sequenced, reliable, connection-based,
                                 datagrams of fixed maximum length. */
    SOCK_DCCP = 6,            /* Datagram Congestion Control Protocol. */
    SOCK_PACKET = 10,         /* Linux specific way of getting packets at the
                                 dev level.  For writing rarp and other
                                 similar things on the user level. */
    /* Flags to be ORed into the type parameter of socket and socketpair and
       used for the flags parameter of paccept. */
    SOCK_CLOEXEC = 02000000, /* Atomically set close-on-exec flag for the new
                                descriptor(s). */
    SOCK_NONBLOCK = 04000;   /* Atomically mark descriptor(s) as
                                non-blocking. */

  /* Protocol families. */
  h_set, SYS,
    PF_UNSPEC     =  0, /* Unspecified. */
    PF_LOCAL      =  1, /* Local to host (pipes and file-domain). */
    PF_INET       =  2, /* IP protocol family. */
    PF_AX25       =  3, /* Amateur Radio AX.25. */
    PF_IPX        =  4, /* Novell Internet Protocol. */
    PF_APPLETALK  =  5, /* Appletalk DDP. */
    PF_NETROM     =  6, /* Amateur radio NetROM. */
    PF_BRIDGE     =  7, /* Multiprotocol bridge. */
    PF_ATMPVC     =  8, /* ATM PVCs. */
    PF_X25        =  9, /* Reserved for X.25 project. */
    PF_INET6      = 10, /* IP version 6. */
    PF_ROSE       = 11, /* Amateur Radio X.25 PLP. */
    PF_DECnet     = 12, /* Reserved for DECnet project. */
    PF_NETBEUI    = 13, /* Reserved for 802.2LLC project. */
    PF_SECURITY   = 14, /* Security callback pseudo AF. */
    PF_KEY        = 15, /* PF_KEY key management API. */
    PF_NETLINK    = 16,
    PF_PACKET     = 17, /* Packet family. */
    PF_ASH        = 18, /* Ash. */
    PF_ECONET     = 19, /* Acorn Econet. */
    PF_ATMSVC     = 20, /* ATM SVCs. */
    PF_RDS        = 21, /* RDS sockets. */
    PF_SNA        = 22, /* Linux SNA Project */
    PF_IRDA       = 23, /* IRDA sockets. */
    PF_PPPOX      = 24, /* PPPoX sockets. */
    PF_WANPIPE    = 25, /* Wanpipe API sockets. */
    PF_LLC        = 26, /* Linux LLC. */
    PF_CAN        = 29, /* Controller Area Network. */
    PF_TIPC       = 30, /* TIPC sockets. */
    PF_BLUETOOTH  = 31, /* Bluetooth sockets. */
    PF_IUCV       = 32, /* IUCV sockets. */
    PF_RXRPC      = 33, /* RxRPC sockets. */
    PF_ISDN       = 34, /* mISDN sockets. */
    PF_PHONET     = 35, /* Phonet sockets. */
    PF_IEEE802154 = 36; /* IEEE 802.15.4 sockets. */

  /* Address families and aliases for protocols. */
  h_set, SYS,
    PF_UNIX       = SYS.PF_LOCAL,   /* POSIX name for PF_LOCAL. */
    PF_FILE       = SYS.PF_LOCAL,   /* Another non-standard name for
                                       PF_LOCAL. */
    PF_ROUTE      = SYS.PF_NETLINK, /* Alias to emulate 4.4BSD. */
    AF_UNSPEC     = SYS.PF_UNSPEC,
    AF_LOCAL      = SYS.PF_LOCAL,
    AF_UNIX       = SYS.PF_UNIX,
    AF_FILE       = SYS.PF_FILE,
    AF_INET       = SYS.PF_INET,
    AF_AX25       = SYS.PF_AX25,
    AF_IPX        = SYS.PF_IPX,
    AF_APPLETALK  = SYS.PF_APPLETALK,
    AF_NETROM     = SYS.PF_NETROM,
    AF_BRIDGE     = SYS.PF_BRIDGE,
    AF_ATMPVC     = SYS.PF_ATMPVC,
    AF_X25        = SYS.PF_X25,
    AF_INET6      = SYS.PF_INET6,
    AF_ROSE       = SYS.PF_ROSE,
    AF_DECnet     = SYS.PF_DECnet,
    AF_NETBEUI    = SYS.PF_NETBEUI,
    AF_SECURITY   = SYS.PF_SECURITY,
    AF_KEY        = SYS.PF_KEY,
    AF_NETLINK    = SYS.PF_NETLINK,
    AF_ROUTE      = SYS.PF_ROUTE,
    AF_PACKET     = SYS.PF_PACKET,
    AF_ASH        = SYS.PF_ASH,
    AF_ECONET     = SYS.PF_ECONET,
    AF_ATMSVC     = SYS.PF_ATMSVC,
    AF_RDS        = SYS.PF_RDS,
    AF_SNA        = SYS.PF_SNA,
    AF_IRDA       = SYS.PF_IRDA,
    AF_PPPOX      = SYS.PF_PPPOX,
    AF_WANPIPE    = SYS.PF_WANPIPE,
    AF_LLC        = SYS.PF_LLC,
    AF_CAN        = SYS.PF_CAN,
    AF_TIPC       = SYS.PF_TIPC,
    AF_BLUETOOTH  = SYS.PF_BLUETOOTH,
    AF_IUCV       = SYS.PF_IUCV,
    AF_RXRPC      = SYS.PF_RXRPC,
    AF_ISDN       = SYS.PF_ISDN,
    AF_PHONET     = SYS.PF_PHONET,
    AF_IEEE802154 = SYS.PF_IEEE802154;

  /* The following constants should be used for the second parameter of
     shutdown. */
  h_set, SYS,
    SHUT_RD   = 0,  /* No more receptions.  */
    SHUT_WR   = 1,  /* No more transmissions.  */
    SHUT_RDWR = 2;  /* No more receptions or transmissions.  */

  /* See definitions in "/usr/include/netdb.h" */
  _sys_link, INT, "getaddrinfo", STRING, STRING, POINTER, POINTER;
  _sys_link, VOID, "freeaddrinfo", ADDRESS;
  _sys_link, STRING, "gai_strerror", INT;
  _sys_link, INT, "getnameinfo", POINTER, SOCKLEN, POINTER, SIZE,
    POINTER, SIZE, INT;

  /* Possible values for `ai_flags' field in `addrinfo' structure.  */
  h_set, SYS,
    AI_PASSIVE     = 0x0001,  /* Socket address is intended for `bind'.  */
    AI_CANONNAME   = 0x0002,  /* Request for canonical name.  */
    AI_NUMERICHOST = 0x0004,  /* Don't use name resolution.  */
    AI_V4MAPPED    = 0x0008,  /* IPv4 mapped addresses are acceptable.  */
    AI_ALL         = 0x0010,  /* Return IPv4 mapped and IPv6 addresses.  */
    AI_ADDRCONFIG  = 0x0020;  /* Use configuration of this host to choose
                                 returned address type..  */
  /* Possible values for `flags' argument in getnameinfo().  */
  h_set, SYS,
    NI_NUMERICHOST =  1,      /* Don't try to look up hostname.  */
    NI_NUMERICSERV =  2,      /* Don't convert port number to name.  */
    NI_NOFQDN      =  4,      /* Only return nodename portion.  */
    NI_NAMEREQD    =  8,      /* Don't return numeric addresses.  */
    NI_DGRAM       = 16;      /* Look up UDP service rather than TCP.  */

}
if (! is_hash(SYS)) {
  _sys_init;
}

/* Structure used to store address information. */
struct sys_addrinfo {
  int     ai_flags;
  int     ai_family;
  int     ai_socktype;
  int     ai_protocol;
  pointer ai_addr;
  string  ai_canonname;
}
/* This definition correspond to the system storage (see
   "/usr/include/netdb.h"). */
struct sys_raw_addrinfo {
  int           ai_flags;
  int           ai_family;
  int           ai_socktype;
  int           ai_protocol;
  sys_socklen_t ai_addrlen;
  sys_address_t ai_addr;       // really: struct sockaddr *ai_addr;
  sys_address_t ai_canonname;  // really: char            *ai_canonname;
  sys_address_t ai_next;       // really: struct addrinfo *ai_next;
}

func sys_getaddrinfo(node, service, flags=, family=, socktype=, protocol=)
{
  /* Constant to check for a NULL address (must have the correct type, beacause
     HANDLE is passed by address below). */
  NULL = sys_address_t(0);
  
  /* Set hints. */
  if (is_void(flags)) flags = 0;
  if (is_void(family)) family = SYS.AF_UNSPEC;
  if (is_void(socktype)) socktype = 0;
  if (is_void(protocol)) protocol = SYS.PF_UNSPEC;
  // FIXME: hide this structure in the SYS object
  hints = sys_raw_addrinfo(ai_flags = flags,
                           ai_family = family,
                           ai_socktype = socktype,
                           ai_protocol = protocol);

  /* Initialize buffers and local variables. */
  handle = NULL; // to store the address of the result
  addrinfo = [];
  entry = sys_raw_addrinfo();
  entry_ptr = &entry;
  entry_size = sizeof(entry);

  /* Query the addresses that match the hints. */
  status = SYS.getaddrinfo(node, service, &hints, &handle);
  if (status != 0) {
    if (handle != NULL) dummy = SYS.freeaddrinfo(handle);
    error, SYS.gai_strerror(staut);
  }
  if (handle != NULL) {
    address = handle;
    while (address != NULL) {
      //entry = dlwrap_fetch(address, sys_raw_addrinfo);
      dlwrap_memcpy, entry_ptr, address, entry_size;
      if ((ai_addr = entry.ai_addr) != NULL &&
          (ai_addrlen = entry.ai_addrlen) > 0) {
        ai_addr_ptr = &array(char, ai_addrlen);
        dlwrap_memcpy, ai_addr_ptr, ai_addr, ai_addrlen;
      } else {
        addr = [];
      }
      grow, addrinfo,
        sys_addrinfo(ai_flags = entry.ai_flags,
                     ai_family = entry.ai_family,
                     ai_socktype = entry.ai_socktype,
                     ai_protocol = entry.ai_protocol,
                     ai_addr = ai_addr_ptr,
                     ai_canonname = dlwrap_strcpy(entry.ai_canonname));
      address = entry.ai_next;
    }
    dummy = SYS.freeaddrinfo(handle);

    /* Unpack addresses.  This is done afterward to minimize the risk
       of interrupts between the calls to SYS.getaddrinfo() and
       SYS.freeaddrinfo() which would left allocated ressources. */
    n = numberof(addrinfo);
    for (k = 1; k <= n; ++k) {
      addrinfo(k).ai_addr = &_sys_unpack_sockaddr(*addrinfo(k).ai_addr);
    }
  }
  return addrinfo;
}

func sys_getnameinfo(sockaddr, &host, &serv, flags=)
{
  if (is_void(flags)) flags = 0;
  host = array(data, 1024);
  serv = array(data, 256);
  status = SYS.getnameinfo(&sockaddr, sizeof(sockaddr),
                           &host, sizeof(host),
                           &serv, sizeof(serv), flags);
  if (status == 0) {
    host = dlwrap_strcpy(&host);
    serv = dlwrap_strcpy(&serv);
  }
  return status;
}

func sys_open(name, mode, perm)
{
  if (is_void(mode)) mode = SYS.O_RDONLY;
  if (is_void(perm)) perm = 0;
  return SYS.open(name, mode, perm);
}

func sys_close(fd)
{
  return SYS.close(fd);
}

func sys_read(fd, buf, count)
{
  return SYS.read(fd, &buf, (is_void(count) ? sizeof(buf) : count));
}

func sys_write(fd, buf, count)
{
  return SYS.write(fd, &buf, (is_void(count) ? sizeof(buf) : count));
}

func sys_lseek(fd, offset, whence)
{
  return SYS.lseek(fd, offset, (is_void(whence) ? SYS.SEEK_SET : whence));
}

func sys_socket(domain, type, protocol)
{
  return SYS.socket(domain, type, protocol);
}

/* FIXME: provide means to build sockaddr */
func sys_bind(sockfd, sockaddr)
{
  return SYS.bind(sockfd, &sockaddr, sizeof(sockaddr));
}

func sys_connect(sockfd, sockaddr)
{
  return SYS.connect(sockfd, &sockaddr, sizeof(sockaddr));
}

func sys_accept(sockfd, &sockaddr)
{
  buf = array(char, 1024);/* FIXME: depends on socket address familly */
  status = SYS.connect(sockfd, &buf, sizeof(buf));
  if (status == 0) {
    /* FIXME: unpack socket address */
    sockaddr = 0;
  }
  return status;
}

func sys_listen(sockfd, backlog)
{
  return SYS.listen(sockfd, backlog);
}

func sys_shutdown(sockfd, how)
{
  return SYS.shutdown(sockfd, how);
}

func sys_send(sockfd, buf, len, flags)
{
  return SYS.send(sockfd, &buf,
                  (is_void(len) ? sizeof(buf) : len),
                  (is_void(flags) ? 0n : flags));
}

func sys_recv(sockfd, buf, len, flags)
{
  return SYS.recv(sockfd, &buf,
                  (is_void(len) ? sizeof(buf) : len),
                  (is_void(flags) ? 0n : flags));
}

func sys_htonl(i) { return SYS.htonl(i); }
func sys_ntohl(i) { return SYS.ntohl(i); }
func sys_htons(i) { return SYS.htons(i); }
func sys_ntohs(i) { return SYS.ntohs(i); }

/*-----------------------------------------------------------------------------
** Management of socket address types
** ==================================
*/

local sys_getpeername, sys_getsockname;
/* DOCUMENT sys_getpeername(sockfd, sockaddr);
         or sys_getsockname(sockfd, sockaddr);

     getsockname() retrieves the current address to which the socket SOCKFD is
     bound and store it in the variable SOCKADDR.

     getpeername() retrieves the address of the peer connected to the socket
     SOCKFD and store it in the variable SOCKADDR.

     On success, zero is returned.  On error, -1 is returned, and errno is set
     appropriately (see dlwrap_errno).     

  SEE ALSO sys_getaddrinfo, dlwrap_errno.
*/
func sys_getsockname(sockfd, &sockaddr)
{
  return _sys_getsockname_worker(SYS.getsockname);
}
func sys_getpeername(sockfd, &sockaddr)
{
  return _sys_getsockname_worker(SYS.getpeername);
}
func _sys_getsockname_worker(getname)
{
  extern sockaddr, sockfd;
  addrlen = sys_socklen_t(256);
  buffer = array(char, addrlen);
  status = getname(sockfd, &buffer, &addrlen);
  if (status != 0) return status;
  if (addrlen > sizeof(buffer)) {
    buffer = array(char, addrlen);
    status = getname(sockfd, &buffer, &addrlen);
    if (status != 0) return status;
  }  
  sockaddr = _sys_unpack_sockaddr(buffer(1:addrlen));
  return status;
}

struct sys_sockaddr {
  sys_uint16_t sa_family;
  char         sa_data(2046);
}

/* Structure describing an Internet socket address IPv4.
   Defined in "/usr/include/netinet/in.h"  */
struct sys_sockaddr_in {
  sys_uint16_t sin_family;  /* Socket family. */
  sys_uint16_t sin_port;    /* Port number in network byte order.    */
  sys_uint32_t sin_addr;    /* Internet address in network byte order.  */
  char         sin_zero(8);
}
if (sizeof(sys_sockaddr_in) != 16) {
  error, "unexpected size for struct sys_sockaddr_in";
}

/* Ditto, for IPv6.  */
struct sys_sockaddr_in6 {
  sys_uint16_t sin6_family;   /* Socket family. */
  sys_uint16_t sin6_port;     /* Transport layer port #  in network byte order. */
  sys_uint32_t sin6_flowinfo; /* IPv6 flow information */
  char         sin6_addr(16); /* IPv6 address */
  sys_uint32_t sin6_scope_id; /* IPv6 scope-id */
  char         sin6_zero(18);
}
// FIXME: because of alignment, the size is a multiple of 4
if (sizeof(sys_sockaddr_in6) < 46) {
  error, "unexpected size for struct sys_sockaddr_in6";
}
/* Structure describing the address of an AF_LOCAL (aka AF_UNIX) socket.
   Defined in "/usr/include/sys/un.h"  */
struct sys_sockaddr_un {
  sys_uint16_t sun_family;      /* Socket family. */
  char         sun_path(108);   /* Path name.  */
}
if (sizeof(sys_sockaddr_un) != 110) {
  error, "unexpected size for struct sys_sockaddr_un";
}

/* Structures describing the address of an AF_APPLETALK (AppleTalk) socket.  */
struct sys_atalk_addr {
  sys_uint16_t s_net;
  sys_uint8_t  s_node;
};
struct sys_sockaddr_at {
  sys_uint16_t   sat_family;
  sys_uint8_t    sat_port;
  sys_atalk_addr sat_addr;
  char           sat_zero(8);
};

/* Structure describing the address of an AF_IPX (Novell Internet Protocol)
   socket.  */
struct sys_sockaddr_ipx {
  sys_uint16_t sipx_family;
  sys_uint16_t sipx_port;
  sys_uint32_t sipx_network;
  sys_uint8_t  sipx_node(6); // IPX_MODE_LEN
  sys_uint8_t  sipx_type;
  sys_uint8_t  sipx_zero;    // 16 bytes fill
};

func _sys_unpack_sockaddr(data)
{
  /* We cannot use the built-in function 'reshape' here because the size of
     structures may differ (due to alignment constraints) */
  family = dlwrap_fetch(&data, sys_uint16_t);
  if (family == SYS.AF_INET) {
    sockaddr = sys_sockaddr_in();
  } else if (family == SYS.AF_UNIX) {
    sockaddr = sys_sockaddr_un();
 } else if (family == SYS.AF_INET6) {
    sockaddr = sys_sockaddr_in6();
 } else if (family == SYS.AF_IPX) {
    sockaddr = sys_sockaddr_ipx();
 } else if (family == SYS.AF_APPLETALK) {
    sockaddr = sys_sockaddr_at();
  } else {
    error, "unsupported socket address family";
  }
  dlwrap_memcpy, &sockaddr, &data, min(sizeof(sockaddr), sizeof(data));
  return sockaddr;
}
errs2caller,_sys_unpack_sockaddr;

struct sys_pollfd {
  int fd;        /* File descriptor to poll.  */
  short events;  /* Types of events poller cares about.  */
  short revents; /* Types of events that actually occurred.  */
}
func sys_poll(fds, timeout)
{
  if (structof(fds) != sys_pollfd) {
    error, "expecting a sys_pollfd structure";
  }
  return SYS.poll(&fds, numberof(fds), timeout);
}

if (0) {
u = sys_getaddrinfo("localhost", "12285", family = SYS.AF_INET, socktype = SYS.SOCK_STREAM, flags = SYS.AI_CANONNAME);
 u;
 }
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
