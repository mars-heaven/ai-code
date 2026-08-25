# -*- coding: utf-8 -*-
"""원본과 리팩터링본의 응답 출력 시퀀스(값/컬럼구분자/레코드구분자)를 SID 단위로 비교"""
import io, os, re, difflib

V = os.environ.get("VERIFY_WORK", "build/") 
NEW = os.environ.get("COMMUNITY_DIR", "../../community/")
FILES = ["apt_community_cafeteria.jsp", "apt_community_facility.jsp", "apt_community_setting.jsp",
         "apt_community_membership.jsp", "apt_community_reservation.jsp"]
SIDRE = re.compile(r'strSID\.contentEquals\("([^"]+)"\)')

def blocks(path):
    t = io.open(path, encoding="utf-8", newline="").read().replace("\r\n", "\n")
    marks = [(m.start(), m.group(1)) for m in SIDRE.finditer(t)]
    d = {}
    for i, (pos, sid) in enumerate(marks):
        end = marks[i + 1][0] if i + 1 < len(marks) else len(t)
        d[sid] = t[pos:end]
    return d

def seq(body, new):
    res = []
    for line in body.split("\n"):
        s = line.strip()
        if s.startswith("//") or s.startswith("/*") or s.startswith("*"):
            continue                                  # 주석 라인 제외
        if new:
            m = re.match(r'writeColumn\(baOutStream,\s*(.*)\);\s*(?://.*)?$', s)
            if m: res.append("VAL " + m.group(1).strip()); res.append("DEL"); continue
            m = re.match(r'writeText\(baOutStream,\s*(.*)\);\s*(?://.*)?$', s)
            if m: res.append("VAL " + m.group(1).strip()); continue
            if s.startswith("writeColumnDel("): res.append("DEL"); continue
            if s.startswith("writeRecord("): res.append("REC"); continue
            if s.startswith("writeResultSet("): res.append("DUMP"); continue
            if s.startswith("writeCurrentRow("): res.append("ROW"); continue
            if re.match(r'for\(int nCol = 1; nCol <= rsMetaData', s): res.append("DUMPLOOP"); continue
        else:
            m = re.match(r'baOutStream\.write\((.*)\.getBytes\(S_CHARSET\)\);\s*(?://.*)?$', s)
            if m: res.append("VAL " + m.group(1).strip()); continue
            if s.startswith("baOutStream.write(COLUMN_DEL)"): res.append("DEL"); continue
            if s.startswith("baOutStream.write(RECORD_DEL)"): res.append("REC"); continue
            if re.match(r'for\(int nCol = 1; nCol <= rsMetaData', s): res.append("DUMPLOOP"); continue
    return res

total_diff = 0
for name in FILES:
    o, n = blocks(V + "orig/" + name), blocks(NEW + name)
    print("== %s" % name)
    for sid in o:
        so, sn = seq(o[sid], False), seq(n[sid], True)
        def expand(seq):
            out = []
            for x in seq:
                if x == "DUMP":
                    out += ["DUMPLOOP", "VAL strData", "DEL", "REC"]
                else:
                    out.append(x)
            return out
        so, sn = expand(so), expand(sn)
        if so == sn:
            print("   OK   %s (%d)" % (sid, len(so)))
            continue
        d = [l for l in difflib.unified_diff(so, sn, "orig", "new", n=1, lineterm="")][2:]
        # errMsg / DUMP 로 설명되는 차이는 표시만 하고 별도 표기
        print("   차이 %s" % sid)
        for l in d:
            print("        " + l)
        total_diff += 1
print("\n차이 SID 수:", total_diff)
