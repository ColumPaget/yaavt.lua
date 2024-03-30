require("stream")
require("strutil")
require("process")
require("filesys")
require("time")
require("net")
require("rawdata")
require("libuseful_errors")
require("units_of_measure")

helpers={

video_encoders={},
audio_encoders={},
audio_decoders={},

add=function(self, list, type, codec, cmd, args)
local item={}

item.codec=codec
item.cmd=cmd
item.args=args

table.insert(self, list, item)
end,


discover=function(self, list, type, codec, exec, args)
local path, item

path=filesys.find(exec, process.getenv("PATH"))
if strutil.strlen(path) > 0
then
	self:add(list, type, codec, path, args)
end

end,


load=function(self)

self:discover(self.audio_encoders, "audio", "ogg", "oggenc", " -o '$(outfile)'")
self:discover(self.audio_encoders, "audio", "mp3", "lame", " - '$(outfile)'" )
self:discover(self.audio_encoders, "audio", "speex", "speexenc")
self:discover(self.audio_decoders, "audio", "ogg", "oggenc", " -o '$(outfile)'")
self:discover(self.audio_decoders, "audio", "mp3", "mpg123", " '$(infile)' -w -" )


end,



find=function(self, type, codec)
local list, i, item

if type=="audio:decoder" then list=audio_decoders
else list=audio_encoders
end

for i,item in ipairs(list)
do
	if item.codec == codec then return item end
end

end,

construct_cmd=function(self, infmt, outfmt, inpath, outpath)
local decoder, encoder

decoder=self:find("audio:decoder", infmt)
encoder=self:find("audio:encoder", outfmt)

end

}
media_details={

new=function()
local details={}

details.duration=0
details.position=0
details.size=0
details.samplerate=0
details.fps=0
details.start=time.secs()
details.streams={}

return details
end

}

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
audio_encoders={

format_args=function(self, encoder, config)
local str=""
local val

if encoder == "libfdk_aac"
then
	if config.audio_vbr > 0
  then
		 val=Math.floor(config.audio_vbr / 2)
		 str=string.format("-vbr %d", val)
	end
elseif encoder == "aac"
then
	if config.audio_vbr > 0 then str=string.format("-q:a %d", config.audio_vbr) end
elseif encoder == "libvorbis"
then
	if config.audio_vbr > 0 then str=string.format("-q:a %d", config.audio_vbr) end
elseif encoder == "libmp3lame"
then
	val=10 - config.audio_vbr
	if config.audio_vbr > 0 then str=string.format("-q:a %d", val) end
end

return str
end

}


-- Handles a list of known output formats, including which audio and video codecs can be stored in which containers

