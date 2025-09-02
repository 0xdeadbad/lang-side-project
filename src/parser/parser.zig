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
    src: [:0]const u8,

    pub fn generate(allocator: Allocator, src: [:0]const u8) !ArrayList(?*Node) {
        var ast = try allocator.create(Ast);
        defer allocator.destroy(ast);

        ast.allocator = allocator;
        ast.src = src;
        ast.current = 0;

        var nodes = ArrayList(?*Node).init(allocator);

        var tkz = Tokenizer.init(src);
        ast.tokens = ArrayList(Token).init(allocator);

        std.debug.print("Generating tokens...\n", .{});
        while (tkz.next()) |token|
            if (token.tag == TokenTag.eof) {
                try ast.tokens.append(token);
                std.debug.print("EOF token reached, stopping token generation.\n", .{});
                break;
            } else try ast.tokens.append(token);

        std.debug.print("Token generation complete, generated {} tokens.\n", .{ast.tokens.items.len});

        for (ast.tokens.items) |token|
            std.debug.print("Token: {s}\n", .{@tagName(token.tag)});

        // while (tkz.next()) |token|
        //     try ast.tokens.append(token);

        while (!ast.is_eof())
            if (ast.declaration()) |node| {
                std.debug.print("Generated node: {s}\n", .{@tagName(node.payload.get_tag())});
                try nodes.append(node);
            } else {
                std.debug.print("No node generated, skipping...\n", .{});
                break;
            };

        std.debug.print("AST generation complete, generated {} nodes.\n", .{nodes.items.len});

        return nodes;
    }

    fn declaration(self: *Ast) ?*Node {
        std.debug.print("\nparsing declaration...\n", .{});

        if (self.check(&.{ TokenTag.let_t, TokenTag.typedef_t })) |t| {
            return switch (t) {
                TokenTag.let_t => self.let_decl(),
                TokenTag.typedef_t => self.typedef_decl(),
                else => @panic("not supposed to reach here."),
            };
        }

        std.debug.print("lexeme is: {s}\n", .{self.get_token_lexeme(self.peek().?)});

        std.debug.print("not a declaration, parsing statement...\n", .{});
        return self.statement();
    }

    fn statement(self: *Ast) ?*Node {
        if (self.check(&.{ TokenTag.for_t, TokenTag.while_t, TokenTag.fun_t, TokenTag.left_brace, TokenTag.if_t })) |t|
            return switch (t) {
                TokenTag.for_t => self.stmt_for(),
                TokenTag.while_t => self.stmt_while(),
                TokenTag.fun_t => self.stmt_fun(),
                TokenTag.if_t => self.stmt_if(),
                TokenTag.left_brace => self.block(),
                else => @panic("not supposed to reach here"),
            }
        else
            return null;

        return self.expr_stmt();
    }

    fn let_decl(self: *Ast) ?*Node {
        std.debug.print("parsing let declaration...\n", .{});

        _ = self.consume(TokenTag.let_t, "failed to consume let token");
        const name = self.consume(TokenTag.identifier, "failed to consume identifier after let");
        var type_ann: ?*Node = null;
        if (self.peek()) |tk| {
            if (tk.tag == TokenTag.colon) {
                _ = self.next(); // consume the colon
                const type_ident = self.consume(TokenTag.identifier, "failed to consume identifier after colon in let declaration");
                type_ann = Node.init(self.allocator, .{
                    .literal = .{
                        .value = .{ .string = self.get_token_lexeme(type_ident) },
                    },
                }) catch @panic("could not create node for type annotation in let declaration");
            }
        }
        var init: ?*Node = null;
        if (self.peek()) |tk| {
            if (tk.tag == TokenTag.equal) {
                _ = self.next(); // consume the equal token
                init = self.expression() orelse @panic("failed to parse expression after equal in let declaration");
            }
        }

        _ = self.consume(TokenTag.semicolon, "failed to consume semicolon after let declaration");

        return Node.init(self.allocator, .{
            .let_decl = .{
                .name = name,
                .init = init,
                .type_ann = type_ann,
            },
        }) catch @panic("could not create node for let declaration");
    }

    fn typedef_decl(self: *Ast) ?*Node {
        std.debug.print("parsing typedef declaration...\n", .{});

        _ = self.consume(TokenTag.typedef_t, "failed to consume typedef token");
        const name = self.consume(TokenTag.identifier, "failed to consume identifier after typedef");
        _ = self.consume(TokenTag.equal, "failed to consume equal token after typedef identifier");
        const ident = self.consume(TokenTag.identifier, "failed to consume identifier after equal token in typedef");
        _ = self.consume(TokenTag.semicolon, "failed to consume semicolon after typedef identifier");

        std.debug.print("typedef name: {s}\ntype: {s}\n", .{ self.get_token_lexeme(name), self.get_token_lexeme(ident) });

        return Node.init(self.allocator, .{
            .typedef_stmt = .{
                .name = name,
                .type_ann = ident,
            },
        }) catch @panic("could not create node for typedef declaration");
    }

    fn expression(_: *Ast) ?*Node {
        return null;
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
                        .value = .{ .int = std.fmt.parseInt(i64, self.get_token_lexeme(self.next().?), 2) catch @panic("could not parse int2") },
                    },
                }) catch @panic("could not create node for int2"),
                TokenTag.int8 => Node.init(self.allocator, .{
                    .literal = .{
                        .value = .{ .int = std.fmt.parseInt(i64, self.get_token_lexeme(self.next().?), 8) catch @panic("could not parse int8") },
                    },
                }) catch @panic("could not create node for int8"),
                TokenTag.int10 => Node.init(self.allocator, .{
                    .literal = .{
                        .value = .{ .int = std.fmt.parseInt(i64, self.get_token_lexeme(self.next().?), 10) catch @panic("could not parse int10") },
                    },
                }) catch @panic("could not create node for int10"),
                TokenTag.int16 => Node.init(self.allocator, .{
                    .literal = .{
                        .value = .{ .int = std.fmt.parseInt(i64, self.get_token_lexeme(self.next().?), 16) catch @panic("could not parse int16") },
                    },
                }) catch @panic("could not create node for int16"),
                TokenTag.string => Node.init(self.allocator, .{
                    .literal = .{
                        .value = .{ .string = self.get_token_lexeme(self.next().?) },
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

    fn get_token_lexeme(self: *Ast, tk: *Token) []const u8 {
        return self.src[tk.loc.start..tk.loc.end];
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
    typedef_stmt,
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
            string: []const u8,
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
        fn_args: ?ArrayList(?*Node),
        body: ?*Node,
    },
    fn_call: struct {
        name: ?*Node,
        call_args: ?ArrayList(?*Node),
    },
    return_expr: struct {
        expr: ?*Node,
    },
    typedef_stmt: struct {
        name: ?*Token,
        type_ann: ?*Token,
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
            .typedef_stmt => |_| NodeTag.typedef_stmt,
        };
    }

    pub fn get_kind(self: NodePayload) NodeKind {
        return switch (self) {
            .let_decl => |_| NodeKind.Stmt,
            .bin_op => |_| NodeKind.Expr,
            .unary_left => |_| NodeKind.Expr,
            .block => |_| NodeKind.ExprStmt,
            .literal => |_| NodeKind.Expr,
            .if_expr => |_| NodeKind.ExprStmt,
            .while_loop => |_| NodeKind.Stmt,
            .for_loop => |_| NodeKind.Stmt,
            .fn_decl => |_| NodeKind.Stmt,
            .fn_call => |_| NodeKind.Expr,
            .return_expr => |_| NodeKind.ExprStmt,
            .typedef_stmt => |_| NodeKind.Stmt,
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

    const NodeAnnotation = struct {
        const Tag = enum {
            type_annotation,
        };

        data: union(Tag) {
            type_annotation: struct {
                name: []const u8,
                id: []const u8,
            },
        },
    };

    pub fn init(allocator: Allocator, payload: NodePayload) !*Node {
        var node = try allocator.create(Node);

        node.allocator = allocator;
        node.payload = payload;

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

    try std.testing.expectEqual(NodeKind.ExprStmt, np.get_kind());
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
            .fn_args = null,
            .body = null,
        },
    };

    try std.testing.expectEqual(NodeKind.Stmt, np.get_kind());
}

test "test NodePayload.get_kind(fn_call)" {
    const np = NodePayload{
        .fn_call = .{
            .name = null,
            .call_args = null,
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

test "test Ast.expr_primary(int2)" {
    // const allocator = std.testing.allocator;
    const allocator = std.heap.page_allocator;

    const src = "let x: MyInt;";
    const ast = try Ast.generate(allocator, src);

    try std.testing.expectEqual(NodeTag.let_decl, ast.items[0].?.payload.get_tag());

    // try std.testing.expectEqual(1, pnodes.items.len);
}
