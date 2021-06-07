# colorenv
Outputs the environment with color.

Features:
* Output environemnt with color
* Output environment to JSON
* Output a selection of environment variables
* Output a selection of environment variables to JSON
* Path expansion - Puts each path entry on its own line

# Usage

```
  Usage: 
    colorenv
    colorenv envar1 envar2 envar3
    colorenv -v <color> -k <color> envar1 envar2 envar3
    colorenv -j envar1 envar2 envar3

  Options:
    -j, --to-json             Outputs to JSON (no color) so you can pipe to jq if you want
    -v, -vc, --value-color    Specifices the color to use for values
    -k, -kc, --key-color      Specifices the color to use for keys
    -p, --path-expand         Turns on path expansion
    -i, --no-icon             Turns off the icon

  Available Colors:
     black,  light_black,  red,  light_red,  green,  light_green, 
     yellow,  light_yellow,  blue,  light_blue,  magenta,  light_magenta, 
     cyan,  light_cyan,  white,  light_white,  default

  Help:
    -h, --help              Show's this help message
```

# Todo
[ ] Turn in to a proper Gem
[ ] Add man entry
[ ] Rewrite in Go or Rust for speed
