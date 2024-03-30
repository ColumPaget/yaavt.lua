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
