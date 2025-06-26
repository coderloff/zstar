const std = @import("std");
const Point = @Vector(2, i8);
const Node = @import("node.zig").Node;
const GridManager = @import("grid_manager.zig").GridManager;

pub const PathError = error{
    NoPathFound,
    GridNotInitialized,
    InvalidStartPoint,
    InvalidEndPoint,
};

pub const AStar = struct {
    allocator: std.mem.Allocator,
    path: std.ArrayList(Point),
    openSet: std.ArrayList(Point),
    closedSet: std.ArrayList(Point),
    gridManager: GridManager,

    pub fn init(allocator: std.mem.Allocator, width: u8, height: u8) !AStar {
        var gridManager = GridManager{};
        try gridManager.init(allocator, width, height);

        return AStar{
            .allocator = allocator,
            .path = std.ArrayList(Point).init(allocator),
            .openSet = std.ArrayList(Point).init(allocator),
            .closedSet = std.ArrayList(Point).init(allocator),
            .gridManager = gridManager,
        };
    }

    pub fn deinit(self: *AStar) void {
        self.path.deinit();
        self.openSet.deinit();
        self.closedSet.deinit();
        self.gridManager.deinit(self.allocator);
    }

    pub fn findPath(self: *AStar, grid: [][]const Node, startPoint: Point, endPoint: Point) !void {
        if (self.gridManager.grid.len == 0) return PathError.GridNotInitialized;

        if (startPoint[0] < 0 or startPoint[0] >= self.gridManager.width or
            startPoint[1] < 0 or startPoint[1] >= self.gridManager.height)
            return PathError.InvalidStartPoint;

        if (endPoint[0] < 0 or endPoint[0] >= self.gridManager.width or
            endPoint[1] < 0 or endPoint[1] >= self.gridManager.height)
            return PathError.InvalidEndPoint;

        try self.gridManager.setGrid(grid);

        self.openSet.clearAndFree();
        self.closedSet.clearAndFree();
        self.path.clearAndFree();

        try self.openSet.append(startPoint);

        while (self.openSet.items.len > 0) {
            const currentPoint = self.findBestNode();
            const currentIndex = self.findPointIndex(self.openSet, currentPoint) orelse unreachable;

            _ = self.openSet.orderedRemove(currentIndex);
            try self.closedSet.append(currentPoint);

            if (std.meta.eql(currentPoint, endPoint)) {
                // Path found, reconstruct the path
                try self.retracePath(startPoint, endPoint);

                // Show grid visualization
                try self.visualizeGrid(startPoint, endPoint);

                // Show exploration visualization
                try self.visualizeExploration(startPoint, endPoint);

                return;
            }

            const neighbours = try self.gridManager.getNeighbours(self.allocator, currentPoint);
            defer self.allocator.free(neighbours);

            for (neighbours) |neighbour| {
                const neighbourNode = try self.gridManager.getNode(neighbour);
                if (!neighbourNode.walkable or self.contains(self.closedSet, neighbour)) continue;

                const tentativeGCost = (try self.gridManager.getNode(currentPoint)).gCost + self.getHeuristic(currentPoint, neighbour);

                const inOpenSet = self.contains(self.openSet, neighbour);
                if (!inOpenSet or tentativeGCost < neighbourNode.gCost) {
                    try self.gridManager.setNodeCosts(neighbour, tentativeGCost, self.getHeuristic(neighbour, endPoint), currentPoint);

                    if (!inOpenSet) {
                        try self.openSet.append(neighbour);
                    }
                }
            }
        }

        std.debug.print("No path found from {any} to {any}\n", .{ startPoint, endPoint });
        return PathError.NoPathFound;
    }

    fn findBestNode(self: *AStar) Point {
        var bestPoint = self.openSet.items[0];
        var bestNode = self.gridManager.getNode(bestPoint) catch unreachable;

        for (self.openSet.items[1..]) |point| {
            const node = self.gridManager.getNode(point) catch unreachable;
            if (node.fCost() < bestNode.fCost() or
                (node.fCost() == bestNode.fCost() and node.hCost < bestNode.hCost))
            {
                bestPoint = point;
                bestNode = node;
            }
        }

        return bestPoint;
    }

    fn findPointIndex(self: *AStar, list: std.ArrayList(Point), point: Point) ?usize {
        _ = self;
        for (list.items, 0..) |item, i| {
            if (std.meta.eql(item, point)) {
                return i;
            }
        }
        return null;
    }

    fn contains(self: *AStar, list: std.ArrayList(Point), point: Point) bool {
        _ = self;
        for (list.items) |item| {
            if (std.meta.eql(item, point)) {
                return true;
            }
        }
        return false;
    }

    fn getHeuristic(self: *AStar, a: Point, b: Point) u32 {
        // Using Manhattan distance as heuristic (more appropriate for grid-based pathfinding)
        _ = self;
        const dx = @abs(a[0] - b[0]);
        const dy = @abs(a[1] - b[1]);
        return @intCast(10 * (dx + dy));
    }

    fn retracePath(self: *AStar, startPoint: Point, endPoint: Point) !void {
        var currentPoint = endPoint;

        while (!std.meta.eql(currentPoint, startPoint)) {
            try self.path.append(currentPoint);
            const currentNode = try self.gridManager.getNode(currentPoint);

            if (currentNode.parent) |parent| {
                currentPoint = parent;
            } else {
                break;
            }
        }

        // Add the start point to complete the path
        try self.path.append(startPoint);

        // Reverse the path to get start -> end order
        std.mem.reverse(Point, self.path.items);
    }

    pub fn visualizeGrid(self: *AStar, startPoint: Point, endPoint: Point) !void {
        std.debug.print("\nGrid Visualization:\n", .{});
        std.debug.print("Legend: . = walkable, # = obstacle, = = path, S = start, E = end\n\n", .{});

        for (0..self.gridManager.height) |y| {
            for (0..self.gridManager.width) |x| {
                const currentPoint = Point{ @intCast(x), @intCast(y) };
                const node = try self.gridManager.getNode(currentPoint);

                // Check if this point is the start or end
                if (std.meta.eql(currentPoint, startPoint)) {
                    std.debug.print("S ", .{});
                } else if (std.meta.eql(currentPoint, endPoint)) {
                    std.debug.print("E ", .{});
                } else if (self.isOnPath(currentPoint)) {
                    std.debug.print("= ", .{});
                } else if (!node.walkable) {
                    std.debug.print("# ", .{});
                } else {
                    std.debug.print(". ", .{});
                }
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("\n", .{});
    }

    pub fn visualizeGridOnly(self: *AStar) !void {
        std.debug.print("\nGrid Layout:\n", .{});
        std.debug.print("Legend: . = walkable, # = obstacle\n\n", .{});

        for (0..self.gridManager.height) |y| {
            for (0..self.gridManager.width) |x| {
                const currentPoint = Point{ @intCast(x), @intCast(y) };
                const node = try self.gridManager.getNode(currentPoint);

                if (!node.walkable) {
                    std.debug.print("# ", .{});
                } else {
                    std.debug.print(". ", .{});
                }
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("\n", .{});
    }

    pub fn visualizeExploration(self: *AStar, startPoint: Point, endPoint: Point) !void {
        std.debug.print("\nExploration Visualization:\n", .{});
        std.debug.print("Legend: . = walkable, # = obstacle, = = path, S = start, E = end, o = explored\n\n", .{});

        for (0..self.gridManager.height) |y| {
            for (0..self.gridManager.width) |x| {
                const currentPoint = Point{ @intCast(x), @intCast(y) };
                const node = try self.gridManager.getNode(currentPoint);

                // Check if this point is the start or end
                if (std.meta.eql(currentPoint, startPoint)) {
                    std.debug.print("S ", .{});
                } else if (std.meta.eql(currentPoint, endPoint)) {
                    std.debug.print("E ", .{});
                } else if (self.isOnPath(currentPoint)) {
                    std.debug.print("= ", .{});
                } else if (!node.walkable) {
                    std.debug.print("# ", .{});
                } else if (self.contains(self.closedSet, currentPoint)) {
                    std.debug.print("o ", .{});
                } else {
                    std.debug.print(". ", .{});
                }
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("\n", .{});
    }

    fn isOnPath(self: *AStar, point: Point) bool {
        for (self.path.items) |pathPoint| {
            if (std.meta.eql(pathPoint, point)) {
                return true;
            }
        }
        return false;
    }
};
