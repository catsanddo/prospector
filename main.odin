package main

import "core:fmt"
import "core:os"
import "core:strings"
import path "core:path/filepath"
import rl "vendor:raylib"

BKGRND_C : rl.Color : { 240, 210, 210, 255 }
FRGRND_C : rl.Color : { 240, 100, 100, 255 }
DIR_FRGRND_C : rl.Color : { 100, 100, 240, 255 }
TEXT_C : rl.Color : { 20, 20, 20, 255 }
TEXTF_C : rl.Color : { 210, 210, 210, 255 }

MouseState :: enum {
    Up,
    Pressed,
    Down,
    Released,
}

UIContext :: struct {
    mouse_pos: [2]i32,
    mouse_state: [3]MouseState,
}

DirState :: struct {
    current_dir: string
    new_dir: string
    files: []os.File_Info
}

main :: proc() {
    state := DirState{}
    switch_dir(&state, os.get_current_directory())

    rl.InitWindow(800, 600, "Prospector")

    for !rl.WindowShouldClose() {
        if state.new_dir != "" {
            fmt.println("before:", state.current_dir)
            switch_dir(&state, state.new_dir)
            state.new_dir = ""
            fmt.println("after:", state.current_dir)
        }
        if rl.IsKeyPressed(.BACKSPACE) {
            fmt.println("before:", state.current_dir)
            new_path := path.dir(state.current_dir)
            switch_dir(&state, new_path)
            fmt.println("after:", state.current_dir)
        }

        ctx: UIContext
        ctx.mouse_pos[0] = rl.GetMouseX()
        ctx.mouse_pos[1] = rl.GetMouseY()
        ctx.mouse_state[0] = .Released if rl.IsMouseButtonReleased(.LEFT) else .Up
        ctx.mouse_state[0] = .Down if rl.IsMouseButtonDown(.LEFT) else ctx.mouse_state[0]

        // TODO: use camera to scroll
        rl.BeginDrawing()
            rl.ClearBackground(BKGRND_C)

            y := i32(100)
            for file in state.files {
                clicked := make_button(ctx, file, y)
                if clicked  && file.is_dir {
                    state.new_dir = strings.clone(file.fullpath)
                }
                y += 120
            }

            if state.files == nil {
                rl.DrawRectangle(50, 100, 700, 100, TEXT_C)
                text := fmt.ctprintf("Error reading `%v`!", state.current_dir)
                rl.DrawText(text, 70, 140, 20, TEXTF_C)
            }

            rl.DrawText("Prospector", 20, 20, 40, TEXT_C)
        rl.EndDrawing()

        free_all(context.temp_allocator)
    }

    rl.CloseWindow()
}

make_button :: proc(ctx: UIContext, file: os.File_Info, y: i32) -> bool {
    mouse := rl.Vector2{ cast(f32) ctx.mouse_pos[0], cast(f32) ctx.mouse_pos[1] }
    rect := rl.Rectangle{ 50, f32(y), 700, 100 }
    collide := rl.CheckCollisionPointRec(mouse, rect)

    color := DIR_FRGRND_C if file.is_dir else FRGRND_C
    if collide && ctx.mouse_state[0] == .Down {
        color.r -= 30
        color.g -= 30
        color.b -= 30
    } else if collide {
        color.r += 15
        color.g += 15
        color.b += 15
    }

    rl.DrawRectangle(50, y, 700, 100, color)
    file_name := strings.clone_to_cstring(file.name, context.temp_allocator)
    rl.DrawText(file_name, 70, y + 40, 20, TEXTF_C)

    if ctx.mouse_state[0] == .Released && collide {
        return true
    }
    return false
}

read_dir :: proc(path: string) -> (info: []os.File_Info) {
    dir_handle, err := os.open(path)

    if err != os.ERROR_NONE {
        return
    }
    defer os.close(dir_handle)

    info, err = os.read_dir(dir_handle, 0)

    if err != os.ERROR_NONE {
        return
    }

    return info
}

sort_files :: proc(files: []os.File_Info) {
    for {
        did_swap := false
        for i in 0..<(len(files)-1) {
            s: bool
            files[i], files[i+1], s = swap(files[i], files[i+1])
            did_swap = did_swap || s
        }
        if !did_swap {
            return
        }
    }
}

swap :: proc(lhs, rhs: os.File_Info) -> (new_lhs, new_rhs: os.File_Info, is_swap: bool) {
    if lhs.is_dir && !rhs.is_dir {
        return lhs, rhs, false
    } else if rhs.is_dir && !lhs.is_dir {
        return rhs, lhs, true
    }
    switch strings.compare(lhs.name, rhs.name) {
        case -1:
            return lhs, rhs, false
        case:
            return rhs, lhs, true
    }
}

switch_dir :: proc(state: ^DirState, path: string) {
    if state.current_dir != "" {
        delete(state.current_dir)
    }
    if state.files != nil {
        delete(state.files)
    }
    state.current_dir = path
    state.files = read_dir(state.current_dir)
    sort_files(state.files)
}
