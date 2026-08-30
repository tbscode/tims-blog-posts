---
title: "My Titan 2 Elite Advanced Setup: The Pocket Terminal Conversion"
description: "A hands-on guide on turning the Titan 2 Elite into a real pocket dev machine with Termux, tmux, opencode, a local LLM and a full Alpine Linux VM under QEMU."
date: "2026-08-30"
featured: true
postOfTheMonth: true
author: "Tim Schupp"
categories: ["Linux", "Setup Guide", "Tools"]
tags: ["Termux", "tmux", "Titan-2-Elite", "Android", "Open-Code", "Ollama", "QEMU", "Alpine", "Docker"]
image: "/static/assets/titan_setup/01_phone_picture.jpeg"
---

## My Titan 2 Elite Advanced Setup

I hope this doubles as a written guide on how to get Termux up and running on the Titan 2 Elite;
this is the exact setup I run daily as a pocket terminal / dev machine.

#### **1. Install tmux from F-Droid**

Get `tmux` (and Termux itself) from [F-Droid](https://f-droid.org/).
The version in the Play Store will *not* work for you; it is out of date and the required mirrors cannot be set up on it.

#### **1.5. Install Unknown Keyboard and my custom symbols layout**

For anything resembling real terminal work you need a keyboard that gives you quick access to special characters.
I use [Unknown Keyboard](https://f-droid.org/en/packages/jp.co.hi_zya.keyboard/) with this custom symbols layout:

```xml
<?xml version="1.0" encoding="utf-8"?>
<keyboard name="Symbols (1-Row)" script="latin">
  <row>
    <key c="(" ne=")" nw="&lt;" se="&gt;"/>
    <key c="[" ne="]" nw="{" se="}"/>
    <key c="=" n="+" s="-" e="*" w="/" nw="%" ne="^"/>
    <key c="\\" n="|" w="~" se="`"/>
    <key c="." n="," e="!" w="\?" ne=":" nw=";"/>
    <key c="&quot;" n="'" e="_" w="-"/>
    <key c="\@" n="\#" e="&amp;" s="%"/>
    <key c="$" ne="€" se="£" sw="¥"/>
  </row>
</keyboard>
```

Also, for my optimal usage, I apply the following key mappings:

- `alt` -> `shift`
- `left shift` -> `alt`
- `home` -> `ctrl`
- `right shift` -> `tab`
- `space` -> `home`

Now you should be able to manage and navigate everything similar to a regular keyboard.
*Note that the Unknown Keyboard will still be required for some special chars!*

#### **2. Set up your Termux package mirrors**

```bash
termux-change-repo
```

Then update and prepare the packages:

```bash
pkg update
pkg upgrade
```

#### **3. Set up Termux storage**

```bash
termux-setup-storage
```

#### **4. Install some helpful packages**

```bash
pkg install git
pkg install gh
pkg install neovim
```

<img width="807" height="900" alt="Termux setup on the Titan 2 Elite" src="/static/assets/titan_setup/02_termux_screenshot.png" />

#### **5. Set up opencode**

I run [opencode](https://opencode.ai/) on the phone via the Termux port from [Hope2333/opencode-termux](https://github.com/Hope2333/opencode-termux).
Grab an `opencode` binary from the [release page](https://github.com/Hope2333/opencode-termux/releases), then:

```bash
apt install -y glibc-repo
apt update
apt install -y glibc openssl-glibc

dpkg -i /path/to/opencode_<version>_aarch64.deb
```

If you want to configure it for local llm usage, check out [my article on usability with local llms](https://blog.t1m.me/blog/opencode-with-local-llms).

#### **6. Running a local llm**

Multiple options here; for now the simplest one: download [Ollama](https://play.google.com/store/apps/details?id=com.ollama) from the Google Play Store.

#### **7. Setting up QEMU**

Termux ships QEMU packages, so we can run a *full Linux VM* right on the phone.
Since Android won't expose KVM on an unrooted device, the guest runs fully emulated as x86_64 through TCG (`-machine q35,accel=tcg`);
slower than native virtualization, but completely functional and headless (`-nographic`), which is all I need inside tmux.

I scripted the whole flow and attached all scripts to this post; grab them straight into Termux:

```bash
for s in setup-host start-installer start-vm postinstall-alpine kill-vm reset-vm; do
  wget "https://github.com/tbscode/tims-blog-posts/raw/main/assets/titan_setup/scripts/$s.sh"
done
chmod +x *.sh
```

Each script is also linked inline below, so you can read exactly what it does before running it.

#### **8. Preparing the host: `setup-host.sh`**

One script does all host preparation: [`setup-host.sh`](https://github.com/tbscode/tims-blog-posts/blob/main/assets/titan_setup/scripts/setup-host.sh)

It will:

1. install the required packages (`qemu-system-x86_64`, `qemu-utils`, `wget`)
2. create the host shared directory at `~/docker_shared`
3. create a 50G `alpine.qcow2` disk image (if missing)
4. download the `alpine-virt-3.20.2-x86_64.iso` (if missing)
5. make the helper scripts executable

```bash
bash setup-host.sh
```

#### **9. Installing Alpine inside QEMU**

Now boot the installer with [`start-installer.sh`](https://github.com/tbscode/tims-blog-posts/blob/main/assets/titan_setup/scripts/start-installer.sh);
it boots the ISO from the qcow2 disk, forwards `2222 -> 22` and `8080` to the host, and exposes `~/docker_shared` to the guest via a 9p `hostshare` mount:

```bash
./start-installer.sh
```

Then inside the VM:

1. log in as `root` (no default password)
2. run `setup-alpine`
3. select the `vda` partition and `sys` as the installation type
4. set a strong root password
5. `poweroff` once the install completes

Here's the disk & install step; you can also see the extra-keys row and my custom symbols keyboard in action, which make navigating and typing the installer prompts feel almost like a real terminal session:

<img width="540" height="602" alt="setup-alpine selecting the vda disk with sys install type in Termux" src="/static/assets/titan_setup/03_alpine_setup_vda.png" />

Boot the installed system with [`start-vm.sh`](https://github.com/tbscode/tims-blog-posts/blob/main/assets/titan_setup/scripts/start-vm.sh) (same flags, minus the ISO), log in as `root`, and run [`postinstall-alpine.sh`](https://github.com/tbscode/tims-blog-posts/blob/main/assets/titan_setup/scripts/postinstall-alpine.sh) inside the guest
(it is already visible under `/mnt/shared` once you mount the share, or just paste its contents):

```sh
sh /mnt/shared/postinstall-alpine.sh
```

The script hardens and provisions the base system in one pass:

- enables the `community` repository and installs `sudo`, `docker`, `docker-cli-compose`, `shadow`
- creates your user, adds it to the `docker` group and grants full sudo access
- enables the Docker daemon at boot
- configures the 9p share as a persistent auto-mount at `/mnt/shared`, owned by your user

Verify everything works from inside the VM:

```bash
su - <your-user>
docker run --rm hello-world   # docker works without root
sudo apk update               # sudo works
touch /mnt/shared/test.txt    # file appears on the host in ~/docker_shared
```

That's it: a persistent Alpine with Docker, reachable from the host via SSH on port `2222`, sharing files through VirtFS.

And it's genuinely usable for real work; here I'm building [this very blog](https://blog.t1m.me) through the shared folder inside the VM:

<img width="540" height="602" alt="docker compose build of the blog running inside the Alpine VM via the shared folder" src="/static/assets/titan_setup/04_docker_compose_build.png" />

##### Day-2 helpers

- [`kill-vm.sh`](https://github.com/tbscode/tims-blog-posts/blob/main/assets/titan_setup/scripts/kill-vm.sh) — stops any running QEMU VM process (graceful, then forced)
- [`reset-vm.sh`](https://github.com/tbscode/tims-blog-posts/blob/main/assets/titan_setup/scripts/reset-vm.sh) — wipes and recreates the qcow2 disk when you want a clean slate

---

That's it for now; the phone happily sits in my pocket running tmux, neovim, opencode, a local model — and now a full Alpine VM with Docker, this blog's dev server included:

<img width="540" height="602" alt="docker compose up of the blog frontend inside tmux on the Titan 2 Elite" src="/static/assets/titan_setup/05_docker_compose_up.png" />
