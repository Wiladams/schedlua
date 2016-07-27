--linux_ffi.lua

local ffi = require("ffi")

local exports = {}
local C = {}



-- all types passed to syscalls are int or long, 
-- define them here for convenience
local int = ffi.typeof("int")
local uint = ffi.typeof("unsigned int")
local long = ffi.typeof("long")
local ulong = ffi.typeof("unsigned long")

local voidp = ffi.typeof("void *")

local function void(x)
  return ffi.cast(voidp, x)
end

local errno = ffi.errno



ffi.cdef[[
long syscall(int number, ...);
]]

local syscall_long = ffi.C.syscall -- returns long
local function syscall(...) return tonumber(syscall_long(...)) end -- int is default as most common
--local function syscall_uint(...) return uint(syscall_long(...)) end
--local function syscall_void(...) return void(syscall_long(...)) end
--local function syscall_off(...) return u64(syscall_long(...)) end -- off_t

local NR = {
	io_setup = 206;
	io_destroy = 207;
	io_getevents = 208;
	io_submit = 209;
	io_cancel = 210;
}

-- endian dependent
if ffi.abi("le") then
ffi.cdef [[
struct iocb {
  uint64_t   aio_data;
  uint32_t   aio_key, aio_reserved1;
  uint16_t   aio_lio_opcode;
  int16_t    aio_reqprio;
  uint32_t   aio_fildes;
  uint64_t   aio_buf;
  uint64_t   aio_nbytes;
  int64_t    aio_offset;
  uint64_t   aio_reserved2;
  uint32_t   aio_flags;
  uint32_t   aio_resfd;
};
]]
else
ffi.cdef [[
struct iocb {
  // internal to the kernel
  uint64_t   aio_data;
  uint32_t   aio_reserved1, aio_key;

  // common fields
  uint16_t   aio_lio_opcode;
  int16_t    aio_reqprio;
  uint32_t   aio_fildes;
  uint64_t   aio_buf;
  uint64_t   aio_nbytes;
  int64_t    aio_offset;
  uint64_t   aio_reserved2;
  uint32_t   aio_flags;
  uint32_t   aio_resfd;
};
]]
end

ffi.cdef[[
struct io_event {
  uint64_t           data;
  uint64_t           obj;
  int64_t            res;
  int64_t            res2;
};
]]

ffi.cdef[[
typedef unsigned long aio_context_t;

enum {
	IOCB_CMD_PREAD = 0,
	IOCB_CMD_PWRITE = 1,
	IOCB_CMD_FSYNC = 2,
	IOCB_CMD_FDSYNC = 3,
	/* These two are experimental.
	 * IOCB_CMD_PREADX = 4,
	 * IOCB_CMD_POLL = 5,
	 */
	IOCB_CMD_NOOP = 6,
	IOCB_CMD_PREADV = 7,
	IOCB_CMD_PWRITEV = 8,
};
]]

-- native Linux aio not generally supported by libc, only posix API
-- aio routines lifted from ljsyscall

function C.io_setup(nr_events, ctx)
  return syscall(NR.io_setup, uint(nr_events), void(ctx))
end

function C.io_destroy(ctx)
  return syscall(NR.io_destroy, ulong(ctx))
end

function C.io_cancel(ctx, iocb, result)
  return syscall(NR.io_cancel, ulong(ctx), void(iocb), void(result))
end

function C.io_getevents(ctx, min, nr, events, timeout)
  return syscall(NR.io_getevents, ulong(ctx), long(min), long(nr), void(events), void(timeout))
end

function C.io_submit(ctx, iocb, nr)
  return syscall(NR.io_submit, ulong(ctx), long(nr), void(iocb))
end

--[[
function S.io_setup(nr_events)
  local ctx = ffi.new("aio_context[1]");
  local ret, err = C.io_setup(nr_events, ctx)
  if ret == -1 then return nil, t.error(err or errno()) end
  return ctx[0]
end

function S.io_destroy(ctx) return retbool(C.io_destroy(ctx)) end

function S.io_cancel(ctx, iocb, result)
  result = result or t.io_event()
  local ret, err = C.io_cancel(ctx, iocb, result)
  if ret == -1 then return nil, t.error(err or errno()) end
  return result
end

function S.io_getevents(ctx, min, events, timeout)
  if timeout then timeout = mktype(t.timespec, timeout) end
  local ret, err = C.io_getevents(ctx, min or events.count, events.count, events.ev, timeout)
  return retiter(ret, err, events.ev)
end

-- iocb must persist until retrieved (as we get pointer), so cannot be passed as table must take t.iocb_array
function S.io_submit(ctx, iocb)
  return retnum(C.io_submit(ctx, iocb.ptrs, iocb.nr))
end
--]]

