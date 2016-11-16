local ffi = require("ffi")

ffi.cdef[[
typedef long ssize_t;

typedef uint32_t in_addr_t;
typedef uint16_t in_port_t;

typedef unsigned short int sa_family_t;
typedef unsigned int socklen_t;

]]


local exports  = {


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
]]

ffi.cdef[[
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


return exports