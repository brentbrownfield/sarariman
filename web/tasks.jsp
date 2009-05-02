<%@page contentType="application/xhtml+xml" pageEncoding="UTF-8"%>
<%@taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@taglib prefix="du" uri="/WEB-INF/tlds/DateUtils" %>
<%@taglib prefix="sarariman" uri="/WEB-INF/tlds/sarariman" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <link href="style.css" rel="stylesheet" type="text/css"/>
        <title>Tasks</title>
    </head>
    <body>
        <p><a href="./">Home</a></p>

        <sql:query dataSource="jdbc/sarariman" var="tasks">
            SELECT t.id, t.name, t.project
            FROM tasks AS t
        </sql:query>

        <table>
            <tr><th>ID</th><th>Name</th><th>Project</th></tr>
            <c:forEach var="task" items="${tasks.rows}">
                <tr>
                    <td><a href="task?task_id=${task.id}">${task.id}</a></td>
                    <td><a href="task?task_id=${task.id}">${fn:escapeXml(task.name)}</a></td>
                    <!-- FIXME: This should be done with a JOIN in SELECT above, but JSTL sql:query does not let us alias column
                    names -->
                    <c:choose>
                        <c:when test="${!empty task.project}">
                            <sql:query dataSource="jdbc/sarariman" var="result" >
                                SELECT name
                                FROM projects
                                WHERE id=?
                                <sql:param value="${task.project}"/>
                            </sql:query>
                            <c:set var="project_name" value="${fn:escapeXml(result.rows[0].name)}"/>
                        </c:when>
                        <c:otherwise>
                            <c:set var="project_name" value="${null}"/>
                        </c:otherwise>
                    </c:choose>
                    <td><a href="task?task_id=${task.id}">${project_name}</a></td>
                </tr>
            </c:forEach>
        </table>
        <%@include file="footer.jsp" %>
    </body>
</html>