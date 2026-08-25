# -*- coding: utf-8 -*-
import io, re, sys, subprocess

COMMUNITY = os.environ.get("COMMUNITY_DIR", "../../community")
BASE_REV = os.environ.get("BASE_REV", "HEAD~1")

FILES = ["apt_community_cafeteria.jsp", "apt_community_facility.jsp",
         "apt_community_setting.jsp", "apt_community_membership.jsp",
         "apt_community_reservation.jsp", "apt_community_common.jsp"]

def java_code(text):
    """JSP 스크립틀릿/선언부의 자바 코드만 추출"""
    parts = []
    for m in re.finditer(r"<%[!=]?(?!--)(.*?)%>", text, re.S):
        parts.append(m.group(1))
    return "\n".join(parts)

def strip_literals(code):
    out = []
    i = 0
    n = len(code)
    while i < n:
        c = code[i]
        if c == '"':
            i += 1
            while i < n and code[i] != '"':
                i += 2 if code[i] == '\\' else 1
            i += 1
        elif c == "'":
            i += 1
            while i < n and code[i] != "'":
                i += 2 if code[i] == '\\' else 1
            i += 1
        elif c == '/' and i + 1 < n and code[i + 1] == '/':
            while i < n and code[i] != '\n':
                i += 1
        elif c == '/' and i + 1 < n and code[i + 1] == '*':
            i = code.find('*/', i + 2)
            i = n if i < 0 else i + 2
        else:
            out.append(c)
            i += 1
    return "".join(out)

def balance(text):
    code = strip_literals(java_code(text))
    depth = 0
    minimum = 0
    for c in code:
        if c == '{':
            depth += 1
        elif c == '}':
            depth -= 1
            minimum = min(minimum, depth)
    return depth, minimum

for name in FILES:
    cur = io.open(os.path.join(COMMUNITY, name), encoding="utf-8", newline="").read()
    d, m = balance(cur)
    try:
        orig = subprocess.check_output(
            ["git", "show", BASE_REV + ":community/" + name]).decode("utf-8")
        od, om = balance(orig)
        ref = "원본 %+d/%+d" % (od, om)
    except Exception:
        ref = "원본 없음(신규)"
    print("%-32s 현재 %+d/%+d   %s" % (name, d, m, ref))
