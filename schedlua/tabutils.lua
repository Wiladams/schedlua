-- tabutils.lua
--[[
   We have need to maintain a table in a sorted order.  We want to be able
   to insert into and remove values from that table easily.  The couple of
   routines here offer a relatively easy binary search mechanism to maintain 
   table order.

   It's good for a few hundred, or couple thousand entries, so you don't have 
   to resort to a more interesting data structure such as b-tree for small things.
   
   Usage:
   bininsert( tbl, value [, comp] )
   
   Inserts a given value through BinaryInsert into the table sorted by [, comp].
   
   If 'comp' is given, it is a function that is used to compare two values
   in the table.  It must be a function that receives two table elements, 
   and returns true when the first is less than the second, depending on the sort order

   example:
      local function comp(a, b) 
         return a > b 
      end

   will give a sorted table, with the biggest value on position 1.
   
   [, comp] behaves as in table.sort(table, value [, comp])
   
   returns the index where 'value' was inserted
--]]

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
