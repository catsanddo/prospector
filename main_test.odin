package main

import "core:testing"
import "core:encoding/json"
import "core:os"
import "core:strings"

@(test)
sort_test :: proc(t: ^testing.T) {
    state := DirState{}
    switch_dir(&state, ".git")
    
    past_dirs := false
    for file in state.files {
        if !past_dirs && !file.is_dir {
            past_dirs = true
        }

        if past_dirs && file.is_dir {
            testing.fail_now(t, file.fullpath)
        }
    }
}

@(test)
json_test :: proc(t: ^testing.T) {
    raw_data, ok := os.read_entire_file("set.json")
    testing.expect(t, ok)

    data, err := json.parse(raw_data)
    testing.expect(t, err == .None)
    testing.log(t, data)
}

@(test)
hex_to_color_test :: proc(t: ^testing.T) {
    testing.expect(t, hex_to_color("#ffffff") == 0xffffff)
    testing.expect(t, hex_to_color("akjsbx") == 0)
    testing.expect(t, hex_to_color("#111111") == 0x111111)
    testing.expect(t, hex_to_color("#abcdef") == 0xefcdab)
}

hex_to_color :: proc(hex: string) -> u32le {
    result: [4]u8
    hex := strings.to_lower(hex, context.temp_allocator)
    if hex[0] != '#' do return 0

    if '0' <= hex[1] && hex[1] <= '9' {
        result[0] = u8(u32(hex[1]) - u32('0')) << 4
    } else if 'a' <= hex[1] && hex[1] <= 'f' {
        result[0] = u8(u32(hex[1]) - u32('a') + 10) << 4
    }
    if '0' <= hex[2] && hex[2] <= '9' {
        result[0] += u8(u32(hex[2]) - u32('0'))
    } else if 'a' <= hex[2] && hex[2] <= 'f' {
        result[0] += u8(u32(hex[2]) - u32('a') + 10)
    }

    if '0' <= hex[3] && hex[3] <= '9' {
        result[1] = u8(u32(hex[3]) - u32('0')) << 4
    } else if 'a' <= hex[3] && hex[3] <= 'f' {
        result[1] = u8(u32(hex[3]) - u32('a') + 10) << 4
    }
    if '0' <= hex[4] && hex[4] <= '9' {
        result[1] += u8(u32(hex[4]) - u32('0'))
    } else if 'a' <= hex[4] && hex[4] <= 'f' {
        result[1] += u8(u32(hex[4]) - u32('a') + 10)
    }

    if '0' <= hex[5] && hex[5] <= '9' {
        result[2] = u8(u32(hex[5]) - u32('0')) << 4
    } else if 'a' <= hex[5] && hex[5] <= 'f' {
        result[2] = u8(u32(hex[5]) - u32('a') + 10) << 4
    }
    if '0' <= hex[6] && hex[6] <= '9' {
        result[2] += u8(u32(hex[6]) - u32('0'))
    } else if 'a' <= hex[6] && hex[6] <= 'f' {
        result[2] += u8(u32(hex[6]) - u32('a') + 10)
    }

    return transmute(u32le) result
}
