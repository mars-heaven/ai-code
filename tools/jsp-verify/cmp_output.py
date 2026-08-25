# -*- coding: utf-8 -*-
"""SID 블록별로 응답 컬럼/레코드 출력 횟수를 원본과 비교한다."""
import io, os, re

FILES = ["apt_community_cafeteria.jsp", "apt_community_facility.jsp", "apt_community_setting.jsp",
         "apt_community_membership.jsp", "apt_community_reservation.jsp"]
V = os.environ.get("VERIFY_WORK", "build")
SID = re.compile(r'strSID\.contentEquals\("([^"]+)"\)')

def blocks(path):
    text = io.open(path, encoding="utf-8", newline="").read().replace("\r\n", "\n")
    # 주석 라인 제거(비교 왜곡 방지)
    text = "\n".join(l for l in text.split("\n") if not l.strip().startswith("//"))
    marks = [(m.start(), m.group(1)) for m in SID.finditer(text)]
    out = {}
    for i, (pos, sid) in enumerate(marks):
        end = marks[i + 1][0] if i + 1 < len(marks) else len(text)
        out[sid] = text[pos:end]
    return out

def counts(body):
    col = (len(re.findall(r"writeColumn\(baOutStream", body))
           + len(re.findall(r"writeColumnDel\(baOutStream", body))
           + len(re.findall(r"baOutStream\.write\(COLUMN_DEL\)", body)))
    txt = (len(re.findall(r"writeText\(baOutStream", body))
           + len(re.findall(r"writeColumn\(baOutStream", body))
           + len(re.findall(r"baOutStream\.write\([^;]*getBytes", body)))
    rec = (len(re.findall(r"writeRecord\(baOutStream", body))
           + len(re.findall(r"baOutStream\.write\(RECORD_DEL\)", body)))
    dump = len(re.findall(r"writeResultSet\(baOutStream", body))
    ret = len(re.findall(r"returnData\(", body))
    return dict(값=txt, 컬럼구분자=col, 레코드구분자=rec, 전체덤프=dump, 전송=ret)

problems = 0
for name in FILES:
    o = blocks(os.path.join(V, "orig", name))
    n = blocks(os.path.join(os.environ.get("COMMUNITY_DIR", "../../community"), name))
    print("== %s (SID %d개)" % (name, len(o)))
    assert set(o) == set(n), (set(o) ^ set(n))
    for sid in o:
        co, cn = counts(o[sid]), counts(n[sid])
        # 전체덤프 1회 = 컬럼/레코드 루프 1개를 대체
        adj = dict(cn)
        if cn["전체덤프"] and not co["전체덤프"]:
            adj["값"] += cn["전체덤프"]
            adj["컬럼구분자"] += cn["전체덤프"]
            adj["레코드구분자"] += cn["전체덤프"]
        diff = {k: (co[k], adj[k]) for k in co if k != "전체덤프" and co[k] != adj[k]}
        status = "OK " if not diff else "차이"
        if diff:
            problems += 1
        print("   %-4s %-32s %s" % (status, sid, diff if diff else ""))
print("\n차이 있는 SID 블록:", problems)