output_formats={

add=function(self, name, container, vcodec, acodec, novideo, noaudio)
local format={}

if novideo == nil then novideo=false end
if noaudio == nil then noaudio=false end

format.name=name
format.container=container
format.vcodec=vcodec
format.acodec=acodec
format.novideo=novideo
format.noaudio=noaudio

if string.sub(format.container, 1, 1) ~= "." then format.container="." .. format.container end
self.items[name]=format
end,


find=function(self, name)
if strutil.strlen(name) == 0 then return nil end
if string.sub(name, 1, 1) == "." then name=string.sub(name, 2) end
if self.items == nil then self:init() end
return(self.items[name])
end,


setup=function(self, name)
local format

format=self:find(name)
if format ~= nil
then 
  config.container=format.container
  config.vcodec=format.vcodec
  config.acodec=format.acodec
  if format.novideo == true then config.novideo=true end
  if format.noaudio == true then config.noaudio=true end
end

end,


codec_cmp=function(c1, c2)
if c1 == nil then return true end
if c2 == nil then return false end
return c1.name < c2.name 
end,


display=function(self)
local name, item, vcodec, acodec
local sorted={}

if self.items == nil then self:init() end

for name, item in pairs(self.items)
do
table.insert(sorted, item)
end
table.sort(sorted, self.codec_cmp)

for name, item in pairs(sorted)
do
  str=string.format("%-20s %6s %10s %12s", item.name, item.container, item.vcodec, item.acodec)

  vcodec=ffmpeg:get_codec("video", item.vcodec) 
	if vcodec == nil then str=str .. " video codec not available" end

  acodec=ffmpeg:get_codec("audio", item.acodec)
	if acodec == nil then str=str .. " audio codec not available" end

	if config.show_all or (vcodec ~= nil and acodec ~= nil) then print(str) end
end

end,

init=function(self)
self.items={}
self:add("webm", "webm", "vp8", "vorbis")
self:add("webm:vp8:vorbis", "webm", "vp8", "vorbis")
self:add("webm:vp8:opus", "webm", "vp8", "opus")
self:add("webm:vp9:vorbis", "webm", "vp9", "vorbis")
self:add("webm:vp9:opus", "webm", "vp9", "opus")

self:add("avi", "avi", "mpeg4", "mp3")
self:add("avi:ac3", "avi", "mpeg4", "ac3")
self:add("avi:mp3", "avi", "mpeg4", "mp3")
self:add("avi:opus", "avi", "mpeg4", "opus")
self:add("avi:flac", "avi", "mpeg4", "flac")
self:add("avi:alac", "avi", "mpeg4", "alac")

self:add("avi:mp2", "avi", "mp2", "mp3")
self:add("avi:mp2:ac3", "avi", "mp2", "ac3")
self:add("avi:mp2:mp3", "avi", "mp2", "mp3")
self:add("avi:mp2:opus", "avi", "mp2", "opus")
self:add("avi:mp2:flac", "avi", "mp2", "flac")
self:add("avi:mp2:alac", "avi", "mp2", "alac")

self:add("avi:h264", "avi", "h264", "mp3")
self:add("avi:h264:ac3", "avi", "h264", "ac3")
self:add("avi:h264:mp3", "avi", "h264", "mp3")
self:add("avi:h264:opus", "avi", "h264", "opus")
self:add("avi:h264:flac", "avi", "h264", "flac")
self:add("avi:h264:alac", "avi", "h264", "alac")

self:add("avi:h265", "avi", "h265", "mp3")
self:add("avi:h265:ac3", "avi", "h265", "ac3")
self:add("avi:h265:mp3", "avi", "h265", "mp3")
self:add("avi:h265:opus", "avi", "h265", "opus")
self:add("avi:h265:flac", "avi", "h265", "flac")
self:add("avi:h265:alac", "avi", "h265", "alac")

self:add("avi:vp8", "avi", "vp8", "mp3")
self:add("avi:vp8:ac3", "avi", "vp8", "ac3")
self:add("avi:vp8:mp3", "avi", "vp8", "mp3")
self:add("avi:vp8:opus", "avi", "vp8", "opus")
self:add("avi:vp8:flac", "avi", "vp8", "flac")
self:add("avi:vp8:alac", "avi", "vp8", "alac")

self:add("avi:vp9", "avi", "vp9", "mp3")
self:add("avi:vp9:ac3", "avi", "vp9", "ac3")
self:add("avi:vp9:mp3", "avi", "vp9", "mp3")
self:add("avi:vp9:opus", "avi", "vp9", "opus")
self:add("avi:vp9:flac", "avi", "vp9", "flac")
self:add("avi:vp9:alac", "avi", "vp9", "alac")


self:add("mkv", "mkv", "h264", "aac")
self:add("mkv:ac3", "mkv", "h264", "ac3")
self:add("mkv:mp3", "mkv", "h264", "mp3")
self:add("mkv:opus", "mkv", "h264", "opus")
self:add("mkv:flac", "mkv", "h264", "flac")
self:add("mkv:alac", "mkv", "h264", "alac")
self:add("mkv:vorbis", "mkv", "h264", "vorbis")

self:add("mkv:mp2", "mkv", "mp2", "aac")
self:add("mkv:mp2:ac3", "mkv", "mp2", "ac3")
self:add("mkv:mp2:mp3", "mkv", "mp2", "mp3")
self:add("mkv:mp2:opus", "mkv", "mp2", "opus")
self:add("mkv:mp2:flac", "mkv", "mp2", "flac")
self:add("mkv:mp2:alac", "mkv", "mp2", "alac")
self:add("mkv:mp2:vorbis", "mkv", "mp2", "vorbis")

self:add("mkv:mpeg4", "mkv", "mpeg4", "aac")
self:add("mkv:mpeg4:ac3", "mkv", "mpeg4", "ac3")
self:add("mkv:mpeg4:mp3", "mkv", "mpeg4", "mp3")
self:add("mkv:mpeg4:opus", "mkv", "mpeg4", "opus")
self:add("mkv:mpeg4:flac", "mkv", "mpeg4", "flac")
self:add("mkv:mpeg4:alac", "mkv", "mpeg4", "alac")
self:add("mkv:mpeg4:vorbis", "mkv", "mpeg4", "vorbis")

self:add("mkv:hevc", "mkv", "hevc", "aac")
self:add("mkv:hevc:ac3", "mkv", "hevc", "ac3")
self:add("mkv:hevc:mp3", "mkv", "hevc", "mp3")
self:add("mkv:hevc:opus", "mkv", "hevc", "opus")
self:add("mkv:hevc:flac", "mkv", "hevc", "flac")
self:add("mkv:hevc:alac", "mkv", "hevc", "alac")
self:add("mkv:hevc:vorbis", "mkv", "hevc", "vorbis")

self:add("mkv:av1", "mkv", "av1", "aac")
self:add("mkv:av1:ac3", "mkv", "av1", "ac3")
self:add("mkv:av1:mp3", "mkv", "av1", "mp3")
self:add("mkv:av1:opus", "mkv", "av1", "opus")
self:add("mkv:av1:flac", "mkv", "av1", "flac")
self:add("mkv:av1:alac", "mkv", "av1", "alac")
self:add("mkv:av1:vorbis", "mkv", "av1", "vorbis")

self:add("mkv:vp9", "mkv", "vp9", "aac")
self:add("mkv:vp9:ac3", "mkv", "vp9", "ac3")
self:add("mkv:vp9:mp3", "mkv", "vp9", "mp3")
self:add("mkv:vp9:opus", "mkv", "vp9", "opus")
self:add("mkv:vp9:flac", "mkv", "vp9", "flac")
self:add("mkv:vp9:alac", "mkv", "vp9", "alac")
self:add("mkv:vp9:vorbis", "mkv", "vp9", "vorbis")

self:add("mkv:theora", "mkv", "theora", "aac")
self:add("mkv:theora:ac3", "mkv", "theora", "ac3")
self:add("mkv:theora:mp3", "mkv", "theora", "mp3")
self:add("mkv:theora:opus", "mkv", "theora", "opus")
self:add("mkv:theora:flac", "mkv", "theora", "flac")
self:add("mkv:theora:alac", "mkv", "theora", "alac")
self:add("mkv:theora:vorbis", "mkv", "theora", "vorbis")

self:add("mp4", "mp4", "mpeg4", "aac")
self:add("mp4:ac3", "mp4", "mpeg4", "ac3")
self:add("mp4:mp3", "mp4", "mpeg4", "mp3")
self:add("mp4:opus", "mp4", "mpeg4", "opus")
self:add("mp4:flac", "mp4", "mpeg4", "flac")
self:add("mp4:alac", "mp4", "mpeg4", "alac")

self:add("mp4:h264", "mp4", "h264", "aac")
self:add("mp4:h264:ac3", "mp4", "h264", "ac3")
self:add("mp4:h264:mp3", "mp4", "h264", "mp3")
self:add("mp4:h264:opus", "mp4", "h264", "opus")
self:add("mp4:h264:flac", "mp4", "h264", "flac")
self:add("mp4:h264:alac", "mp4", "h264", "alac")

self:add("mp4:hevc", "mp4", "hevc", "aac")
self:add("mp4:hevc:ac3", "mp4", "hevc", "ac3")
self:add("mp4:hevc:mp3", "mp4", "hevc", "mp3")
self:add("mp4:hevc:opus", "mp4", "hevc", "opus")
self:add("mp4:hevc:flac", "mp4", "hevc", "flac")
self:add("mp4:hevc:alac", "mp4", "hevc", "alac")

self:add("mp4:mp2", "mp4", "mp2", "aac")
self:add("mp4:mp2:ac3", "mp4", "mp2", "ac3")
self:add("mp4:mp2:mp3", "mp4", "mp2", "mp3")
self:add("mp4:mp2:opus", "mp4", "mp2", "opus")
self:add("mp4:mp2:flac", "mp4", "mp2", "flac")
self:add("mp4:mp2:alac", "mp4", "mp2", "alac")

self:add("mp4:av1", "mp4", "av1", "aac")
self:add("mp4:av1:ac3", "mp4", "av1", "ac3")
self:add("mp4:av1:mp3", "mp4", "av1", "mp3")
self:add("mp4:av1:opus", "mp4", "av1", "opus")
self:add("mp4:av1:flac", "mp4", "av1", "flac")
self:add("mp4:av1:alac", "mp4", "av1", "alac")

self:add("mp4:vp9", "mp4", "vp9", "aac")
self:add("mp4:vp9:ac3", "mp4", "vp9", "ac3")
self:add("mp4:vp9:mp3", "mp4", "vp9", "mp3")
self:add("mp4:vp9:opus", "mp4", "vp9", "opus")
self:add("mp4:vp9:flac", "mp4", "vp9", "flac")
self:add("mp4:vp9:alac", "mp4", "vp9", "alac")

self:add("mp4:vp8", "mp4", "vp8", "aac")
self:add("mp4:vp8:ac3", "mp4", "vp8", "ac3")
self:add("mp4:vp8:mp3", "mp4", "vp8", "mp3")
self:add("mp4:vp8:opus", "mp4", "vp8", "opus")
self:add("mp4:vp8:flac", "mp4", "vp8", "flac")
self:add("mp4:vp8:alac", "mp4", "vp8", "alac")


self:add("flv", "flv", "flv", "nellymoser")
self:add("flv:aac", "flv", "flv", "aac")
self:add("flv:mp3", "flv", "flv", "mp3")
self:add("flv:speex", "flv", "flv", "speex")
self:add("flv:vp6", "flv", "vp6", "nellymoser")
self:add("flv:vp6:aac", "flv", "vp6", "aac")
self:add("flv:vp6:mp3", "flv", "vp6", "mp3")
self:add("flv:vp6:speex", "flv", "vp6", "speex")

self:add("f4v", "f4v", "h264", "aac")
self:add("f4v:mp3", "f4v", "h264", "mp3")

self:add("ogv", "ogv", "theora", "vorbis")
self:add("ogv:opus", "ogv", "theora", "opus")
self:add("ogg", "ogg", "none", "vorbis")
self:add("ogg:opus", "ogg", "none", "opus")

self:add("flac", "flac", "none", "flac")
self:add("mp3", "mp3", "none", "mp3")
self:add("aac", "aac", "none", "aac")
self:add("m4a", "mp4", "none", "alac", true)
self:add("m4a:aac", "mp4", "none", "aac", true)
self:add("caf", "caf", "none", "alac")
end
}



