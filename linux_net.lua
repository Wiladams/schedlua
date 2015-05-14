local ffi = require("ffi")
local bit = require("bit")
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local Kernel = require("kernel")()
local asyncio = require("asyncio"){Kernel = Kernel, AutoStart=true}
local epoll = require("epoll")
local errnos = require("linux_errno").errnos

local exports = nil;


ffi.cdef[[
typedef long ssize_t;

typedef uint32_t in_addr_t;

typedef uint16_t in_port_t;

typedef unsigned short int sa_family_t;
typedef unsigned int socklen_t;

]]

ffi.cdef[[
struct in_addr {
    in_addr_t       s_addr;
};

struct in6_addr {
  unsigned char  s6_addr[16];
};
]]

ffi.cdef[[
/* Structure describing a generic socket address.  */
struct sockaddr {
  sa_family_t   sa_family;
  char          sa_data[14];
};
]]

ffi.cdef[[
struct sockaddr_in {
  sa_family_t     sin_family;
  in_port_t       sin_port;
  struct in_addr  sin_addr;
    unsigned char sin_zero[sizeof (struct sockaddr) -
      (sizeof (unsigned short int)) -
      sizeof (in_port_t) -
      sizeof (struct in_addr)];
};
]]


ffi.cdef[[
struct sockaddr_in6 {
  uint8_t         sin6_len;
  sa_family_t     sin6_family;
  in_port_t       sin6_port;
  uint32_t        sin6_flowinfo;
  struct in6_addr sin6_addr;
  uint32_t        sin6_scope_id;
};

struct sockaddr_un
{
    sa_family_t sun_family;
    char sun_path[108];
};

struct sockaddr_storage {
//  uint8_t       ss_len;
  sa_family_t   ss_family;
  char          __ss_pad1[6];
  int64_t       __ss_align;
  char          __ss_pad2[128 - 2 - 8 - 6];
};



/* Structure used to manipulate the SO_LINGER option.  */
struct linger
  {
    int l_onoff;		/* Nonzero to linger on close.  */
    int l_linger;		/* Time to linger.  */
  };

struct ethhdr {
  unsigned char   h_dest[6];
  unsigned char   h_source[6];
  unsigned short  h_proto; /* __be16 */
} __attribute__((packed));

struct udphdr {
  uint16_t source;
  uint16_t dest;
  uint16_t len;
  uint16_t check;
};

]]

ffi.cdef[[
int close(int fd);
int fcntl (int __fd, int __cmd, ...);
int ioctl (int __fd, unsigned long int __request, ...);

ssize_t read(int fd, void *buf, size_t count);
ssize_t write(int fd, const void *buf, size_t count);
]]

ffi.cdef[[
int inet_aton (__const char *__cp, struct in_addr *__inp);
char *inet_ntoa (struct in_addr __in);
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
struct addrinfo {
  int     ai_flags;          // AI_PASSIVE, AI_CANONNAME, ...
  int     ai_family;         // AF_xxx
  int     ai_socktype;       // SOCK_xxx
  int     ai_protocol;       // 0 (auto) or IPPROTO_TCP, IPPROTO_UDP 

  socklen_t  ai_addrlen;     // length of ai_addr
  struct sockaddr  *ai_addr; // binary address
  char   *ai_canonname;      // canonical name for nodename
  struct addrinfo  *ai_next; // next structure in linked list
};

int getaddrinfo(const char *nodename, const char *servname,
                const struct addrinfo *hints, struct addrinfo **res);

void freeaddrinfo(struct addrinfo *ai);
]]

