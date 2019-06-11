"""A tool for fetching and printing names of supported Ubuntu releases."""

import urllib2

from lxml import html


if __name__ == "__main__":
  tree = html.fromstring(urllib2.urlopen("http://releases.ubuntu.com").read())
  releases_header = tree.xpath(
      "//h1[text()='These releases of Ubuntu are available']")[0]
  release_anchors = releases_header.xpath("../../div[2]/ul/li/a")
  for anchor in release_anchors:
    print(anchor.get("href")[:-1])
