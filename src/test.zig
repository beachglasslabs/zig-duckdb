const std = @import("std");

const DuckDb = @import("main.zig");

test "boolean" {
    var duck = try DuckDb.init(null);
    defer duck.deinit();

    try duck.query("CREATE TABLE test_bool_table (test_bool BOOL);");
    var true_sql = try std.fmt.allocPrintZ(std.testing.allocator, "INSERT INTO test_bool_table (SELECT '{}') RETURNING test_bool;", .{true});
    defer std.testing.allocator.free(true_sql);
    var result = try duck.queryResult(true_sql);
    defer duck.freeResult(&result);
    try std.testing.expect(duck.countRows(&result) == 1);
    var true_result = duck.boolean(&result, 0, 0);
    try std.testing.expect(true_result == true);
    var false_sql = try std.fmt.allocPrintZ(std.testing.allocator, "INSERT INTO test_bool_table (SELECT {}) RETURNING test_bool;", .{false});
    defer std.testing.allocator.free(false_sql);
    var result2 = try duck.queryResult(false_sql);
    defer duck.freeResult(&result2);
    try std.testing.expect(duck.countRows(&result2) == 1);
    var false_result = duck.boolean(&result2, 0, 0);
    try std.testing.expect(false_result == false);
}

test "optional" {
    var duck = try DuckDb.init(null);
    defer duck.deinit();

    var opt_val: ?[]const u8 = "dog";
    try duck.query("CREATE TABLE test_optional_table (test_optional varchar(32));");
    var str_sql = try std.fmt.allocPrintZ(std.testing.allocator, "INSERT INTO test_optional_table(test_optional) VALUES ('{?s}') RETURNING test_optional;", .{opt_val});
    defer std.testing.allocator.free(str_sql);
    var result = try duck.queryResult(str_sql);
    defer duck.freeResult(&result);
    try std.testing.expect(duck.countRows(&result) == 1);
    var str_result = try duck.optional(std.testing.allocator, &result, 0, 0);
    defer if (str_result) |str| std.testing.allocator.free(str);
    if (str_result) |str| {
        try std.testing.expect(std.mem.eql(u8, str, opt_val.?));
    }
    opt_val = null;
    var null_sql = try std.fmt.allocPrintZ(std.testing.allocator, "INSERT INTO test_optional_table (test_optional) VALUES ({?s}) RETURNING test_optional;", .{opt_val});
    defer std.testing.allocator.free(null_sql);
    var result2 = try duck.queryResult(null_sql);
    defer duck.freeResult(&result2);
    try std.testing.expect(duck.countRows(&result2) == 1);
    var null_result = try duck.optional(std.testing.allocator, &result2, 0, 0);
    try std.testing.expectEqual(null_result, opt_val);
}