local exports  = {
FIONBIO = 0x5421;

INADDR_ANY             = 0x00000000;
INADDR_LOOPBACK        = 0x7f000001;
INADDR_BROADCAST       = 0xffffffff;
INADDR_NONE            = 0xffffffff;

INET_ADDRSTRLEN         = 16;
INET6_ADDRSTRLEN        = 46;

-- Socket Types
SOCK_STREAM     = 1;    -- stream socket
SOCK_DGRAM      = 2;    -- datagram socket
SOCK_RAW        = 3;    -- raw-protocol interface
SOCK_RDM        = 4;    -- reliably-delivered message
SOCK_SEQPACKET  = 5;    -- sequenced packet stream


-- Address families
AF_UNSPEC       = 0;          -- unspecified */
AF_LOCAL		= 1;
AF_UNIX         = 1;            -- local to host (pipes, portals) */
AF_INET         = 2;            -- internetwork: UDP, TCP, etc. */
AF_IMPLINK      = 3;         -- arpanet imp addresses */
AF_PUP          = 4;            -- pup protocols: e.g. BSP */
AF_CHAOS        = 5;           -- mit CHAOS protocols */
AF_IPX          = 6;             -- IPX and SPX */
AF_NS           = 6;              -- XEROX NS protocols */
AF_ISO          = 7;             -- ISO protocols */
AF_OSI          = 7;        -- OSI is ISO */
AF_ECMA         = 8;            -- european computer manufacturers */
AF_DATAKIT      = 9;         -- datakit protocols */
AF_CCITT        = 10;          -- CCITT protocols, X.25 etc */
AF_SNA          = 11;           -- IBM SNA */
AF_DECnet       = 12;         -- DECnet */
AF_DLI          = 13;            -- Direct data link interface */
AF_LAT          = 14;            -- LAT */
AF_HYLINK       = 15;         -- NSC Hyperchannel */
AF_APPLETALK    = 16;      -- AppleTalk */
AF_NETBIOS      = 17;        -- NetBios-style addresses */
AF_VOICEVIEW    = 18;     -- VoiceView */
AF_FIREFOX      = 19;        -- FireFox */
AF_UNKNOWN1     = 20;       -- Somebody is using this! */
AF_BAN          = 21;            -- Banyan */
AF_INET6        = 23;              -- Internetwork Version 6
AF_SIP			= 24;
AF_IRDA         = 26;              -- IrDA
AF_NETDES       = 28;       -- Network Designers OSI & gateway
AF_INET6		= 28;


AF_TCNPROCESS   = 29;
AF_TCNMESSAGE   = 30;
AF_ICLFXBM      = 31;

AF_BTH  = 32;              -- Bluetooth RFCOMM/L2CAP protocols
AF_LINK = 33;
AF_ARP	= 35;
AF_BLUETOOTH	= 36;
AF_MAX  = 37;

--
-- Protocols
--

IPPROTO_IP          = 0;        -- dummy for IP
IPPROTO_ICMP        = 1;        -- control message protocol
IPPROTO_IGMP        = 2;        -- group management protocol
IPPROTO_GGP         = 3;        -- gateway^2 (deprecated)
IPPROTO_TCP         = 6;        -- tcp
IPPROTO_PUP         = 12;       -- pup
IPPROTO_UDP         = 17;       -- user datagram protocol
IPPROTO_IDP         = 22;       -- xns idp
IPPROTO_RDP         = 27;
IPPROTO_IPV6        = 41;       -- IPv6 header
IPPROTO_ROUTING     = 43;       -- IPv6 Routing header
IPPROTO_FRAGMENT    = 44;       -- IPv6 fragmentation header
IPPROTO_ESP         = 50;       -- encapsulating security payload
IPPROTO_AH          = 51;       -- authentication header
IPPROTO_ICMPV6      = 58;       -- ICMPv6
IPPROTO_NONE        = 59;       -- IPv6 no next header
IPPROTO_DSTOPTS     = 60;       -- IPv6 Destination options
IPPROTO_ND          = 77;       -- UNOFFICIAL net disk proto
IPPROTO_ICLFXBM     = 78;
IPPROTO_PIM         = 103;
IPPROTO_PGM         = 113;
--IPPROTO_RM          = IPPROTO_PGM;
IPPROTO_L2TP        = 115;
IPPROTO_SCTP        = 132;


IPPROTO_RAW          =   255;             -- raw IP packet
IPPROTO_MAX          =   256;

-- Possible values for `ai_flags' field in `addrinfo' structure.
AI_PASSIVE              = 0x0001;
AI_CANONNAME            = 0x0002;
AI_NUMERICHOST          = 0x0004;
AI_V4MAPPED             = 0x0008;
AI_ALL                  = 0x0010;
AI_ADDRCONFIG           = 0x0020;
AI_IDN                  = 0x0040;
AI_CANONIDN             = 0x0080;
AI_IDN_ALLOW_UNASSIGNED = 0x0100;
AI_IDN_USE_STD3_ASCII_RULES = 0x0200;
AI_NUMERICSERV          = 0x0400;
}


