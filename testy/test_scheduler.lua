--test_scheduler.lua
package.path = package.path..";../?.lua"

Scheduler = require("scheduler")()
Task = require("task")
local taskID = 0;

local function getNewTaskID()
	taskID = taskID + 1;
	return taskID;
end

local function spawn(scheduler, func, ...)
	local task = Task(func, ...)
	task.TaskID = getNewTaskID();
	scheduler:scheduleTask(task, {...});
	
	return task;
end


local function task1()
	print("first task, first line")
	Scheduler:yield();
	print("first task, second line")
end

local function task2()
	print("second task, only line")
end

local function main()
	local t1 = spawn(Scheduler, task1)
	local t2 = spawn(Scheduler, task2)

	while (true) do
		--print("STATUS: ", t1:getStatus(), t2:getStatus())
		if t1:getStatus() == "dead" and t2:getStatus() == "dead" then
			break;
		end
		Scheduler:step()
	end
end

main()


