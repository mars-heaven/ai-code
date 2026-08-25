package javax.servlet.http;
import javax.servlet.*;
public interface HttpServletRequest {
	String getParameter(String name);
	String[] getParameterValues(String name);
	void setAttribute(String name, Object o);
	Object getAttribute(String name);
	String getHeader(String name);
	String getRemoteAddr();
	HttpSession getSession();
	RequestDispatcher getRequestDispatcher(String path);
}
