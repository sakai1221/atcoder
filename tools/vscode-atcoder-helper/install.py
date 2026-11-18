#!/usr/bin/env python3
"""この拡張を .vsix にまとめて VSCode (WSL 側) にインストールする。

  python3 tools/vscode-atcoder-helper/install.py

インストール後、VSCode で Ctrl+Shift+P → "Developer: Reload Window" を1回実行する。
extension.js / package.json を直したときも、これを実行し直す (package.json の version は同じでよい)。
"""
import json
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent

CONTENT_TYPES = """<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension=".json" ContentType="application/json"/>
  <Default Extension=".js" ContentType="application/javascript"/>
  <Default Extension=".vsixmanifest" ContentType="text/xml"/>
</Types>
"""

MANIFEST = """<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="{name}" Version="{version}" Publisher="{publisher}"/>
    <DisplayName>{display}</DisplayName>
    <Description xml:space="preserve">{description}</Description>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine" Value="{engine}"/>
      <Property Id="Microsoft.VisualStudio.Code.ExtensionKind" Value="workspace"/>
    </Properties>
  </Metadata>
  <Installation>
    <InstallationTarget Id="Microsoft.VisualStudio.Code"/>
  </Installation>
  <Dependencies/>
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/>
  </Assets>
</PackageManifest>
"""


def main() -> None:
    pkg = json.loads((HERE / "package.json").read_text())
    manifest = MANIFEST.format(
        name=pkg["name"], version=pkg["version"], publisher=pkg["publisher"],
        display=pkg["displayName"], description=pkg["description"], engine=pkg["engines"]["vscode"])
    with tempfile.TemporaryDirectory() as tmp:
        vsix = Path(tmp) / f"{pkg['name']}.vsix"
        with zipfile.ZipFile(vsix, "w", zipfile.ZIP_DEFLATED) as z:
            z.writestr("[Content_Types].xml", CONTENT_TYPES)
            z.writestr("extension.vsixmanifest", manifest)
            for name in ("package.json", "extension.js"):
                z.write(HERE / name, f"extension/{name}")
        r = subprocess.run(["code", "--install-extension", str(vsix), "--force"])
    if r.returncode != 0:
        sys.exit(r.returncode)
    print('インストールした。VSCode で Ctrl+Shift+P → "Developer: Reload Window" を1回実行する')


if __name__ == "__main__":
    main()
