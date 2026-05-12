#!/usr/bin/env python3
"""Prepend a new release entry to docs/appcast.xml.

Run from the release workflow after the DMG is built, notarized, and
signed with Sparkle's sign_update tool.
"""

from __future__ import annotations

import argparse
import sys
from datetime import datetime, timezone
from pathlib import Path


ITEM_TEMPLATE = """    <item>
      <title>{title}</title>
      <link>{link}</link>
      <pubDate>{pub_date}</pubDate>
      <sparkle:version>{version}</sparkle:version>
      <sparkle:shortVersionString>{version}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>{min_macos}</sparkle:minimumSystemVersion>
      <enclosure
        url="{url}"
        length="{size}"
        type="application/octet-stream"
        sparkle:edSignature="{signature}"/>
    </item>"""


def render_item(args: argparse.Namespace) -> str:
    pub_date = datetime.now(timezone.utc).strftime("%a, %d %b %Y %H:%M:%S +0000")
    return ITEM_TEMPLATE.format(
        title=f"v{args.version}",
        link=args.release_notes_url,
        pub_date=pub_date,
        version=args.version,
        min_macos=args.min_macos,
        url=args.url,
        size=args.size,
        signature=args.signature,
    )


def prepend_item(appcast_path: Path, item_xml: str) -> None:
    if not appcast_path.exists():
        print(f"::error::appcast not found at {appcast_path}", file=sys.stderr)
        sys.exit(1)

    content = appcast_path.read_text()
    needle = "</channel>"
    if needle not in content:
        print(f"::error::no </channel> in {appcast_path}", file=sys.stderr)
        sys.exit(1)
    new_content = content.replace(needle, f"{item_xml}\n  </channel>")
    appcast_path.write_text(new_content)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True, help="e.g. 0.6.0")
    parser.add_argument("--url", required=True, help="DMG download URL")
    parser.add_argument("--signature", required=True, help="sparkle:edSignature value")
    parser.add_argument("--size", required=True, type=int, help="DMG byte size")
    parser.add_argument(
        "--release-notes-url",
        required=True,
        help="GitHub Releases page URL for this version",
    )
    parser.add_argument(
        "--min-macos",
        default="14.0",
        help="Minimum macOS version (default 14.0)",
    )
    parser.add_argument(
        "--appcast",
        default="docs/appcast.xml",
        type=Path,
        help="Path to appcast.xml",
    )
    args = parser.parse_args()

    item_xml = render_item(args)
    prepend_item(args.appcast, item_xml)
    print(f"Prepended v{args.version} entry to {args.appcast}")


if __name__ == "__main__":
    main()
