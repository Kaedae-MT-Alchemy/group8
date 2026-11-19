"""Builds the sample learning materials and lib/data/course_seed_content.dart.

    pip install python-docx python-pptx reportlab
    python tool/course_content/build_course_content.py

Outputs per course in assets/materials/<course id>/:
    slides.pptx, workbook.pdf, worksheet.docx, action-plan.pdf, welcome.mp4
(the MP4 needs ffmpeg on PATH; it is skipped when ffmpeg is missing).
"""
import json
import os
import shutil
import subprocess
import sys

from docx import Document
from docx.shared import Pt, RGBColor
from pptx import Presentation
from pptx.dml.color import RGBColor as PRGB
from pptx.util import Inches, Pt as PPt
from reportlab.lib.colors import HexColor
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (ListFlowable, ListItem, PageBreak, Paragraph,
                                SimpleDocTemplate, Spacer, Table, TableStyle)

sys.path.insert(0, os.path.dirname(__file__))
from content import COURSES, YT  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
ASSETS = os.path.join(ROOT, 'assets', 'materials')
DART = os.path.join(ROOT, 'lib', 'data', 'course_seed_content.dart')

DEEP = '#1E128C'
PURPLE = '#5B3CC4'
YELLOW = '#F5C518'


# ---------------------------------------------------------------- PPTX deck
def build_slides(cid, course, path):
    prs = Presentation()
    prs.slide_width, prs.slide_height = Inches(13.333), Inches(7.5)
    blank = prs.slide_layouts[6]

    def slide(title, lines, kicker=None, dark=False):
        s = prs.slides.add_slide(blank)
        bg = s.background.fill
        bg.solid()
        bg.fore_color.rgb = PRGB.from_string((DEEP if dark else 'FFFFFF').lstrip('#'))
        y = Inches(0.8)
        if kicker:
            tb = s.shapes.add_textbox(Inches(0.8), y, Inches(11.5), Inches(0.5))
            p = tb.text_frame.paragraphs[0]
            p.text = kicker.upper()
            p.font.size = PPt(16)
            p.font.bold = True
            p.font.color.rgb = PRGB.from_string(YELLOW.lstrip('#') if dark else PURPLE.lstrip('#'))
            y += Inches(0.6)
        tb = s.shapes.add_textbox(Inches(0.8), y, Inches(11.7), Inches(1.4))
        tf = tb.text_frame
        tf.word_wrap = True
        p = tf.paragraphs[0]
        p.text = title
        p.font.size = PPt(40)
        p.font.bold = True
        p.font.color.rgb = PRGB.from_string('FFFFFF' if dark else DEEP.lstrip('#'))
        if lines:
            body = s.shapes.add_textbox(Inches(0.8), y + Inches(1.7), Inches(11.7), Inches(4.5)).text_frame
            body.word_wrap = True
            for i, line in enumerate(lines):
                q = body.paragraphs[0] if i == 0 else body.add_paragraph()
                q.text = line
                q.font.size = PPt(22)
                q.space_after = PPt(12)
                q.font.color.rgb = PRGB.from_string('FFFFFF' if dark else '222222')

    slide(course['title'], ['MT Alchemy · Course slides', f"{len(course['modules'])} modules · video, reading and practice in each"], 'MT Alchemy', dark=True)
    slide('What you will learn', [f"Module {i + 1}: {m['title']}" for i, m in enumerate(course['modules'])], 'Course overview')
    for i, m in enumerate(course['modules']):
        slide(m['title'], [m['summary']], f'Module {i + 1}')
        slide('Key ideas', ['• ' + p for p in m['points']], f"Module {i + 1} · {m['title']}")
        slide('Try this', [m['practice']], f'Module {i + 1} · Practice', dark=True)
    slide('Next steps', ['Complete every lesson in the course player.', 'Pass the course quiz to earn your certificate.', 'Use the workbook and worksheet to plan how you will apply the learning.'], 'Well done', dark=True)
    prs.save(path)


