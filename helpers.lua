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