exports.O_RDONLY	=   00;
exports.O_WRONLY	=   01;
exports.O_RDWR		=   02;
exports.O_CREAT	  = 0100;


-- File system
ffi.cdef[[
typedef uint32_t mode_t;
typedef uint32_t uid_t;
typedef uint32_t gid_t;
typedef int32_t pid_t;
typedef uint64_t dev_t;


int open(const char *pathname, int flags, mode_t mode);
int close(int fd);
int chdir(const char *path);
int fchdir(int fd);
int mkdir(const char *pathname, mode_t mode);
int rmdir(const char *pathname);
int unlink(const char *pathname);
int rename(const char *oldpath, const char *newpath);
int chmod(const char *path, mode_t mode);
int fchmod(int fd, mode_t mode);
int chown(const char *path, uid_t owner, gid_t group);
int fchown(int fd, uid_t owner, gid_t group);
int lchown(const char *path, uid_t owner, gid_t group);
int link(const char *oldpath, const char *newpath);
int linkat(int olddirfd, const char *oldpath, int newdirfd, const char *newpath, int flags);
int symlink(const char *oldpath, const char *newpath);
int chroot(const char *path);
mode_t umask(mode_t mask);
void sync(void);
int mknod(const char *pathname, mode_t mode, dev_t dev);
int mkfifo(const char *path, mode_t mode);
]]

-- file IO
--[=[
ffi.cdef[[
ssize_t read(int fd, void *buf, size_t count);
ssize_t readv(int fd, const struct iovec *iov, int iovcnt);
ssize_t write(int fd, const void *buf, size_t count);
ssize_t writev(int fd, const struct iovec *iov, int iovcnt);
ssize_t pread(int fd, void *buf, size_t count, off_t offset);
ssize_t pwrite(int fd, const void *buf, size_t count, off_t offset);
ssize_t preadv(int fd, const struct iovec *iov, int iovcnt, off_t offset);
ssize_t pwritev(int fd, const struct iovec *iov, int iovcnt, off_t offset);
int access(const char *pathname, int mode);
off_t lseek(int fd, off_t offset, int whence);
ssize_t readlink(const char *path, char *buf, size_t bufsiz);
int fsync(int fd);
int fdatasync(int fd);
int fcntl(int fd, int cmd, void *arg); /* arg is long or pointer */
int stat(const char *path, struct stat *sb);
int lstat(const char *path, struct stat *sb);
int fstat(int fd, struct stat *sb);
int truncate(const char *path, off_t length);
int ftruncate(int fd, off_t length);
]]
--]=]


ffi.cdef[[
int shm_open(const char *pathname, int flags, mode_t mode);
int shm_unlink(const char *name);
int flock(int fd, int operation);
]]

ffi.cdef[[
int socket(int domain, int type, int protocol);
int socketpair(int domain, int type, int protocol, int sv[2]);
ssize_t recv(int sockfd, void *buf, size_t len, int flags);
ssize_t send(int sockfd, const void *buf, size_t len, int flags);
ssize_t sendto(int sockfd, const void *buf, size_t len, int flags, const struct sockaddr *dest_addr, socklen_t addrlen);
ssize_t recvfrom(int sockfd, void *buf, size_t len, int flags, struct sockaddr *src_addr, socklen_t *addrlen);
ssize_t sendmsg(int sockfd, const struct msghdr *msg, int flags);
ssize_t recvmsg(int sockfd, struct msghdr *msg, int flags);
int getsockopt(int sockfd, int level, int optname, void *optval, socklen_t *optlen);
int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen);
int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
int listen(int sockfd, int backlog);
int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
int accept4(int sockfd, void *addr, socklen_t *addrlen, int flags);
int getsockname(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
int getpeername(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
int shutdown(int sockfd, int how);
int sendmmsg(int sockfd, struct mmsghdr *msgvec, unsigned int vlen, unsigned int flags);
int recvmmsg(int sockfd, struct mmsghdr *msgvec, unsigned int vlen, unsigned int flags, struct timespec *timeout);
]]


ffi.cdef[[
int pipe2(int pipefd[2], int flags);
int dup(int oldfd);
int dup2(int oldfd, int newfd);
int dup3(int oldfd, int newfd, int flags);

int pipe(int pipefd[2]);

int select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, struct timeval *timeout);
int poll(struct pollfd *fds, nfds_t nfds, int timeout);
int pselect(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, const struct timespec *timeout, const sigset_t *sigmask);

int nanosleep(const struct timespec *req, struct timespec *rem);
int getrusage(int who, struct rusage *usage);
int getpriority(int which, int who);
int setpriority(int which, int who, int prio);
]]


