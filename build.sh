#!/bin/bash
#
# This script builds source packages for emacs-extras and uploads
# them to ppa:demonchild2112/emacs (by default). It figures out which Ubuntu
# releases do not have corresponding packages available in the
# ppa and only builds packages for those.
#
# Without any arguments, the script just builds the packages. Run
# it with '--upload' to upload them after building.

set -ex

readonly VERSION='1.0-0ubuntu4'
readonly DESCRIPTION='First release.'
readonly UPLOAD_PPA=${UPLOAD_PPA:-demonchild2112/emacs}

readonly SCRAPE_PATTERN='<p>The following releases of Ubuntu are available:</p>  <ul>.*?</ul>'
readonly SCRAPE_RESULT="$(curl -s releases.ubuntu.com 2>/dev/null | tr '\n' ' ' | grep -oP "${SCRAPE_PATTERN}")"
if [[ -z "${SCRAPE_RESULT}" ]]; then
  echo "Error: Scraping releases.ubuntu.com failed."
  exit 1
fi

readonly CURRENT_UBUNTU_RELEASES=($(echo "${SCRAPE_RESULT}" | grep -oP 'href=".*?"' | sed 's/href=//; s/"//g; s/\///'))
if [[ ${#CURRENT_UBUNTU_RELEASES[@]} -eq 0 ]]; then
  echo "Error: Failed to parse Ubuntu releases from scrape result."
  exit 1
fi

readonly DEB_URL_PREFIX='https://launchpad.net/~demonchild2112/+archive/ubuntu/emacs/+files'
# Sanity-check the deb-url pattern we use for checking whether a package
# was uploaded.
readonly CONTROL_DEB_URL="${DEB_URL_PREFIX}/emacs-extras_1.0-0ubuntu2~xenial_amd64.deb"
if [[ "$(curl -s -w %{http_code} --head "${CONTROL_DEB_URL}" -o /dev/null)" != '303' ]]; then
  echo "Error: Unexpected response code for ${CONTROL_DEB_URL}"
  exit 1
fi

# Figure out which packages to build and upload.
declare -a RELEASES_TO_UPLOAD
for release in "${CURRENT_UBUNTU_RELEASES[@]}"; do
  if [[ "${release}" == 'precise' ]]; then
    # emacs24 is not available for precise.
    continue
  fi
  deb_url="${DEB_URL_PREFIX}/emacs-extras_${VERSION}~${release}_amd64.deb"
  deb_response_code="$(curl -s -w %{http_code} --head "${deb_url}" -o /dev/null)"
  if [[ "${deb_response_code}" == '303' ]]; then
    echo "Found ${deb_url}"
    continue
  elif [[ "${deb_response_code}" == '404' ]]; then
    RELEASES_TO_UPLOAD+=("${release}")
  else
    echo "Error: Unexpected response code (${deb_response_code}) for ${deb_url}"
    exit 1
  fi
done

if [[ ${#RELEASES_TO_UPLOAD[@]} -eq 0 ]]; then
  echo "No new packages to upload."
  exit 0
fi

rm -rf /tmp/emacs-extras-builds
mkdir /tmp/emacs-extras-builds

for release in "${RELEASES_TO_UPLOAD[@]}"; do
  debchange --create \
    --newversion "${VERSION}~${release}" \
    --package emacs-extras \
    --urgency low \
    --controlmaint \
    --distribution "${release}" \
    "${DESCRIPTION}"
  echo "Building for ${release}"
  debuild -S -p'gpg --passphrase-file emacs-extras/travis_gpg_pass.txt --batch --no-use-agent'
  cd ../
  mkdir "/tmp/emacs-extras-builds/${release}"
  mv emacs-extras_* "/tmp/emacs-extras-builds/${release}"
  cd -
  dh clean
  rm -f debian/changelog
done

if [[ "${1}" != '--upload' ]]; then
  exit 0
fi

for release in "${RELEASES_TO_UPLOAD[@]}"; do
  cd "/tmp/emacs-extras-builds/${release}"
  echo "Uploading ${release}..."
  dput "ppa:${UPLOAD_PPA}" "emacs-extras_${VERSION}~${release}_source.changes"
done
