import os
import re
import subprocess

md_path = r"C:\Users\Lenovo\Downloads\G5_PUPSPOT\db-backup-recovery\group05-lostandfound\reports\final-activity-6-report.md"
html_path = r"C:\Users\Lenovo\Downloads\G5_PUPSPOT\db-backup-recovery\group05-lostandfound\reports\final-activity-6-report.html"
pdf_path = r"C:\Users\Lenovo\Downloads\G5_PUPSPOT\db-backup-recovery\group05-lostandfound\reports\final-activity-6-report.pdf"

with open(md_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

html_lines = []
in_code = False
code_lang = ""
in_table = False
table_headers = []

css = """
<style>
    @page {
        size: A4;
        margin: 20mm 15mm 20mm 15mm;
        @bottom-right {
            content: counter(page);
        }
    }
    body {
        font-family: 'Segoe UI', Helvetica, Arial, sans-serif;
        font-size: 10.5pt;
        line-height: 1.5;
        color: #24292e;
        padding: 0;
        margin: 0;
    }
    h1 {
        font-size: 18pt;
        color: #0366d6;
        border-bottom: 2px solid #0366d6;
        padding-bottom: 4px;
        margin-top: 15px;
        margin-bottom: 10px;
    }
    h2 {
        font-size: 14pt;
        color: #1a202c;
        border-bottom: 1px solid #eaecef;
        padding-bottom: 4px;
        margin-top: 18px;
        margin-bottom: 8px;
        page-break-after: avoid;
    }
    h3 {
        font-size: 12pt;
        color: #2d3748;
        margin-top: 12px;
        margin-bottom: 6px;
        page-break-after: avoid;
    }
    h4 {
        font-size: 11pt;
        color: #4a5568;
        margin-top: 10px;
        margin-bottom: 4px;
        page-break-after: avoid;
    }
    p {
        margin: 6px 0;
    }
    table {
        width: 100%;
        border-collapse: collapse;
        margin: 10px 0;
        font-size: 9pt;
        page-break-inside: avoid;
    }
    th, td {
        border: 1px solid #cbd5e0;
        padding: 6px 8px;
        text-align: left;
    }
    th {
        background-color: #f7fafc;
        font-weight: 600;
        color: #2d3748;
    }
    tr:nth-child(even) {
        background-color: #f8fafc;
    }
    code {
        font-family: 'Consolas', 'Courier New', monospace;
        font-size: 9pt;
        background-color: #f1f5f9;
        padding: 2px 4px;
        border-radius: 3px;
        color: #0f172a;
    }
    pre {
        background-color: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 4px;
        padding: 8px 10px;
        overflow-x: auto;
        font-size: 8.5pt;
        line-height: 1.4;
        page-break-inside: avoid;
        margin: 8px 0;
    }
    pre code {
        background-color: transparent;
        padding: 0;
        border: none;
    }
    blockquote {
        margin: 8px 0;
        padding: 6px 12px;
        border-left: 4px solid #3182ce;
        background-color: #ebf8ff;
        color: #2b6cb0;
        font-size: 9.5pt;
    }
    ul, ol {
        margin: 6px 0 6px 20px;
        padding: 0;
    }
    li {
        margin-bottom: 3px;
    }
    hr {
        border: 0;
        height: 1px;
        background: #e2e8f0;
        margin: 15px 0;
    }
</style>
"""

html_out = ["<!DOCTYPE html><html><head><meta charset='utf-8'><title>COMP 018 Activity 6 Report</title>", css, "</head><body>"]

i = 0
while i < len(lines):
    line = lines[i].rstrip("\r\n")
    
    # Code block fence
    if line.startswith("```"):
        if not in_code:
            in_code = True
            code_lang = line[3:].strip()
            html_out.append(f"<pre><code class='{code_lang}'>")
        else:
            in_code = False
            html_out.append("</code></pre>")
        i += 1
        continue
    
    if in_code:
        escaped = line.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
        html_out.append(escaped + "\n")
        i += 1
        continue
        
    # Table processing
    if "|" in line and line.strip().startswith("|") and line.strip().endswith("|"):
        if not in_table:
            in_table = True
            html_out.append("<table>")
            # Parse header
            headers = [c.strip() for c in line.strip().strip("|").split("|")]
            html_out.append("<thead><tr>" + "".join(f"<th>{h}</th>" for h in headers) + "</tr></thead>")
            html_out.append("<tbody>")
            # Skip separator line if next
            if i + 1 < len(lines) and re.match(r"^\|(\s*:?-+:?\s*\|)+$", lines[i+1].strip()):
                i += 1
        else:
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
            # Format inline codes/bold in cells
            formatted_cells = []
            for cell in cells:
                c = re.sub(r"\*\*(.*?)\*\*", r"<strong>\1</strong>", cell)
                c = re.sub(r"`(.*?)`", r"<code>\1</code>", c)
                formatted_cells.append(f"<td>{c}</td>")
            html_out.append("<tr>" + "".join(formatted_cells) + "</tr>")
        i += 1
        continue
    else:
        if in_table:
            in_table = False
            html_out.append("</tbody></table>")
            
    # Empty line
    if not line.strip():
        i += 1
        continue
        
    # Headers
    if line.startswith("# "):
        html_out.append(f"<h1>{line[2:]}</h1>")
    elif line.startswith("## "):
        html_out.append(f"<h2>{line[3:]}</h2>")
    elif line.startswith("### "):
        html_out.append(f"<h3>{line[4:]}</h3>")
    elif line.startswith("#### "):
        html_out.append(f"<h4>{line[5:]}</h4>")
    elif line.startswith("---"):
        html_out.append("<hr>")
    elif line.startswith("> "):
        quote_text = line[2:]
        quote_text = re.sub(r"\*\*(.*?)\*\*", r"<strong>\1</strong>", quote_text)
        html_out.append(f"<blockquote>{quote_text}</blockquote>")
    elif line.startswith("* ") or line.startswith("- "):
        li_text = line[2:]
        li_text = re.sub(r"\*\*(.*?)\*\*", r"<strong>\1</strong>", li_text)
        li_text = re.sub(r"`(.*?)`", r"<code>\1</code>", li_text)
        html_out.append(f"<ul><li>{li_text}</li></ul>")
    elif re.match(r"^\d+\.\s", line):
        li_text = re.sub(r"^\d+\.\s", "", line)
        li_text = re.sub(r"\*\*(.*?)\*\*", r"<strong>\1</strong>", li_text)
        li_text = re.sub(r"`(.*?)`", r"<code>\1</code>", li_text)
        html_out.append(f"<ol><li>{li_text}</li></ol>")
    else:
        p_text = line
        p_text = re.sub(r"\*\*(.*?)\*\*", r"<strong>\1</strong>", p_text)
        p_text = re.sub(r"`(.*?)`", r"<code>\1</code>", p_text)
        html_out.append(f"<p>{p_text}</p>")
    i += 1

if in_table:
    html_out.append("</tbody></table>")

html_out.append("</body></html>")

with open(html_path, "w", encoding="utf-8") as f:
    f.write("\n".join(html_out))

print(f"HTML written to {html_path}")

edge_path = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if not os.path.exists(edge_path):
    edge_path = r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"

cmd = [
    edge_path,
    "--headless",
    "--disable-gpu",
    "--no-pdf-header-footer",
    f"--print-to-pdf={pdf_path}",
    f"file:///{html_path.replace(os.sep, '/')}"
]

print("Converting HTML to PDF via Edge headless...")
res = subprocess.run(cmd, capture_output=True, text=True)
if os.path.exists(pdf_path):
    size = os.path.getsize(pdf_path)
    print(f"SUCCESS: PDF generated at {pdf_path} ({size} bytes)")
else:
    print(f"FAILED: Edge return code {res.returncode}, stderr: {res.stderr}")

