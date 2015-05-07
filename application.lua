-- Application.lua
if Application_Included then
	return appInstance
end

Application_Included = true;


local Scheduler = require("scheduler")
local Task = require("task")
local Functor = require("functor")

-- scheduler plug-ins
local fwaitForIO = require("waitForIO")




-- IO Functions
function Application.getNextOperationId(self)
	return self.wfio:getNextOperationId();
end

function Application.setMessageQuanta(self, millis)
	return self.wfio:setMessageQuanta(millis);
end

function Application.waitForIO(self, socket, pOverlapped)
	return self.wfio:yield(socket, pOverlapped);
end

function Application.watchForIO(self, handle, param)
	return self.wfio:watchForIOEvents(handle, param)
end