# ---------------------------------------------------------------- PDF files
def _styles():
    ss = getSampleStyleSheet()
    return {
        'kicker': ParagraphStyle('k', parent=ss['Normal'], fontName='Helvetica-Bold', fontSize=9, textColor=HexColor(PURPLE), spaceAfter=4),
        'h1': ParagraphStyle('h1', parent=ss['Title'], fontName='Helvetica-Bold', fontSize=24, leading=29, textColor=HexColor(DEEP), alignment=0, spaceAfter=8),
        'h2': ParagraphStyle('h2', parent=ss['Heading2'], fontName='Helvetica-Bold', fontSize=16, leading=20, textColor=HexColor(DEEP), spaceBefore=10, spaceAfter=6),
        'h3': ParagraphStyle('h3', parent=ss['Heading3'], fontName='Helvetica-Bold', fontSize=11, textColor=HexColor(PURPLE), spaceBefore=8, spaceAfter=4),
        'body': ParagraphStyle('b', parent=ss['Normal'], fontName='Helvetica', fontSize=10.5, leading=15, spaceAfter=6),
    }


def _lines(n):
    t = Table([[''] for _ in range(n)], colWidths=[170 * mm], rowHeights=[8 * mm] * n)
    t.setStyle(TableStyle([('LINEBELOW', (0, 0), (-1, -1), 0.4, HexColor('#BBBBCC'))]))
    return t


def _esc(s):
    return s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def build_workbook(cid, course, path):
    st = _styles()
    doc = SimpleDocTemplate(path, pagesize=A4, leftMargin=20 * mm, rightMargin=20 * mm, topMargin=18 * mm, bottomMargin=18 * mm,
                            title=f"{course['title']} workbook", author='MT Alchemy')
    out = [Paragraph('MT ALCHEMY · LEARNER WORKBOOK', st['kicker']), Paragraph(_esc(course['title']), st['h1']),
           Paragraph('Use this workbook alongside the course player. Each module has a summary, the key ideas, a practice activity and space for your notes.', st['body'])]
    for i, m in enumerate(course['modules']):
        if i:
            out.append(PageBreak())
        out += [Paragraph(f'MODULE {i + 1}', st['kicker']), Paragraph(_esc(m['title']), st['h2']), Paragraph(_esc(m['summary']), st['body']),
                Paragraph('Key ideas', st['h3']),
                ListFlowable([ListItem(Paragraph(_esc(p), st['body']), leftIndent=12) for p in m['points']], bulletType='bullet', start='•'),
                Paragraph('Practice', st['h3']), Paragraph(_esc(m['practice']), st['body']),
                Paragraph('My notes', st['h3']), _lines(8)]
    doc.build(out)


def build_action_plan(cid, course, path):
    st = _styles()
    doc = SimpleDocTemplate(path, pagesize=A4, leftMargin=20 * mm, rightMargin=20 * mm, topMargin=18 * mm, bottomMargin=18 * mm,
                            title=f"{course['title']} action plan", author='MT Alchemy')
    rows = [['Module', 'What I will do', 'By when', 'Done']] + [[m['title'], '', '', ''] for m in course['modules']]
    t = Table(rows, colWidths=[55 * mm, 75 * mm, 25 * mm, 15 * mm], rowHeights=[9 * mm] + [20 * mm] * len(course['modules']))
    t.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), HexColor(DEEP)), ('TEXTCOLOR', (0, 0), (-1, 0), HexColor('#FFFFFF')),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'), ('FONTSIZE', (0, 0), (-1, -1), 9.5),
        ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#BBBBCC')), ('VALIGN', (0, 0), (-1, -1), 'TOP'),
    ]))
    out = [Paragraph('MT ALCHEMY · ACTION PLAN', st['kicker']), Paragraph(_esc(course['title']), st['h1']),
           Paragraph('Turn the course into action. For each module, write one specific thing you will do, when you will do it, and tick it off when done.', st['body']),
           Spacer(1, 6), t, Spacer(1, 10), Paragraph('Who will support me', st['h3']), _lines(2),
           Paragraph('How I will know it is working', st['h3']), _lines(3)]
    doc.build(out)


