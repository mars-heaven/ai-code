package org.apache.http.impl.client;
import org.apache.http.HttpResponse;
import org.apache.http.client.ResponseHandler;
public class BasicResponseHandler implements ResponseHandler<String> {
	public String handleResponse(HttpResponse response) { return ""; }
}
