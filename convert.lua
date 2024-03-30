


convert={
-- ffmpeg -i input.mkv -codec:v libtheora -qscale:v 7 -codec:a libvorbis -qscale:a 5 output.ogv


output_status=function(self, details)
local tdiff, percent, str

 tdiff=time.secs() - details.start
 percent=details.position * 100 / details.duration
 remain=processing_time:remain_time(tdiff, percent)
 str=string.format("\r- %0.2f%%  size:%s  elapsed:%s  remain:%s  eta:%s    ", percent, units_of_measure.to_iec(details.size, 1), processing_time:fmt_time(tdiff), processing_time:fmt_time(remain), time.formatsecs("%H:%M:%S %a %d %Y", time.secs() + remain))
 StdOut:writeln(str)
 StdOut:flush()

end,


read_output=function(self, S)
local str, toks, tok
local tdiff, percent
local details
local errors=""

details=media_details:new()
str=S:multi_readto("\r\n")
while str ~= nil
do
str=strutil.trim(str)

ffmpeg:parse_output(str, details)
if details.duration > 0 then self:output_status(details) end

if string.find(str, "Error") ~= nil then errors=errors .. str .. " " end
if string.find(str, "Unrecognized") ~= nil then errors=errors .. str .. " " end
str=S:multi_readto("\r\n")
end

print(errors)
end,


process_item=function(self, input, output)
local str

if filesys.exists(input) == false
then
	print("ERROR: input file '"..input.."' does not exist")
else
  str=ffmpeg:convert_command(input, output, config)
  print(str)
  ffcmd=stream.STREAM("cmd:"..str, "r +stderr pty")
  self:read_output(ffcmd)
end
end,



process=function(self, config)
self:process_item(config.inputs[1], config.inputs[2])
end,


batch_process=function(self, config)
local i, item, str

for i,item in ipairs(config.inputs)
do
if strutil.strlen(item) > 0
then
str=filesys.filename(item) .. config.container
self:process_item(item, str)
print("")
end
end

end

}



