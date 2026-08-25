package org.json.simple.parser;
import org.json.simple.*;
/** 테스트용 미니 JSON 파서(객체/배열/문자열/숫자/불리언/null 지원) */
public class JSONParser {
	private String s; private int i;
	public Object parse(String text) throws ParseException {
		if (text == null) throw new ParseException();
		s = text; i = 0;
		ws();
		Object v = value();
		ws();
		if (i != s.length()) throw new ParseException();
		return v;
	}
	private void ws() { while (i < s.length() && Character.isWhitespace(s.charAt(i))) i++; }
	private Object value() throws ParseException {
		if (i >= s.length()) throw new ParseException();
		char c = s.charAt(i);
		if (c == '{') return object();
		if (c == '[') return array();
		if (c == '"') return string();
		if (s.startsWith("true", i)) { i += 4; return Boolean.TRUE; }
		if (s.startsWith("false", i)) { i += 5; return Boolean.FALSE; }
		if (s.startsWith("null", i)) { i += 4; return null; }
		return number();
	}
	private JSONObject object() throws ParseException {
		JSONObject o = new JSONObject();
		i++; ws();
		if (i < s.length() && s.charAt(i) == '}') { i++; return o; }
		while (true) {
			ws();
			String k = string();
			ws();
			if (i >= s.length() || s.charAt(i) != ':') throw new ParseException();
			i++; ws();
			o.put(k, value());
			ws();
			if (i >= s.length()) throw new ParseException();
			if (s.charAt(i) == ',') { i++; continue; }
			if (s.charAt(i) == '}') { i++; return o; }
			throw new ParseException();
		}
	}
	private JSONArray array() throws ParseException {
		JSONArray a = new JSONArray();
		i++; ws();
		if (i < s.length() && s.charAt(i) == ']') { i++; return a; }
		while (true) {
			ws();
			a.add(value());
			ws();
			if (i >= s.length()) throw new ParseException();
			if (s.charAt(i) == ',') { i++; continue; }
			if (s.charAt(i) == ']') { i++; return a; }
			throw new ParseException();
		}
	}
	private String string() throws ParseException {
		if (i >= s.length() || s.charAt(i) != '"') throw new ParseException();
		i++;
		StringBuilder sb = new StringBuilder();
		while (i < s.length() && s.charAt(i) != '"') {
			char c = s.charAt(i);
			if (c == '\\') { i++; c = s.charAt(i); }
			sb.append(c); i++;
		}
		if (i >= s.length()) throw new ParseException();
		i++;
		return sb.toString();
	}
	private Object number() throws ParseException {
		int start = i;
		while (i < s.length() && "-+.eE0123456789".indexOf(s.charAt(i)) >= 0) i++;
		if (start == i) throw new ParseException();
		String n = s.substring(start, i);
		if (n.contains(".") || n.contains("e") || n.contains("E")) return Double.valueOf(n);
		return Long.valueOf(n);
	}
}
