<%--
  Copyright (C) 2009-2012 StackFrame, LLC
  This code is licensed under GPLv2.
--%>

<%@page contentType="application/xhtml+xml" pageEncoding="UTF-8"%>
<%@taglib prefix="sql" uri="http://java.sun.com/jsp/jstl/sql" %>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@taglib prefix="du" uri="/WEB-INF/tlds/DateUtils" %>
<%@taglib prefix="sarariman" uri="/WEB-INF/tlds/sarariman" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<c:set var="employeeNumber" value="${user.number}"/>
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <link href="style.css" rel="stylesheet" type="text/css"/>
        <title>Sarariman</title>
        <script type="text/javascript" src="utilities.js"/>

        <!-- jQuery -->
        <link type="text/css" href="jquery/css/ui-lightness/jquery-ui-1.8.20.custom.css" rel="Stylesheet" />	
        <script type="text/javascript" src="jquery/js/jquery-1.7.2.min.js"></script>
        <script type="text/javascript" src="jquery/js/jquery-ui-1.8.20.custom.min.js"></script>
        <!-- /jQuery -->

        <!-- TinyMCE -->
        <script type="text/javascript" src="tiny_mce/tiny_mce.js"></script>
        <script type="text/javascript">
            tinyMCE.init({
                mode : "textareas",
                theme : "simple"
            });
        </script>
        <!-- /TinyMCE -->

        <script>
            // FIXME: Replace this with a single function that validates the entire form and enables the submit button if valid.
            function enable(id) {
                var element = document.getElementById(id);
                element.disabled = false;
            }
            
            $(function() {
                $( "#date" ).datepicker({dateFormat: 'yy-mm-dd'});
            });
        </script>
    </head>

    <!-- FIXME: error if param.week is not a Saturday -->
    <body onload="altRows()">
        <a href="tools">Tools</a>

        <sql:query dataSource="jdbc/sarariman" var="averageEntry">
            SELECT AVG(DATEDIFF(hours_changelog.timestamp, hours.date)) AS average
            FROM hours
            JOIN hours_changelog ON hours.employee = hours_changelog.employee AND hours.task = hours_changelog.task AND hours.date = hours_changelog.date
            WHERE hours.employee = ? AND hours.date > DATE_SUB(NOW(), INTERVAL 7 DAY)
            <sql:param value="${employeeNumber}"/>
        </sql:query>
        <c:set var="good" value="${averageEntry.rows[0].average < 0.25}"/>
        <p>
            <c:choose>
                <c:when test="${good}"><span title="Your recent timesheet entries have been on time!" style="font-size: 14pt">&#x263A;</span></c:when> 
                <c:otherwise><span title="Your recent timesheet entries have been late." style="font-size: 14pt">&#x2639;</span></c:otherwise>
            </c:choose>
        </p>

        <c:choose>
            <c:when test="${!empty param.week}">
                <fmt:parseDate var="week" value="${param.week}" type="date" pattern="yyyy-MM-dd"/>
            </c:when>
            <c:otherwise>
                <c:set var="week" value="${du:weekStart(du:now())}"/>
            </c:otherwise>
        </c:choose>

        <c:set var="timesheet" value="${sarariman:timesheet(sarariman, employeeNumber, week)}"/>
        <c:set var="submitted" value="${timesheet.submitted}"/>

        <c:if test="${!submitted && param.submit}">
            <c:set var="submitted" value="${sarariman:submitTimesheet(timesheet)}"/>
        </c:if>

        <c:if test="${!empty param.recordTime}">

            <c:choose>
                <c:when test="${!empty param.task}">
                    <c:set var="task" value="${param.task}"/>
                </c:when>
                <c:otherwise>
                    <p class="error">You must enter a task.</p>
                    <c:set var="insertError" value="true"/>
                </c:otherwise>
            </c:choose>

            <!-- FIXME: Check that the time is not already in a submitted sheet. -->
            <!-- FIXME: Check that the day is not more than 24 hours on timesheet submit. -->
            <!-- FIXME: Enforce that entry has a comment. -->
            <sql:query dataSource="jdbc/sarariman" var="existing" sql="SELECT * FROM hours WHERE task=? AND date=? AND employee=?">
                <sql:param value="${task}"/>
                <sql:param value="${param.date}"/>
                <sql:param value="${employeeNumber}"/>
            </sql:query>
            <c:if test="${!empty existing.rows}">
                <p class="error">Cannot have more than one entry for a given task and date.</p>
                <c:set var="insertError" value="true"/>
            </c:if>

            <c:set var="entryDescription" value="${fn:trim(param.description)}"/>
            <c:if test="${empty entryDescription}">
                <p class="error">You must enter a description.</p>
                <c:set var="insertError" value="true"/>
            </c:if>

            <fmt:parseDate var="parsedParamDate" value="${param.date}" type="date" pattern="yyyy-MM-dd"/>

            <c:set var="timesheetOfSubmission" value="${sarariman:timesheet(sarariman, employeeNumber, du:weekStart(parsedParamDate))}"/>
            <c:if test="${timesheetOfSubmission.submitted}">
                <p class="error">Cannot modify a submitted timesheet.</p>
                <c:set var="insertError" value="true"/>
            </c:if>

            <c:if test="${parsedParamDate.time > du:now().time && task != 4 && task != 5}">
                <p class="error">Cannot record non-PTO time in the future.</p>
                <c:set var="insertError" value="true"/>
            </c:if>

            <c:choose>
                <c:when test="${empty param.duration}">
                    <p class="error">You must have a duration.</p>
                    <c:set var="insertError" value="true"/>
                </c:when>
                <c:otherwise>
                    <c:if test="${param.duration <= 0.0}">
                        <p class="error">Duration must be positive.</p>
                        <c:set var="insertError" value="true"/>
                    </c:if>

                    <c:if test="${param.duration > 24.0}">
                        <p class="error">Duration must be less than 24 hours.</p>
                        <c:set var="insertError" value="true"/>
                    </c:if>
                </c:otherwise>
            </c:choose>

            <c:if test="${!insertError}">
                <sql:update dataSource="jdbc/sarariman" var="rowsInserted">
                    INSERT INTO hours (employee, task, date, description, duration) values(?, ?, ?, ?, ?)
                    <sql:param value="${employeeNumber}"/>
                    <sql:param value="${task}"/>
                    <sql:param value="${param.date}"/>
                    <sql:param value="${entryDescription}"/>
                    <sql:param value="${param.duration}"/>
                </sql:update>
                <c:choose>
                    <c:when test="${rowsInserted == 1}">
                        <sql:update dataSource="jdbc/sarariman" var="rowsInserted">
                            INSERT INTO hours_changelog (employee, task, date, reason, remote_address, remote_user, duration) values(?, ?, ?, ?, ?, ?, ?)
                            <sql:param value="${employeeNumber}"/>
                            <sql:param value="${task}"/>
                            <sql:param value="${param.date}"/>
                            <sql:param value="Entry created."/>
                            <sql:param value="${pageContext.request.remoteHost}"/>
                            <sql:param value="${employeeNumber}"/>
                            <sql:param value="${param.duration}"/>
                        </sql:update>
                        <c:if test="${rowsInserted != 1}">
                            <p class="error">There was an error creating the audit log for your entry.</p>
                        </c:if>
                    </c:when>
                    <c:otherwise>
                        <p class="error">There was an error creating your entry.</p>
                    </c:otherwise>
                </c:choose>
            </c:if>
        </c:if>

        <c:if test="${!timesheet.submitted}">
            <div id="recordTime">
                <h2>Record time worked</h2>
                <form action="${request.requestURI}" method="post">
                    <label for="date">Date:</label>
                    <fmt:formatDate var="now" value="${du:now()}" type="date" pattern="yyyy-MM-dd" />
                    <input size="10" type="text" name="date" id="date" value="${now}"/>
                    <br/>

                    <label for="task">Task:</label>
                    <select name="task" id="task" onchange="enable('submit');">
                        <option selected="true"></option>
                        <c:forEach var="task" items="${sarariman:billableTasks(sarariman, user)}">
                            <option value="${task.id}">${fn:escapeXml(task.name)} (${task.id})
                                <c:if test="${!empty task.project}">
                                    - ${fn:escapeXml(task.project.name)}:${fn:escapeXml(sarariman.customers[task.project.customer].name)}
                                </c:if>
                            </option>
                        </c:forEach>
                        <c:forEach var="task" items="${sarariman:unbillableTasks(sarariman, user)}">
                            <option value="${task.id}">${fn:escapeXml(task.name)} (${task.id})
                                <c:if test="${!empty task.project}">
                                    - ${fn:escapeXml(task.project.name)}:${fn:escapeXml(sarariman.customers[task.project.customer].name)}
                                </c:if>
                            </option>
                        </c:forEach>
                    </select>
                    <br/>

                    <label for="duration">Duration:</label>
                    <input size="5" type="text" name="duration" id="duration"/>
                    <br/>
                    <label for="description">Description:</label><br/>
                    <textarea cols="80" rows="10" name="description" id="description"></textarea>
                    <fmt:formatDate var="weekString" value="${week}" type="date" pattern="yyyy-MM-dd" />
                    <input type="hidden" name="week" value="${weekString}"/><br/>
                    <input type="submit" name="recordTime" value="Record" id="submit" disabled="true"/>
                </form>
            </div>
        </c:if>

        <div id="weekNavigation">
            <h2>Navigate to another week</h2>
            <form action="${request.requestURI}" method="post">
                <fmt:formatDate var="prevWeekString" value="${du:prevWeek(week)}" type="date" pattern="yyyy-MM-dd"/>
                <input type="submit" name="week" value="${prevWeekString}"/>
                <fmt:formatDate var="nextWeekString" value="${du:nextWeek(week)}" type="date" pattern="yyyy-MM-dd"/>
                <input type="submit" name="week" value="${nextWeekString}"/>
            </form>
        </div>

        <div id="sheetView">
            <fmt:formatDate var="thisWeekStart" value="${week}" type="date" pattern="yyyy-MM-dd" />

            <h2>Timesheet for the week of ${thisWeekStart}</h2>

            <table class="altrows" id="days">
                <c:set var="dayTotals" value="${timesheet.hoursByDay}"/>
                <tr>
                    <c:forEach items="${dayTotals}" var="entry">
                        <fmt:formatDate var="day" value="${entry.key.time}" pattern="E"/>
                        <th>${day}</th>
                    </c:forEach>
                </tr>
                <tr>
                    <c:forEach items="${dayTotals}" var="entry">
                        <td class="duration">${entry.value}</td>
                    </c:forEach>
                </tr>
            </table>

            <br/>

            <!-- FIXME: Can I do the nextWeek part in SQL? -->
            <sql:query dataSource="jdbc/sarariman" var="entries">
                SELECT hours.task, hours.description, hours.date, hours.duration, tasks.name
                FROM hours INNER JOIN tasks ON hours.task=tasks.id
                WHERE employee=? AND hours.date >= ? AND hours.date < DATE_ADD(?, INTERVAL 7 DAY)
                ORDER BY hours.date DESC, hours.task ASC
                <sql:param value="${employeeNumber}"/>
                <sql:param value="${thisWeekStart}"/>
                <sql:param value="${thisWeekStart}"/>
            </sql:query>
            <c:set var="totalHours" value="0.0"/>
            <c:set var="totalRegular" value="0.0"/>
            <c:set var="totalPTO" value="0.0"/>
            <c:set var="totalHoliday" value="0.0"/>
            <table class="altrows" id="hours">
                <tr><th>Date</th><th>Task</th><th>Task #</th><th>Duration</th><th>Description</th>
                    <c:if test="${!timesheet.submitted}">
                        <th></th>
                    </c:if>
                </tr>
                <c:forEach var="entry" items="${entries.rows}">
                    <tr>
                        <fmt:formatDate var="entryDate" value="${entry.date}" pattern="E, MMM d"/>
                        <td class="date">${entryDate}</td>
                        <td>${fn:escapeXml(entry.name)}</td>
                        <td class="task">${entry.task}</td>
                        <td class="duration">${entry.duration}</td>
                        <c:set var="entryDescription" value="${entry.description}"/>
                        <c:if test="${sarariman:containsHTML(entryDescription)}">
                            <!-- FIXME: I really only want to escape XML entities in the above fixup. -->
                            <c:set var="entryDescription" value="${entryDescription}"/>
                        </c:if>
                        <td>${entryDescription}</td>
                        <c:if test="${!timesheet.submitted}">
                            <td>
                                <c:url var="editLink" value="editentry">
                                    <c:param name="task" value="${entry.task}"/>
                                    <c:param name="date" value="${entry.date}"/>
                                    <c:param name="employee" value="${employeeNumber}"/>
                                </c:url>
                                <a href="${fn:escapeXml(editLink)}">Edit</a>
                            </td>
                        </c:if>
                        <c:set var="totalHours" value="${totalHours + entry.duration}"/>
                        <c:choose>
                            <%-- FIXME: This needs to look this up somewhere. --%>
                            <c:when test="${entry.task == 5}">
                                <c:set var="totalPTO" value="${totalPTO + entry.duration}"/>
                            </c:when>
                            <c:when test="${entry.task == 4}">
                                <c:set var="totalHoliday" value="${totalHoliday + entry.duration}"/>
                            </c:when>
                            <c:otherwise>
                                <c:set var="totalRegular" value="${totalRegular + entry.duration}"/>
                            </c:otherwise>
                        </c:choose>
                    </tr>
                </c:forEach>
                <tr>
                    <td colspan="3"><b>Total</b></td>
                    <td class="duration"><b>${totalHours}</b></td>
                    <td colspan="2"></td>
                </tr>
                <tr>
                    <td colspan="3"><b>Total Regular</b></td>
                    <td class="duration"><b>${totalRegular}</b></td>
                    <td colspan="2"></td>
                </tr>
                <tr>
                    <td colspan="3"><b>Total Holiday</b></td>
                    <td class="duration"><b>${totalHoliday}</b></td>
                    <td colspan="2"></td>
                </tr>
                <tr>
                    <td colspan="3"><b>Total PTO</b></td>
                    <td class="duration"><b>${totalPTO}</b></td>
                    <td colspan="2"></td>
                </tr>
            </table>

            <c:set var="hoursNeeded" value="0.0" />
            <c:if test="${user.fulltime}">
                <c:set var="hoursNeeded" value="40.0" />
            </c:if>
            <c:set var="hoursNeeded" value="${hoursNeeded - totalHours}"/>
            <c:set var="canSubmit" value="true"/>
            <c:if test="${hoursNeeded > 0.0}">
                <p>Salaried hours remaining in week: <span class="duration">${hoursNeeded}</span></p>
                <c:set var="canSubmit" value="false"/>
            </c:if>

            <c:if test="${totalHours > 40.0 && totalPTO > 0.0}">
                <p class="error">PTO taken when sheet is above 40 hours!</p>
                <c:set var="canSubmit" value="false"/>
            </c:if>

            <form action="${request.requestURI}" method="post">
                <label for="submitted">Submitted: </label>
                <input type="checkbox" name="submitted" id="submitted" disabled="true" <c:if test="${submitted}">checked="checked"</c:if>/>
                <c:set var="approved" value="${timesheet.approved}"/>
                <label for="approved">Approved: </label>
                <input type="checkbox" name="approved" id="approved" disabled="true" <c:if test="${approved}">checked="checked"</c:if>/>
                <c:if test="${!submitted && canSubmit}">
                    <input type="hidden" value="true" name="submit"/>
                    <input type="submit" value="Submit"/>
                    <fmt:formatDate var="weekString" value="${week}" pattern="yyyy-MM-dd"/>
                    <input type="hidden" name="week" value="${weekString}"/>
                </c:if>
            </form>

        </div>

        <sql:query dataSource="jdbc/sarariman" var="groupingResult">
            SELECT DISTINCT(e.grouping) FROM hours AS h
            JOIN task_grouping_element AS e ON e.task = h.task
            JOIN task_grouping_employee AS emp ON e.grouping = emp.grouping
            WHERE h.duration > 0 AND h.date >= ? AND h.date < DATE_ADD(?, INTERVAL 7 DAY) AND h.employee = ? AND emp.employee = ?
            <sql:param value="${thisWeekStart}"/>
            <sql:param value="${thisWeekStart}"/>
            <sql:param value="${employeeNumber}"/>
            <sql:param value="${employeeNumber}"/>
        </sql:query>
        <c:if test="${groupingResult.rowCount != 0}">
            <h3>Task Groupings</h3>
            <c:forEach var="groupRow" items="${groupingResult.rows}">
                <sql:query dataSource="jdbc/sarariman" var="groupResult">
                    SELECT * FROM task_grouping where id=?
                    <sql:param value="${groupRow.grouping}"/>
                </sql:query>
                <c:set var="grouping" value="${groupResult.rows[0]}"/>

                <table class="altrows">
                    <caption>${fn:escapeXml(grouping.name)}</caption>
                    <tr><th>Task</th><th>Name</th><th>Target</th><th>Actual</th></tr>

                    <sql:query dataSource="jdbc/sarariman" var="elementsResult">
                        SELECT e.fraction, e.task, t.name FROM task_grouping_element AS e
                        JOIN task_grouping AS g ON g.id = e.grouping
                        JOIN tasks AS t ON t.id = e.task
                        WHERE g.id = ?
                        ORDER BY e.task
                        <sql:param value="${grouping.id}"/>
                    </sql:query>

                    <sql:query dataSource="jdbc/sarariman" var="totalActualResult">
                        SELECT SUM(h.duration) AS total FROM hours AS h
                        JOIN task_grouping_element AS e ON e.task = h.task
                        JOIN task_grouping_employee AS emp ON e.grouping = emp.grouping
                        WHERE h.date >= ? AND h.date < DATE_ADD(?, INTERVAL 7 DAY) AND h.employee = ? AND emp.employee = ?
                        <sql:param value="${thisWeekStart}"/>
                        <sql:param value="${thisWeekStart}"/>
                        <sql:param value="${employeeNumber}"/>
                        <sql:param value="${employeeNumber}"/>
                    </sql:query>
                    <c:set var="totalInGroup" value="${totalActualResult.rows[0].total}"/>

                    <c:forEach var="row" items="${elementsResult.rows}">
                        <tr>
                            <td><a href="task?task_id=${row.task}">${row.task}</a></td>
                            <td><a href="task?task_id=${row.task}">${fn:escapeXml(row.name)}</a></td>
                            <td class="percentage"><fmt:formatNumber value="${row.fraction}" type="percent"/></td>
                            <sql:query dataSource="jdbc/sarariman" var="actualResult">
                                SELECT SUM(h.duration) AS total FROM hours AS h
                                WHERE h.date >= ? AND h.date < DATE_ADD(?, INTERVAL 7 DAY) AND h.employee = ? AND h.task = ?
                                <sql:param value="${thisWeekStart}"/>
                                <sql:param value="${thisWeekStart}"/>
                                <sql:param value="${employeeNumber}"/>
                                <sql:param value="${row.task}"/>
                            </sql:query>
                            <c:set var="actual" value="${actualResult.rows[0].total / totalInGroup}"/>
                            <td class="percentage"><fmt:formatNumber value="${actual}" type="percent"/></td>
                        </tr>
                    </c:forEach>
                </table>
            </c:forEach>
        </c:if>

        <sql:query dataSource="jdbc/sarariman" var="resultSet">
            SELECT pm.project
            FROM project_managers AS pm
            JOIN projects AS p ON pm.project = p.id
            WHERE pm.employee = ? AND
            p.active = TRUE
            UNION
            SELECT pm.project
            FROM project_cost_managers AS pm
            JOIN projects AS p ON pm.project = p.id
            WHERE pm.employee = ? AND
            p.active = TRUE
            UNION
            SELECT DISTINCT(p.id) AS project
            FROM projects AS p
            JOIN tasks AS t ON t.project = p.id
            JOIN task_assignments AS ta ON ta.task=t.id
            WHERE ta.employee = ? AND
            p.active = TRUE
            <sql:param value="${employeeNumber}"/>
            <sql:param value="${employeeNumber}"/>
            <sql:param value="${employeeNumber}"/>
        </sql:query>
        <c:if test="${resultSet.rowCount != 0}">
            <h2>Projects</h2>
            <ul>
                <c:forEach var="mapping_row" items="${resultSet.rows}">
                    <c:set var="project" value="${sarariman.projects[mapping_row.project]}"/>
                    <c:set var="customer" value="${sarariman.customers[project.customer]}"/>
                    <c:url var="link" value="project">
                        <c:param name="id" value="${mapping_row.project}"/>
                    </c:url>
                    <li><a href="${link}">${fn:escapeXml(project.name)} - ${fn:escapeXml(customer.name)}</a></li>
                </c:forEach>
            </ul>
        </c:if>

        <sql:query dataSource="jdbc/sarariman" var="resultSet">
            SELECT begin, end, name, description FROM company_events WHERE (begin >= DATE(NOW()) OR end >= DATE(NOW()))
        </sql:query>
        <c:if test="${resultSet.rowCount != 0}">
            <h2>Events</h2>
            <ul>
                <c:forEach var="row" items="${resultSet.rows}">
                    <li>
                        <fmt:formatDate value="${row.begin}" type="both" dateStyle="long" timeStyle="short" /> -
                        <fmt:parseDate var="beginDate" pattern="yyyy-MM-dd" value="${row.begin}"/>
                        <fmt:parseDate var="endDate" pattern="yyyy-MM-dd" value="${row.end}"/>
                        <c:choose>
                            <c:when test="${beginDate eq endDate}">
                                <fmt:formatDate value="${row.end}" type="time" timeStyle="short" />                                    
                            </c:when>
                            <c:otherwise>
                                <fmt:formatDate value="${row.end}" type="both" dateStyle="long" timeStyle="short" />                                
                            </c:otherwise>
                        </c:choose>
                        - ${fn:escapeXml(row.name)}
                        <c:if test="${!empty row.description}">
                            - ${fn:escapeXml(row.description)}
                        </c:if>
                    </li>
                </c:forEach>
            </ul>
        </c:if>

        <h2>Upcoming Holidays</h2>
        <sql:query dataSource="jdbc/sarariman" var="resultSet">
            SELECT * FROM holidays WHERE date >= DATE(NOW()) ORDER BY date
        </sql:query>
        <table>
            <tr><th>Date</th><th>Holiday</th></tr>
            <c:forEach var="row" items="${resultSet.rows}">
                <tr>
                    <td><fmt:formatDate value="${row.date}" type="date" pattern="MMM d" /></td>
                    <td>${row.description}</td>
                </tr>
            </c:forEach>
        </table>

        <h2 id="scheduledVacation">Scheduled Vacation</h2>
        <p>
            <a href="vacation/create.jsp">Add an entry</a>
            <sql:query dataSource="jdbc/sarariman" var="resultSet">
                SELECT begin, end, comment FROM vacation WHERE employee=? AND (begin >= DATE(NOW()) OR end >= DATE(NOW()))
                <sql:param value="${employeeNumber}"/>
            </sql:query>
            <c:if test="${resultSet.rowCount != 0}">
                <ul>
                    <c:forEach var="row" items="${resultSet.rows}">
                        <li>
                            <c:choose>
                                <c:when test="${row.begin eq row.end}">
                                    <fmt:formatDate value="${row.begin}" type="date" dateStyle="long" />
                                </c:when>
                                <c:otherwise>
                                    <fmt:formatDate value="${row.begin}" type="date" dateStyle="long" /> -
                                    <fmt:formatDate value="${row.end}" type="date" dateStyle="long" />
                                </c:otherwise>
                            </c:choose>
                            <c:if test="${!empty row.comment}">
                                - ${fn:escapeXml(row.comment)}
                            </c:if>
                            <form style="display:inline" method="GET" action="vacation/edit.jsp">
                                <input type="hidden" name="begin" value="${row.begin}"/>
                                <input type="hidden" name="end" value="${row.end}"/>
                                <input type="submit" name="Edit" value="edit"/>
                            </form>
                            <form style="display:inline" method="POST" action="vacation/handleDelete.jsp">
                                <input type="hidden" name="begin" value="${row.begin}"/>
                                <input type="hidden" name="end" value="${row.end}"/>
                                <input type="submit" name="Delete" value="delete"/>
                            </form>
                        </li>
                    </c:forEach>
                </ul>
            </c:if>
        </p>

        <h2 id="outOfOffice">Scheduled Out of Office</h2>
        <p>
            <a href="outOfOffice/create.jsp">Add an entry</a>
            <sql:query dataSource="jdbc/sarariman" var="resultSet">
                SELECT id, begin, end, comment FROM out_of_office WHERE employee=? AND (begin >= DATE(NOW()) OR end >= DATE(NOW()))
                <sql:param value="${employeeNumber}"/>
            </sql:query>
            <c:if test="${resultSet.rowCount != 0}">
                <ul>
                    <c:forEach var="row" items="${resultSet.rows}">
                        <li>
                            <fmt:formatDate value="${row.begin}" type="both" dateStyle="long" timeStyle="short" /> -
                            <fmt:parseDate var="beginDate" pattern="yyyy-MM-dd" value="${row.begin}"/>
                            <fmt:parseDate var="endDate" pattern="yyyy-MM-dd" value="${row.end}"/>
                            <c:choose>
                                <c:when test="${beginDate eq endDate}">
                                    <fmt:formatDate value="${row.end}" type="time" timeStyle="short" />                                    
                                </c:when>
                                <c:otherwise>
                                    <fmt:formatDate value="${row.end}" type="both" dateStyle="long" timeStyle="short" />                                
                                </c:otherwise>
                            </c:choose>
                            <c:if test="${!empty row.comment}">
                                - ${fn:escapeXml(row.comment)}
                            </c:if>
                            <form style="display:inline" method="GET" action="outOfOffice/edit.jsp">
                                <input type="hidden" name="id" value="${row.id}"/>
                                <input type="submit" name="Edit" value="edit"/>
                            </form>
                            <form style="display:inline" method="POST" action="outOfOffice/handleDelete.jsp">
                                <input type="hidden" name="id" value="${row.id}"/>
                                <input type="submit" name="Delete" value="delete"/>
                            </form>
                        </li>
                    </c:forEach>
                </ul>
            </c:if>
        </p>

        <%@include file="footer.jsp" %>
    </body>
</html>
