const std = @import("std");
const Node = @import("node.zig").Node;
const AStar = @import("a_star.zig").AStar;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== A* Pathfinding Demo ===\n", .{});

    // Test: Complex maze
    {
        std.debug.print("\nTest: Complex 8x8 maze\n", .{});
        const complexGrid = [_][]const Node{
            &[_]Node{ Node.init(true), Node.init(true), Node.init(false), Node.init(false), Node.init(false), Node.init(true), Node.init(true), Node.init(true) },
            &[_]Node{ Node.init(true), Node.init(true), Node.init(false), Node.init(true), Node.init(true), Node.init(true), Node.init(false), Node.init(true) },
            &[_]Node{ Node.init(true), Node.init(false), Node.init(false), Node.init(true), Node.init(false), Node.init(true), Node.init(false), Node.init(true) },
            &[_]Node{ Node.init(true), Node.init(true), Node.init(true), Node.init(true), Node.init(false), Node.init(true), Node.init(true), Node.init(true) },
            &[_]Node{ Node.init(false), Node.init(false), Node.init(false), Node.init(true), Node.init(false), Node.init(false), Node.init(false), Node.init(true) },
            &[_]Node{ Node.init(true), Node.init(true), Node.init(true), Node.init(true), Node.init(true), Node.init(true), Node.init(true), Node.init(true) },
            &[_]Node{ Node.init(true), Node.init(false), Node.init(false), Node.init(false), Node.init(false), Node.init(false), Node.init(true), Node.init(true) },
            &[_]Node{ Node.init(true), Node.init(true), Node.init(true), Node.init(true), Node.init(true), Node.init(true), Node.init(true), Node.init(true) },
        };
        const grid: [][]const Node = @constCast(&complexGrid);

        var pathFinder = AStar.init(allocator, 8, 8) catch |err| {
            std.debug.print("Error initializing A* pathfinder: {}\n", .{err});
            return err;
        };
        defer pathFinder.deinit();

        // Show the initial grid layout
        try pathFinder.gridManager.setGrid(grid);
        try pathFinder.visualizeGridOnly();

        pathFinder.findPath(grid, .{ 0, 0 }, .{ 7, 7 }) catch |err| {
            std.debug.print("Error finding path: {}\n", .{err});
        };
    }

    std.debug.print("\n=== Demo Complete ===\n", .{});
}
