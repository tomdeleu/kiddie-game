#!/usr/bin/env python3
"""Structural checks for De Bakkerij and the five-room round loop.

There is no Swift compiler in this container. This script is the reviewer
artifact: it reads the files a compiler would type-check and fails if the
loop contract is not actually in them.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "NinaBakeryPOC"
SOURCES = APP / "Sources"
VOICE = APP / "Resources" / "Voice"
FAILS: list[str] = []


def read(path: Path) -> str:
    if not path.exists():
        FAIL(f"missing file {path.relative_to(ROOT)}")
        return ""
    return path.read_text()


def FAIL(msg: str) -> None:
    FAILS.append(msg)


def must_contain(path: Path, needle: str, why: str) -> None:
    text = read(path)
    if needle not in text:
        FAIL(f"{path.relative_to(ROOT)}: expected {why!r} ({needle!r})")


def main() -> int:
    room_swift = read(SOURCES / "Game" / "Room.swift")
    if not re.search(
        r"case bakkerij,\s*tuin,\s*keuken,\s*versieren,\s*feest",
        room_swift,
    ):
        FAIL("RoomID is not in round order bakkerij, tuin, keuken, versieren, feest")
    must_contain(
        SOURCES / "Game" / "Room.swift",
        "case bakkerij(FeestResult?)",
        "RoomExit.bakkerij carries an optional party result",
    )

    content = read(SOURCES / "ContentView.swift")
    must_contain(
        SOURCES / "ContentView.swift",
        "currentRoom: RoomID = .bakkerij",
        "GameScene starts on the bakery",
    )
    must_contain(
        SOURCES / "ContentView.swift",
        "enter(.bakkerij, greeting: greeting)",
        "resume() with no round opens the bakery",
    )
    must_contain(
        SOURCES / "ContentView.swift",
        "IntroMovie.hasPlayed",
        "film plays once",
    )
    must_contain(
        SOURCES / "ContentView.swift",
        "BakkerijRoom.lighting(from: settings)",
        "bakery lighting is applied",
    )
    must_contain(
        SOURCES / "ContentView.swift",
        "friend: friend",
        "garden and later rooms receive the friend",
    )
    if "roundFriend = nil" not in content or "wishCard = nil" not in content:
        FAIL("ContentView: visit return to bakery does not clear the round")

    garden = read(SOURCES / "Garden" / "GardenRoom.swift")
    must_contain(
        SOURCES / "Garden" / "GardenRoom.swift",
        "friend: Friend? = nil",
        "GardenRoom takes a friend",
    )
    must_contain(
        SOURCES / "Garden" / "GardenRoom.swift",
        "friend?.hintedIngredient",
        "garden idle hint reads the wish jar",
    )
    must_contain(
        SOURCES / "Garden" / "GardenRoom.swift",
        "onExit?(.bakkerij(nil))",
        "garden visit door returns home",
    )
    must_contain(
        SOURCES / "Garden" / "GardenRoom.swift",
        "onExit?(.keuken(basket))",
        "garden round door hands the basket",
    )

    kitchen = read(SOURCES / "Kitchen" / "KitchenRoom.swift")
    if "state.lastFinished != nil" not in kitchen:
        FAIL("KitchenRoom.roomComplete does not use lastFinished for a round")
    must_contain(
        SOURCES / "Kitchen" / "KitchenRoom.swift",
        "onExit?(.bakkerij(nil))",
        "kitchen visit door returns home",
    )
    must_contain(
        SOURCES / "Kitchen" / "KitchenRoom.swift",
        "onExit?(.versieren(cake))",
        "kitchen round door hands the cake",
    )

    versier = read(SOURCES / "Versieren" / "VersierRoom.swift")
    must_contain(
        SOURCES / "Versieren" / "VersierRoom.swift",
        "friend: Friend? = nil",
        "VersierRoom takes a friend",
    )
    must_contain(
        SOURCES / "Versieren" / "VersierRoom.swift",
        "friend?.hintedSticker",
        "decorating idle hint reads the wish tray",
    )
    must_contain(
        SOURCES / "Versieren" / "VersierRoom.swift",
        ".bakkerij(nil)",
        "decorating visit door returns home",
    )
    must_contain(
        SOURCES / "Versieren" / "VersierRoom.swift",
        ".feest(cake)",
        "decorating round door hands the cake",
    )

    feest = read(SOURCES / "Feest" / "FeestRoom.swift")
    must_contain(
        SOURCES / "Feest" / "FeestRoom.swift",
        "friend handedFriend: Friend? = nil",
        "FeestRoom takes a handed friend",
    )
    must_contain(
        SOURCES / "Feest" / "FeestRoom.swift",
        "FeestResult(friend: state.friend, cake: state.cake, matched: matched)",
        "party tap builds a FeestResult",
    )
    must_contain(
        SOURCES / "Feest" / "FeestRoom.swift",
        ".bakkerij(result)",
        "party round tap returns the result",
    )
    if "startFreshParty()" in feest.split("private func tapCake()")[1].split(
        "private func eatTheCake()"
    )[0]:
        FAIL("FeestRoom.tapCake still starts a fresh party instead of going home")

    bakery = read(SOURCES / "Bakkerij" / "BakkerijRoom.swift")
    must_contain(
        SOURCES / "Bakkerij" / "BakkerijRoom.swift",
        "static func lighting(from settings: LightingSettings)",
        "BakkerijRoom.lighting exists",
    )
    must_contain(
        SOURCES / "Bakkerij" / "BakkerijRoom.swift",
        'arguments.contains("-no-bakkerij-ao")',
        "bakery lighting has an A/B flag",
    )
    must_contain(
        SOURCES / "Bakkerij" / "BakkerijRoom.swift",
        "sqrt(settings.contactShadowOpacity)",
        "contact shadows compensate for the double write",
    )
    must_contain(
        SOURCES / "Bakkerij" / "BakkerijRoom.swift",
        "onExit?(.tuin(friend))",
        "bakery outbound exit names the friend",
    )
    must_contain(
        SOURCES / "Bakkerij" / "BakkerijRoom.swift",
        "debugTitle: String { RoomID.bakkerij.title }",
        "debug title uses RoomID",
    )

    must_contain(
        SOURCES / "Bakkerij" / "BakkerijAO.swift",
        "punchAmount: CGFloat = 1.6",
        "bakery chroma punch matches Het Feest",
    )
    must_contain(
        SOURCES / "Bakkerij" / "BakkerijProps.swift",
        "BakkerijAO.paint",
        "props are painted through BakkerijAO",
    )
    must_contain(
        SOURCES / "Bakkerij" / "BakkerijProps.swift",
        "root.excludeFromShadowCasting()",
        "wall-hugging bakery furniture does not cast",
    )
    must_contain(
        SOURCES / "Bakkerij" / "FrameWall.swift",
        "root.excludeFromShadowCasting()",
        "frames on the wall do not cast",
    )

    store = read(SOURCES / "Game" / "GameStore.swift")
    must_contain(
        SOURCES / "Game" / "GameStore.swift",
        "var goldIsEarned: Bool { filledCount >= Friend.allCases.count }",
        "gold frame is derived, never stored",
    )
    if re.search(r"frames\[.goud", store):
        FAIL("GameStore stores a gold frame slot")

    must_contain(
        SOURCES / "Intro" / "IntroMovie.swift",
        'forKey: "introPlayed"',
        "film-once flag lives in UserDefaults",
    )
    must_contain(
        SOURCES / "Feest" / "Friend.swift",
        "var hintedIngredient: Ingredient?",
        "Friend exposes the garden hint",
    )

    plates = [
        "bel.png",
        "lijstje-twee-staten.png",
        "poes.png",
        "raam.png",
        "radio.png",
        "tekeningen.png",
        "uithangbord-twee-staten.png",
        "vriend-aan-toonbank.png",
        "roombox-v2.png",
        "wall-of-frames.png",
        "rolluik.png",
        "winkeldeur.png",
        "bestelhaak.png",
    ]
    for name in plates:
        path = ROOT / "references" / "bakkerij" / name
        if not path.exists():
            FAIL(f"missing plate {path.relative_to(ROOT)}")

    line_ids = set(
        re.findall(
            r'static let \w+ = "([^"]+)"',
            read(SOURCES / "Bakkerij" / "BakkerijRoom.swift"),
        )
    )
    friends_match = re.search(
        r"enum Friend[^{]+\{[^}]*case ([^\n]+)",
        read(SOURCES / "Feest" / "Friend.swift"),
    )
    friends = [part.strip() for part in friends_match.group(1).split(",")] if friends_match else []
    if len(friends) != 11:
        FAIL(f"expected 11 friends, found {friends}")
    for friend in friends:
        line_ids.add(f"nina.bakkerij.wens.{friend}")

    script_path = ROOT / "audio" / "script-bakkerij.json"
    bundled_path = VOICE / "script-bakkerij.json"
    script = json.loads(read(script_path) or "{}")
    bundled = json.loads(read(bundled_path) or "{}")
    script_ids = {line["id"] for line in script.get("lines", [])}
    bundled_ids = {line["id"] for line in bundled.get("lines", [])}
    if script_ids != bundled_ids:
        FAIL("audio/script-bakkerij.json ids differ from the bundled copy")
    missing_in_script = sorted(line_ids - script_ids)
    extra_unused = sorted(script_ids - line_ids)
    if missing_in_script:
        FAIL(f"BakkerijLine ids missing from script: {missing_in_script}")
    if extra_unused:
        FAIL(f"script ids with no BakkerijLine constant: {extra_unused}")

    voice_files = {p.name for p in VOICE.glob("nina-bakkerij-*.mp3")}
    voice_files.update(p.name for p in VOICE.glob("nina-dit-*.mp3"))
    for line in script.get("lines", []):
        for variant in line.get("variants", []):
            name = variant["file"]
            if not (VOICE / name).exists():
                FAIL(f"missing voice file {name} for {line['id']}")

    if FAILS:
        print("verify-bakkerij-loop: FAIL")
        for item in FAILS:
            print(f"  - {item}")
        return 1
    print("verify-bakkerij-loop: PASS")
    print(f"  RoomID order, RoomExit.bakkerij, launch, film-once, five handovers")
    print(f"  wish hints, lighting, {len(line_ids)} line ids, {len(friends)} friends")
    print(f"  {len(script.get('lines', []))} script lines, extra plates on disk")
    return 0


if __name__ == "__main__":
    sys.exit(main())
