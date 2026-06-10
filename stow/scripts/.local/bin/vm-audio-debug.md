# VM Audio Debug — Known Facts

## Current Working Design

Guest audio uses SPICE, not QEMU's direct PulseAudio backend.

Playback chain:

```text
Guest app -> PipeWire -> ICH9 sound card -> QEMU spice audiodev
-> SPICE playback channel -> virt-viewer -> host PulseAudio -> HDMI speakers
```

Microphone chain:

```text
Host USB mic -> host PulseAudio -> virt-viewer -> SPICE record channel
-> QEMU -> ICH9 sound card -> guest PipeWire
```

The supported way to open the console is:

```bash
x_vm connect --name <vm>
```

## Known Good VM Configuration

The VM XML should contain SPICE audio:

```xml
<sound model='ich9'/>
<audio id='1' type='spice'/>
<graphics type='spice'/>
```

The running QEMU command should contain:

```text
-audiodev {"id":"audio1","driver":"spice"}
-device ich9-intel-hda
-device hda-duplex,...,audiodev=audio1
```

`virt-install` 4.0.0 needs explicit `key=value` audio syntax:

```bash
--sound ich9
--audio id=1,type=spice
```

## Known Bad Configuration

Do not use QEMU's direct PulseAudio backend for system libvirt VMs:

```xml
<audio id='1' type='pulseaudio' serverName='/run/user/1000/pulse/native'/>
```

It generates a QEMU `pa` audiodev and fails because QEMU launched by libvirtd does not have the
normal desktop PulseAudio environment:

```text
pulseaudio: pa_context_connect() failed
pulseaudio: Reason: Connection refused
audio: Could not init `pa' audio driver
```

Attempts to inject `HOME` or `XDG_RUNTIME_DIR` via `qemu:commandline` were not reliable. The fix is
to keep QEMU on `type='spice'` and let `virt-viewer` talk to the user's PulseAudio session.

## Recurring Failure

The VM can be fully correct and still produce no audible sound if host PulseAudio routes the
`Virt Viewer` playback stream to S/PDIF instead of HDMI.

Confirmed failure pattern:

```text
Default Sink: alsa_output.pci-0000_01_00.1.hdmi-stereo
Virt Viewer sink input: alsa_output.pci-0000_00_1f.3.iec958-stereo
```

This happens because PulseAudio stream-restore remembers a per-application route for
`application.name = "Virt Viewer"` and can override the current default sink.

## Self-Service Commands

Run this on the host while sound is playing in the guest:

```bash
x_vm audio-status --name <vm>
```

If the `Virt Viewer` stream is on S/PDIF, fix it with:

```bash
x_vm audio-fix
```

`audio-fix` does three things:

1. Sets the host default output to HDMI.
2. Sets the host default input to the USB condenser microphone.
3. Moves any active `Virt Viewer` playback stream to HDMI.

## Manual Host Commands

Useful when debugging without `x_vm`:

```bash
# Host default devices
pactl info | grep -E "Default Sink|Default Source"

# Host audio devices
pactl list sinks short
pactl list sources short

# Active playback streams; Virt Viewer should be on HDMI
pactl list sink-inputs short

# Move a live Virt Viewer stream manually
pactl move-sink-input <id> alsa_output.pci-0000_01_00.1.hdmi-stereo

# Reset defaults manually
pactl set-default-sink alsa_output.pci-0000_01_00.1.hdmi-stereo
pactl set-default-source alsa_input.usb-Generic_USB_Condenser_Microphone_201701110001-00.analog-stereo
```

## Guest Checks

Run inside the VM:

```bash
pactl info | grep -E "Server Name|Default Sink|Default Source"
pactl list sinks short
pactl list cards short
aplay -l
systemctl --user --no-pager --full status pipewire pipewire-pulse wireplumber
speaker-test -t wav -c 2
```

If `speaker-test` runs cleanly and `x_vm audio-status` shows a live `Virt Viewer` sink input on the
host, the guest audio stack is working. The remaining problem is host routing.
