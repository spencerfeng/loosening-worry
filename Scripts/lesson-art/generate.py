"""Writes every drawing in art.py into the asset catalog as an image set named "lessonN.slot", with a dark version,
and sets each card's `tint` in lessons.json to its drawing's panel, so a card shows a panel only once it has art.

    python3 Scripts/lesson-art/generate.py
"""
import json
import pathlib
import shutil

import art

ROOT = pathlib.Path(__file__).resolve().parents[2]
FOLDER = ROOT / 'LooseningWorry/Resources/Assets.xcassets/Lessons'
LESSONS = ROOT / 'LooseningWorry/Resources/lessons.json'
TINTS = {art.VT: 'violet', art.BT: 'blue', art.AT: 'amber', art.GT: 'green'}

# Dark mode: the panel tints (used inside the art for cut-outs) and the deeper hues take the theme's dark values.
DARK = {
    art.VT: '#2A2347', art.BT: '#1E2B47', art.AT: '#3A2C17', art.GT: '#17322A',
    art.V: '#8A73EE', art.GD: '#5CC48F', art.B: '#4C82F0',
}


def svg(body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="342" height="200" viewBox="0 0 342 200">'
            f'{art.outline(body)}</svg>\n')


def dark(text):
    for light, night in DARK.items():
        text = text.replace(f'"{light}"', f'"{night}"')
    return text


def main():
    if FOLDER.exists():
        shutil.rmtree(FOLDER)
    FOLDER.mkdir(parents=True)
    (FOLDER / 'Contents.json').write_text(json.dumps({'info': {'author': 'xcode', 'version': 1}}, indent=2) + '\n')
    for name, (_, body) in sorted(art.ART.items()):
        asset = 'lesson' + name.removeprefix('day')
        folder = FOLDER / f'{asset}.imageset'
        folder.mkdir()
        light = svg(body)
        (folder / 'light.svg').write_text(light)
        (folder / 'dark.svg').write_text(dark(light))
        contents = {
            'images': [
                {'filename': 'light.svg', 'idiom': 'universal'},
                {'appearances': [{'appearance': 'luminosity', 'value': 'dark'}], 'filename': 'dark.svg',
                 'idiom': 'universal'},
            ],
            'info': {'author': 'xcode', 'version': 1},
            'properties': {'preserves-vector-representation': True},
        }
        (folder / 'Contents.json').write_text(json.dumps(contents, indent=2) + '\n')
    print(f'{len(art.ART)} illustrations written to {FOLDER.relative_to(ROOT)}')
    set_tints()


def set_tints():
    """The same slot names as `Lesson.illustration(at:)` in the app."""
    lessons = json.loads(LESSONS.read_text())
    for lesson in lessons:
        ideas = 0
        for card in lesson['cards']:
            if card['kind'] == 'idea':
                ideas += 1
            slot = {'idea': f'idea{ideas}', 'tryIt': 'try'}.get(card['kind'], card['kind'])
            drawing = art.ART.get(f"day{lesson['day']}.{slot}")
            card.pop('tint', None)
            if drawing:
                card['tint'] = TINTS[drawing[0]]
    LESSONS.write_text(json.dumps(lessons, indent=2, ensure_ascii=False) + '\n')
    print(f'Tints set in {LESSONS.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
