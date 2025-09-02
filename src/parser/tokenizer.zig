const std = @import("std");
const ascii = std.ascii;
const StaticStringMap = std.StaticStringMap;
const debug = std.debug;

pub const Token = struct {
    tag: Tag,
    loc: Loc,

    pub const Loc = struct {
        start: usize,
        end: usize,
    };

    pub const Tag = enum {
        eof,

        left_paren,
        right_paren,
        left_brace,
        right_brace,
        left_bracket,
        right_bracket,

        comma,
        colon,
        semicolon,
        dot,
        question_mark,
        star,
        minus,
        plus,
        slash,

        inc,
        dec,

        equal,
        bang,
        bang_equal,
        equal_equal,
        lesser,
        lesser_equal,
        greater,
        greater_equal,
        plus_equal,
        minus_equal,
        star_equal,
        slash_equal,
        pipe_equal,
        pipe,
        pipe_pipe,
        ampersand,
        ampersand_ampersand,
        xor,
        xor_equal,
        rem,
        backslash,

        shift_left,
        shift_right,
        left_arrow,
        right_arrow,
        fun_arrow,

        if_t,
        else_t,
        for_t,
        while_t,
        let_t,
        return_t,
        fun_t,
        bool_t,
        nil_t,
        switch_t,
        goto_t,
        break_t,
        continue_t,
        typeann_t,
        typedef_t,
        void_t,
        defun_t,
        case_t,
        lambda_t,
        set_t,
        setq_t,
        setf_t,
        loop_t,

        identifier,
        string,

        float,
        int16,
        int10,
        int8,
        int2,
    };

    pub const keywords = StaticStringMap(Tag).initComptime(.{
        .{ "if", .if_t },
        .{ "else", .else_t },
        .{ "while", .while_t },
        .{ "for", .for_t },
        .{ "let", .let_t },
        .{ "fun", .fun_t },
        .{ "fn", .fun_t },
        .{ "void", .void_t },
        .{ "return", .return_t },
        .{ "switch", .switch_t },
        .{ "goto", .goto_t },
        .{ "nil", .nil_t },
        .{ "true", .bool_t },
        .{ "false", .bool_t },
        .{ "definetype", .typedef_t },
        .{ "break", .break_t },
        .{ "continue", .continue_t },
        .{ "defun", .defun_t },
        .{ "case", .case_t },
        .{ "lambda", .lambda_t },
        .{ "set", .set_t },
        .{ "setq", .setq_t },
        .{ "setf", .setf_t },
        .{ "loop", .loop_t },
    });
};

