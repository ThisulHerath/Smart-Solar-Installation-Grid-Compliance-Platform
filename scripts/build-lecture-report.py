"""Build the offline bilingual report from its two reviewed Markdown sources.

Intentionally supports only the headings, paragraphs, lists and inline markup
used by these reports. No network, external assets or Markdown dependency.
"""
from html import escape
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'docs' / 'assessment'


def inline(text):
    text = escape(text)
    text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
    return re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', text)


def render(source, lang):
    output, navigation, paragraph = [], [], []
    current_list = None

    def flush():
        if paragraph:
            output.append('<p>' + inline(' '.join(paragraph)) + '</p>')
            paragraph.clear()

    def close_list():
        nonlocal current_list
        if current_list:
            output.append(f'</{current_list}>')
            current_list = None

    for line in source.splitlines():
        heading = re.match(r'^(#{1,3}) (.+)$', line)
        item = re.match(r'^(?:- |\d+\. )(.+)$', line)
        if heading:
            flush(); close_list()
            level, label = len(heading[1]), heading[2]
            identity = f'{lang}-section-{len(navigation)}'
            if level == 2:
                navigation.append((identity, label))
            output.append(f'<h{level}' + (f' id="{identity}"' if level == 2 else '') + f'>{inline(label)}</h{level}>')
        elif item:
            flush()
            kind = 'ul' if line.startswith('- ') else 'ol'
            if current_list != kind:
                close_list(); output.append(f'<{kind}>'); current_list = kind
            output.append('<li>' + inline(item[1]) + '</li>')
        elif not line.strip():
            flush(); close_list()
        else:
            close_list(); paragraph.append(line)
    flush(); close_list()
    return '\n'.join(output), navigation


articles, menus = [], []
for lang in ('en', 'si'):
    body, headings = render((OUTPUT / f'lecture-theory-audit.{lang}.md').read_text(encoding='utf-8'), lang)
    articles.append(f'<article lang="{lang}" data-language="{lang}">{body}</article>')
    menus.append(f'<nav aria-label="{"Report contents" if lang == "en" else "වාර්තාවේ කොටස්"}" data-language="{lang}">' + ''.join(f'<a href="#{identifier}">{escape(label)}</a>' for identifier, label in headings) + '</nav>')

page = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Smart Solar • Lecture alignment report</title>
<style>
:root{color-scheme:light;--ink:#173f32;--muted:#526451;--paper:#f6f7ef;--line:#d3ddc7;--accent:#dcf08b}
*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:100px}body{margin:0;background:var(--paper);color:var(--ink);font:16px/1.8 "Segoe UI","Nirmala UI",sans-serif}
header{padding:22px 5vw;border-bottom:1px solid var(--line);background:#fffef8;display:flex;justify-content:space-between;align-items:center;gap:20px;flex-wrap:wrap}
.brand{font-weight:750;font-size:23px;letter-spacing:-1px}.brand small{display:block;font-size:12px;font-weight:500;letter-spacing:1px;color:var(--muted)}
.controls{display:flex;flex-wrap:wrap;gap:8px}button{font:inherit;border:1px solid #9aaf89;border-radius:24px;background:transparent;color:var(--ink);padding:9px 18px;min-height:48px;cursor:pointer}button[aria-pressed=true]{background:var(--ink);color:white}button:hover{border-color:var(--ink)}button:focus-visible,a:focus-visible{outline:3px solid #8da94a;outline-offset:4px}
.layout{max-width:1480px;margin:auto;padding:36px 5vw;display:grid;grid-template-columns:230px minmax(0,1fr);gap:52px}aside{position:sticky;top:24px;height:max-content}aside p{font-size:12px;letter-spacing:1px;font-weight:700}nav a{display:block;padding:8px 0;color:var(--muted);text-decoration:none;font-size:14px;line-height:1.5}nav a:hover{text-decoration:underline;color:var(--ink)}
main{min-width:0;max-width:950px}h1{font-size:clamp(28px,4vw,43px);line-height:1.25;letter-spacing:-1px;margin:0 0 18px}h2{font-size:27px;line-height:1.4;border-top:1px solid var(--line);padding-top:34px;margin-top:50px}h3{font-size:21px;line-height:1.5;margin-top:30px}p{margin:16px 0}li{padding:5px 0}ul,ol{padding-left:25px}strong{font-weight:700}code{font-family:Consolas,monospace;font-size:.9em;background:#e8eedd;padding:2px 5px;border-radius:4px;overflow-wrap:anywhere}article[lang=si]{font-family:"Nirmala UI","Iskoola Pota","Segoe UI",sans-serif;line-height:2}article[lang=si] h1{line-height:1.7;font-size:34px}article[lang=si] h2,article[lang=si] h3{line-height:1.8}
.overview{background:#e7eed6;padding:24px;border-radius:16px;margin-bottom:32px}.overview h2{border:0;padding:0;margin:0 0 12px;font-size:21px}.flow{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:8px}.flow div{background:#fffef8;padding:14px 10px;border-radius:8px;font-size:13px}.flow b{display:block;font-size:16px}.notice{font-size:14px;color:var(--muted)}[hidden]{display:none!important}footer{border-top:1px solid var(--line);padding:25px 5vw;font-size:13px;color:var(--muted)}
@media(max-width:850px){.layout{display:block;padding:28px 6vw}aside{position:static;margin-bottom:30px}nav{display:flex;flex-wrap:wrap;gap:8px 18px}nav a{max-width:100%}.flow{grid-template-columns:repeat(2,minmax(0,1fr))}}
@media print{header,.controls,aside,.overview,footer{display:none!important}.layout{display:block;padding:0}main{max-width:none}body{background:white;font-size:10.5pt;line-height:1.6}h1{font-size:25pt}h2{font-size:18pt;break-after:avoid}h3{font-size:14pt;break-after:avoid}article+article{break-before:page}code{overflow-wrap:anywhere}article[lang=si]{font-size:11pt}p,li{orphans:3;widows:3}@page{size:A4;margin:18mm}}
</style></head><body>
<header><div class="brand">smartsolar.<small>LECTURE ALIGNMENT / දේශන න්‍යාය</small></div><div class="controls" aria-label="Report language"><button type="button" data-choice="en" aria-pressed="true">English</button><button type="button" data-choice="si" aria-pressed="false">සිංහල</button><button type="button" data-choice="both" aria-pressed="false">Both / දෙකම</button><button type="button" id="print">Print / Save PDF</button></div></header>
<div class="layout"><aside><p>CONTENTS / අන්තර්ගතය</p>__MENUS__</aside><main>
<section class="overview" aria-label="Workflow overview"><h2>One shared installation journey</h2><div class="flow"><div>01 · Member 1<b>Assess</b>Survey → sizing</div><div>02 · Member 2<b>Inspect</b>Evidence → screening</div><div>03 · Member 3<b>Review</b>Validation → human approval</div><div>04 · Member 4<b>Prepare</b>Quote → stock reservation</div></div><p class="notice">No paid model required. Current specialists are deterministic; live LLM reasoning and full RAG remain gaps.<br>ගෙවන model සේවාවක් අවශ්‍ය නැත. දැනට ක්‍රියා කරන්නේ නීති මත පදනම් වූ workflows ය.</p></section>
__ARTICLES__</main></div><footer>Prepared from seven supplied lecture PDFs and repository evidence. Review began 16 September; report completed 19 September 2026. Local implementation audit — no grade or production certification implied.</footer>
<script>
const buttons=document.querySelectorAll('[data-choice]');
function showLanguage(value){document.querySelectorAll('[data-language]').forEach(el=>el.hidden=value!=='both'&&el.dataset.language!==value);buttons.forEach(button=>button.setAttribute('aria-pressed',String(button.dataset.choice===value)));document.documentElement.lang=value==='si'?'si':'en';}
buttons.forEach(button=>button.addEventListener('click',()=>showLanguage(button.dataset.choice)));
document.getElementById('print').addEventListener('click',()=>window.print());showLanguage('en');
</script></body></html>'''
(OUTPUT / 'lecture-theory-report.html').write_text(page.replace('__MENUS__', '\n'.join(menus)).replace('__ARTICLES__', '\n'.join(articles)), encoding='utf-8')
print('Built docs/assessment/lecture-theory-report.html')
