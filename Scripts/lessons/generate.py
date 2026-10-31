"""Builds lessons.json from lessons.md, the course's words card by card. Each card's `tint` is its drawing's panel in
Scripts/lesson-art/art.py, so a card shows a panel only once it has art.

    python3 Scripts/lessons/generate.py

In lessons.md each day is a "## Day N · Title" section. Its first line names the key idea and today's task, whose
words become the task card's title. Then come the cards, each a bold heading and its paragraphs: **Hook**,
**Idea N — Title**, **Example — Title**, **Try it now (N s)** and **Today's task**, which may end with
*Button: Label* (where the task goes) and a **Footer** heading with its line.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SOURCE = pathlib.Path(__file__).with_name('lessons.md')
LESSONS = ROOT / 'LooseningWorry/Resources/lessons.json'
sys.path.insert(0, str(ROOT / 'Scripts/lesson-art'))
import art  # noqa: E402

TINTS = {art.VT: 'violet', art.BT: 'blue', art.AT: 'amber', art.GT: 'green'}
# Button labels as written, and the task each opens (`LessonAction` in LessonCatalog.swift).
ACTIONS = {
    'Log a loop': 'logLoop', 'Open Insights': 'openInsights', 'Open Settings': 'openSettings',
    'Get curious': 'curious', 'Breathe': 'breathe', 'Note it': 'noteIt', 'Be kind': 'beKind',
}
# The drawing each card kind takes; ideas are numbered in order.
SLOTS = {'hook': 'hook', 'example': 'example', 'tryIt': 'try', 'task': 'task'}


def card_for(heading, task, day):
    if heading == 'Hook':
        return {'kind': 'hook'}
    if heading.startswith('Idea'):
        return {'kind': 'idea', 'title': heading.split(' — ', 1)[1]}
    if heading.startswith('Example'):
        return {'kind': 'example', 'title': heading.split(' — ', 1)[1]}
    if heading.startswith('Try it now'):
        return {'kind': 'tryIt', 'seconds': int(re.search(r'\((\d+) s\)', heading)[1])}
    if heading == "Today's task":
        return {'kind': 'task', 'title': task}
    raise SystemExit(f'Day {day}: unknown heading "{heading}"')


def lesson(section):
    head, *rest = section.strip().split('\n')
    match = re.fullmatch(r'Day (\d+) · (.+)', head)
    day, title = int(match[1]), match[2].strip()
    paragraphs = [p.strip() for p in '\n'.join(rest).split('\n\n') if p.strip()]
    task = re.search(r'\*\*Task:\*\* (.+?)\.?$', paragraphs[0])[1]
    task = task[0].upper() + task[1:]
    cards, in_footer = [], False
    for paragraph in paragraphs[1:]:
        heading = re.fullmatch(r'\*\*(.+?)\*\*', paragraph)
        button = re.fullmatch(r'\*Button: (.+)\*', paragraph)
        if heading and heading[1].startswith('Footer'):
            in_footer = True
        elif heading:
            cards.append(card_for(heading[1], task, day))
        elif button:
            cards[-1]['action'] = ACTIONS[button[1]]
        elif in_footer:
            cards[-1]['footer'] = paragraph
        else:
            card = cards[-1]
            card['body'] = f"{card['body']}\n\n{paragraph}" if 'body' in card else paragraph
    if not cards or cards[0]['kind'] != 'hook' or cards[-1]['kind'] != 'task':
        raise SystemExit(f'Day {day}: a lesson runs from its hook to today\'s task')
    ideas = 0
    for card in cards:
        if card['kind'] == 'idea':
            ideas += 1
            slot = f'idea{ideas}'
        else:
            slot = SLOTS[card['kind']]
        drawing = art.ART.get(f'day{day}.{slot}')
        if drawing:
            card['tint'] = TINTS[drawing[0]]
    return {'day': day, 'title': title, 'minutes': 5, 'cards': cards}


lessons = [lesson(section) for section in re.split(r'^## ', SOURCE.read_text(), flags=re.M)[1:]]
LESSONS.write_text(json.dumps(lessons, indent=2, ensure_ascii=False) + '\n')
print(f'{len(lessons)} lessons written to {LESSONS.relative_to(ROOT)}')
