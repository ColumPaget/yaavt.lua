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



