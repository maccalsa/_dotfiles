# KVM/libvirt VM Cheat Sheet

## Quick Reference — What Tool to Use

| Task                          | Command / Tool          |
|-------------------------------|-------------------------|
| Create VM                     | `x_vm create`           |
| List VMs                      | `x_vm list`             |
| Connect console + audio       | `x_vm connect --name <vm>` |
| Diagnose VM audio routing     | `x_vm audio-status --name <vm>` |
| Fix VM audio routing          | `x_vm audio-fix`        |
| Start VM                      | `virsh --connect qemu:///system start <vm>` |
| Stop VM (graceful)            | `virsh --connect qemu:///system shutdown <vm>` |
| Stop VM (force)               | `virsh --connect qemu:///system destroy <vm>` |
| Rename VM                     | `virsh --connect qemu:///system domrename <old> <new>` |
| Edit VM hardware/XML          | `virsh --connect qemu:///system edit <vm>` |
| Delete VM + disk              | `x_vm delete --name <vm>` |
| Take snapshot                 | `virsh --connect qemu:///system snapshot-create-as <vm> <name>` |
| List snapshots                | `virsh --connect qemu:///system snapshot-list <vm>` |
| Restore snapshot              | `virsh --connect qemu:///system snapshot-revert <vm> <name>` |
| Browse VMs visually           | virt-manager (read-only browsing only) |

> **Avoid using virt-manager to make changes** — it has bugs with UEFI/NVRAM VMs
> (renaming, hardware edits). Use `virsh` for all mutations.

---

## VM Templates

| VM Name                      | Description                                      |
|------------------------------|--------------------------------------------------|
| `template_ubuntu26_base`     | Clean Ubuntu 26.04 install, no extras            |
| `template_ubuntu26_extensions` | Base + guest-setup (SPICE agent, audio working) |
| `ubuntu-template`            | Working template — audio in/out confirmed ✓      |

---

## Audio Setup — How It Works

SPICE audio is used. The chain is:

**Output (playback):**
```
Guest app → PipeWire → ICH9 sound card → QEMU spice audiodev
→ SPICE protocol → virt-viewer → GStreamer → PulseAudio → HDMI speakers
```

**Input (microphone):**
```
Host USB mic → PulseAudio source → virt-viewer → SPICE record channel
→ QEMU → ICH9 sound card → Guest PipeWire → arecord / app
```

### Rules for audio to work
1. **VM audio must use `type='spice'`** — the `pa` (PulseAudio) driver fails because
   QEMU running under libvirtd has no access to the user's PulseAudio session (no HOME/XDG vars).
   SPICE audio routes through virt-viewer instead, which runs in the full user session.
2. **Always connect via `x_vm connect`** — uses `virt-viewer --attach`, which creates the
   SPICE audio pipeline. virt-manager does not handle SPICE audio reliably.
3. **Host default output must be HDMI** — set permanently in `~/.config/pulse/default.pa`
4. **Virt Viewer's playback stream must be routed to HDMI** — PulseAudio stream-restore can
   pin the app back to S/PDIF even when HDMI is the default.
5. **Host default input must be USB mic** — already set as system default
6. Guest must have `spice-vdagent` installed (`x_vm guest-setup` handles this)
   Note: spice-vdagent is for clipboard/display/mouse — SPICE audio works without it.

### Audio troubleshooting

```bash
# One-command host-side diagnosis/fix
x_vm audio-status --name <vm>
x_vm audio-fix

# Check audio is reaching host from VM (run while guest plays sound)
pactl list sink-inputs short        # should show virt-viewer entry at 48000Hz 2ch

# Check mic is being read by virt-viewer (run while guest records)
pactl list source-outputs short     # should show entry reading from USB mic

# Check/fix default output
pactl info | grep "Default Sink"
pactl set-default-sink alsa_output.pci-0000_01_00.1.hdmi-stereo

# Move a running stream to HDMI manually
pactl move-sink-input <id> alsa_output.pci-0000_01_00.1.hdmi-stereo
```

Known recurring failure: the guest and SPICE are working, but PulseAudio has restored the
`Virt Viewer` stream to S/PDIF (`alsa_output.pci-0000_00_1f.3.iec958-stereo`). In that case,
`x_vm audio-fix` moves the live stream back to HDMI and resets the host defaults.

