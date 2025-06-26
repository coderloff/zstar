const std = @import("std");
const Point = @Vector(2, i8);
const Node = @import("node.zig").Node;

const GridError = error{
    InvalidDimensions,
    DimensionsTooLarge,
    OutOfMemory,
    IndexOutOfBounds,
};

pub const GridManager = struct {
    width: u8 = 0,
    height: u8 = 0,
    grid: [][]Node = &[_][]Node{},
    startPoint: Point = undefined,
    endPoint: Point = undefined,

    pub fn init(self: *GridManager, allocator: std.mem.Allocator, width: u8, height: u8) !void {
        if (width == 0 or height == 0) return GridError.InvalidDimensions;
        if (width > 255 or height > 255) return GridError.DimensionsTooLarge;

        self.width = width;
        self.height = height;

        // Allocate memory for the grid
        self.grid = try allocator.alloc([]Node, height);
        for (0..height) |i| {
            self.grid[i] = try allocator.alloc(Node, width);
        }
    }

    pub fn deinit(self: *GridManager, allocator: std.mem.Allocator) void {
        for (self.grid) |row| {
            allocator.free(row);
        }
        if (self.grid.len > 0) {
            allocator.free(self.grid);
        }
        self.grid = &[_][]Node{};
    }

    pub fn setGrid(self: *GridManager, grid: [][]const Node) !void {
        if (grid.len == 0 or grid[0].len == 0) return GridError.InvalidDimensions;

        // Clear the existing grid
        self.clear();

        // Copy data from input grid (note: input grid is [y][x] format)
        for (0..self.height) |y| {
            if (y >= grid.len) return GridError.IndexOutOfBounds;
            for (0..self.width) |x| {
                if (x >= grid[y].len) return GridError.IndexOutOfBounds;
                self.grid[y][x] = grid[y][x];
            }
        }
    }

    pub fn getNeighbours(self: *GridManager, allocator: std.mem.Allocator, point: Point) ![]Point {
        if (point[0] < 0 or point[0] >= self.width or point[1] < 0 or point[1] >= self.height) {
            return GridError.IndexOutOfBounds;
        }

        var neighbours = std.ArrayList(Point).init(allocator);
        defer neighbours.deinit();

        // Check 8 directions (including diagonals)
        for ([_]i8{ -1, 0, 1 }) |dx| {
            for ([_]i8{ -1, 0, 1 }) |dy| {
                // if (dx != 0 and dy != 0) continue; // Commented out to include diagonals. Erase comment to have only orthogonal neighbours (up, down, left, right)
                if (dx == 0 and dy == 0) continue; // Skip the current point

                const newX = point[0] + dx;
                const newY = point[1] + dy;

                if (newX < 0 or newX >= self.width or newY < 0 or newY >= self.height) {
                    continue; // Skip out-of-bounds neighbours
                }

                const neighbourPos = Point{ newX, newY };
                try neighbours.append(neighbourPos);
            }
        }

        return neighbours.toOwnedSlice();
    }

    pub fn getNode(self: *GridManager, position: Point) !Node {
        if (position[0] < 0 or position[0] >= self.width or position[1] < 0 or position[1] >= self.height) {
            return GridError.IndexOutOfBounds;
        }
        return self.grid[@intCast(position[1])][@intCast(position[0])];
    }

    pub fn setNodeCosts(self: *GridManager, position: Point, gCost: u32, hCost: u32, parent: Point) !void {
        if (position[0] < 0 or position[0] >= self.width or position[1] < 0 or position[1] >= self.height) {
            return GridError.IndexOutOfBounds;
        }
        const node = &self.grid[@intCast(position[1])][@intCast(position[0])];
        node.gCost = gCost;
        node.hCost = hCost;
        node.parent = parent;
    }

    fn clear(self: *GridManager) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                self.grid[y][x] = Node.init(true);
            }
        }
    }
};
