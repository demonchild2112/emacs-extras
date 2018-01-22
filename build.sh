#!/bin/bash

set -e

readonly VERSION='1.0'

dpkg-buildpackage -us -uc
