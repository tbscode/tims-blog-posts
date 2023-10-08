---
title: "Simulate secondary webcam on linux"
description: "How to use `ffmpeg` to funnel screen or video data as video input."
date: "2023-10-09T16:56:47+06:00"
featured: false
postOfTheMonth: false
author: "Tim Schupp"
categories: ["Tools"]
tags: ["ffmpeg", "video"]
---

Simulate a webcam even in your deveice doesn't have one!
The video input can even work to simulate video inputs on remote development devices.

You'll need to install and anable `v4l2loopback`.

```bash
sudo apt install v4l2loopback-dkms
sudo modprobe v4l2loopback
```

## Live video from screen

```bash
sudo ffmpeg -f x11grab -r 15 -s 1280x720 -i :1 -vcodec rawvideo -pix_fmt yuv420p -threads 0 -f v4l2 /dev/video2
```

## From Video File


```bash
ffmpeg -re -i <some-video>.mp4 -map 0:v -f v4l2 /dev/video2
```

> Where to go from here? Loop a video of you listen patiently in your zoom meetings? ;)