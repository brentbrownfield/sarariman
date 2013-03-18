<%--
  Copyright (C) 2009-2013 StackFrame, LLC
  This code is licensed under GPLv2.
--%>

<%@page contentType="application/xhtml+xml" pageEncoding="UTF-8"%>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@taglib prefix="du" uri="/WEB-INF/tlds/DateUtils" %>
<%@taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <link href="style.css" rel="stylesheet" type="text/css"/>
        <link href="style/font-awesome.css" rel="stylesheet" type="text/css"/>
        <title>Tools</title>
    </head>

    <body>
        <span style="float: right">
            <a href="${user.URL}">${user.userName}</a>
            <a href="${user.URL}"><img width="25" height="25" onerror="this.style.display='none'" src="${user.photoURL}"/></a>
        </span>

        <ul>
            <li><a class="icon-home" href="./"></a></li>
            <li><a href="help.xhtml">Help</a></li>
            <li><a href="tickets/">Tickets</a></li>
            <li><a href="orgChart">Org Chart</a></li>
            <li><a href="timesheets">Timesheets</a></li>
            <li><a href="timereportsbyproject">Time reports by project</a></li>
            <li><a href="employees">Employees</a></li>
            <li><a href="scheduledVacation">Scheduled Vacation</a></li>
            <li><a href="stats">Stats</a></li>
            <c:if test="${user.administrator}">
                <li><a href="approvers">Approvers</a></li>
                <li><a href="globalAudits.jsp">Global Audits</a></li>
                <li><a href="invoices">Invoices</a></li>
                <li><a href="invoicemanagers">Invoice Managers</a></li>
                <li><a href="uninvoicedprojects">Uninvoiced Projects</a></li>
                <li><a href="customers">Customers</a></li>
                <li><a href="laborcategoryassignments">Labor Category Assignments</a></li>
                <li><a href="taskGroupings">Task Groupings</a></li>
                <li><a href="projects">Projects</a></li>
                <li><a href="tasks">Tasks</a></li>
                <li><a href="serviceagreements">Service Agreements</a></li>
                <li>
                    <fmt:formatDate var="week" value="${du:weekStart(du:now())}" type="date" pattern="yyyy-MM-dd"/>
                    <c:url var="weekBilled" value="weekBilled">
                        <c:param name="week" value="${week}"/>
                    </c:url>
                    <a href="${fn:escapeXml(weekBilled)}">Weekly Billing Report</a>
                </li>
                <li><a href="changelog">Changelog</a></li>
                <li><a href="day">Daily Activity</a></li>
                <li><a href="contacts">Contacts</a></li>
            </c:if>
            <c:if test="${user.invoiceManager}">
                <li><a href="laborcategories">Labor Categories</a></li>
                <li><a href="uninvoicedbillable">Uninvoiced Billable</a></li>
                <li><a href="saic/">SAIC Tools</a></li>
                <li><a href="unbilledservices">Unbilled Services</a></li>
                <li><a href="expenses">Expenses</a></li>
            </c:if>
            <c:if test="${user.benefitsAdministrator}">
                <li><a href="healthInsuranceSummary.jsp">Current Health Insurance Summary</a></li>                
            </c:if>
        </ul>

        <%@include file="footer.jsp" %>
    </body>
</html>
