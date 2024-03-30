

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



