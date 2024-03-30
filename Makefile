PREFIX=/usr/local
UNITS=includes.lua helpers.lua media_details.lua reformat_path.lua audio_encoders.lua output_formats.lua command_line.lua processing_time.lua ffmpeg.lua convert.lua main.lua 

yaavt.lua: $(UNITS) 
	cat $(UNITS) > yaavt.lua
	chmod a+x yaavt.lua

install: yaavt.lua
	mkdir -p $(PREFIX)/bin
	cp -f yaavt.lua $(PREFIX)/bin
	mkdir -p $(PREFIX)/man/man1
	cp -f yaavt.lua.1 $(PREFIX)/man/man1/
