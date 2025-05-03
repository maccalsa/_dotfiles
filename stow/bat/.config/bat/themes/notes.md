## Download themes

`curl -O https://github.com/folke/tokyonight.nvim/blob/main/extras/sublime/tokyonight_night.tmTheme`

## Refresh cache and check themes

> `bat cache --build`
> `bat --list-themes | fzf --preview="bat --theme={} --color=always /path/to/file"`

## Install

Add the folllowing to yor .zshrc file

```bash
# Add bat to the path
export BAT_THEME=tokyonight_theme
```
