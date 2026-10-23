# suckless

Patched and configured builds of suckless tools.

## Tools

| Tool | Description |
|------|-------------|
| [st](./st) | Simple terminal — alpha transparency + JetBrainsMono Nerd Font |
| [slstatus](./slstatus) | Status bar — wifi, RAM, CPU, volume, brightness, battery |

## Patches

**st**
- alpha (transparency)
- scrollback (go back to further text up in the terminal)

## Install

```bash
cd st && sudo make clean install
cd slstatus && sudo make clean install
```

## Dependencies

- picom (for transparency)
- JetBrainsMono Nerd Font
