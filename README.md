emacs-extras
==========

[![Build Status](https://travis-ci.org/google/grr.svg?branch=master)](https://travis-ci.org/demonchild2112/emacs-extras)

*emacs-extras* is a package (currently just for Ubuntu) that adds color themes
and other convenient settings to a default emacs installation.

The following color themes are currently included:
* [dracula](https://draculatheme.com/emacs/)
* [solarized](http://ethanschoonover.com/solarized)

Other settings addded by *emacs-extras* include:
* Managing backup files in a central location (default behavior for emacs is to
   place backup files in the same directory as the original files).
* Disabling electric indent (I really wish that was off by default).

### Installation
1. Check that you can have 'add-apt-repository' installed:

        [[ -z "$(which add-apt-repository)" ]] && sudo apt-get install software-properties-common

2. Add the hosting ppa:

        sudo add-apt-repository ppa:demonchild2112/emacs

 3. Update apt sources:
 
        sudo apt-get update

 4. Install:
 
        sudo apt-get install emacs-extras

 5. Check that installation worked by running `emacs-extras` on a terminal
    without arguments - a usage message should be printed.
