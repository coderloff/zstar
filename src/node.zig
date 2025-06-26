const Point = @Vector(2, i8);

pub const Node = struct {
    walkable: bool,
    gCost: u32, // Cost from start to this node
    hCost: u32, // Heuristic cost to end node
    parent: ?Point, // Parent point in the path

    pub fn init(walkable: bool) Node {
        return Node{
            .walkable = walkable,
            .gCost = 0,
            .hCost = 0,
            .parent = null,
        };
    }

    pub fn fCost(self: Node) u32 {
        return self.gCost + self.hCost;
    }
};
