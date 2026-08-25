# -*- coding: utf-8 -*-
"""JSP를 컴파일 가능한 Java 클래스로 변환한다(정적 include 인라인)."""
import io, os, re, sys

PAGE_DIRECTIVE = re.compile(r'<%@\s*page\s+(.*?)%>', re.S)
INCLUDE = re.compile(r'<%@\s*include\s+file\s*=\s*"([^"]+)"\s*%>')
COMMENT = re.compile(r'<%--.*?--%>', re.S)
DECL = re.compile(r'<%!(.*?)%>', re.S)
EXPR = re.compile(r'<%=(.*?)%>', re.S)
SCRIPTLET = re.compile(r'<%(?!@|!|=|--)(.*?)%>', re.S)
IMPORT = re.compile(r'import\s*=\s*"([^"]+)"')

def load(path, seen):
    """include 를 인라인해서 하나의 텍스트로 만든다"""
    text = io.open(path, encoding="utf-8", newline="").read().replace("\r\n", "\n")
    text = COMMENT.sub("", text)

    def repl(m):
        target = m.group(1)
        base = os.path.dirname(path)
        cand = os.path.normpath(os.path.join(base, target))
        for p in (cand, os.path.join(GLOBALS, os.path.basename(target))):
            if os.path.exists(p):
                if p in seen:
                    return ""          # 중복 include 방지
                seen.add(p)
                return load(p, seen)
        raise SystemExit("include not found: %s (from %s)" % (target, path))

    return INCLUDE.sub(repl, text)

def convert(jsp_path, class_name, out_dir):
    seen = set([os.path.abspath(jsp_path)])
    text = load(jsp_path, seen)

    imports = []
    for m in PAGE_DIRECTIVE.finditer(text):
        for im in IMPORT.finditer(m.group(1)):
            for one in im.group(1).split(","):
                one = one.strip()
                if one and one not in imports:
                    imports.append(one)
    text = PAGE_DIRECTIVE.sub("", text)

    decls = [m.group(1) for m in DECL.finditer(text)]
    text = DECL.sub("", text)

    scriptlets = [m.group(1) for m in SCRIPTLET.finditer(text)]
    text = SCRIPTLET.sub("", text)
    text = EXPR.sub("", text)

    src = []
    src.append("import javax.servlet.*;")
    src.append("import javax.servlet.http.*;")
    src.append("import javax.servlet.jsp.*;")
    src.append("import javax.servlet.jsp.tagext.*;")
    for i in imports:
        src.append("import %s;" % i)
    src.append("")
    src.append("public class %s {" % class_name)
    src.append("\tprotected ServletContext getServletContext() { return null; }")
    src.append("")
    for d in decls:
        src.append(d)
    src.append("")
    src.append("\tpublic void _jspService(HttpServletRequest request, HttpServletResponse response,")
    src.append("\t\t\tJspWriter out, PageContext pageContext, HttpSession session, ServletContext application)")
    src.append("\t\t\tthrows Exception {")
    for s in scriptlets:
        src.append(s)
    src.append("\t}")
    src.append("}")

    out = os.path.join(out_dir, class_name + ".java")
    io.open(out, "w", encoding="utf-8").write("\n".join(src))
    return out

if __name__ == "__main__":
    GLOBALS = sys.argv[1]
    src_dir = sys.argv[2]
    out_dir = sys.argv[3]
    prefix  = sys.argv[4]
    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)
    for name in sys.argv[5:]:
        cls = prefix + re.sub(r"[^A-Za-z0-9]", "_", name.replace(".jsp", ""))
        p = convert(os.path.join(src_dir, name), cls, out_dir)
        print("  %-34s -> %s" % (name, os.path.basename(p)))