pub const Tokenizer = struct {
    buffer: [:0]const u8,
    current: usize,
    last: usize,
    eof: bool,

    pub fn init(buffer: [:0]const u8) Tokenizer {
        return .{
            .buffer = buffer,
            .current = 0,
            .last = 0,
            .eof = false,
        };
    }

    const State = enum {
        start,
        string,
        end,
        integer,
        decimal,
        hex,
        bin,
        skip_whitespace,
        logical,
        enclosure,
        punct,
        identifier,
    };

    pub fn next(self: *Tokenizer) ?Token {
        var tk = Token{
            .tag = undefined,
            .loc = .{
                .start = undefined,
                .end = undefined,
            },
        };

        if (self.eof)
            return null;

        state: switch (State.start) {
            .start => {
                switch (self.peek()) {
                    ' ', '\t' => continue :state .skip_whitespace,
                    '\n' => {
                        _ = self.advance();
                        continue :state .start;
                    },
                    '"' => {
                        tk.tag = .string;
                        _ = self.advance();
                        continue :state .string;
                    },
                    '1'...'9' => {
                        tk.tag = .int10;
                        continue :state .integer;
                    },
                    '0' => {
                        _ = self.advance();
                        if (self.peek() == 'x') {
                            tk.tag = .int16;
                            _ = self.advance();
                            continue :state .hex;
                        }
                        if (self.peek() == 'b') {
                            tk.tag = .int2;
                            _ = self.advance();
                            continue :state .bin;
                        }
                        tk.tag = .int10;
                    },
                    '!', '+', '-', '*', '/', '\\', '^', '=', '|', '>', '<' => continue :state .logical,
                    '(', ')', '[', ']', '{', '}' => continue :state .enclosure,
                    ',', '.', ';', ':', '?' => continue :state .punct,
                    0 => {
                        tk.tag = .eof;
                        self.last = self.current;
                        continue :state .end;
                    },
                    else => {
                        if (ascii.isAlphabetic(self.peek())) {
                            tk.tag = .identifier;
                            continue :state .identifier;
                        }
                    },
                }
            },
            .string => if (self.peek() != 0 and self.advance() == '"')
                continue :state .end
            else
                continue :state .string,
            .integer => if (ascii.isDigit(self.peek())) {
                _ = self.advance();
                continue :state .integer;
            } else if (self.peek() == '.')
                continue :state .decimal
            else
                continue :state .end,
            .decimal => {
                tk.tag = .float;
                _ = self.advance();
                while (ascii.isDigit(self.peek()))
                    _ = self.advance();

                continue :state .end;
            },
            .logical => {
                switch (self.peek()) {
                    '!' => {
                        _ = self.advance();
                        switch (self.peek()) {
                            '=' => {
                                _ = self.advance();
                                tk.tag = .bang_equal;
                            },
                            else => tk.tag = .bang,
                        }
                    },
                    '=' => {
                        _ = self.advance();
                        switch (self.peek()) {
                            '=' => {
                                _ = self.advance();
                                tk.tag = .equal_equal;
                            },
                            '>' => {
                                _ = self.advance();
                                tk.tag = .fun_arrow;
                            },
                            else => tk.tag = .equal,
                        }
                    },
                    '>' => {
                        _ = self.advance();
                        switch (self.peek()) {
                            '=' => {
                                _ = self.advance();
                                tk.tag = .greater_equal;
                            },
                            '>' => {
                                _ = self.advance();
                                tk.tag = .shift_right;
                            },
                            else => tk.tag = .greater,
                        }
                    },
                    '<' => {
                        _ = self.advance();
                        switch (self.peek()) {
                            '=' => {
                                _ = self.advance();
                                tk.tag = .lesser_equal;
                            },
                            '<' => {
                                _ = self.advance();
                                tk.tag = .shift_left;
                            },
                            '-' => {
                                _ = self.advance();
                                tk.tag = .left_arrow;
                            },
                            else => tk.tag = .lesser,
                        }
                    },
                    '^' => {
                        _ = self.advance();
                        switch (self.peek()) {
                            '=' => {
                                _ = self.advance();
                                tk.tag = .xor_equal;
                            },
                            else => tk.tag = .xor,
                        }
                    },
                    '+' => {
                        _ = self.advance();
                        switch (self.peek()) {
                            '=' => {
                                _ = self.advance();
                                tk.tag = .plus_equal;
                            },
                            '+' => {
                                _ = self.advance();
                                tk.tag = .inc;
                            },
                            else => tk.tag = .plus,
                        }
                    },
                    '-' => {
                        _ = self.advance();
                        switch (self.peek()) {
                            '=' => {
                                _ = self.advance();
                                tk.tag = .minus_equal;
                            },
                            '>' => {
                                _ = self.advance();
                                tk.tag = .right_arrow;
                            },
                            '-' => {
                                _ = self.advance();
                                tk.tag = .dec;
                            },
                            else => tk.tag = .minus,
                        }
                    },
                    '*' => {
                        _ = self.advance();
                        switch (self.peek()) {
                            '=' => {
                                _ = self.advance();
                                tk.tag = .star_equal;
                            },
                            else => tk.tag = .star,
                        }
                    },
                    '/' => {
                        _ = self.advance();
                        switch (self.peek()) {
                            '=' => {
                                _ = self.advance();
                                tk.tag = .slash_equal;
                            },
                            '/' => {
                                _ = self.advance();
                                while (self.peek() != 0 and self.peek() != '\n')
                                    _ = self.advance();
                                continue :state .start;
                            },
                            else => tk.tag = .slash,
                        }
                    },
                    '\\' => {
                        _ = self.advance();
                        tk.tag = .backslash;
                    },
                    '|' => {
                        _ = self.advance();
                        switch (self.peek()) {
                            '=' => {
                                _ = self.advance();
                                tk.tag = .pipe_equal;
                            },
                            '|' => {
                                _ = self.advance();
                                tk.tag = .pipe_pipe;
                            },
                            else => tk.tag = .pipe,
                        }
                    },
                    '&' => {
                        _ = self.advance();
                        switch (self.peek()) {
                            '&' => {
                                _ = self.advance();
                                tk.tag = .ampersand_ampersand;
                            },
                            else => tk.tag = .ampersand,
                        }
                    },
                    else => @panic("should be unreacheable"),
                }
                continue :state .end;
            },
            .enclosure => {
                switch (self.peek()) {
                    '(' => tk.tag = .left_paren,
                    ')' => tk.tag = .right_paren,
                    '[' => tk.tag = .left_bracket,
                    ']' => tk.tag = .right_bracket,
                    '{' => tk.tag = .left_brace,
                    '}' => tk.tag = .right_brace,
                    else => @panic("should be unreachable"),
                }
                _ = self.advance();
                continue :state .end;
            },
            .identifier => {
                while (ascii.isAlphanumeric(self.peek()))
                    _ = self.advance();
                const lexeme = self.buffer[self.last..self.current];
                if (Token.keywords.get(lexeme)) |kw|
                    tk.tag = kw;
                continue :state .end;
            },
            .punct => {
                switch (self.peek()) {
                    ',' => tk.tag = .comma,
                    '.' => tk.tag = .dot,
                    ';' => tk.tag = .semicolon,
                    ':' => tk.tag = .colon,
                    '?' => tk.tag = .question_mark,
                    else => @panic("should be unreachable"),
                }
                _ = self.advance();
                continue :state .end;
            },
            .hex => {
                while (ascii.isDigit(self.peek()) or (self.peek() >= 'a' and self.peek() <= 'f') or (self.peek() >= 'A' and self.peek() <= 'F'))
                    _ = self.advance();
                continue :state .end;
            },
            .bin => {
                while (self.peek() == '0' or self.peek() == '1')
                    _ = self.advance();
                continue :state .end;
            },
            .skip_whitespace => {
                while (self.peek() == ' ' or self.peek() == '\t')
                    _ = self.advance();
                self.last = self.current;
                continue :state .start;
            },
            .end => {},
        }

        tk.loc.start = self.last;
        tk.loc.end = self.current;
        self.last = self.current;

        if (tk.tag == .eof)
            self.eof = true;

        return tk;
    }

    fn is_eof(self: *Tokenizer) bool {
        return self.current >= self.buffer.len;
    }

    fn peek(self: *Tokenizer) u8 {
        return if (self.is_eof()) 0 else self.buffer[self.current];
    }

    fn advance(self: *Tokenizer) u8 {
        if (self.is_eof())
            return 0;
        defer self.current += 1;

        return self.buffer[self.current];
    }

    fn skip(self: *Tokenizer, n: usize) void {
        const s = self.current + n;
        if (s > self.buffer.len)
            self.current = self.buffer.len
        else
            self.current += n;
    }
};

