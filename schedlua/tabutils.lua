-- tabutils.lua
local floor = math.floor;
local insert = table.insert;

local function fcomp_default( a,b ) 
   return a < b 
end

local function getIndex(t, value, fcomp)
   local fcomp = fcomp or fcomp_default

   local iStart = 1;
   local iEnd = #t;
   local iMid = 1;
   local iState = 0;

   while iStart <= iEnd do
      -- calculate middle
      iMid = floor( (iStart+iEnd)/2 );
      
      -- compare
      if fcomp( value,t[iMid] ) then
            iEnd = iMid - 1;
            iState = 0;
      else
            iStart = iMid + 1;
            iState = 1;
      end
   end

   return (iMid+iState);
end

local function binsert(tbl, value, fcomp)
   local idx = getIndex(tbl, value, fcomp);
   insert( tbl, idx, value);
   
   return idx;
end


return {
   getIndex = getIndex,
   binsert = binsert,
}
