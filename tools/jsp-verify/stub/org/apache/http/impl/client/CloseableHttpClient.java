package org.apache.http.impl.client;
import org.apache.http.client.ResponseHandler;
import org.apache.http.client.methods.*;
import java.io.Closeable;
public abstract class CloseableHttpClient implements Closeable {
	public abstract CloseableHttpResponse execute(HttpPost post) throws java.io.IOException;
	public abstract <T> T execute(HttpPost post, ResponseHandler<? extends T> handler) throws java.io.IOException;
}
