---
title: "Full Setup Guide: Lenovo Yoga 9 Pro with Regolith Linux (Ubuntu 23.10 + i3)"
description: "A comprehensive setup guide for setting up a Lenovo Yoga 9 Pro with Ubuntu 23.10 and Regolith i3, including resolution and external monitors configuration, and workarounds for common issues."
date: "2024-02-24T16:56:47+06:00"
featured: true
postOfTheMonth: false
author: "Tim Schupp"
categories: ["Linux", "Setup Guide"]
tags: ["Lenovo Yoga 9 Pro", "Ubuntu 23.10", "Regolith Linux", "i3", "System Configuration", "Troubleshooting"]
---

### Full Setup Lenovo Yoga 9 Pro Regolith Linux (Ubuntu 23.10 + i3)

This is my setup guide for Linux on my new laptop. I'm using the newest 23.10 Ubuntu because I want to.
This blog intends to report how I got things set up & the open issues I still have.

> Don't hesitate to contact me if you have possible solutions or questions regarding my setup, cheers :)

## Open Issues:

1. Keyboard backlight levels not working correctly
It goes from bright to medium to bright to out. But medium is also very bright.
2. Master sound level not working (generally sound seems off)
I've also played with a lot of different output options in `pavucontrol`,
some seem to be completely broken and sound super metallic, while others sound pretty good at full volume but then start sounding weird when leveling down the audio.
This is significantly annoying but ok since it can be worked around by leveling the specific output sound level instead of using the volume buttons.

## Initial setup

The laptop comes with Windows originally. So I:

- create a boot USB with Ubuntu 23.10.
- disable BitLocker in PowerShell
- disable hibernation in PowerShell
- in Windows prepare an unformatted partition of the hard drive
- in BIOS disable secure boot
- boot & install Ubuntu 23.10
- install regolith-desktop using package: https://regolith-desktop.com/

## Configuring Regolith

Basic Regolith / i3 looks can be configured in `~/.config/regolith3/Xresources`.
E.g.: I like to adjust gap and border sizes & colors:

```
wm.gaps.inner.size: 1
wm.window.border.size: 3
wm.client.focused.color.child_border: #AAD3E9
```

## Resolution

- Falsely detected out of the box required xrandr adjustments.
- issues with fractional scaling if not on Ubuntu desktop (so i3)

I found that the i3 window header and bar sizes seem to depend on the dpi set in `~/.Xresources`.
`Xft.dpi: 100`. Weirdly, a higher value causes bigger i3 bar and UI and a lower one smaller.

> I found the cursor size set here to have no effect `Xcursor.size: 5`

To view the current resolution config `xdpyinfo | grep -B 2 resolution`:

```
screen #0:
  dimensions:    2560x1600 pixels (677x423 millimeters)
  resolution:    96x96 dots per inch
```

## External Monitors (& USB monitors)

At first, I thought the external monitors were not working but I soon realized that they were detected but not set to `active`, simply going into `arandr`, setting them to active, and then applying the configuration made all external monitors work as expected.

### Persisting xrandr settings using autorandr

`sudo apt install autorandr` just set the correct settings using `xrandr` or a UI like `arandr`,
then save the profile as default `autorandr --save default`

### Gnome Scaling Factor

I wasn't yet able to get fractional scaling working on Ubuntu yet.
But I found that the overall scale can be set from the command line using:

```bash
gsettings set org.gnome.settings-daemon.plugins.xsettings overrides  "[{'Gdk/WindowScalingFactor', <1>}]"
gsettings set org.gnome.desktop.interface scaling-factor 1
```

It accepts scaling factors `1`, `2`, `3`

## Setting up Keepmenu as password manager

I love using Keepmenu to easily manage a local password database.

- https://github.com/firecat53/keepmenu

I use it with `rofi`; this is my config: `~/.config/keepmenu/config.ini`:

```ini
[dmenu]
dmenu_command = rofi -show drun -dpi 1

[dmenu_passphrase]
nf = #222222
nb = #222222
rofi_obscure = True

[database]
database_1 = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
keyfile_1 = 
pw_cache_period_min = 30
autotype_default = {USERNAME}{TAB}{PASSWORD}{ENTER}
```

### Setting up the keybinding

The easiest way is to just use the GNOME system keybindings like described in: https://regolith-desktop.com/docs/using-regolith/configuration/

Just open the GNOME settings `Super+c` & open the keybindings editor in the 'Keyboard' settings.

You could also set it up using an i3 config e.g.:

```bash
bindsym $mod+Shift+K exec "DO SOMETHING"
```