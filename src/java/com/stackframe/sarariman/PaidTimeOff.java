/*
 * Copyright (C) 2012 StackFrame, LLC
 * This code is licensed under GPLv2.
 */
package com.stackframe.sarariman;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collection;
import java.util.Map;

/**
 *
 * @author mcculley
 */
public class PaidTimeOff {

    private static Collection<Employee> employeesToCredit(Sarariman sarariman) {
        Directory directory = sarariman.getDirectory();
        Map<String, Employee> employeesByUserName = directory.getByUserName();
        Collection<Employee> result = new ArrayList<Employee>();
        for (Employee employee : employeesByUserName.values()) {
            if (employee.isActive() && employee.isFulltime()) {
                result.add(employee);
            }
        }

        return result;
    }

    private static void creditPaidTimeOff(Connection connection, double amount, Employee employee, Date effective, String source, String comment) throws SQLException {
        PreparedStatement checkQuery = connection.prepareStatement("SELECT * FROM paid_time_off WHERE employee=? AND effective=? AND source=?");
        try {
            checkQuery.setInt(1, employee.getNumber());
            checkQuery.setDate(2, effective);
            checkQuery.setString(3, source);
            ResultSet result = checkQuery.executeQuery();
            try {
                boolean found = result.first();
                if (!found) {
                    PreparedStatement addPTO = connection.prepareStatement("INSERT INTO paid_time_off(employee, amount, comment, effective, source) VALUES(?, ?, ?, ?, ?)");
                    try {
                        addPTO.setInt(1, employee.getNumber());
                        addPTO.setDouble(2, amount);
                        addPTO.setString(3, comment);
                        addPTO.setDate(4, effective);
                        addPTO.setString(5, source);
                        int rowCount = addPTO.executeUpdate();
                        if (rowCount != 1) {
                            throw new AssertionError("Expected there to be 1 row");
                        }
                    } finally {
                        addPTO.close();
                    }
                }
            } finally {
                result.close();
            }
        } finally {
            checkQuery.close();
        }
    }

    public static void creditWeeklyPaidTimeOff(Sarariman sarariman, Date weekStart) throws SQLException {
        Collection<Employee> employeesToCredit = employeesToCredit(sarariman);
        double perWeek = 3.39;
        String source = "weeklyPTOCredit";
        Connection connection = sarariman.openConnection();
        try {
            connection.setAutoCommit(false);
            for (Employee employee : employeesToCredit) {
                creditPaidTimeOff(connection, perWeek, employee, weekStart, source, "credit for week of " + weekStart);
            }

            connection.commit();
            connection.setAutoCommit(true);

            sarariman.getEmailDispatcher().send(EmailDispatcher.addresses(sarariman.getInvoiceManagers()), null, "PTO updated",
                    "Paid time off was updated for all active fulltime employees.");
        } finally {
            connection.close();
        }
    }

    public static boolean isHoliday(Sarariman sarariman, Date date, StringBuilder holidayName) throws SQLException {
        Connection connection = sarariman.openConnection();
        try {
            PreparedStatement checkQuery = connection.prepareStatement("SELECT description FROM holidays WHERE date=?");
            try {
                checkQuery.setDate(1, date);
                ResultSet result = checkQuery.executeQuery();
                try {
                    boolean hasFirst = result.first();
                    if (!hasFirst) {
                        return false;
                    } else {
                        String description = result.getString("description");
                        if (holidayName != null) {
                            holidayName.append(description);
                        }

                        return true;
                    }
                } finally {
                    result.close();
                }
            } finally {
                checkQuery.close();
            }
        } finally {
            connection.close();
        }
    }

    public static void creditHolidayPTO(Sarariman sarariman) throws SQLException {
        Calendar today = Calendar.getInstance();
        Date todayDate = new Date(today.getTime().getTime());
        StringBuilder holidayName = new StringBuilder();
        boolean todayIsHoliday = isHoliday(sarariman, todayDate, holidayName);
        if (todayIsHoliday) {
            creditHolidayPTO(sarariman, todayDate, holidayName);
        }
    }

    public static void creditHolidayPTO(Sarariman sarariman, Date day, CharSequence holidayName) throws SQLException {
        Collection<Employee> employeesToCredit = employeesToCredit(sarariman);
        String source = "holidayPTOCredit";
        Connection connection = sarariman.openConnection();
        try {
            connection.setAutoCommit(false);
            for (Employee employee : employeesToCredit) {
                creditPaidTimeOff(connection, 8.00, employee, day, source, "credit for holiday: " + holidayName);
            }

            connection.commit();
            connection.setAutoCommit(true);

            sarariman.getEmailDispatcher().send(EmailDispatcher.addresses(sarariman.getInvoiceManagers()), null, "holiday PTO updated",
                    "Holiday paid time off was updated for all active fulltime employees.");
        } finally {
            connection.close();
        }
    }

}
