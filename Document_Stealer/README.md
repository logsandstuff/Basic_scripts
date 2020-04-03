# Quick Usage Guide

1) Flash the rubber ducky with Twin rubber ducky firmware.
2) Copy the three files on this folder to an SD card named "UO_2020" (inject.bin, d.cmd, e.cmd, i.vbs). 
    NOTE: encode your own inject.bin file if you're naming your usb something other than "UO_2020"
3) Put loaded SD card back into the ducky & you're set.

## Changes made to the original
- Payload was optimized and obfuscated. All the target sees is a cmd window open for a fraction of a 
second, the rest happens in the background.
- I had removed the blinking Caps Lock key, but some people might find it useful to know when the ducky
is done copying the documents
- Make sure you use a large enough SD card, I'd recommend 8 gb, but I've tried with much smaller ones
and it works. You just run out of space pretty quickly and it slows things down.

Reference: https://www.hak5.org/blog/main-blog/stealing-files-with-the-usb-rubber-ducky-usb-exfiltration-explained

