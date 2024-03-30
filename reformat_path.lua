
path_reformats={
reformats={},


quote=function(self, item)
local str

str=string.gsub(item, "%(", "%%(")
str=string.gsub(item, "%*", "%%*")
str=string.gsub(item, "%+", "%%+")

return str
end,


add=function(self, target, replace)
local qtarget, qreplace

qtarget=self:quote(target)
qreplace=self:quote(replace)
self.reformats[qtarget]=qreplace
end,


nospaces=function(self)
self:add(" ","")
self:add("	","")
end,


spacestounderscore=function(self)
self:add(" ","_")
self:add("	","_")
end,


defaults=function(self)
self:add("%|", "-")
self:add("%/", "-")
self:add("\\", "-")
self:add(" ", "_")
self:add("	", "_")
self:add("!", "")
self:add(",", "")
self:add(";", "")
self:add("`", "")
self:add("'", "")
self:add("%(", "")
self:add("%)", "")
end,



process=function(self, input_path)
local str, item, replace

str=input_path
for item,replace in pairs(self.reformats)
do
	str=string.gsub(str, item, replace)
end

return(str)
end

}
