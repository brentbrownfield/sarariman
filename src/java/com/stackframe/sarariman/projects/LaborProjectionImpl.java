/*
 * Copyright (C) 2013 StackFrame, LLC
 * This code is licensed under GPLv2.
 */
package com.stackframe.sarariman.projects;

import com.stackframe.sarariman.Directory;
import com.stackframe.sarariman.Employee;
import com.stackframe.sarariman.PeriodOfPerformance;
import com.stackframe.sarariman.tasks.Task;
import com.stackframe.sarariman.tasks.Tasks;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Date;
import javax.sql.DataSource;

/**
 *
 * @author mcculley
 */
public class LaborProjectionImpl implements LaborProjection {

    private final int id;
    private final DataSource dataSource;
    private final Directory directory;
    private final Tasks tasks;

    public LaborProjectionImpl(int id, DataSource dataSource, Directory directory, Tasks tasks) {
        this.id = id;
        this.dataSource = dataSource;
        this.directory = directory;
        this.tasks = tasks;
    }

    public int getId() {
        return id;
    }

    public Employee getEmployee() {
        try {
            Connection connection = dataSource.getConnection();
            try {
                PreparedStatement s = connection.prepareStatement("SELECT employee FROM labor_projection WHERE id=?");
                try {
                    s.setInt(1, id);
                    ResultSet r = s.executeQuery();
                    try {
                        boolean hasRow = r.first();
                        assert hasRow;
                        int employeeNumber = r.getInt("employee");
                        return directory.getByNumber().get(employeeNumber);
                    } finally {
                        r.close();
                    }
                } finally {
                    s.close();
                }
            } finally {
                connection.close();
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public PeriodOfPerformance getPeriodOfPerformance() {
        try {
            Connection connection = dataSource.getConnection();
            try {
                PreparedStatement s = connection.prepareStatement("SELECT pop_start, pop_end FROM labor_projection WHERE id=?");
                try {
                    s.setInt(1, id);
                    ResultSet r = s.executeQuery();
                    try {
                        boolean hasRow = r.first();
                        assert hasRow;
                        Date start = r.getDate("pop_start");
                        Date end = r.getDate("pop_end");
                        return new PeriodOfPerformance(start, end);
                    } finally {
                        r.close();
                    }
                } finally {
                    s.close();
                }
            } finally {
                connection.close();
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public Task getTask() {
        try {
            Connection connection = dataSource.getConnection();
            try {
                PreparedStatement s = connection.prepareStatement("SELECT task FROM labor_projection WHERE id=?");
                try {
                    s.setInt(1, id);
                    ResultSet r = s.executeQuery();
                    try {
                        boolean hasRow = r.first();
                        assert hasRow;
                        return tasks.get(r.getInt("task"));
                    } finally {
                        r.close();
                    }
                } finally {
                    s.close();
                }
            } finally {
                connection.close();
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    public double getUtilization() {
        try {
            Connection connection = dataSource.getConnection();
            try {
                PreparedStatement s = connection.prepareStatement("SELECT utilization FROM labor_projection WHERE id=?");
                try {
                    s.setInt(1, id);
                    ResultSet r = s.executeQuery();
                    try {
                        boolean hasRow = r.first();
                        assert hasRow;
                        return r.getDouble("utilization");
                    } finally {
                        r.close();
                    }
                } finally {
                    s.close();
                }
            } finally {
                connection.close();
            }
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

}