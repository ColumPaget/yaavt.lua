--[[

    analog NTSC compatible: 352×240 (240p)
    analog PAL/SECAM compatible: 352×288 (288p)

At a display rate of 25 frames per second, interlaced or progressive scan (commonly used in regions with 50 Hz image scanning frequency, compatible with analog 625-line PAL/SECAM):

    720 × 576 pixels (D-1 resolution, 4:3 fullscreen or 16:9 widescreen aspect ratio)
    704 × 576 pixels (4CIF resolution, 4:3)
    352 × 576 pixels (China Video Disc resolution, 4:3)
    352 × 288 pixels (CIF resolution, 4:3)

At a display rate of 29.97 frames per second, interlaced or progressive scan (commonly used in regions with 60 Hz image scanning frequency, compatible with analog 525-line NTSC):

    720 × 480 pixels (D-1 resolution, 4:3 or 16:9)
    704 × 480 pixels (4SIF resolution, 4:3)
    352 × 480 pixels (China Video Disc resolution, 4:3)
    352 × 240 pixels (SIF resolution, 4:3)
]]--

resolutions={
items={},

add=function(self, name, wide, high)
local reso={}

reso.name=name
reso.width=wide
reso.height=high
table.insert(self.items, reso)
end,


init=function(self)
self.add("1080p HD 16:9", 1920, 1080)
self.add("720p HD 16:9", 1280, 720)
self.add("DVD D1 PAL/SECAM 16:9", 720, 576)
self.add("DVD 4CIF PAL/SECAM 4:3", 704, 576)
self.add("DVD CIF PAL/SECAM 4:3", 352, 288)
self.add("DVD D1 NTSC 16:9", 720, 480)
self.add("DVD 4SIF NTSC 4:3", 704, 480)
self.add("DVD SIF NTSC 4:3", 352, 240)
self.add("576i SVCD PAL/SECAM 4:3", 480, 576)
self.add("480i SVCD NTSC 4:3", 480, 480)
self.add("288p VCD 4:3", 352, 288)
self.add("240p VCD 4:3", 352, 240)
end
}


