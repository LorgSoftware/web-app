# Lorg (web version)

Lorg is a hierarchical data manager. You define your data and their associated
units in a text file, and Lorg automatically calculates the missing units.

This project contains the web version of Lorg. You can learn more about Lorg
and even trying it at [the official website](https://www.lorg.software).

## Build

The source code is written in Haxe version 4.2.4. If you want to build this
software yourself, you must install Haxe first. You can find the compiler at
the [Haxe official website](https://haxe.org/), or you can directly install it
from your package manager on Linux.

If you want to build the web version.

```
make web-release
```

This command will generate the file `lorg.js` in the `build-web` directory. You
can use the software by opening the file `index.html` in the `build-web`
directory with a web browser.

You can also compile a CLI version. We advise you to use [the official CLI
version](https://dev.lorg.software/lorg) instead, the official CLI version is
more performant than the CLI version compiled from this project. We compile
this project as a CLI version only to test it against [the official test
suite](http://dev.lorg.software/test-suite).

You first need to install the library `hxcpp`.

```
haxelib install hxcpp
```

You can then build the CLI version from this project.

```
make cli-release
```

## License

This project licensed is under GNU AGPLv3 (GNU Affero General Public License
version 3). The terms and conditions of this license are in the `LICENSE` file.

Note that if you simply include the web app in your website, we consider that
as an "aggregate". (Read the section "5. Conveying Modified Source Versions.".)
In other words, if you include a modified or unmodified version of the web app
into your work, we want you to share the modified or unmodified version of the
web app but not necessarily your own independent work.

## Copyright

```
Lorg - a hierarchical data manager - web version
Copyright (C) 2023  Alex Canales

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
```
