package org.apache.http.client.methods;
import org.apache.http.HttpResponse;
import java.io.Closeable;
public interface CloseableHttpResponse extends HttpResponse, Closeable {}
