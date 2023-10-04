const std = @import("std");
const duckdb = @cImport(@cInclude("duckdb.h"));

db: duckdb.duckdb_database,
conn: duckdb.duckdb_connection,

pub const duckdb_result = duckdb.duckdb_result;

pub const Self = @This();

pub fn init(db_path: ?[]const u8) !Self {
    var self = Self{
        .db = undefined,
        .conn = undefined,
    };

    if (db_path) |db_file| {
        if (duckdb.duckdb_open(db_file.ptr, &self.db) == duckdb.DuckDBError) {
            std.debug.print("duckdb: error opening db {s}\n", .{db_file});
            return error.DuckDBError;
        } else {
            std.debug.print("duckdb: db opened {s}\n", .{db_file});
        }
    } else {
        if (duckdb.duckdb_open(null, &self.db) == duckdb.DuckDBError) {
            std.debug.print("duckdb: error opening in-memory db\n", .{});
            return error.DuckDBError;
        } else {
            std.debug.print("duckdb: opened in-memory db\n", .{});
        }
    }
    if (duckdb.duckdb_connect(self.db, &self.conn) == duckdb.DuckDBError) {
        std.debug.print("duckdb: error connecting to db\n", .{});
        return error.DuckDBError;
    } else {
        std.debug.print("duckdb: db connected\n", .{});
    }

    return self;
}

pub fn deinit(self: *Self) void {
    duckdb.duckdb_disconnect(&self.conn);
    duckdb.duckdb_close(&self.db);
}

pub fn query(self: *const Self, query_str: []const u8) !void {
    var result = try self.queryResult(query_str);
    defer self.freeResult(&result);
}

pub fn queryResult(self: *const Self, query_str: []const u8) !duckdb.duckdb_result {
    var result: duckdb.duckdb_result = undefined;
    std.debug.print("duckdb: query sql {s}\n", .{query_str});
    if (duckdb.duckdb_query(self.conn, query_str.ptr, &result) == duckdb.DuckDBError) {
        std.debug.print("duckdb: query error {s}\n", .{duckdb.duckdb_result_error(&result)});
        return error.DuckDBError;
    }
    return result;
}

pub fn freeResult(_: *const Self, result: *duckdb.duckdb_result) void {
    defer duckdb.duckdb_destroy_result(result);
}

pub fn countRows(_: *const Self, result: *duckdb.duckdb_result) usize {
    return duckdb.duckdb_row_count(result);
}

pub fn countCols(_: *const Self, result: *duckdb.duckdb_result) usize {
    return duckdb.duckdb_column_count(result);
}

pub fn value(_: *const Self, allocator: std.mem.Allocator, result: *duckdb.duckdb_result, row: usize, col: usize) ![]const u8 {
    var val = duckdb.duckdb_value_varchar(result, col, row);
    defer duckdb.duckdb_free(val);
    return try allocator.dupe(u8, std.mem.span(val));
}

pub fn boolean(_: *const Self, result: *duckdb.duckdb_result, row: usize, col: usize) bool {
    return duckdb.duckdb_value_boolean(result, col, row);
}

pub fn isNull(_: *const Self, result: *duckdb.duckdb_result, row: usize, col: usize) bool {
    return duckdb.duckdb_value_is_null(result, col, row);
}

pub fn optional(self: *const Self, allocator: std.mem.Allocator, result: *duckdb.duckdb_result, row: usize, col: usize) !?[]const u8 {
    if (self.isNull(result, col, row)) {
        return null;
    } else {
        return try self.value(allocator, result, col, row);
    }
}
