asyncio
=======

Performing asynchronous IO operations is one of the areas of fundamental
difference between Linux and Windows.  Both platforms allow for the performance
of async IO operations, but they do them slightly differently.

On Linux, there are many mechanisms available, from kernel supported asio routines
to higher level library routines.  The mechanism employed by schedlua is epoll.

With epoll, you essentially query a file descriptor to see if it is ready
for a specified operation to occur without blocking.  For example, if you want
to read from a network socket, you would perform the following operations:

```lua
function AsyncSocket.read(self, buff, bufflen)
    
    local success, err = asyncio:waitForIOEvent(self.fdesc, self.ReadEvent);
    
    --print(string.format("AsyncSocket.read(), after wait: 0x%x %s", success, tostring(err)))

   if not success then
        print("AsyncSocket.read(), FAILED WAITING: ", string.format("0x%x",err))
        return false, err;
    end

 
    local bytesRead = 0;

    if band(success, epoll.EPOLLIN) > 0 then
        bytesRead, err = self.fdesc:read(buff, bufflen);
        --print("async_read(), bytes read: ", bytesRead, err)
    end
    
    return bytesRead, err;
end
```

The first operation is to wait for readiness to read.  Then, assuming it's ready, perform
the read operation on the file descriptor, returning the number of bytes actually read.

Windows takes an almost opposite approach.  Rather than waiting until the file descriptor is ready to be read, you perform the read operation, and wait to be told when
the operation was completed.

```lua
fd:read(buff, bufflen)
waitForCompletion(fd)
```

It's challenging to make these two different paradigms appear the same as an abstraction,
so the approach taken in schedlua is to provide objects that are surfaced from the 
platform specific, and generalize there.  So, there is a nativesocket, nativefiledescriptor, and the like.  Any generalizations will be peformed atop these 
native objects.