command_line={

help=function(self)
print("usage:")
print("  yaavt.lua formats [-all]                                 - print list of known output formats")
print("  yaavt.lua show <path> [path] ...                         - print media/codec details of <path>")
print("  yaavt.lua convert [options] <in path> <out path>         - convert file at <in path> writing to <outpath>")
print("  yaavt.lua batch [options] <path> [path] ...              - batch convert a list of file paths")
print("options:")
print("  -f <fmt>              - set output format to use")
print("  -w <width>            - scale video to <width> preseving aspect ratio")
print("  -h <height>           - scale video to <height> preseving aspect ratio")
print("  -s <width>x<height>   - scale video to <width> and <height>")
print("  -mono                 - encode mono audio")
print("  -af <low>:<high>      - filter (select) audio frequencies between <low> and <high> Hz")
print("  -af speech            - filter (select) audio frequencies between 300 and 3000 Hz")
print("  -af speech-tight      - filter (select) audio frequencies between 400 and 1000 Hz")
print("  -af tight             - filter (select) audio frequencies between 200 and 4000 Hz")
print("  -af mid               - filter (select) audio frequencies between  60 and 6000 Hz")
print("  -af wide              - filter (select) audio frequencies between  10 and 8000 Hz")
print("  -vol <percent>        - set volume as a percent of the current volume")
print("  -n                    - normalize volume")
print("  -volnorm              - normalize volume")
print("  -vbr:a <value>        - activate audio variable bit rate")
print("  -q:a <value>          - activate audio variable bit rate")
print("  -threads <n>          - number of threads to run")
print("  -r90                  - rotate video 90 degrees")
print("  -r180                 - rotate video 180 degrees")
print("  -r270                 - rotate video 270 degrees")
print("  -rot90                - rotate video 90 degrees")
print("  -rot180               - rotate video 180 degrees")
print("  -rot270               - rotate video 270 degrees")
print("  -fps <value>          - change video frame rate")
print("  -di                   - deinterlace video")
print("  -novideo              - don't include video in output")
print("  -noaudio              - don't include audio in output")
end,

parse_args=function(self, args, conf)
local i, arg


for i,arg in ipairs(args)
do
  
  if i == 1 
  then 
  -- do nothing
  elseif arg == "-f"
  then 
      conf.outformat=args[i+1]
      args[i+1]=""
  elseif arg == "-w"
  then 
    conf.width=tonumber(args[i+1])
    args[i+1]=""
  elseif arg == "-h"
  then 
    conf.height=tonumber(args[i+1])
    args[i+1]=""
  elseif arg == "-q:a"
  then 
    conf.audio_vbr=tonumber(args[i+1])
    args[i+1]=""
  elseif arg == "-vbr:a"
  then 
    conf.audio_vbr=tonumber(args[i+1])
    args[i+1]=""
  elseif arg == "-af"
  then 
    conf.audio_filter=args[i+1]
    args[i+1]=""
  elseif arg == "-vol"
  then 
    conf.volume=args[i+1]
    args[i+1]=""
  elseif arg == "-fps"
  then 
    conf.fps=args[i+1]
    args[i+1]=""
  elseif arg == "-mono" then conf.audiochannels=1
  elseif arg == "-novideo" then conf.novideo=true
  elseif arg == "-noaudio" then conf.novideo=true
  elseif arg == "-a" then conf.show_all=true
  elseif arg == "-all" then conf.show_all=true
  elseif arg == "-ufast" or arg =="-ultrafast" then conf.encode_speed="ultrafast"
  elseif arg == "-sfast" or arg =="-superfast" then conf.encode_speed="superfast"
  elseif arg == "-vfast" or arg =="-veryfast" then conf.encode_speed="veryfast"
  elseif arg == "-fast" then conf.encode_speed="fast"
  elseif arg == "-slow" then conf.encode_speed="slow"
  elseif arg == "-vslow" or arg =="-veryslow" then conf.encode_speed="slow"
  elseif arg == "-s"
  then 
    toks=strutil.TOKENIZER(args[i+1], "x|.|,", "m")
    conf.width=tonumber(toks:next())
    conf.height=tonumber(toks:next())
    args[i+1]=""
  elseif arg == "-n" or arg == "-volnorm"
  then 
    conf.volnorm=true
  elseif arg == "-t" or arg == "-threads"
  then 
    conf.threads=tonumber(args[i+1])
    args[i+1]=""
  elseif arg == "-r90" then conf.transpose="rot90"
  elseif arg == "-r180" then conf.transpose="rot180"
  elseif arg == "-r270" then conf.transpose="rot270"
  elseif arg == "-rot90" then conf.transpose="rot90"
  elseif arg == "-rot180" then conf.transpose="rot180"
  elseif arg == "-rot270" then conf.transpose="rot270"
  elseif arg == "-di" then conf.deinterlace="yadif"
  elseif strutil.strlen(arg) > 0
  then
    table.insert(conf.inputs, arg)
  end
  
end

end,


postprocess_config=function(self, conf)
local actions={"help", "formats", "convert", "batch"}
local i, item

if conf.action=="-help" then conf.action="help"
elseif conf.action=="--help" then conf.action="help" 
elseif conf.action=="-formats" then conf.action="formats" 
elseif conf.action=="--formats" then conf.action="formats" 
elseif conf.action=="-convert" then conf.action="convert" 
elseif conf.action=="--convert" then conf.action="convert" 
elseif conf.action=="-batch" then conf.action="batch" 
elseif conf.action=="--batch" then conf.action="batch" 
end

for i,item in ipairs(actions)
do
	if conf.action == item then return end
end

if strutil.strlen(conf.action) == 0 then print("No action given on command line")
else print("Unrecognized action: '"..conf.action.."'")
end

print("use \"yaavt.lua --help\" to see usage") 
end,


parse=function(self, args)
local conf={}
local str

conf.inputs={}
conf.action=args[1]
conf.show_all=false
conf.width=0
conf.height=0
conf.threads=0
conf.volnorm=false
conf.novideo=false
conf.noaudio=false
conf.audio_vbr=0

self:parse_args(args, conf)

if conf.action=="convert" 
then

-- in convert mode usage is <options> <infile> <outfile>
if #conf.inputs ~= 2
then
	print("ERROR: 'convert requires input and an output file path, and no other paths")
	os.exit(1)
end

if strutil.strlen(conf.outformat) == 0
then
str=filesys.extn(conf.inputs[2])
if string.sub(str, 1, 1) == '.' then conf.outformat=string.sub(str, 2)
else conf.outformat=str
end

end

end

self:postprocess_config(conf)
return conf
end

}