if ffi.abi("be") then -- nothing to do
    function exports.htonl(b) return b end
    function exports.htons(b) return b end
else
    function exports.htonl(b) return bit.bswap(b) end
    function exports.htons(b) return bit.rshift(bit.bswap(b), 16) end
end
exports.ntohl = exports.htonl -- reverse is the same
exports.ntohs = exports.htons -- reverse is the same


-- Socket level values.
-- To select the IP level.
exports.SOL_IP  = 0;

-- from /usr/include/asm-generic/socket.h
-- For setsockopt(2) 
exports.SOL_SOCKET  = 1;

exports.SO_DEBUG  =1
exports.SO_REUSEADDR  =2
exports.SO_TYPE   =3
exports.SO_ERROR  =4
exports.SO_DONTROUTE  =5
exports.SO_BROADCAST  =6
exports.SO_SNDBUF =7
exports.SO_RCVBUF =8
exports.SO_SNDBUFFORCE  =32
exports.SO_RCVBUFFORCE  =33
exports.SO_KEEPALIVE  =9
exports.SO_OOBINLINE  =10
exports.SO_NO_CHECK =11
exports.SO_PRIORITY =12
exports.SO_LINGER =13
exports.SO_BSDCOMPAT  =14
exports.SO_REUSEPORT  =15
exports.SO_PASSCRED =16
exports.SO_PEERCRED =17
exports.SO_RCVLOWAT =18
exports.SO_SNDLOWAT =19
exports.SO_RCVTIMEO =20
exports.SO_SNDTIMEO =21

exports.SOL_IPV6    = 41;
exports.SOL_ICMPV6  = 58;

exports.SOL_RAW		 = 255;
exports.SOL_DECNET  =    261;
exports.SOL_X25     =    262;
exports.SOL_PACKET  = 263;
exports.SOL_ATM		 = 264;	-- ATM layer (cell level).
exports.SOL_AAL		 = 265;	-- ATM Adaption Layer (packet level).
exports.SOL_IRDA	 = 266;

-- Maximum queue length specifiable by listen.
exports.SOMAXCONN	= 128;


-- for SOL_IP Options
exports.IP_DEFAULT_MULTICAST_TTL     =   1;
exports.IP_DEFAULT_MULTICAST_LOOP    =   1;
exports.IP_MAX_MEMBERSHIPS           =   20;

