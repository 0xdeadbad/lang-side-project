const std = @import("std");
const meta = std.meta;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

// const prettiziy = @import("prettizy");

const tokenizer = @import("./tokenizer.zig");
const Token = tokenizer.Token;
const Tokenizer = tokenizer.Tokenizer;
const TokenTag = tokenizer.Token.Tag;

const NodeArrayList = ArrayList(?*Node);
const Ast = struct {
    allocator: Allocator,
    tokens: ArrayList(Token),
    current: usize,

    pub fn generate(allocator: Allocator, src: [:0]const u8) !ArrayList(?*Node) {
        var ast = try allocator.create(Ast);
        defer allocator.destroy(ast);

        ast.allocator = allocator;

        var nodes = ArrayList(?*Node).init(allocator);

        var tkz = Tokenizer.init(src);
        ast.tokens = ArrayList(Token).init(allocator);

        while (tkz.next()) |token|
            try ast.tokens.append(token);

        while (!ast.is_eof())
            try nodes.append(ast.declaration());

        return nodes;
    }

    fn declaration(self: *Ast) ?*Node {
        if (self.check(&.{ TokenTag.let_t, TokenTag.typedef_t })) |t| {
            return switch (t) {
                TokenTag.let_t => self.let_decl(),
                TokenTag.typedef_t => self.typedef_decl(),
                else => @panic("not supposed to reach here."),
            };
        }

        return self.statement();
    }

    fn statement(self: *Ast) ?*Node {
        if (self.check(&.{ TokenTag.for_t, TokenTag.while_t, TokenTag.fun_t, TokenTag.left_brace, TokenTag.if_t })) |t|
            return switch (t) {
                TokenTag.for_t => self.for_stmt(),
                TokenTag.while_t => self.while_stmt(),
                TokenTag.fun_t => self.fun_stmt(),
                TokenTag.if_t => self.if_stmt(),
                TokenTag.left_brace => self.block(),
                else => @panic("not supposed to reach here"),
            }
        else
            return null;

        return self.expr_stmt();
    }

    fn let_decl(self: *Ast) ?*Node {
        _ = self.consume(TokenTag.let_t, "expected let to consume");
        const name = self.consume(TokenTag.identifier, "expected identifier after let token");
        var type_ann: ?*Token = null;
        var init: ?*Node = null;

        if (self.peek()) |p| {
            if (p.tag == TokenTag.colon) {
                self.skip();
                type_ann = self.consume(.identifier, "expected identifier after colon");
            }
        }

        if (self.peek()) |p| {
            if (p.tag == .equal) {
                self.skip();
                init = self.expression();
            }
        }

        _ = self.consume(.semicolon, "expected semicolon");

        var r = Node.init(self.allocator) catch @panic("shiiiit");

        r.kind = .Stmt;
        r.payload = .{
            .let_decl = .{
                .name = name,
                .init = if (init) |t| t else null,
                .type_ann = type_ann,
            },
        };

        return r;
    }

    fn typedef_decl(_: *Ast) ?*Node {
        return null;
    }

    fn expression(self: *Ast) ?*Node {
        if (self.peek()) |tk| {
            switch (tk.tag) {
                TokenTag.identifier => {
                    self.consume(TokenTag.identifier, "failed to consume identifier");
                    if (self.peek()) |tkn|
                        switch (tkn.tag) {
                            TokenTag.left_paren => {},
                            TokenTag.dec, TokenTag.inc => {},
                            else => {},
                        };
                },
                TokenTag.return_t => self.expr_return(),
                else => {},
            }
        } else return null;

        return self.stmt_assignment();
    }

    fn expr_fn_call(_: *Ast) ?*Node {
        return null;
    }

    fn expr_unary_left(_: *Ast) ?*Node {
        return null;
    }

    fn expr_return(_: *Ast) ?*Node {
        return null;
    }

    fn expr_stmt(_: *Ast) ?*Node {
        return null;
    }

    fn stmt_for(_: *Ast) ?*Node {
        return null;
    }

    fn stmt_while(_: *Ast) ?*Node {
        return null;
    }

    fn stmt_fun(_: *Ast) ?*Node {
        return null;
    }

    fn stmt_if(_: *Ast) ?*Node {
        return null;
    }

    fn block(_: *Ast) ?*Node {
        return null;
    }

    fn stmt_assignment(_: *Ast) ?*Node {
        return null;
    }

    fn expr_equality(_: *Ast) ?*Node {
        return null;
    }

    fn expr_logic(_: *Ast) ?*Node {
        return null;
    }

    fn expr_comparison(_: *Ast) ?*Node {
        return null;
    }

    fn expr_term(_: *Ast) ?*Node {
        return null;
    }

    fn expr_factor(_: *Ast) ?*Node {
        return null;
    }

    fn expr_unary_right(_: *Ast) ?*Node {
        return null;
    }

    fn expr_primary(self: *Ast) ?*Node {
        if (self.check(&.{ TokenTag.int2, TokenTag.int8, TokenTag.int10, TokenTag.int16, TokenTag.string, TokenTag.bool_t, TokenTag.nil_t })) |tk_tag| {
            return switch (tk_tag) {
                TokenTag.int2 => Node.init(self.allocator, .{
                    .literal = .{
                        .value = .{ .int = try std.fmt.parseInt(i64, self.peek() orelse @panic("expected token"), 2) },
                    },
                }) catch @panic("could not create node for int2"),
                TokenTag.int8 => Node.init(self.allocator, .{
                    .literal = .{
                        .value = .{ .int = try std.fmt.parseInt(i64, self.peek() orelse @panic("expected token"), 8) },
                    },
                }) catch @panic("could not create node for int8"),
                TokenTag.int10 => Node.init(self.allocator, .{
                    .literal = .{
                        .value = .{ .int = try std.fmt.parseInt(i64, self.peek() orelse @panic("expected token"), 10) },
                    },
                }) catch @panic("could not create node for int10"),
                TokenTag.int16 => Node.init(self.allocator, .{
                    .literal = .{
                        .value = .{ .int = try std.fmt.parseInt(i64, self.peek() orelse @panic("expected token"), 16) },
                    },
                }) catch @panic("could not create node for int16"),
                TokenTag.string => Node.init(self.allocator, .{
                    .literal = .{
                        .value = .{ .string = self.peek() orelse @panic("expected token").lexeme },
                    },
                }) catch @panic("could not create node for string"),
                else => @panic("not implemented"),
            };
        }

        return null;
    }

    fn expr_or(_: *Ast) ?*Node {
        return null;
    }

    fn expr_and(_: *Ast) ?*Node {
        return null;
    }

    fn peek(self: *Ast) ?*Token {
        if (self.is_eof()) return null;

        return &self.tokens.items[self.current];
    }

    fn peek_n(self: *Ast, n: usize) ?*Token {
        if (self.is_eof()) return null;
        if (self.current + n >= self.tokens.items.len) return null;

        return &self.tokens[self.current + n];
    }

    // fn peek_next(self: *Ast) ?*Token {
    //     if (self.is_eof() or self.current + 1 > self.tokens.items.len) return null;

    // }

    fn next(self: *Ast) ?*Token {
        if (self.is_eof()) return null;
        defer self.current += 1;

        return &self.tokens.items[self.current];
    }

    fn skip(self: *Ast) void {
        _ = self.next();
    }

    inline fn is_eof(self: *Ast) bool {
        return self.current >= self.tokens.items.len;
    }

    fn check(self: *Ast, tk_types: []const TokenTag) ?TokenTag {
        const tkp = self.peek();
        if (tkp) |tk1|
            for (tk_types) |tk2|
                if (tk1.tag == tk2)
                    return tk2;

        return null;
    }

    fn consume(self: *Ast, tk: TokenTag, msg: [:0]const u8) *Token {
        if (self.next()) |n|
            if (tk == n.tag)
                return n;
        @panic(msg);
    }
};