ffi.cdef[[
uid_t getuid(void);
uid_t geteuid(void);
pid_t getpid(void);
pid_t getppid(void);
gid_t getgid(void);
gid_t getegid(void);
int setuid(uid_t uid);
int setgid(gid_t gid);
int seteuid(uid_t euid);
int setegid(gid_t egid);
pid_t getsid(pid_t pid);
pid_t setsid(void);
int setpgid(pid_t pid, pid_t pgid);
pid_t getpgid(pid_t pid);
pid_t getpgrp(void);
]]

ffi.cdef[[
pid_t fork(void);
int execve(const char *filename, const char *argv[], const char *envp[]);
void exit(int status);
void _exit(int status);
int sigaction(int signum, const struct sigaction *act, struct sigaction *oldact);
int sigprocmask(int how, const sigset_t *set, sigset_t *oldset);
int sigpending(sigset_t *set);
int sigsuspend(const sigset_t *mask);
int kill(pid_t pid, int sig);

int getgroups(int size, gid_t list[]);
int setgroups(size_t size, const gid_t *list);

int gettimeofday(struct timeval *tv, void *tz);
int settimeofday(const struct timeval *tv, const void *tz);
int getitimer(int which, struct itimerval *curr_value);
int setitimer(int which, const struct itimerval *new_value, struct itimerval *old_value);

int acct(const char *filename);

void *mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
int munmap(void *addr, size_t length);
int msync(void *addr, size_t length, int flags);
int madvise(void *addr, size_t length, int advice);
int mlock(const void *addr, size_t len);
int munlock(const void *addr, size_t len);
int mlockall(int flags);
int munlockall(void);

int openat(int dirfd, const char *pathname, int flags, mode_t mode);
int mkdirat(int dirfd, const char *pathname, mode_t mode);
int unlinkat(int dirfd, const char *pathname, int flags);
int renameat(int olddirfd, const char *oldpath, int newdirfd, const char *newpath);
int fchownat(int dirfd, const char *pathname, uid_t owner, gid_t group, int flags);
int symlinkat(const char *oldpath, int newdirfd, const char *newpath);
int mknodat(int dirfd, const char *pathname, mode_t mode, dev_t dev);
int mkfifoat(int dirfd, const char *pathname, mode_t mode);
int fchmodat(int dirfd, const char *pathname, mode_t mode, int flags);
int readlinkat(int dirfd, const char *pathname, char *buf, size_t bufsiz);
int faccessat(int dirfd, const char *pathname, int mode, int flags);
int fstatat(int dirfd, const char *pathname, struct stat *buf, int flags);

int futimens(int fd, const struct timespec times[2]);
int utimensat(int dirfd, const char *pathname, const struct timespec times[2], int flags);

int lchmod(const char *path, mode_t mode);
int fchroot(int fd);
int utimes(const char *filename, const struct timeval times[2]);
int futimes(int, const struct timeval times[2]);
int lutimes(const char *filename, const struct timeval times[2]);
pid_t wait4(pid_t wpid, int *status, int options, struct rusage *rusage);
int posix_openpt(int oflag);


int getpagesize(void);

int timer_create(clockid_t clockid, struct sigevent *sevp, timer_t *timerid);
int timer_settime(timer_t timerid, int flags, const struct itimerspec *new_value, struct itimerspec * old_value);
int timer_gettime(timer_t timerid, struct itimerspec *curr_value);
int timer_delete(timer_t timerid);
int timer_getoverrun(timer_t timerid);

int adjtime(const struct timeval *delta, struct timeval *olddelta);

int aio_cancel(int, struct aiocb *);
int aio_error(const struct aiocb *);
int aio_fsync(int, struct aiocb *);
int aio_read(struct aiocb *);
int aio_return(struct aiocb *);
int aio_write(struct aiocb *);
int lio_listio(int, struct aiocb *const *, int, struct sigevent *);
int aio_suspend(const struct aiocb *const *, int, const struct timespec *);
int aio_waitcomplete(struct aiocb **, struct timespec *);
]]

return exports