processing_time={

parse_duration=function(self, str)
local toks, tok
local val=0

toks=strutil.TOKENIZER(str, ":|.", "m")

val = val + tonumber(toks:next()) * 3600
val = val + tonumber(toks:next()) * 60
val = val + tonumber(toks:next())

return val
end,


fmt_time=function(self, time_diff)
local hours, mins, secs

hours=math.floor(time_diff / 3600)
time_diff=time_diff - hours * 3600
mins=math.floor(time_diff / 60)
secs=math.floor(time_diff - mins * 60)

return string.format("%02d:%02d:%02d", hours, mins, secs)
end,

remain_time=function(self, time_diff, percent)
local perc1, full

if (percent==0) then return(0) end
perc1=time_diff / percent
full=perc1 * 100
return(full - time_diff)
end,


fmt_remain_time=function(self, time_diff, percent)
local val

val=self:remain_time(time_diff, percent)
return(self:fmt_time(val))
end

}
--[[
https://trac.ffmpeg.org/wiki/Encode/MP3
https://trac.ffmpeg.org/wiki/Encode/H.264
https://trac.ffmpeg.org/wiki/Encode/VP8
https://trac.ffmpeg.org/wiki/Encode/VP9
https://trac.ffmpeg.org/wiki/Encode/MPEG-4
https://trac.ffmpeg.org/wiki/Encode/YouTube
https://trac.ffmpeg.org/wiki/StreamingGuide
https://slhck.info/video/2017/02/24/vbr-settings.html

Convert an audio file to AAC in an M4A (MP4) container:

ffmpeg -i input.wav -c:a libfdk_aac -vbr 3 output.m4a

From a video file, convert only the audio stream:

ffmpeg -i input.mp4 -c:v copy -c:a libfdk_aac -vbr 3 output.mp4

Convert the video with libx264, and mix down audio to two channels:

ffmpeg -i input.mp4 -c:v libx264 -crf 22 -preset:v veryfast \
-ac 2 -c:a libfdk_aac -vbr 3 output.mp4

 Based on quality produced from high to low:

 libopus > libvorbis >= libfdk_aac > libmp3lame >= eac3/ac3 > aac > libtwolame > vorbis > mp2 > wmav2/wmav1

 The >= sign means greater or the same quality.

Container formats

Only certain audio codecs will be able to fit in your target output file.
Container	Audio formats supported
MKV/MKA	Opus, Vorbis, MP2, MP3, LC-AAC, HE-AAC, WMAv1, WMAv2, AC3, E-AC3, TrueHD
MP4/M4A	Opus, MP2, MP3, LC-AAC, HE-AAC, AC3, E-AC3, TrueHD
FLV/F4V	MP3, LC-AAC, HE-AAC
3GP/3G2	LC-AAC, HE-AAC
MPG	MP2, MP3
PS/TS Stream	MP2, MP3, LC-AAC, HE-AAC, AC3, TrueHD
M2TS	AC3, E-AC3, TrueHD
VOB	MP2, AC3
RMVB	Vorbis, HE-AAC
WebM	Vorbis, Opus
OGG	Vorbis, Opus

There are more container formats available than those listed above, like mxf. Also, E-AC3 is only officially (according to Dolby) supported in mp4 (for example, E-AC3 needs editlist to remove padding of initial 256 silence samples).
Recommended minimum bitrates to use

The bitrates listed here assume 2-channel stereo and a sample rate of 44.1kHz or 48kHz. Mono, speech, and quiet audio may require fewer bits.

    libopus – usable range ≥ 32Kbps. Recommended range ≥ 64Kbps
    libfdk_aac default AAC LC profile – recommended range ≥ 128Kbps; see AAC Encoding Guide.
    libfdk_aac -profile:a aac_he_v2 – usable range ≤ 48Kbps CBR. Transparency: Does not reach transparency. Use AAC LC instead to achieve transparency
    libfdk_aac -profile:a aac_he – usable range ≥ 48Kbps and ≤ 80Kbps CBR. Transparency: Does not reach transparency. Use AAC LC instead to achieve transparency
    libvorbis – usable range ≥ 96Kbps. Recommended range -aq 4 (≥ 128Kbps)
    libmp3lame – usable range ≥ 128Kbps. Recommended range -aq 2 (≥ 192Kbps)
    ac3 or eac3 – usable range ≥ 160Kbps. Recommended range ≥ 160Kbps
    Example of usage:

    ffmpeg -i input.wav -c:a ac3 -b:a 160k output.m4a

    aac – usable range ≥ 32Kbps (depending on profile and audio). Recommended range ≥ 128Kbps
    Example of usage:

    ffmpeg -i input.wav -c:a aac -b:a 128k output.m4a

    libtwolame – usable range ≥ 192Kbps. Recommended range ≥ 256Kbps
    mp2 – usable range ≥ 320Kbps. Recommended range ≥ 320Kbps

The vorbis and wmav1/wmav2 encoders are not worth using.
The wmav1/wmav2 encoder does not reach transparency at any bitrate.
The vorbis encoder does not use the bitrate specified in FFmpeg. On some samples it does sound reasonable, but the bitrate is very high.

To calculate the bitrate to use for multi-channel audio: (bitrate for stereo) x (channels / 2).
Example for 5.1 (6 channels) Vorbis audio: 128Kbps x (6 / 2) = 384Kbps

When compatibility with hardware players doesn't matter then use libopus in a MKV container when libfdk_aac isn't available.

When compatibility with hardware players does matter then use libmp3lame or ac3 in a MP4/MKV container when libfdk_aac isn't available.
Transparency means the encoded audio sounds indistinguishable from the audio in the source file.
Some codecs have a more efficient variable bitrate (VBR) mode which optimizes to a given, constant quality level rather than having variable quality at a given, constant bitrate (CBR). The info above is for CBR. VBR is more efficient than CBR but may not be as hardware-compatible.



Theora/Vorbis Variable Bitrate (VBR)

ffmpeg -i input.mkv -codec:v libtheora -qscale:v 7 -codec:a libvorbis -qscale:a 5 output.ogv

    -qscale:v – video quality. Range is 0–10, where 10 is highest quality. 5–7 is a good range to try. If you omit -qscale:v (or the alias -q:v) then ffmpeg will use the default -b:v 200k which will most likely provide a poor quality output, and libtheora may drop/skip frames if the bitrate is too low.

        -qscale:a – audio quality. Range is -1.0 to 10.0, where 10.0 is highest quality. Default is -q:a 3 with a target of ​112kbps. The formula 16×(q+4) is used below 4, 32×q is used below 8, and 64×(q-4) otherwise. Examples: 112=16×(3+4), 160=32×5, 200=32×6.25, 384=64×(10-4).
]]--