const NodeTag = enum {
    let_decl,
    bin_op,
    unary_left,
    block,
    literal,
    if_expr,
    while_loop,
    for_loop,
    fn_decl,
    fn_call,
    return_expr,
};

const NodePayload = union(NodeTag) {
    let_decl: struct {
        name: ?*Token,
        init: ?*Node = null,
        type_ann: ?*Node = null,
    },
    bin_op: struct {
        op: OpType,
        left: ?*Node,
        right: ?*Node,

        const OpType = enum {
            add,
            subtract,
            multiply,
            divide,
            mod,
            left_hift,
            right_shift,
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
        stmts: ArrayList(?*Node),
    },
    literal: struct {
        const LiteralTag = enum {
            string,
            int,
            float,
        };
        value: union(LiteralTag) {
            string: [:0]const u8,
            int: i64,
            float: f64,
        },
    },
    if_expr: struct {
        condition: ?*Node,
        then_branch: ?*Node,
        else_branch: ?*Node,
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
    fn_decl: struct {
        name: ?*Node,
        fn_args: ArrayList(?*Node),
        body: ?*Node,
    },
    fn_call: struct {
        name: ?*Node,
        call_args: ArrayList(?*Node),
    },
    return_expr: struct {
        expr: ?*Node,
    },

    pub fn get_tag(self: NodePayload) NodeTag {
        return switch (self) {
            .let_decl => |_| NodeTag.let_decl,
            .bin_op => |_| NodeTag.bin_op,
            .unary_left => |_| NodeTag.unary_left,
            .block => |_| NodeTag.block,
            .literal => |_| NodeTag.literal,
            .if_expr => |_| NodeTag.if_expr,
            .while_loop => |_| NodeTag.while_loop,
            .for_loop => |_| NodeTag.for_loop,
            .fn_decl => |_| NodeTag.fn_decl,
            .fn_call => |_| NodeTag.fn_call,
            .return_expr => |_| NodeTag.return_expr,
        };
    }

    pub fn get_kind(self: NodePayload) NodeKind {
        return switch (self) {
            .let_decl => |_| NodeKind.Stmt,
            .bin_op => |_| NodeKind.Expr,
            .unary_left => |_| NodeKind.Expr,
            .block => |_| NodeKind.Stmt,
            .literal => |_| NodeKind.Expr,
            .if_expr => |_| NodeKind.ExprStmt,
            .while_loop => |_| NodeKind.Stmt,
            .for_loop => |_| NodeKind.Stmt,
            .fn_decl => |_| NodeKind.Stmt,
            .fn_call => |_| NodeKind.Expr,
            .return_expr => |_| NodeKind.ExprStmt,
        };
    }
};

const NodeKind = enum {
    Expr,
    Stmt,
    ExprStmt,
};

pub const Node = struct {
    allocator: Allocator,
    payload: NodePayload,

    pub fn init(allocator: Allocator, payload: NodePayload) !*Node {
        var node = try allocator.create(Node);

        node.allocator = allocator;
        node.kind = payload.get_kind();

        return node;
    }

    pub fn deinit(self: *Node) void {
        switch (self.payload) {
            else => self.allocator.destroy(self),
        }
    }
};

test "test NodePayload.get_tag(let_decl)" {
    const np = NodePayload{
        .let_decl = .{
            .name = null,
        },
    };

    try std.testing.expectEqual(NodeTag.let_decl, np.get_tag());
}

test "test NodePayload.get_tag(bin_op)" {
    const np = NodePayload{
        .bin_op = .{
            .op = .add,
            .left = null,
            .right = null,
        },
    };

    try std.testing.expectEqual(NodeTag.bin_op, np.get_tag());
}

test "test NodePayload.get_tag(unary_left)" {
    const np = NodePayload{
        .unary_left = .{
            .op = .inc,
            .left = null,
        },
    };

    try std.testing.expectEqual(NodeTag.unary_left, np.get_tag());
}

test "test NodePayload.get_tag(block)" {
    const np = NodePayload{
        .block = .{
            .stmts = NodeArrayList.init(std.heap.page_allocator),
        },
    };

    try std.testing.expectEqual(NodeTag.block, np.get_tag());
}

test "test NodePayload.get_tag(literal)" {
    const np = NodePayload{
        .literal = .{
            .value = .{ .int = 42 },
        },
    };

    try std.testing.expectEqual(NodeTag.literal, np.get_tag());
}

test "test NodePayload.get_tag(if_expr)" {
    const np = NodePayload{
        .if_expr = .{
            .condition = null,
            .then_branch = null,
            .else_branch = null,
        },
    };

    try std.testing.expectEqual(NodeTag.if_expr, np.get_tag());
}

test "test NoudePayload.get_tag(while_loop)" {
    const np = NodePayload{
        .while_loop = .{
            .condition = null,
            .body = null,
        },
    };

    try std.testing.expectEqual(NodeTag.while_loop, np.get_tag());
}

test "test NodePayload.get_tag(for_loop)" {
    const np = NodePayload{
        .for_loop = .{
            .initializer = null,
            .condition = null,
            .apply = null,
            .body = null,
        },
    };

    try std.testing.expectEqual(NodeTag.for_loop, np.get_tag());
}

test "test NodePayload.get_tag(fn_decl)" {
    const np = NodePayload{
        .fn_decl = .{
            .name = null,
            .fn_args = NodeArrayList.init(std.heap.page_allocator),
            .body = null,
        },
    };

    try std.testing.expectEqual(NodeTag.fn_decl, np.get_tag());
}

test "test NodePayload.get_tag(fn_call)" {
    const np = NodePayload{
        .fn_call = .{
            .name = null,
            .call_args = NodeArrayList.init(std.heap.page_allocator),
        },
    };

    try std.testing.expectEqual(NodeTag.fn_call, np.get_tag());
}

test "test NodePayload.get_tag(return_expr)" {
    const np = NodePayload{
        .return_expr = .{
            .expr = null,
        },
    };

    try std.testing.expectEqual(NodeTag.return_expr, np.get_tag());
}

test "test NodePayload.get_kind(let_decl)" {
    const np = NodePayload{
        .let_decl = .{
            .name = null,
        },
    };

    try std.testing.expectEqual(NodeKind.Stmt, np.get_kind());
}

test "test NodePayload.get_kind(bin_op)" {
    const np = NodePayload{
        .bin_op = .{
            .op = .add,
            .left = null,
            .right = null,
        },
    };

    try std.testing.expectEqual(NodeKind.Expr, np.get_kind());
}

test "test NodePayload.get_kind(unary_left)" {
    const np = NodePayload{
        .unary_left = .{
            .op = .inc,
            .left = null,
        },
    };

    try std.testing.expectEqual(NodeKind.Expr, np.get_kind());
}

test "test NodePayload.get_kind(block)" {
    const np = NodePayload{
        .block = .{
            .stmts = NodeArrayList.init(std.heap.page_allocator),
        },
    };

    try std.testing.expectEqual(NodeKind.Stmt, np.get_kind());
}

test "test NodePayload.get_kind(literal)" {
    const np = NodePayload{
        .literal = .{
            .value = .{ .int = 42 },
        },
    };

    try std.testing.expectEqual(NodeKind.Expr, np.get_kind());
}

test "test NodePayload.get_kind(if_expr)" {
    const np = NodePayload{
        .if_expr = .{
            .condition = null,
            .then_branch = null,
            .else_branch = null,
        },
    };

    try std.testing.expectEqual(NodeKind.ExprStmt, np.get_kind());
}

test "test NodePayload.get_kind(while_loop)" {
    const np = NodePayload{
        .while_loop = .{
            .condition = null,
            .body = null,
        },
    };

    try std.testing.expectEqual(NodeKind.Stmt, np.get_kind());
}

test "test NodePayload.get_kind(for_loop)" {
    const np = NodePayload{
        .for_loop = .{
            .initializer = null,
            .condition = null,
            .apply = null,
            .body = null,
        },
    };

    try std.testing.expectEqual(NodeKind.Stmt, np.get_kind());
}

test "test NodePayload.get_kind(fn_decl)" {
    const np = NodePayload{
        .fn_decl = .{
            .name = null,
            .fn_args = NodeArrayList.init(std.heap.page_allocator),
            .body = null,
        },
    };

    try std.testing.expectEqual(NodeKind.Stmt, np.get_kind());
}

test "test NodePayload.get_kind(fn_call)" {
    const np = NodePayload{
        .fn_call = .{
            .name = null,
            .call_args = NodeArrayList.init(std.heap.page_allocator),
        },
    };

    try std.testing.expectEqual(NodeKind.Expr, np.get_kind());
}

test "test NodePayload.get_kind(return_expr)" {
    const np = NodePayload{
        .return_expr = .{
            .expr = null,
        },
    };

    try std.testing.expectEqual(NodeKind.ExprStmt, np.get_kind());
}
