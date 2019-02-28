# Hardware Video Processing Path, Jan 2019

This project contains an Intelectual Property(IP) that can was a part of my Final Engeenering Project at 
Politechnika Gdanska on the major of Electronics and Telecomunications with a speciality Microelectronics.
IP's functionality is to process video data throgh a hardware device with an FPGA onboard.
IP contains all the means to whilst loaded onto the ML509/XUPV5 development board collect, process and 
properly sent data to a, compliant with the video format, monitor.

It's a version that won't be revised anymore because i have lost access to the dev board.

Alongside core files of the IP included are: .ufc file, Microblaze configuration files and code written in C for MicroBlaze.

This embedded system in completion performs a simply erosion algorithm on a 128x128 pixel matrix. 
Video format is VGA in a 640x480@75Hz resolution.
Input and output video codecs are properly programmed through I2C bus.
Data is stored in an internal BRAM.

