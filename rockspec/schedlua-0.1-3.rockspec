 package = "schedlua"
 version = "0.1-3"

 source = {
    url = "https://github.com/wiladams/schedlua/archive/v0.1-3.tar.gz",
    dir = "schedlua-0.1-3",
 }

 description = {
    summary = "Scheduled cooperative task kernel written in LuaJIT",
    detailed = [[
       LuaJIT based kernel which provides easy cooperative multi-tasking
       environment.  The kernel supports signaling, alarms (sleep, delay, periodic)
       as well as seamless async io without forcing the use of callbacks.

       This is for Linux ONLY!  And requires LuaJIT
    ]],
    homepage = "http://github.com/wiladams/schedlua",
    license = "MIT/X11"
 }
 
 supported_platforms = {"linux"}
  
  dependencies = {
    "lua ~> 5.1"
  }

  build = {
    type = "builtin",

    modules = {
      -- general programming goodness
      ["schedlua.AsyncSocket"] = "schedlua/AsyncSocket.lua",
      ["schedlua.alarm"] = "schedlua/alarm.lua",
      ["schedlua.asyncio"] = "schedlua/asyncio.lua",
      ["schedlua.clock"] = "schedlua/clock.lua",
      ["schedlua.epoll"] = "schedlua/epoll.lua",
      ["schedlua.functor"] = "schedlua/functor.lua",
      ["schedlua.linux"] = "schedlua/linux.lua",
      ["schedlua.linux_errno"] = "schedlua/linux_errno.lua",
      ["schedlua.linux_net"] = "schedlua/linux_net.lua",
      ["schedlua.predicate"] = "schedlua/predicate.lua",
      ["schedlua.queue"] = "schedlua/queue.lua",
      ["schedlua.scheduler"] = "schedlua/scheduler.lua",
      ["schedlua.tabutils"] = "schedlua/tabutils.lua",
      ["schedlua.task"] = "schedlua/task.lua",

    },
 }
