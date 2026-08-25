package org.apache.http.client;
import org.apache.http.HttpResponse;
public interface ResponseHandler<T> { T handleResponse(HttpResponse response) throws Exception; }
