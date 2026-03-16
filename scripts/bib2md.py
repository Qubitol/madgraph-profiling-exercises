#!/usr/bin/env python3
"""Convert a .bib file to a Markdown reference list."""
import re, sys

def extract_braced(text, field):
    """Extract a field value handling both {nested braces} and "quotes"."""
    pattern = rf'{field}\s*=\s*'
    m = re.search(pattern, text, re.IGNORECASE)
    if not m:
        return None
    i = m.end()
    # skip whitespace
    while i < len(text) and text[i] in ' \t':
        i += 1
    if i >= len(text):
        return None
    delimiter = text[i]
    if delimiter == '{':
        # Brace-delimited: count depth
        i += 1
        start = i
        depth = 1
        while i < len(text) and depth > 0:
            if text[i] == '{':
                depth += 1
            elif text[i] == '}':
                depth -= 1
            i += 1
        return text[start:i - 1]
    elif delimiter == '"':
        # Quote-delimited: find matching close quote (ignoring braces inside)
        i += 1
        start = i
        while i < len(text) and text[i] != '"':
            i += 1
        return text[start:i]
    return None

def clean_latex(s):
    """Convert common LaTeX markup to plain Unicode."""
    if not s:
        return s
    # Accented characters
    replacements = {
        r'\"o': 'ö', r'\"u': 'ü', r'\"a': 'ä',
        r'\"O': 'Ö', r'\"U': 'Ü', r'\"A': 'Ä',
        r"\'e": 'é', r"\'a": 'á', r"\`e": 'è',
        r'\v{c}': 'č', r'\v{s}': 'š', r'\v{z}': 'ž',
        r'\c{c}': 'ç', r'\~n': 'ñ',
    }
    for latex, uni in replacements.items():
        s = s.replace(latex, uni)
    # Strip LaTeX commands like \texttt{...}, \emph{...}, \textbf{...}, etc.
    s = re.sub(r'\\(?:texttt|textbf|textit|emph|textrm|textsf|mbox)\s*\{([^}]*)\}', r'\1', s)
    # Strip remaining braces and backslashes before underscores
    s = s.replace(r'{\_}', '_')
    s = s.replace(r'\_', '_')
    s = re.sub(r'[{}]', '', s)
    return s.strip()

def format_authors(raw):
    """Format 'Last, First and Last, First and ...' into readable form."""
    if not raw:
        return ''
    authors = [a.strip() for a in raw.split(' and ')]
    names = []
    for a in authors:
        parts = [p.strip() for p in a.split(',', 1)]
        if len(parts) == 2:
            names.append(f'{parts[1]} {parts[0]}')
        else:
            names.append(parts[0])
    names = [clean_latex(n) for n in names]
    if len(names) > 3:
        return f'{names[0]} et al.'
    return ', '.join(names)

with open(sys.argv[1]) as f:
    content = f.read()

# Split on entry boundaries
entries = re.split(r'\n(?=@)', content)

for entry in entries:
    title  = extract_braced(entry, 'title')
    author = extract_braced(entry, 'author')
    url    = extract_braced(entry, 'url')
    eprint = extract_braced(entry, 'eprint')

    if not title:
        continue

    t = clean_latex(title)
    a = format_authors(author)
    prefix = f'{a}, ' if a else ''

    if eprint:
        ep = eprint.strip()
        link = f'[arXiv:{ep}](https://arxiv.org/abs/{ep})'
    elif url:
        link = url.strip()
    else:
        link = ''

    print(f'- {prefix}*{t}*: {link}')
