package javax.servlet;
import javax.servlet.http.*;
public interface RequestDispatcher {
	void forward(HttpServletRequest req, HttpServletResponse res) throws Exception;
	void include(HttpServletRequest req, HttpServletResponse res) throws Exception;
}
