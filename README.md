# Pie

Pie (Python installer extraordinare) is a PowerShell script for Windows for installing a local and isolated version of [Python], [pip] and packages
required by a _project_.

A project is simply any collection of Python scripts in a directory that share
the same requirements.


## Installation

Pie is always installed at the root of a project; that is the top-most
directory that defines a project with sub-directories.

To install Pie, copy, paste and run the following line at a PowerShell prompt:

    iex (Invoke-RestMethod https://github.com/atifaziz/pie.ps/blob/master/get-pie.ps1)

This will add `pie.ps1` to your project. You should check-in this file if you
are using a version control system (e.g. Git, Mercurial, Subversion or
another).

Next, simply run the PowerShell script (add the `-Verbose` switch if you are
interested in verbose output):

    ./pie.ps1

The script will:

- Download and install the latest version of Python in a directory called
  `.python`. This directory should not be checked into you version control
  system.

- Download and install pip.

- If there is a `requirement.txt` found then it will run:
  `pip install -f requirements.txt`

- Create convenience batch scripts, namely `python.cmd` and `pip.cmd`, for
  running the project's local Python version and pip commands.

The above steps can repeated at any time.

To lock to a specific version of Python, add a file named `pyver.txt` in the
root of your project containing just the requirement version number, e.g.:

    3.7.1

If you change the version in this file, run `./pie.ps1` once more. It will
detect the change, uninstall the currently installed version and install the
newly specified version instead.


## Uninstallation

Run:

    ./pie.ps1 -Uninstall

This will remove all artifacts installed into the project (i.e. Python, pip
packages and supporting scripts) except Pie. To remove Pie from the project,
simply delete `pie.ps1`.


## Updating Your Installation

To ensure you are using the latest version of Pie, run:

    ./pie.ps1 -Update

This will download and replace your current version with the latest. If you
have `pie.ps1` checked into a version control system and the update changes the
file then it would be wise to commit the updated version.


## Supported Python Versions

To list the supported versions of Python versions, run:

    ./pie.ps1 -ListVersions

To include pre-releases like alpha and beta versions, run instead:

    ./pie.ps1 -ListVersions -IncludePrerelease


[Python]: https://www.python.org/
[pip]: https://pip.pypa.io/en/stable/
