package.path = "../?.lua;"..package.path

local queue = require("schedlua.queue")
local tutils = require("schedlua.tabutils")

local q1 = queue();

--print("Q Length (0): ", q1:length())


local t1 = {Priority = 20, name = "1"}
local t2 = {Priority = 50, name = "2"}
local t3 = {Priority = 30, name = "3"}
local t4 = {Priority = 10, name = "4"}
local t5 = {Priority = 10, name = "5"}
local t6 = {Priority = 10, name = "6"}

local function priority_comp( a,b ) 
   return a.Priority < b.Priority 
end

q1:pinsert(t1, priority_comp);
q1:pinsert(t2, priority_comp);
q1:pinsert(t3, priority_comp);
q1:pinsert(t4, priority_comp);
q1:pinsert(t5, priority_comp);
q1:pinsert(t6, priority_comp);


print("Q Length : ", q1.first, q1.last, q1:length())


for entry in q1:Entries() do
    print("Entry: ", entry.Priority, entry.name)
end