test "test string state" {
    const testing = std.testing;

    const src = "\"aaaaaa\"";

    var tkz = Tokenizer.init(src);
    const tk = tkz.next().?;

    const expect = src;
    const got = src[tk.loc.start..tk.loc.end];

    try testing.expectEqual(Token.Tag.string, tk.tag);
    try testing.expectEqualStrings(expect, got);
}

test "test integer" {
    const testing = std.testing;

    const src = "98765";

    var tkz = Tokenizer.init(src);
    const tk = tkz.next().?;

    const expect = src;
    const got = src[tk.loc.start..tk.loc.end];

    try testing.expectEqual(Token.Tag.int10, tk.tag);
    try testing.expectEqualStrings(expect, got);
}

test "test decimal" {
    const testing = std.testing;

    const src = "123456.123412";

    var tkz = Tokenizer.init(src);
    const tk = tkz.next().?;

    const expect = src;
    const got = src[tk.loc.start..tk.loc.end];

    try testing.expectEqual(Token.Tag.float, tk.tag);
    try testing.expectEqualStrings(expect, got);
}

test "test hex" {
    const testing = std.testing;

    const src = "0xdeAdbAd";

    var tkz = Tokenizer.init(src);
    const tk = tkz.next().?;

    const expect = src;
    const got = src[tk.loc.start..tk.loc.end];

    try testing.expectEqual(Token.Tag.int16, tk.tag);
    try testing.expectEqualStrings(expect, got);
}

test "test bin" {
    const testing = std.testing;

    const src = "0b010011100110";

    var tkz = Tokenizer.init(src);
    const tk = tkz.next().?;
    const eof_tk = tkz.next().?;

    const expect = src;
    const got = src[tk.loc.start..tk.loc.end];

    try testing.expectEqual(Token.Tag.int2, tk.tag);
    try testing.expectEqualStrings(expect, got);
    try testing.expectEqual(Token.Tag.eof, eof_tk.tag);
}

