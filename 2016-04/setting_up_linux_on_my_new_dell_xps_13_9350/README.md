# Setting up Linux on my new Dell XPS 13 9350

I am writing this in retrospect, so if I am missing something, if it is incorrect, or if things have changed in the future, then please tell me. I will update this guide when I reinstall my laptop sometime.

## The laptop

I bought the Dell XPS 13 (9350) with the QHD (3200x1800) non-developer edition (comes with Windoze 10), at the time the developer edition wasn't available yet.

## Preparation

The non-developer edition comes with a Broadcom DW1820A Wifi+Bluetooth module which is not supported in Kernel 4.2 (I think 4.4 will support it). So the first thing to do is to replace the wifi module. I chose the Intel 7265 module to replace the current one (Intel modules apparently get better reception than Broadcom ones too). After reading a few other blog posts and an iFixit teardown, I proceeded to crack open the bottom. The back plate is held with a couple of Torx T5 screws and several plastic clips. Using a thin metal spudger and my plastic student ID card that I slid across the edges, I popped off the clips and got in. Be gentle, or it may snap off the clips. If you were wondering if the blue stuff on the screws were warranty void things. Nope. They are [thread-locking fluid](https://en.wikipedia.org/wiki/Thread-locking_fluid) to stop the vibrations making the screws fall out.

## Installing Ubuntu

I chose to install Ubuntu Server 15.10 as the Desktop edition has too much bloat. They have no differences in the kernel or the repositories, just less crap when installed (yes, that includes Unity, so you'll boot into a blinking cursor). A USB ethernet adapter may be required to download packages during the installation.

## Setting up the computer

With the high resolution, you will have to bear with the **super tiny** text for a while until we configure the DPI.

### Setting up i3, my window manager

`# apt-get install --no-install-recommends i3 i3status i3lock xorg lightdm`

My config files for i3 and i3status are included in `~/.config/(i3|i3status)/config`.

### DPI

If the `-dpi <dpi>` flag isn't set when starting X, X will [calculate](https://wiki.archlinux.org/index.php/xorg#Display_size_and_DPI) the DPI based on the physical display size (in mm) specified in `/etc/X11/xorg.conf.d/60-dpi.conf`.

You may need to create the parent `xorg.conf.d` folder. Restarting X will be required for these changes to take effect, or you can reboot to restart your display manager `# service lightdm restart`.
```
Section "Monitor"
        Identifier      "<default monitor>"
        DisplaySize     395 260                 # certain applications (such as i3) use this value, I overreported the dimensions to get a higher DPI thus smaller text
        Option          "UseEdidDpi" "False"
        Option          "DPI" "192 x 192"       # others use this
EndSection
```

Another place to spcify the DPI is at `~/.Xresources`. Restart or run `xrdb -merge ~/.Xresources` to take effect.

```bash
$ echo "Xft.dpi: 192" >> ~/.Xresources
```

#### Chromium

Modify `/etc/chromium-browser/default` and add the following startup flag. You will need to close all instances of Chromium and restart in order for it to take effect.
```
--force-device-scale-factor=1.8
````

#### Firefox & Thunderbird

If Firefox or Thunderbird doesn't detect the correct DPI, head to `about:config` for Firefox and `Preferences > Advanced > Config Editor` for Thunderbird and change `layout.css.devPixelsPerPx` to something around `1.8`.

#### IntelliJ IDEA

Starting from [IDEA 15](http://blog.jetbrains.com/idea/2015/07/intellij-idea-15-eap-comes-with-true-hidpi-support-for-windows-and-linux/), there is an HiDPI option.

Edit `/path/to/idea/bin/idea.vmoptions` and add `-Dhidpi=true`.

#### Cursor too small

`# apt-get install dmz-cursor-theme`

You can further tweak the size in `~/.Xresources` with the `Xcursor.size: 32`.

### Terminal emulator

`# apt-get install --no-install-recommends rxvt-unicode-256color`

You can change the font size and colors in `~/.Xresources`. Don't forget to `xrdb -merge ~/.Xresources` to reload the change.
```
Rxvt.font: xft:DejaVu Sans Mono:size=8.5
Rxvt.background: rgb:0000/0000/0000
Rxvt.foreground: rgb:ffff/ffff/ffff
Rxvt.scrollBar: false
```

#### Bash PS1 prompt

Edit `~/.bashrc`'s PS1 to be `PS1='\[\e[38;5;256m\]\u\[\e[38;5;252m\] at \[\e[38;5;111m\]\h\[\e[38;5;252m\] in \[\e[38;5;256m\]\w \[\e[38;5;47m\]\$ \[\e[38;5;256m\]'`.


### Fonts

`# apt-get install fonts-dejavu`

After installing you need to create a `fonts.dir` file. Browse to `/usr/share/fons/truetype/dejavu` and run `# mkfontsdir`. To permanently add these fonts to your font path, copy `60-fonts.conf` to `/etc/X11/xorg.conf.d/60-fonts.conf`. This will be added on the next restart of X. To add it now run `xset +fp <path> && xset fp rehash`. You can verify it by checking `xfontsel`.

### Trash instead of rm

`# apt-get install --no-install-recommends trash-cli`

Use `trash <file>` to delete `trash-list` to view and `trash-empty` to empty instead of rm. Also use a bash alias to override `rm`.

```bash
alias rm="echo 'Please use trash instead.' && echo '$1' > /dev/null
```

### Wifi

`# apt-get install --no-install-recommends network-manager`

To connect to a network
```bash
$ nmcli device wifi rescan
$ nmcli device wifi list
$ nmcli device wifi connect <ssid> <password>
```

### Backlight

`# apt-get install xbacklight`

You can bind keys with `i3` to run `xbacklight -inc 6` or `-dec 6`.

### Audio

`# apt-get install --no-install-recommends pulseaudio alsa-base alsa-utils`

You can change the volume through the TUI mixer `alsamixer`, or through command line with `amixer`.

```bash
alsamixer                                                           # TUI mixer
amixer -q -D pulse set Master toggle                                # toggle
amixer -q set Master 5%- && amixer -q -D pulse set Master unmute    # increment and unmute
amixer -q set Master 5%+ && amixer -q -D pulse set Master unmute    # decrement and unmute
```

### Firewall

```bash
$ sudo apt-get install ufw
$ sudo ufw enable                       # enable now and on start
$ sudo ufw default deny incomming       # deny incoming connections
$ sudo ufw default deny outgoing        # deny outgoing connections
$ sudo ufw allow out 53/udp 53/tcp      # DNS
$ sudo ufw allow out 67/udp 68/udp      # DHCP
$ sudo ufw allow out 80/tcp 443/tcp     # HTTP and HTTPS
$ sudo ufw allow out 465/tcp 993/tcp    # SMTP and IMAP
$ sudo ufw allow out 7000/tcp           # IRC
$ tail -f /var/log/ufw.log              # monitor your ufw logs
```

### Yubikey

I use a Yubikey Neo for OpenPGP. To get this to work, you will need the following packages.

`# apt-get install --no-install-recommends pcscd scdaemon libu2f-host0`

Running `gpg --card-edit` with your Yubikey plugged in should show the card.

The Yubikey should work with Chromium with no additional configuration.

### Pass

`# apt-get install --no-install-recommends pass`

GPG support for pass should work out of the box. Pass uses `gpg2` (not `gpg`) which doesn't seem to detect my Yubikey until I had scdaemon installed (`gpg` worked fine without).

### Screen locking, suspend, hibernate, poweroff, and reboot

`# apt-get install --no-install-recommends xautolock`a

I use the following script to handle these tasks. When locked, `i3lock` will display a blur version of your screen. This is accomplised by screenshoting (`scrot` package) your desktop and blurring it with `convert` (`imagemagick` package). When I first suspended or hibernated, on resume, my screen was black and did not repond to any events. Adding `i915.preliminary_hw_support=1` kernel flag in the GRUB may fix it. Gold shift after the Dell logo to enter GRUB menu, press `e` to edit entry and add it after the `linux` command, press `F10` to continue booting with the modified entry. Your entry is not permanent.

```bash
lock() {
        # Only have one instance of i3lock running.
        pgrep i3lock
        if [ $? -eq 0 ]; then
                return
        fi
        # Blur desktop.
        scrot /tmp/screenshot.png
        convert /tmp/screenshot.png -filter box -blur 0x3 /tmp/screenshot.png
        i3lock --image /tmp/screenshot.png --show-failed-attempts
}

case "$1" in
        lock)
                lock
                ;;
        logout)
                i3msg exit
                ;;
        suspend)
                lock && systemctl suspend
                ;;
        hibernate)
                lock && systemctl hibernate
                ;;
        poweroff)
                poweroff
                ;;
        reboot)
                reboot
                ;;
        *)
                echo "Usage: $0 {lock|logout|hibernate|poweroff|reboot}"
                exit 2
esac
```
