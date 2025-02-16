const std = @import("std");

const Token = struct {
    tag: Tag,
    loc: Loc,

    const Loc = struct {
        start: usize,
        end: usize,
    };

    const Tag = enum {
        left_param,
        right_param,
        left_brace,
        right_brace,
        left_bracket,
        right_bracket,
        comma,
        colon,
        semicolon,
        dot,
        star,
        minus,
        plus,
        slash,
        inc,
        dec,
        bang,
        bang_equal,
        equal_equal,
        lesser,
        lesser_equal,
        greater,
        greater_equal,
        plus_equal,
        minus_equals,
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
        shift_left,
        shift_right,
        left_arrow,
        right_arrow,

        if_t,
        else_t,
        for_t,
        while_t,
        let_t,
        return_t,
        fun,
        true_t,
        false_t,
        nil_t,
        switch_t,
        goto_t,

        identifier,
        string,

        int16,
        int10,
        int8,
        int2,

        type_ann,

        type_def,
    };
};

const Tokenizer = struct {
    buffer: [:0]const u8,
    current: usize,
    last: usize,

    const TokenizerError = error{
        eof,
    };

    pub fn init(buffer: [:0]const u8) Tokenizer {
        return .{
            .buffer = buffer,
            .current = 0,
            .last = 0,
        };
    }

    const State = enum {
        start,
        string,
    };

    pub fn next(self: *Tokenizer) Tokenizer!Token {
        var tk = Token{
            .tag = undefined,
            .loc = .{
                .start = 0,
                .end = 0,
            },
        };

        state: switch (State.start) {
            .start => {
                switch (self.peek()) {
                    '"' => {
                        self.advance();
                        continue :state .string;
                    },
                    0 => continue :state .end,
                    else => @panic("unimplemented"),
                }
            },
            .string => {
                if (self.advance() == '"') {
                    tk.tag = .string;
                    continue :state .end;
                } else continue :state .string;
            },
            .end => {
                tk.loc = .{
                    .start = self.last,
                    .end = self.current,
                };

                self.last = self.current;
            },
        }

        return tk;
    }

    fn is_eof(self: *Tokenizer) bool {
        return self.current >= self.buffer.len;
    }

    fn peek(self: *Tokenizer) TokenizerError!u8 {
        if (self.is_eof()) {
            return TokenizerError.eof;
        }

        return self.buffer[self.current];
    }

    fn advance(self: *Tokenizer) TokenizerError!u8 {
        if (self.is_eof()) {
            return TokenizerError.eof;
        }
        defer self.current += 1;

        return self.buffer[self.current];
    }
};

test "test string state" {
    const src = "\"aaaaaa\"";

    var tkz = Tokenizer.init(src);

    const tk = try tkz.next();

    std.debug.print("{any}", tk);
}
