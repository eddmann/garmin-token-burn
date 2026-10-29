#!/usr/bin/env python3
"""Generate Connect IQ device folders (compiler.json / simulator.json)
without the login-gated SDK Manager.

The compiler jar (bin/monkeybrains.jar) ships a devices.xml containing full
definitions for every device (resolution, memory limits, fonts, part
numbers). The compiler itself only reads per-device JSON folders from
~/.Garmin/ConnectIQ/Devices, so this script converts the bundled XML into
that layout. Good enough to compile and sign a .prg; the simulator still
needs real device files (fonts, bitmaps) from the SDK Manager.

Usage: gen-devices.py --sdk <sdk-dir> --out <devices-dir> <deviceId> [...]
"""
import argparse
import json
import os
import xml.etree.ElementTree as ET
import zipfile

DEVICES_XML_PATH = "com/garmin/monkeybrains/devices/devices.xml"

# XML app ids → JSON app type names (AppTypeManager.getAppTypeFromJson)
APP_TYPE_MAP = {
    "background": "background",
    "datafield": "datafield",
    "glance": "glance",
    "watch-app": "watchApp",
    "watchface": "watchFace",
    "widget": "widget",
    "audio-content-provider-app": "audioContentProvider",
}


def build_device(dev):
    part_numbers = []
    for pn in dev.findall("./part_numbers/part_number"):
        languages = [
            {"code": lang.text, "fontSet": lang.get("font_set")}
            for lang in pn.findall("./languages/language")
        ]
        part_numbers.append({
            "number": pn.get("number"),
            "firmwareVersion": int(pn.get("firmwareVersion")),
            "connectIQVersion": pn.get("connectIQVersion"),
            "languages": languages,
        })

    app_types = [
        {"type": APP_TYPE_MAP[app.get("id")], "memoryLimit": int(app.get("memory_limit"))}
        for app in dev.findall("./app_types/app")
    ]

    font_sets = []
    for fs in dev.findall("./fonts/font_set"):
        fonts = [
            {"name": f.get("id"), "filename": f.text + ".cft"}
            for f in fs.findall("./font")
        ]
        font_sets.append({"fontSet": fs.get("id"), "fonts": fonts})

    res = dev.find("./resolution")
    launcher = dev.find("./launcher_icon")
    complication = dev.find("./complication_icon")

    compiler = {
        "deviceId": dev.get("id"),
        "displayName": dev.get("name"),
        "deviceFamily": dev.get("family"),
        "worldWidePartNumber": dev.get("part_number"),
        "resolution": {"width": int(res.get("width")), "height": int(res.get("height"))},
        "bitsPerPixel": int(dev.findtext("./bpp")),
        "pixelFormat": dev.findtext("./pixel_format", default="DEFAULT"),
        "orientation": dev.findtext("./orientation", default="GFX_ORNTN_0"),
        "alphaBlendingSupport": dev.findtext("./alpha_blending_support", default="FALSE").upper() == "TRUE",
        "appTypes": app_types,
        "partNumbers": part_numbers,
        "fonts": font_sets,
    }
    if launcher is not None:
        compiler["launcherIcon"] = {
            "width": int(launcher.get("width")),
            "height": int(launcher.get("height")),
        }
    if complication is not None:
        compiler["complicationIcon"] = {
            "width": int(complication.get("width")),
            "height": int(complication.get("height")),
        }

    simulator = {"fonts": font_sets}
    return compiler, simulator


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sdk", required=True, help="Connect IQ SDK directory")
    parser.add_argument("--out", required=True, help="devices output directory (e.g. ~/.Garmin/ConnectIQ/Devices)")
    parser.add_argument("devices", nargs="+", help="device ids (e.g. fr255)")
    args = parser.parse_args()

    jar = os.path.join(args.sdk, "bin", "monkeybrains.jar")
    with zipfile.ZipFile(jar) as z, z.open(DEVICES_XML_PATH) as f:
        root = ET.parse(f).getroot()

    wanted = set(args.devices)
    found = set()
    for dev in root.iter("device"):
        if dev.get("id") not in wanted:
            continue
        found.add(dev.get("id"))
        compiler, simulator = build_device(dev)
        dev_dir = os.path.join(os.path.expanduser(args.out), dev.get("id"))
        os.makedirs(dev_dir, exist_ok=True)
        with open(os.path.join(dev_dir, "compiler.json"), "w") as f:
            json.dump(compiler, f, indent=2)
        with open(os.path.join(dev_dir, "simulator.json"), "w") as f:
            json.dump(simulator, f, indent=2)
        print("generated", dev_dir)

    missing = wanted - found
    if missing:
        raise SystemExit(f"device ids not found in bundled devices.xml: {sorted(missing)}")


if __name__ == "__main__":
    main()
