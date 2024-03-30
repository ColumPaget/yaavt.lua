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