test "test space between integers" {
    const testing = std.testing;

    const src = "0b010011100110    0xdeadbad";

    var tkz = Tokenizer.init(src);
    const tk1 = tkz.next().?;
    const tk2 = tkz.next().?;
    const tk3 = tkz.next().?;

    try testing.expectEqual(Token.Tag.int2, tk1.tag);
    try testing.expectEqual(Token.Tag.int16, tk2.tag);
    try testing.expectEqual(Token.Tag.eof, tk3.tag);
}

test "test logical" {
    const testing = std.testing;

    const src = "! * + - | / < > = == != >= <= *= /= |= -= += << >> ^= \\";

    var tkz = Tokenizer.init(src);
    const tk1 = tkz.next().?;
    const tk2 = tkz.next().?;
    const tk3 = tkz.next().?;
    const tk4 = tkz.next().?;
    const tk5 = tkz.next().?;
    const tk6 = tkz.next().?;
    const tk7 = tkz.next().?;
    const tk8 = tkz.next().?;
    const tk9 = tkz.next().?;
    const tk10 = tkz.next().?;
    const tk11 = tkz.next().?;
    const tk12 = tkz.next().?;
    const tk13 = tkz.next().?;
    const tk14 = tkz.next().?;
    const tk15 = tkz.next().?;
    const tk16 = tkz.next().?;
    const tk17 = tkz.next().?;
    const tk18 = tkz.next().?;
    const tk19 = tkz.next().?;
    const tk20 = tkz.next().?;
    const tk21 = tkz.next().?;
    const tk22 = tkz.next().?;
    const tk23 = tkz.next().?;

    try testing.expectEqual(Token.Tag.bang, tk1.tag);
    try testing.expectEqual(Token.Tag.star, tk2.tag);
    try testing.expectEqual(Token.Tag.plus, tk3.tag);
    try testing.expectEqual(Token.Tag.minus, tk4.tag);
    try testing.expectEqual(Token.Tag.pipe, tk5.tag);
    try testing.expectEqual(Token.Tag.slash, tk6.tag);
    try testing.expectEqual(Token.Tag.lesser, tk7.tag);
    try testing.expectEqual(Token.Tag.greater, tk8.tag);
    try testing.expectEqual(Token.Tag.equal, tk9.tag);
    try testing.expectEqual(Token.Tag.equal_equal, tk10.tag);
    try testing.expectEqual(Token.Tag.bang_equal, tk11.tag);
    try testing.expectEqual(Token.Tag.greater_equal, tk12.tag);
    try testing.expectEqual(Token.Tag.lesser_equal, tk13.tag);
    try testing.expectEqual(Token.Tag.star_equal, tk14.tag);
    try testing.expectEqual(Token.Tag.slash_equal, tk15.tag);
    try testing.expectEqual(Token.Tag.pipe_equal, tk16.tag);
    try testing.expectEqual(Token.Tag.minus_equal, tk17.tag);
    try testing.expectEqual(Token.Tag.plus_equal, tk18.tag);
    try testing.expectEqual(Token.Tag.shift_left, tk19.tag);
    try testing.expectEqual(Token.Tag.shift_right, tk20.tag);
    try testing.expectEqual(Token.Tag.xor_equal, tk21.tag);
    try testing.expectEqual(Token.Tag.backslash, tk22.tag);
    try testing.expectEqual(Token.Tag.eof, tk23.tag);
}

test "test enclosure" {
    const testing = std.testing;

    const src = "( ) [ ] { }";

    var tkz = Tokenizer.init(src);
    const lparen = tkz.next().?;
    const rparen = tkz.next().?;

    try testing.expectEqual(Token.Tag.left_paren, lparen.tag);
    try testing.expectEqual(Token.Tag.right_paren, rparen.tag);

    const lbracket = tkz.next().?;
    const rbracket = tkz.next().?;

    try testing.expectEqual(Token.Tag.left_bracket, lbracket.tag);
    try testing.expectEqual(Token.Tag.right_bracket, rbracket.tag);

    const lbrace = tkz.next().?;
    const rbrace = tkz.next().?;

    try testing.expectEqual(Token.Tag.left_brace, lbrace.tag);
    try testing.expectEqual(Token.Tag.right_brace, rbrace.tag);

    const eof = tkz.next().?;

    try testing.expectEqual(Token.Tag.eof, eof.tag);
}

