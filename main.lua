
function List()
local alist, i, item

alist=ffmpeg:get_acodecs("aac ac3 mp1 mp2 mp3 vorbis flac")
for i,item in ipairs(alist)
do
	print(item.name .. " " .. item.description)
end

alist=ffmpeg:get_vcodecs("vp9 mpeg1video mpeg2video mpeg4 webp")
for i,item in ipairs(alist)
do
	print(item.name .. " " .. item.description)
end


end


function ShowSingle(path)
local details, i, item, str

print(path)
details=ffmpeg:analyze(path)
for i, item in ipairs(details.streams)
do
  str="   " ..item.id .. "  " .. item.type .." " .. item.codec
  if item.type == "video" then 
  	if strutil.strlen(item.resolution) then str=str .. " ".. item.resolution end
  	if item.fps ~= nil then str=str .. " ".. item.fps .. "fps " end
  elseif item.type=="audio"
  then
   	if strutil.strlen(item.samplerate) then str=str.. " "..item.samplerate.."Hz" end
  	if item.channels==2 then str=str .. " stereo"
  	else str=str .. " mono"
	end
  end

  print(str)
end
print()

end


function Show(config)
local i, path, details, finfo

for i, path in ipairs(config.inputs)
do
  finfo=filesys.path_info(path)
  if finfo ~= nil and finfo.type=="file" then ShowSingle(path) end
end

end





StdOut=stream.STREAM("stdout:", "w")
path_reformats:defaults()
config=command_line:parse(arg)

if config.action == "show"
then
Show(config)
elseif config.action == "convert"
then
output_formats:setup(config.outformat)
convert:process(config)
elseif config.action == "batch"
then
output_formats:setup(config.outformat)
convert:batch_process(config)
elseif config.action == "formats"
then
output_formats:display()
elseif config.action == "help"
then
command_line:help()
end
