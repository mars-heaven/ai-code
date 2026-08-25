package javax.servlet.jsp;
import java.io.Writer;
public abstract class JspWriter extends Writer {
	public abstract void clear() throws java.io.IOException;
	public abstract void clearBuffer() throws java.io.IOException;
	public abstract void println(Object o) throws java.io.IOException;
	public abstract void println(String s) throws java.io.IOException;
	public abstract void print(Object o) throws java.io.IOException;
}
