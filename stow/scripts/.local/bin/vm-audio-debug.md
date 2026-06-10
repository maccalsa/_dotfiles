# VM Audio Debug — Known Facts

## Goal
Guest VM (Ubuntu 26.04, `template_ubuntu26`) to have working:
- **Audio output** → host HDMI monitor speakers
- **Audio input** → host USB condenser microphone

The host has both working correctly.

---

## Host Environment

| Item | Value |
|------|-------|
| OS | Ubuntu 22.04 (jammy) |
| Desktop | XFCE |
| QEMU machine type | `pc-q35-6.2` |
| Libvirt connection | `qemu:///system` |
| PulseAudio socket | `/run/user/1000/pulse/native` |
| PipeWire socket | `/run/user/1000/pipewire-0` (exists) |
| Default output sink | `alsa_output.pci-0000_01_00.1.hdmi-stereo` (HDMI) |
| Default input source | `alsa_input.usb-Generic_USB_Condenser_Microphone_201701110001-00.analog-stereo` |

### QEMU process facts
- Runs as user `maccalsa` (UID 1000) — correct user
- Has **no** `HOME`, `USER`, or `XDG_RUNTIME_DIR` in its environment
- Has only `XDG_DATA_DIRS` set
- `qemu:commandline` env entries appear in `dumpxml` XML but do **not** appear in `/proc/PID/environ` — reason unknown
- QEMU sandbox enabled: `-sandbox on,obsolete=deny,elevateprivileges=deny,spawn=deny,resourcecontrol=deny`

### QEMU audio driver support
```
qemu-system-x86_64 -audiodev help  →  "Help is not available for this option"
pipewire audiodev: NOT compiled in
pa (PulseAudio) audiodev: compiled in, but failing
```

---

## VM Configuration (current)

```xml
<sound model='ich9-intel-hda'>
<audio id='1' type='pulseaudio' serverName='/run/user/1000/pulse/native'/>
<video model='virtio'/>
```

QEMU command generated:
```
-audiodev '{"id":"audio1","driver":"pa","server":"/run/user/1000/pulse/native"}'
-device ich9-intel-hda
-device hda-duplex,id=sound0-codec0,bus=sound0.0,cad=0,audiodev=audio1
```

---

## What Works

- SPICE display ✓
- Clipboard sharing (spice-vdagent) ✓
- Mouse integration ✓
- VM networking ✓
- Host audio output (HDMI speakers) ✓
- Host audio input (USB mic, `pactl` confirms correct default source) ✓
- SPICE audio **output** — works but ~12 second latency via virt-manager

---

## What Doesn't Work

- QEMU `pa` audiodev cannot connect to PulseAudio:
  ```
  pulseaudio: pa_context_connect() failed
  pulseaudio: Reason: Connection refused
  pulseaudio: Failed to initialize PA context
  audio: Could not init `pa' audio driver
  audio: warning: Using timer based audio emulation
  ```
- No sink-inputs appear on host when guest plays audio
- No source-outputs appear on host when guest records
- `qemu:commandline` env var injection (HOME, XDG_RUNTIME_DIR) does not appear in QEMU process environment

---

## Approaches Tried (all failed for `pa` driver)

| Attempt | Result |
|---------|--------|
| `--audio type=spice` | Works but ~12s latency via virt-manager |
| `--audio type=pulseaudio` (no server) | Connection refused |
| `type=pulseaudio` + `serverName=/run/user/1000/pulse/native` | Connection refused |
| `type=pulseaudio` + `serverName` + `mixingEngine='no'` | Connection refused |
| `type=pulseaudio` + `qemu:env HOME + XDG_RUNTIME_DIR` | Env vars in XML but not in process, still Connection refused |
| `type=pipewire` | Not compiled into QEMU on this system |

---

## Approaches Not Yet Tried

1. **Anonymous PulseAudio Unix socket** — load `module-native-protocol-unix socket=/tmp/pulse-vm.sock auth-anonymous=1` and point QEMU at it. Removes all auth from the equation.

2. **PulseAudio TCP** — `pactl load-module module-native-protocol-tcp port=4713 auth-anonymous=1`, use `serverName=tcp:127.0.0.1:4713`. Similar to above but via TCP.

3. **SPICE audio via `virt-viewer` instead of `virt-manager`** — virt-manager uses GStreamer for SPICE audio (high latency). `virt-viewer`/`remote-viewer` uses a different SPICE audio path and may have much lower latency. **This is worth trying — SPICE audio IS working, just slow.**

4. **USB passthrough** — pass the USB microphone directly to the guest via `<hostdev>`. Guest gets direct device access, bypasses all QEMU audio complexity. Output would still need fixing separately.

5. **Virtio-sound** — newer paravirtualized audio device (`<sound model='virtio'>`). Requires kernel 5.14+ in guest (Ubuntu 26.04 qualifies). Still needs a working host audiodev backend though.

6. **Investigate sandbox blocking** — the QEMU `-sandbox on` seccomp filter may be blocking the socket `connect()` syscall. Test by temporarily creating a VM without the sandbox to confirm/rule out.

7. **Why do `qemu:env` entries not reach the process?** — this is unexplained and worth understanding before trying more audiodev configs.

---

## Recommended Next Step

**Try option 3 first** (virt-viewer for SPICE audio) — it requires zero VM config changes and SPICE output is already confirmed working. If latency is acceptable, that solves output. Mic input via SPICE is also supported by the protocol.

If that fails, try **option 1** (anonymous Unix socket) which definitively removes the auth/env problem.