# ---------------------------------------------------------------- DOCX
def build_worksheet(cid, course, path):
    d = Document()
    style = d.styles['Normal']
    style.font.name = 'Calibri'
    style.font.size = Pt(11)
    k = d.add_paragraph()
    r = k.add_run('MT ALCHEMY · REFLECTION WORKSHEET')
    r.bold = True
    r.font.color.rgb = RGBColor.from_string(PURPLE.lstrip('#'))
    h = d.add_heading(course['title'], level=0)
    for run in h.runs:
        run.font.color.rgb = RGBColor.from_string(DEEP.lstrip('#'))
    d.add_paragraph('Answer each question after you finish the module. You can type in this document or print it.')
    d.add_paragraph('Name: ______________________    Date: ______________')
    for i, m in enumerate(course['modules']):
        hh = d.add_heading(f"Module {i + 1}: {m['title']}", level=1)
        for run in hh.runs:
            run.font.color.rgb = RGBColor.from_string(DEEP.lstrip('#'))
        d.add_paragraph(m['summary'])
        table = d.add_table(rows=3, cols=2)
        table.style = 'Table Grid'
        qs = [f"Which key idea from \"{m['title']}\" matters most in your role, and why?",
              f"Practice: {m['practice']} What happened?",
              'What will you do differently from now on?']
        for row, q in zip(table.rows, qs):
            row.cells[0].text = q
            row.cells[1].text = '\n\n\n'
    d.save(path)


# ---------------------------------------------------------------- MP4
def build_video(cid, course, path):
    ff = shutil.which('ffmpeg')
    if not ff:
        print('  ffmpeg not found, skipping', path)
        return False
    font = 'C\\:/Windows/Fonts/arialbd.ttf' if os.name == 'nt' else '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
    title = course['title'].replace("'", '').replace(':', '\\:')
    mods = len(course['modules'])
    vf = (f"drawbox=x=0:y=446:w=iw:h=6:color=0xF5C518@1:t=fill,"
          f"drawtext=fontfile='{font}':text='MT ALCHEMY':fontcolor=0xF5C518:fontsize=26:x=60:y=70,"
          f"drawtext=fontfile='{font}':text='Welcome to':fontcolor=white:fontsize=34:x=60:y=150:alpha='min(1,t/1)',"
          f"drawtext=fontfile='{font}':text='{title}':fontcolor=white:fontsize=46:x=60:y=200:alpha='min(1,max(0,t-0.6))',"
          f"drawtext=fontfile='{font}':text='{mods} modules - videos - readings - practice - quiz':fontcolor=0xD8D0FF:fontsize=24:x=60:y=300:alpha='min(1,max(0,t-1.5))',"
          f"drawtext=fontfile='{font}':text='Mark each lesson complete then pass the quiz for your certificate.':fontcolor=white:fontsize=22:x=60:y=486:alpha='min(1,max(0,t-3))',format=yuv420p")
    cmd = [ff, '-y', '-loglevel', 'error', '-f', 'lavfi', '-i', 'color=c=0x1E128C:s=1280x720:d=10:r=25',
           '-f', 'lavfi', '-i', 'sine=frequency=432:duration=10:sample_rate=44100',
           '-vf', vf, '-af', 'volume=0.05,afade=t=in:d=1,afade=t=out:st=8.5:d=1.5',
           '-c:v', 'libx264', '-profile:v', 'main', '-pix_fmt', 'yuv420p', '-crf', '30',
           '-c:a', 'aac', '-b:a', '64k', '-movflags', '+faststart', '-shortest', path]
    subprocess.run(cmd, check=True)
    return True


