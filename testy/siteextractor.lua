-- download a .csv file from
-- https://moz.com/top500
-- Then run it through this program.
-- running the extractfromcsv will generate individual
-- lines, each containing the url of a domain
-- this will go to stdout
-- redirect to a file, edit as necessary, typically making a table

local function split(s, sep)
	local sep = sep or "/"
	local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    
    s:gsub(pattern, function(c) fields[#fields+1] = c end)
	
    return fields
end

local function extractfromcsv(filename)
	local filename = "top500.domains.01.14.csv"
	for line in io.lines(filename) do
		local record = split(line, ',')
		local url = record[2]:gsub('/','');

		print(string.format("%s,",url))
	end
end

local function importfromtable(moduleName)
	print("==== importfromtable: ", moduleName)
	
	local sites = require(moduleName)
	
	for _, site in ipairs(sites) do
		print(site)
	end
end


extractfromcsv("top500.domains.01.14.csv")
--importfromtable("sites")
