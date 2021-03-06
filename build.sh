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

function fatal() {
  >&2 echo "Error: ${1}"
  exit 1
}

python -c "import lxml"

if [[ $? -ne 0 ]]; then
  fatal "Error: Install lxml before continuing."
fi

readonly VERSION='1.1-0ubuntu1'
readonly DESCRIPTION='Add more color themes.'
readonly UPLOAD_PPA=${UPLOAD_PPA:-demonchild2112/emacs}

readonly CURRENT_UBUNTU_RELEASES=($(python fetch_ubuntu_releases.py))
if [[ ${#CURRENT_UBUNTU_RELEASES[@]} -eq 0 ]]; then
  echo "Error: Failed to fetch the list of current Ubuntu releases."
  exit 1
fi

readonly DEB_URL_PREFIX='https://launchpad.net/~demonchild2112/+archive/ubuntu/emacs/+files'
# Sanity-check the deb-url pattern we use for checking whether a package
# was uploaded.
readonly CONTROL_DEB_URL="${DEB_URL_PREFIX}/emacs-extras_1.1-0ubuntu1~xenial_amd64.deb"
if [[ "$(curl -s -w %{http_code} --head "${CONTROL_DEB_URL}" -o /dev/null)" != '303' ]]; then
  fatal "Error: Unexpected response code for ${CONTROL_DEB_URL}"
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
    fatal "Error: Unexpected response code (${deb_response_code}) for ${deb_url}"
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
  if [[ -f travis_gpg_pass.txt ]]; then
    debuild -S -p'gpg --passphrase-file emacs-extras/travis_gpg_pass.txt --batch --no-use-agent'
  else
    if [[ "${1}" == '--upload' ]]; then
      debuild -S
    else
      debuild
    fi
  fi
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
