title: yaavt.lua
mansection: 1
date: 30 March 2024

SYNOPSIS
========

yaavt.lua (Yet Another Audio Video Transcoder) is a lua script that uses ffmpeg to transcode/modify audio and video files.


RUNNING
=======

yaavt.lua is a lua script, so it can be run using `lua yaavt.lua` or by using linux's "binfmt" system to recognize lua scripts.



USAGE
=====

```
  yaavt.lua formats [-all]                                 - print list of known output formats
  yaavt.lua show <path> [path] ...                         - print media/codec details of <path>
  yaavt.lua convert [options] <in path> <out path>         - convert file at <in path> writing to <outpath>
  yaavt.lua batch [options] <path> [path] ...              - batch convert a list of file paths
```



OPTIONS
=======

-f <fmt>
: set output format to use

-w <width>
: scale video to <width> preseving aspect ratio

-h <height>
: scale video to <height> preseving aspect ratio

-s <width>x<height>
: scale video to <width> and <height>

-mono
: encode mono audio

-af <low>:<high>
: filter (select) audio frequencies between <low> and <high> Hz

-af speech
: filter (select) audio frequencies between 300 and 3000 Hz

-af speech-tight
: filter (select) audio frequencies between 400 and 1000 Hz

-af tight
: filter (select) audio frequencies between 200 and 4000 Hz

-af mid
: filter (select) audio frequencies between  60 and 6000 Hz

-af wide
: filter (select) audio frequencies between  10 and 8000 Hz

-vol <percent>
: set volume as a percent of the current volume

-n
: normalize volume

-volnorm
: normalize volume

-vbr:a <value>
: activate audio variable bit rate

-q:a <value>
: activate audio variable bit rate

-threads <n>
: number of threads to run

-r90
: rotate video 90 degrees

-r180
: rotate video 180 degrees

-r270
: rotate video 270 degrees

-rot90
: rotate video 90 degrees

-rot180
: rotate video 180 degrees

-rot270
: rotate video 270 degrees

-fps <value>
: change video frame rate

-di
: deinterlace video

-novideo
: don't include video in output

-noaudio
: don't include audio in output
