

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
