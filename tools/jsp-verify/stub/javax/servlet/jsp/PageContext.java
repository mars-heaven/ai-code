package javax.servlet.jsp;
import javax.servlet.jsp.tagext.BodyContent;
public abstract class PageContext {
	public abstract BodyContent pushBody();
	public abstract JspWriter popBody();
}
