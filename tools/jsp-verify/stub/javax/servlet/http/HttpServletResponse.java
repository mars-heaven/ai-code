package javax.servlet.http;
import javax.servlet.*;
public interface HttpServletResponse {
	ServletOutputStream getOutputStream() throws java.io.IOException;
	void setContentType(String type);
	void setHeader(String name, String value);
	void sendRedirect(String url) throws java.io.IOException;
}