ffmpeg={

parse_stream=function(self, toks, details)
local tok
local prev_tok=""
local item={}

item.type="????"
item.codec="????"

item.id=toks:next()
tok=toks:next()
if tok == "Video:" then item.type="video"
elseif tok == "Audio:" then item.type="audio"
elseif tok == "Subtitle:" then item.type="subtitle"
elseif tok == "Data:" then item.type="data"
end

item.codec=toks:next()

tok=toks:next()
while tok ~= nil
do
if tok=="stereo" then item.channels=2 
elseif tok=="mono" then item.channels=1 
elseif tok=="Hz" then item.samplerate=tonumber(prev_tok)
elseif tok=="fps" then item.fps=tonumber(prev_tok)
elseif string.find(tok, "^%d+x%d+$") ~= nil then item.resolution=tok
end

prev_tok=tok
tok=toks:next()
end

table.insert(details.streams, item)
end,



parse_output=function(self, line, details)
local toks, tok

toks=strutil.TOKENIZER(line, "\\S|,", "m")
tok=toks:next()
while tok ~= nil
do
  if tok == "Duration:" then details.duration=processing_time:parse_duration(toks:next()) 
  elseif tok == "Stream" then self:parse_stream(toks, details) 
  elseif string.sub(tok, 1, 5) == "time=" then details.position=processing_time:parse_duration(string.sub(tok, 6)) 
  elseif string.sub(tok, 1, 5) == "size=" then
	tok=string.sub(tok, 6)
	if strutil.strlen(tok)==0 then tok=toks:next() end
	details.size=units_of_measure.from_iec(tok)
  end
  tok=toks:next()
end

end,


--use ffmpeg to analyze a media file
analyze=function(self, path)
local details, str, S

details=media_details:new()
str="ffmpeg -nostdin -i \""..path.."\" " 
S=stream.STREAM("cmd:"..str, "r +stderr pty")

str=S:multi_readto("\r\n")
while str ~= nil
do
self:parse_output(str, details)
str=S:multi_readto("\r\n")
end

return(details)
end,



get_codecs=function(self, type)
local S, line, str, id, codec, toks
local clist={}

str="cmd:ffmpeg -codecs 2>/dev/null"
S=stream.STREAM(str)
if S ~= nil
then
	line=S:readln()
	while line ~= nil
	do
	line=strutil.trim(line)
	toks=strutil.TOKENIZER(line, " ")

	codec={}
	str=toks:next()

  id=string.sub(str, 3, 3)
	if id=='V' then codec.type="video"
	elseif id=='A' then codec.type="audio"
	end

	if strutil.strlen(codec.type) > 0
	then
	codec.name=toks:next()
	codec.description=toks:remaining()
	clist[codec.name]=codec
	end
	
	line=S:readln()
	end
S:close()
end

return(clist)
end,

load_encoders=function(self, type)
local S, line, str, id, codec, toks
local clist={}

str="cmd:ffmpeg -encoders 2>/dev/null"
S=stream.STREAM(str)
if S ~= nil
then
	line=S:readln()
	while line ~= nil
  do
	line=strutil.trim(line)
	toks=strutil.TOKENIZER(line, " ")

	codec={}
	str=toks:next()

  id=string.sub(str, 1, 1)
	if id=='V' then codec.type="video"
	elseif id=='A' then codec.type="audio"
	end

	if strutil.strlen(codec.type) > 0 and codec.type == type
	then
	codec.name=toks:next()
	codec.description=toks:remaining()
	clist[codec.name]=codec
	end
	
	line=S:readln()
	end
S:close()
end

return(clist)
end,


get_encoders=function(self, type)
if self.vencoders==nil then self.vencoders=self:load_encoders("video") end
if self.aencoders==nil then self.aencoders=self:load_encoders("audio") end

if type == "video" then return self.vencoders end
if type == "audio" then return self.aencoders end
return nil
end,

chosen=function(self, item, choices)
local str

str=choices:first()
if str== nil then return true end
while str ~= nil
do
if item==str then return(true) end
str=choices:next()
end

return false
end,


select_codecs=function(self, type, choices)
local clist 
local slist={}
local toks

toks=strutil.TOKENIZER(choices, " ")
clist=self:get_codecs("audio")
for name,item in pairs(clist)
do
  if item.type==type and self:chosen(item.name, toks) == true then table.insert(slist, item) end
end

return slist
end,


encoders_for_codec=function(self, type, codec_name)

if type=="video"
then
  if codec_name == "mp1" then return {"mpeg1video"}
  elseif codec_name == "mp2" then return {"mpeg2video"}
  elseif codec_name == "mp4" then return {"mpeg4","libxvid,mpeg4_omx"}
  elseif codec_name == "theora" then return {"libtheora"}
  elseif codec_name == "vp8" then return {"libvpx"}
  elseif codec_name == "vp9" then return {"libvpx-vp9"}
  elseif codec_name == "h264" then return {"libx264"}
  elseif codec_name == "h265" then return {"libx265"}
  elseif codec_name == "hevc" then return {"libx265"}
  elseif codec_name == "flv1" then return {"flv"}
  elseif codec_name == "av1" then return {"libaom-av1"}
  end
elseif type=="audio"
then
  if codec_name == "aac" then return {"aac_at", "libfdk_aac", "aac", "aac_fixed"}
  elseif codec_name == "ac3" then return {"ac3","ac3_fixed"}
  elseif codec_name == "ogg" then return {"libvorbis"}
  elseif codec_name == "vorbis" then return {"libvorbis"}
  elseif codec_name == "mp2" then return {"mp2","mp2fixed"}
  elseif codec_name == "mp3" then return {"libmp3lame", "libshine"}
  elseif codec_name == "opus" then return {"libopus","opus"}
  elseif codec_name == "speex" then return {"libspeex"}
	end
end

end,

get_codec=function(self, type, codec_name)
local encoders, candidates, i, name

if codec_name == "none" then return({name="none"}) end

encoders=self:get_encoders(type)
if encoders==nil then return(nil) end

candidates=self:encoders_for_codec(type, codec_name)
if candidates ~= nil
then
  for i,name in ipairs(candidates)
  do
   if encoders[name] ~= nil then return(encoders[name]) end
  end
end

return(encoders[codec_name])
end,


translate_codec=function(self, type, codec_name)
local codec 

codec=self:get_codec(type, codec_name)
if codec ~= nil then return codec.name end
return(codec_name)
end,


get_vcodecs=function(self, choices)
return self:select_codecs("video", choices)
end,


get_acodecs=function(self, choices)
return self:select_codecs("audio", choices)
end,


audio_filter=function(self, filter_config) 
local toks
local str=""

if filter_config == "speech"
then
low=300
high=3000
elseif filter_config == "speech-tight"
then
low=400
high=1000
elseif filter_config == "tight"
then
low=200
high=4000
elseif filter_config == "mid"
then
low=60
high=6000
elseif filter_config == "wide"
then
low=10
high=8000
else
toks=strutil.TOKENIZER(filter_config, ":")
low=toks:next()
high=toks:next()
end


if low ~= nil and high ~= nil
then
-- highpass passes things above the low level and lowpass passes things below the high level
str=" -af 'highpass=f=" .. low .. ", lowpass=f=" .. high..",afftdn=nf=-25' "
end

return str
end,



setup_volume=function(self, volume)
local val

val=tonumber(volume) / 100 * 256

return string.format(" -vol %d", val)
end,



convert_command=function(self, input, output, config)
local str, acodec, vcodec

str="ffmpeg -nostdin -i \""..input.."\" " 

if config.threads > 0 then str=str .. " -threads " .. tostring(config.threads) end

if config.novideo == true then str=str .. " -map 0 -map -0:v" end
if config.noaudio == true then str=str .. " -map 0 -map -0:a" end


if config.fps ~= nil then str=str.." -vf fps=fps="..config.fps end
if config.deinterlace ~= nil then str=str.." -vf "..config.deinterlace end


if config.width > 0
then
	if config.height == 0 then str=str.." -vf scale="..tostring(config.width)..":-2"
	else str=str.." -vf scale="..tostring(config.width)..":"..tostring(config.height)
	end
elseif config.height > 0 then str=str.." -vf scale=-2:" .. tostring(config.height)
end

if config.transpose ~= nil
then
	if config.transpose == "rot90" then str=str.." -vf 'transpose=2'"
	elseif config.transpose == "rot180" then str=str.." -vf 'transpose=2,transpose=2'"
	elseif config.transpose == "rot270" then str=str.." -vf 'transpose=2,transpose=2,transpose=2'"
	end
end


if config.audio_filter ~= nil then str=str .. self:audio_filter(config.audio_filter) end
if config.volume ~= nil then str=str .. self:setup_volume(config.volume) end

if config.loudnorm == true then str=str .. " -af loudnorm " end

if config.threads > 0 then str=str.." -threads " .. tostring(config.threads) end

if config.audiochannels ~= nil then str=str.." -ac " .. tostring(config.audiochannels) end

if strutil.strlen(config.acodec) > 0 and config.acodec ~= "none"
then
acodec=self:translate_codec("audio", config.acodec)
str=str .. " -acodec " .. acodec .. " ".. audio_encoders:format_args(acodec, config)
end

if strutil.strlen(config.vcodec) > 0 and config.vcodec ~= "none"
then 
	vcodec=self:translate_codec("video", config.vcodec)
  str=str .. " -vcodec " .. vcodec
  if vcodec == "libx264" and strutil.strlen(config.encoding_speed) > 0 then str=str.." -preset " .. config.encoding_speed end
end

str=str .. " \"" ..  path_reformats:process(output) .. "\""

return str
end

}






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
