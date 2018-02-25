#!/bin/bash

set -e

readonly VERSION=1.0
readonly UBUNTU_RELEASES=(precise trusty xenial artful)
readonly INITIAL_DIR="${PWD}"

rm -rf /tmp/emacs-extras-builds
mkdir /tmp/emacs-extras-builds

for release in "${UBUNTU_RELEASES[@]}"; do
  debchange --create \
    --newversion "${VERSION}" \
    --package emacs-extras \
    --urgency low \
    --controlmaint \
    --distribution "${release}" \
    "First release."
  echo "Building for ${release}"
  debuild -S
  cd ../
  mkdir "/tmp/emacs-extras-builds/${release}"
  mv emacs-extras_* "/tmp/emacs-extras-builds/${release}"
  cd -
  dh clean
  rm -f debian/changelog
done

for release in "${UBUNTU_RELEASES[@]}"; do
  cd "/tmp/emacs-extras-builds/${release}"
  echo "Uploading ${release}..."
  dput ppa:demonchild2112/emacs "emacs-extras_${VERSION}_source.changes"
done

cd "${INITIAL_DIR}"
