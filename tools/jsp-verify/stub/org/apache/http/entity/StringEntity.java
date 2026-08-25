package org.apache.http.entity;
import org.apache.http.HttpEntity;
public class StringEntity implements HttpEntity {
	public StringEntity(String s) throws java.io.UnsupportedEncodingException {}
	public StringEntity(String s, String charset) {}
	public java.io.InputStream getContent() { return null; }
}
