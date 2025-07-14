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
        if (self.check(&.{ TokenTag.int2, TokenTag.int8, TokenTag.int10, TokenTag.int16, TokenTag.string, TokenTag.bool_t, TokenTag.nil_t })) |tk| {
            switch (tk) {
                TokenTag.int2, TokenTag.int8, TokenTag.int10, TokenTag.int16 => @panic("not implemented"),
                TokenTag.string => return Node{
                    .kind = .Expr,
                    .payload = .{
                        .literal = .{
                            .value = .{ .string = "test aa" },
                        },
                    },
                },
                else => @panic("not implemented"),
            }
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
};

const NodeKind = enum {
    Expr,
    Stmt,
    ExprStmt,
};

pub const Node = struct {
    allocator: Allocator,

    kind: NodeKind,
    payload: NodePayload,

    pub fn init(allocator: Allocator, tag: NodeTag, init_expr: anytype) !*Node {
        var node = try allocator.create(Node);
        node.allocator = allocator;

        switch (tag) {
            .let_decl => {
                node.kind = .Stmt;
                node.payload = .{
                    .let_decl = .{
                        .name = @field(init_expr, "name"),
                    },
                };
            },
            else => {
                std.debug.print("init for node ({s}) not implemented yet\n", .{@tagName(tag)});
                @panic("init switch NodeTag fail");
            },
        }

        return node;
    }

    pub fn deinit(self: *Node) void {
        switch (self.payload) {
            else => self.allocator.destroy(self),
        }
    }
};

test "test parser" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var tk = try allocator.create(Token);

    tk.tag = .string;
    tk.loc = .{
        .end = 0,
        .start = 0,
    };

    defer allocator.destroy(tk);

    const iexpr = .{
        .name = @constCast(tk),
    };

    var c = try Node.init(allocator, .let_decl, iexpr);
    defer c.deinit();

    // var string = std.ArrayList(u8).init(allocator);
    // try std.json.stringify(c, .{}, string.writer());

    // std.debug.print("{any}\n", .{string});

    // const src =
    //     \\ fn main() : void {
    //     \\   let variable: int = (4 * 2) + 5;
    //     \\   variable = 4;
    //     \\   variable = 5 * 2 * ( 5 + 3 );
    //     \\   let test = 5;
    //     \\   if ((x > 5) || (x < 2)) {
    //     \\     let y = (5 + 1) - 2;
    //     \\   } else {
    //     \\     let h = Nil;
    //     \\   }
    //     \\   while (7 < x) {
    //     \\     --x;
    //     \\     x++;
    //     \\   }
    //     \\   for (let x = 10; x < 10; ++x) {
    //     \\     let str = "hello";
    //     \\     let a = "test";
    //     \\   }
    //     \\   // comment
    //     \\   /* comment */
    //     \\ }
    //     \\ fn test(a: int, b: uint, c: char) : uint {
    //     \\   print("a b c", -1, --1, x + 5);
    //     \\   return b;
    //     \\ }
    //     \\ fun TEST2() : int {
    //     \\   if(true) {
    //     \\     0
    //     \\   } else {
    //     \\     1
    //     \\   }
    //     \\   101
    //     \\ }
    //     \\ // fn TEST03() : int {
    //     \\ //   return if (false) { 10 } else { 20 };
    //     \\ // }
    // ;

    // const src = "let abc: int;";

    // _ = Ast.generate(allocator, src);
}