### Host audio devices
| Device | Name |
|--------|------|
| Output (HDMI, monitor speakers) | `alsa_output.pci-0000_01_00.1.hdmi-stereo` |
| Output (S/PDIF — not used)      | `alsa_output.pci-0000_00_1f.3.iec958-stereo` |
| Input (USB condenser mic)       | `alsa_input.usb-Generic_USB_Condenser_Microphone_201701110001-00.analog-stereo` |

---

## QEMU / libvirt Facts

- Connection URI: `qemu:///system` (not `qemu:///session` — session has no VMs)
- VM disks stored at: `~/.local/share/libvirt/images/`
- NVRAM (UEFI vars) stored at: `/var/lib/libvirt/qemu/nvram/`
- QEMU logs: `/var/log/libvirt/qemu/<vm-name>.log`
- Audio driver: `spice` (PulseAudio `pa` driver fails — QEMU has no HOME/XDG env vars when launched by libvirtd)
- virt-install version: 4.0.0 (options use `key=value` form, e.g. `--audio id=1,type=spice`)
- Recurrent host routing failure: PulseAudio stream-restore can remember `Virt Viewer` on S/PDIF; run `x_vm audio-fix`

---

## Common virsh Commands

```bash
# List all VMs (including shut off)
virsh --connect qemu:///system list --all

# Start / stop
virsh --connect qemu:///system start <vm>
virsh --connect qemu:///system shutdown <vm>
virsh --connect qemu:///system destroy <vm>       # force off

# Rename (works with UEFI, unlike virt-manager)
virsh --connect qemu:///system domrename <old-name> <new-name>

# Snapshots
virsh --connect qemu:///system snapshot-create-as <vm> <snapshot-name> --description "..."
virsh --connect qemu:///system snapshot-list <vm>
virsh --connect qemu:///system snapshot-revert <vm> <snapshot-name>
virsh --connect qemu:///system snapshot-delete <vm> <snapshot-name>

# Inspect running QEMU process audio config
ps aux | grep <vm-name> | grep -o '"driver":"[^"]*"'

# Check SPICE channels (display, audio, usb)
virsh --connect qemu:///system qemu-monitor-command <vm> --hmp "info spice"
```

---

## Resizing a VM Disk

### Step 1 — on the host (VM must be shut off)
```bash
# Check current disk size
qemu-img info ~/.local/share/libvirt/images/<vm>.qcow2 | grep 'virtual size'

# Expand the image (adds to existing size)
qemu-img resize ~/.local/share/libvirt/images/<vm>.qcow2 +20G

# Start the VM
virsh --connect qemu:///system start <vm>
```

### Step 2 — inside the guest
```bash
x_vm resize
```
Handles plain partitions and LVM/encrypted layouts automatically.
Grows: partition → LVM PV/LV (if present) → filesystem (ext4 or xfs).

---

## x_vm Script Reference

```bash
x_vm                                          # interactive menu
x_vm create --profile template --os ubuntu26  # create Ubuntu 26 template VM
x_vm create --profile dev --os ubuntu26       # create dev VM (4 vCPU, 8GB, 80GB)
x_vm connect --name <vm>                      # open console via virt-viewer (audio works)
x_vm audio-status --name <vm>                 # inspect host/SPICE audio routing
x_vm audio-fix                                # move Virt Viewer audio back to HDMI
x_vm list                                     # list all VMs
x_vm delete --name <vm>                       # delete VM and disk
x_vm guest-setup                              # run INSIDE guest after install
x_vm resize                                   # run INSIDE guest after disk expansion
```

### Profiles
| Profile  | vCPU | RAM   | Disk  | Use for             |
|----------|------|-------|-------|---------------------|
| template | 2    | 4 GB  | 40 GB | Clean base snapshot |
| dev      | 4    | 8 GB  | 80 GB | Development work    |
| test     | 4    | 8 GB  | 80 GB | Throwaway testing   |

### OS options
| Flag       | ISO glob                              | osinfo variant |
|------------|---------------------------------------|----------------|
| `ubuntu`   | `~/Downloads/ubuntu-24.04*amd64.iso`  | ubuntu24.04    |
| `ubuntu26` | `~/Downloads/ubuntu-26.04*amd64.iso`  | ubuntu25.04 *  |
| `pop`      | `~/Downloads/pop-os_24.04*.iso`       | ubuntu24.04    |

\* ubuntu26.04 not yet in osinfo-db (as of Jan 2025 db); ubuntu25.04 used as closest match