-- constants should be used for the second parameter of `shutdown'.
exports.SHUT_RD = 0,  -- No more receptions.
exports.SHUT_WR,    -- No more transmissions.
exports.SHUT_RDWR   -- No more receptions or transmissions.


local sockaddr_in = ffi.typeof("struct sockaddr_in");
local sockaddr_in_mt = {
  __new = function(ct, address, port, family)
      family = family or exports.AF_INET;

      local sa = ffi.new(ct)
      sa.sin_family = family;
      sa.sin_port = exports.htons(port)
      if type(address) == "number" then
        addr.sin_addr.s_addr = address;
      elseif type(address) == "string" then
        local inp = ffi.new("struct in_addr")
        local ret = ffi.C.inet_aton (address, inp);
        sa.sin_addr.s_addr = inp.s_addr;
      end

      return sa;
  end;

  __index = {
    setPort = function(self, port)
      self.sin_port = exports.htons(port);
      return self;
    end,
  },

}
ffi.metatype(sockaddr_in, sockaddr_in_mt);
exports.sockaddr_in = sockaddr_in;



-- the filedesc type gives an easy place to hang things
-- related to a file descriptor.  Primarily it keeps the 
-- basic file descriptor.  
-- It also performs the async read/write operations

ffi.cdef[[
typedef struct filedesc_t {
  int fd;
} filedesc;

typedef struct async_ioevent_t {
  struct filedesc_t fdesc;
  int eventKind;
} async_ioevent;
]]

exports.IO_READ = 1;
exports.IO_WRITE = 2;
exports.IO_CONNECT = 3;

local filedesc = ffi.typeof("struct filedesc_t")
local filedesc_mt = {
    __new = function(ct, fd)
        local obj = ffi.new(ct, fd);

        return obj;
    end;

    __gc = function(self)
        if self.fd > -1 then
            self:close();
        end
    end;

    __index = {
        close = function(self)
            ffi.C.close(self.fd);
            self.fd = -1; -- make it invalid
        end,

        read = function(self, buff, bufflen)
            local bytes = tonumber(ffi.C.read(self.fd, buff, bufflen));

            if bytes > 0 then
                return bytes;
            end

            if bytes == 0 then
              return 0;
            end

            return false, ffi.errno();
        end,

        write = function(self, buff, bufflen)
            local bytes = tonumber(ffi.C.write(self.fd, buff, bufflen));

            if bytes > 0 then
                return bytes;
            end

            if bytes == 0 then
              return 0;
            end

            return false, ffi.errno();
        end,

        setNonBlocking = function(self)
            local feature_on = ffi.new("int[1]",1)
            local ret = ffi.C.ioctl(self.fd, exports.FIONBIO, feature_on)
            return ret == 0;
        end,

    };
}
ffi.metatype(filedesc, filedesc_mt);
exports.filedesc = filedesc;





-- the bsdsocket type gives us a garbage collectible
-- place to stick the file descriptor associated with
-- a socket.  Also, the metatable gives a place to 
-- implement fairly esoteric socket related functions.
--[=[
ffi.cdef[[
typedef struct bsdsocket_t
{
  int fd;
} bsdsocket;
]]

local bsdsocket = ffi.typeof("struct bsdsocket_t")
local bsdsocket_mt = {
    __new = function(ct, kind, flags, family)
        kind = kind or exports.SOCK_STREAM;
        family = family or exports.AF_INET
        flags = flags or 0;
        local s = ffi.C.socket(family, kind, flags);
        if s < 0 then
            return nil, ffi.errno();
        end

        local obj = ffi.new(ct, s);

        return obj;
    end;

    __gc = function(self)
        if self.fd > -1 then
            self:close();
        end
    end;

    __index = {
        close = function(self)
            ffi.C.close(self.fd);
            self.fd = -1; -- make it invalid
        end,

        read = function(self, buff, bufflen)
            local bytes = tonumber(ffi.C.read(self.fd, buff, bufflen));

            if bytes > 0 then
                return bytes;
            end

            if bytes == 0 then
              return 0;
            end

            return false, ffi.errno();
        end,

        write = function(self, buff, len)
            local bytes = tonumber(ffi.C.write(self.fd, buff, bufflen));

            if bytes > 0 then
                return bytes;
            end

            if bytes == 0 then
              return 0;
            end

            return false, ffi.errno();
        end,

        setSocketOption = function(self, level, optname, on)
            local feature_on = ffi.new("int[1]")
            if on then feature_on[0] = 1; end
            local ret = ffi.C.setsockopt(self.fd, level, optname, feature_on, ffi.sizeof("int"))
            return ret == 0;
        end,

        setNonBlocking = function(self)
            local FIONBIO=0x5421;
            local feature_on = ffi.new("int[1]",1)
            local ret = ffi.C.ioctl(self.fd, FIONBIO, feature_on)
            return ret == 0;
        end,

        setUseKeepAlive = function(self, on)
            return self:setSocketOption(SOL_SOCKET, SO_KEEPALIVE, on);
        end,

        setReuseAddress = function(self, on)
            return self:setSocketOption(SOL_SOCKET, SO_REUSEADDR, on);
        end,

        getLastError = function(self)
            local retVal = ffi.new("int[1]")
            local retValLen = ffi.new("int[1]", ffi.sizeof("int"))

            local ret = self:getSocketOption(SOL_SOCKET, SO_ERROR, retVal, retValLen)
        end,
    };
}
ffi.metatype(bsdsocket, bsdsocket_mt);
exports.bsdsocket = bsdsocket;



function exports.connect(s, sa)
  local ret = tonumber(ffi.C.connect(s.fd, ffi.cast("struct sockaddr *", sa), ffi.sizeof(sa)));
  if ret ~= 0 then
    return false, ffi.errno();
  end

  return true;
end
--]=]

function exports.globalize()
      for k,v in pairs(exports) do
        _G[k] = v;
      end
end

setmetatable(exports, {
	__call = function(self, params)
		params = params or {}
		if params.exportglobal then
      exports.globalize();
		end
    return self;
	end,
})

return exports
