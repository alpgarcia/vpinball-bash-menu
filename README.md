# vpinball-bash-menu
Simple bash launcher for [vpinball standalone](https://github.com/vpinball/vpinball/tree/standalone).

## Usage
```
./menu.sh [ -t | --tables ]
          [ -i | --ini ]
          [ -e | --exe ]
          [ -h | --help ]
```
* `-t | --tables`: path to our collection of vpx files. It may contain sub-directories. Defaults to `${HOME}/pinball/tables`.
* `-i | --ini`: path to the directory containing our ini files. It may contain sub-directories. Defaults to `${HOME}/pinball/ini`.
* `-e | --exe`: path to the vpinball standalone binary file. Defaults to `${HOME}/pinball/vpinball/build/VPinballX_GL`.

To change default values, just edit the bash script variables defined at the beginning.


# References & Ackowledgements
[https://askubuntu.com/questions/682095/create-bash-menu-based-on-file-list-map-files-to-numbers](https://askubuntu.com/questions/682095/create-bash-menu-based-on-file-list-map-files-to-numbers)
