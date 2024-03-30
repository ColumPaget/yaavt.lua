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
