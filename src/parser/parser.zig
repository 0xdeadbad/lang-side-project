const std = @import("std");
const tokenizer = @import("./tokenizer.zig");

const Allocator = std.mem.Allocator;
const Token = tokenizer.Token;
const Tokenizer = tokenizer.Tokenizer;
const ArrayList = std.ArrayList;

const Ast = struct {
    tokens: ArrayList(Token),
    current: usize,

    pub fn generate(allocator: Allocator, src: [*:0]const u8) ?ArrayList(*Node) {
        var ast = allocator.create(Ast) orelse return null;
        defer allocator.destroy(ast);

        var nodes = ArrayList(?*Node).init(allocator);

        var tkz = Tokenizer.init(src);
        ast.tokens = ArrayList(Token).init(allocator);

        while (tkz.next()) |token|
            ast.tokens.append(token);

        while (!ast.is_eof())
            nodes.append(ast.declaration());

        return nodes;
    }

    fn declaration(self: *Ast) ?*Node {
        const p = self.peek();
      if (p) |token|

      else return null;

    }

    fn peek(self: *Ast) ?*Token {
        if (self.is_eof()) return null;

        return self.tokens.items[self.current];
    }

    fn next(self: *Ast) ?*Token {
        if (self.is_eof()) return null;
        defer self.current += 1;

        return self.tokens.items[self.current];
    }

    inline fn is_eof(self: *Ast) bool {
        return self.current >= self.tokens.items.len;
    }
};

const NodeTag = enum {
    var_decl,
    bin_op,
    unary_left,
    block,
    literal,
    if_expr,
    fn_decl,
    fn_call,
    while_loop,
    for_loop,
};

const NodeKind = enum {
    Expr,
    Stmt,
    ExprStmt,
};

const Node = struct {
    kind: NodeKind,
    payload: union(NodeTag) {
        var_decl: struct {
            name: ?*Token,
            init: ?*Node,
            type_ann: ?*Node,
        },

        bin_op: struct {
            op: OpType,
            left: ?*Node,
            right: ?*Node,

            const OpType = enum {
                Add,
                Subtract,
                Multiply,
                Divide,
            };
        },

        unary_left: struct {
            op: OpType,
            left: ?*Token,

            const OpType = enum {
                inc,
                dec,
            };
        },

        block: struct {
            stmts: [*:null]?*Node,
        },

        literal: struct {
            value: ?*Token,
        },

        if_expr: struct {
            condition: ?*Node,
            then_branch: ?*Node,
            else_branch: ?*Node,
        },

        fn_decl: struct {
            name: ?*Node,
            fn_args: [*:null]?*Node,
            body: ?*Node,
        },

        fn_call: struct {
            name: ?*Node,
            call_args: [*:null]?*Node,
        },

        while_loop: struct {
            condition: ?*Node,
            body: ?*Node,
        },

        for_loop: struct {
            initializer: ?*Node,
            condition: ?*Node,
            apply: ?*Node,
            body: ?*Node,
        },
    },

    pub fn init(allocator: Allocator) !*Node {
        const node = try allocator.create(Node);

        return node;
    }
};

test "test parser" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var t = try Node.init(allocator);
    defer allocator.destroy(t);

    t.kind = .Expr;
    t.payload = .{ .bin_op = .{
        .left = null,
        .right = null,
        .op = .Add,
    } };

    std.debug.print("{any}\n", .{t});
}