test "test punct" {
    const testing = std.testing;

    const src = ", . \t ;  : ?";

    var tkz = Tokenizer.init(src);
    const comma = tkz.next().?;
    const dot = tkz.next().?;
    const semi = tkz.next().?;
    const colon = tkz.next().?;
    const question = tkz.next().?;
    const eof = tkz.next().?;

    try testing.expectEqual(Token.Tag.comma, comma.tag);
    try testing.expectEqual(Token.Tag.dot, dot.tag);
    try testing.expectEqual(Token.Tag.semicolon, semi.tag);
    try testing.expectEqual(Token.Tag.colon, colon.tag);
    try testing.expectEqual(Token.Tag.question_mark, question.tag);
    try testing.expectEqual(Token.Tag.eof, eof.tag);
}

test "test reject comments" {
    const testing = std.testing;

    const src = "// HELLO \n // HIII";

    var tkz = Tokenizer.init(src);
    const tk = tkz.next().?;

    try testing.expectEqual(Token.Tag.eof, tk.tag);
}

test "test keywords" {
    const testing = std.testing;

    const src = "for if while f0r defun case set setq setf loop";

    var tkz = Tokenizer.init(src);
    const tk_for = tkz.next().?;
    const tk_if = tkz.next().?;
    const tk_while = tkz.next().?;
    const tk_f0r = tkz.next().?;
    const tk_defun = tkz.next().?;
    const tk_case = tkz.next().?;
    const tk_set = tkz.next().?;
    const tk_setq = tkz.next().?;
    const tk_setf = tkz.next().?;
    const tk_loop = tkz.next().?;
    const eof = tkz.next().?;

    try testing.expectEqual(Token.Tag.for_t, tk_for.tag);
    try testing.expectEqual(Token.Tag.if_t, tk_if.tag);
    try testing.expectEqual(Token.Tag.while_t, tk_while.tag);
    try testing.expectEqual(Token.Tag.identifier, tk_f0r.tag);
    try testing.expectEqual(Token.Tag.defun_t, tk_defun.tag);
    try testing.expectEqual(Token.Tag.case_t, tk_case.tag);
    try testing.expectEqual(Token.Tag.set_t, tk_set.tag);
    try testing.expectEqual(Token.Tag.setq_t, tk_setq.tag);
    try testing.expectEqual(Token.Tag.setf_t, tk_setf.tag);
    try testing.expectEqual(Token.Tag.loop_t, tk_loop.tag);
    try testing.expectEqual(Token.Tag.eof, eof.tag);
}

test "test arrows" {
    const testing = std.testing;

    const src = "<- ->";

    var tkz = Tokenizer.init(src);
    const larrow = tkz.next().?;
    const rarrow = tkz.next().?;
    const eof = tkz.next().?;

    try testing.expectEqual(Token.Tag.left_arrow, larrow.tag);
    try testing.expectEqual(Token.Tag.right_arrow, rarrow.tag);
    try testing.expectEqual(Token.Tag.eof, eof.tag);
}

test "visual test" {
    const src =
        \\ fn main() : void {
        \\   let variable: int = (4 * 2) + 5;
        \\   variable = 4;
        \\   variable = 5 * 2 * ( 5 + 3 );
        \\   let test = 5;
        \\   if ((x > 5) || (x < 2)) {
        \\     let y = (5 + 1) - 2;
        \\   } else {
        \\     let h = Nil;
        \\   }
        \\   while (7 < x) {
        \\     --x;
        \\     x++;
        \\   }
        \\   for (let x = 10; x < 10; ++x) {
        \\     let str = "hello";
        \\     let a = "test";
        \\   }
        \\   // comment
        \\   /* comment */
        \\ }
        \\ fn test(a: int, b: uint, c: char) : uint {
        \\   print("a b c", -1, --1, x + 5);
        \\   return b;
        \\ }
        \\ fun TEST2() : int {
        \\   if(true) {
        \\     0
        \\   } else {
        \\     1
        \\   }
        \\   101
        \\ }
        \\ // fn TEST03() : int {
        \\ //   return if (false) { 10 } else { 20 };
        \\ // }
        \\ definetype SomeType = int;
    ;

    var tkz = Tokenizer.init(src);

    while (tkz.next()) |tk|
        _ = tk;
}
