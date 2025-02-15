const std = @import("std");

const Token = struct {
    tag: Tag,
    loc: Loc,

    const Loc = struct {
        line: usize,
        column: usize,
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

    pub fn init(buffer: [:0]const u8) Tokenizer {}
};
