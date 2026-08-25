package org.json.simple;
import java.util.HashMap;
import java.util.Map;
public class JSONObject extends HashMap<Object, Object> {
	public JSONObject() { super(); }
	public JSONObject(Map m) { super(m); }
	public String toJSONString() { return super.toString(); }
}
