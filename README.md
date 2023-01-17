# Lorg (web version)

_If you are reading this on GitHub or other Git repository or service, then you
are looking at a mirror. The official repository is [this Fossil
repository](https://dev.lorg.software/web-app)._

Lorg is a hierarchical data manager. You define your data and their associated
units in a text file, and Lorg automatically calculates the missing units.

This project contains the web version of Lorg. You can learn more about Lorg
and even trying it at [the official website](https://www.lorg.software).

## How to use Lorg

### Example

It is easier to explain and understand how to use Lorg with an example.

For example you have a new home and you need to renovate some rooms. You want
to know how long it will take to renovate and how much it would cost in total.

Let say you need to renovate the `Living room` and the `Bathroom`. You know how
many `Days` and the `Cost` for the `Living room` room renovation, you only know
the `Cost` for the `Bathroom`.

Let's define your data:

```lorg
# House
## First floor
### Living room
$ Days: 2
$ Cost: 500
## Second floor
### Bathroom
$ Cost: 1500
I have no idea how long it will take!
```

Now use Lorg to automatically calculate the total. You can use the web
interface or, if you compiled this project as a CLI version, you can use this
command:

```
lorg house.lorg
```

Lorg will print the result:

```
# House
  $ Cost: 2000 [Calculated]
  $ Days: 2 [Calculated]
  ## First floor
    $ Cost: 500 [Calculated]
    $ Days: 2 [Calculated]
    ### Living room
      $ Cost: 500
      $ Days: 2
  ## Second floor
    $ Cost: 1500 [Calculated]
    $ Days: 0 [Calculated]
    ### Bathroom
      $ Cost: 1500
      $ Days: 0 [Calculated]
```

You now know that it will takes at least `2` days and it will cost you `2000`
to renovate your new home.

### The syntax

By convention, we write into files with a `.lorg` extension. In our example, we
save everything into a file named `house.lorg`.

Each component is called a **node**. A node can contain other nodes and
**units**.

#### Nodes

If you know Markdown, you already know how to structure your data.

A node is defined in one line starting by one or multiple `#` then the node
title. The number of `#` defines the node level, in other words it defines if
the node is the child of a previously defined node.

To take the previous example, the `House` has a `First floor` and a `Second
floor`. The `First floor` contains a `Living room` and the `Second floor`
contains a `Bathroom`. In Lorg, it is written this way:

```lorg
# House
## First floor
### Living room
## Second floor
### Bathroom
```

#### Units

A unit is defined in one line starting with one `$` then the unit name then `:`
then the unit value. Unit values can only be integers or decimal-point numbers.

In our example, we know that it takes 2 days and it costs 500 to renovate the
living room. We also know it costs 1500 to renovate the bathroom. We define
units for those nodes.

```lorg
# House
## First floor
### Living room
$ Days: 2
$ Cost: 500
## Second floor
### Bathroom
$ Cost: 1500
```

### Comments

All lines that are not node definitions nor unit definitions are comments. They
are ignored by Lorg.

### Usage

Lorg will calculate for us the unit values for the other nodes. Note that for
the moment it only **sums** the values.

Lorg contains some options. Here is the command to print the result in a pretty
format using the compile CLI version.

```
lorg --prettify house.lorg
```

It returns this result

```
House
│ $ Cost: 2000 [Calculated]
│ $ Days: 2 [Calculated]
├── First floor
│   │ $ Cost: 500 [Calculated]
│   │ $ Days: 2 [Calculated]
│   └── Living room
│         $ Cost: 500
│         $ Days: 2
└── Second floor
    │ $ Cost: 1500 [Calculated]
    │ $ Days: 0 [Calculated]
    └── Bathroom
          $ Cost: 1500
          $ Days: 0 [Calculated]
```


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

Note that in the section "2. Basic Permissions.", the license gives you the
right to copy and paste small code snippets for various purposes (share
snippets of the code, use snippets for your own work...) without the need of
covering your own work under GNU AGPLv3.

> This License acknowledges your rights of fair use or other equivalent, as
> provided by copyright law.

In other words, if you integrate in your project some small parts of the code
from this project, you are not forced to license your work under GNU AGPLv3.

Note also that if you simply include the web app in your website, we consider
that as an "aggregate". (Read the section "5. Conveying Modified Source
Versions.".) In other words, if you include a modified or unmodified version of
the web app into your work, we want you to share the modified or unmodified
version of the web app but not necessarily your own independent work.

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