# ---------------------------------------------------------------- Dart seed
def lessons_for(cid, course, has_video):
    base = f'assets/materials/{cid}'
    out = []

    def add(module, title, kind, body, minutes, url=None, file_name=None):
        out.append({'id': f'{cid}-{len(out) + 1}', 'module': module, 'title': title, 'type': kind, 'url': url or '',
                    'fileName': file_name or '', 'body': body, 'minutes': minutes})

    mods = course['modules']
    if has_video:
        add(0, 'Welcome to the course', 'video', f"A short welcome to {course['title']}: how the course works and how to earn your certificate.", 1,
            f'{base}/welcome.mp4', 'welcome.mp4')
    article_title, article_url = course['article']
    extra = [
        ('Course slides', 'slides', 'Slide deck covering every module. Open it full screen or download it for later.', 15, f'{base}/slides.pptx', 'slides.pptx'),
        ('Learner workbook', 'pdf', 'Summaries, key ideas, practice activities and space for your notes for each module.', 20, f'{base}/workbook.pdf', 'workbook.pdf'),
        ('Reflection worksheet', 'document', 'Download the Word worksheet, answer the reflection questions and keep it for your records.', 15, f'{base}/worksheet.docx', 'worksheet.docx'),
        ('Further reading: ' + article_title, 'link', 'Read this article to go deeper into the ideas from this module.', 10, article_url, None),
        ('Action plan', 'pdf', 'Turn what you learned into specific actions with dates. Print it or fill it in on screen.', 10, f'{base}/action-plan.pdf', 'action-plan.pdf'),
    ]
    for i, m in enumerate(mods):
        vtitle, vid = m['video']
        add(i, f'Watch: {vtitle}', 'video', f"Watch this talk and note one idea you can use in your work. It supports the module \"{m['title']}\".", 15, YT + vid)
        body = m['summary'] + '\n\nKey ideas\n' + '\n'.join('• ' + p for p in m['points']) + '\n\nTry this\n' + m['practice']
        add(i, f"Reading: {m['title']}", 'reading', body, 10)
        if i < len(extra):
            t, kind, b, mins, url, fn = extra[i]
            add(i, t, kind, b, mins, url, fn)
    return out


def quiz_for(course):
    return [{'type': t, 'prompt': p, 'options': o, 'answers': a, 'explanation': e} for (t, p, o, a, e) in course['quiz']]


def write_dart(data):
    body = json.dumps(data, ensure_ascii=True, indent=2).replace('$', '\\$')
    with open(DART, 'w', encoding='utf8', newline='\n') as f:
        f.write('// GENERATED by tool/course_content/build_course_content.py. Do not edit.\n')
        f.write('// Built-in lessons and quizzes, used when a course in the database has none.\n')
        f.write('// ignore_for_file: prefer_single_quotes, lines_longer_than_80_chars\n\n')
        f.write('const Map<String, Map<String, List<Map<String, Object>>>> seedCourseContent = ')
        f.write(body)
        f.write(';\n')


def main():
    data = {}
    for cid, course in COURSES.items():
        folder = os.path.join(ASSETS, cid)
        os.makedirs(folder, exist_ok=True)
        print('Building', cid)
        build_slides(cid, course, os.path.join(folder, 'slides.pptx'))
        build_workbook(cid, course, os.path.join(folder, 'workbook.pdf'))
        build_action_plan(cid, course, os.path.join(folder, 'action-plan.pdf'))
        build_worksheet(cid, course, os.path.join(folder, 'worksheet.docx'))
        mp4 = os.path.join(folder, 'welcome.mp4')
        has_video = build_video(cid, course, mp4) or os.path.exists(mp4)
        data[cid] = {'lessons': lessons_for(cid, course, has_video), 'quiz': quiz_for(course)}
    write_dart(data)
    print('Wrote', DART)


if __name__ == '__main__':
    main()
