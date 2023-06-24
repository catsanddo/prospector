package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:mem"
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
    current_dir: string,
    new_dir: string,
    files: []FileInfo,
}

FileInfo :: struct {
    name: string,
    fullpath: string,
    is_dir: bool,
    size: i64,
}

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    defer mem.tracking_allocator_destroy(&track)
    context.allocator = mem.tracking_allocator(&track)
    
    _main()
    
    for _, leak in track.allocation_map {
    	fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
    }
    for bad_free in track.bad_free_array {
    	fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
    }
}

_main :: proc() {
    state := DirState{}
    switch_dir(&state, os.get_current_directory())

    rl.InitWindow(800, 600, "Prospector")

    y_offset := i32(0)

    // NOTE: this reduces CPU usage by a LOT
    // But I don't know if it's the best long term
    rl.EnableEventWaiting()

    for !rl.WindowShouldClose() {
        if state.new_dir != "" {
            fmt.println("before:", state.current_dir)
            switch_dir(&state, state.new_dir)
            state.new_dir = ""
            y_offset = 0
            fmt.println("after:", state.current_dir)
        }
        if rl.IsKeyPressed(.BACKSPACE) {
            fmt.println("before:", state.current_dir)
            new_path := path.dir(state.current_dir)
            switch_dir(&state, new_path)
            y_offset = 0
            fmt.println("after:", state.current_dir)
        }

        scroll := rl.GetMouseWheelMove()
        y_offset += i32(30 * scroll)

        max_offset := cast(i32) (len(state.files)) * 70
        y_offset = clamp(y_offset, -max_offset, 0)

        ctx: UIContext
        ctx.mouse_pos[0] = rl.GetMouseX()
        ctx.mouse_pos[1] = rl.GetMouseY()
        ctx.mouse_state[0] = .Released if rl.IsMouseButtonReleased(.LEFT) else .Up
        ctx.mouse_state[0] = .Down if rl.IsMouseButtonDown(.LEFT) else ctx.mouse_state[0]

        rl.BeginDrawing()
            rl.ClearBackground(BKGRND_C)

            parent := FileInfo{
                is_dir = true,
                name = "..",
            }
            if make_button(ctx, parent, 100+y_offset) {
                new_path := path.dir(state.current_dir)
                state.new_dir = new_path
            }
            y := i32(170)
            for file in state.files {
                clicked := make_button(ctx, file, y+y_offset)
                if clicked  && file.is_dir {
                    state.new_dir = strings.clone(file.fullpath)
                }
                y += 70
            }

            if state.files == nil {
                rl.DrawRectangle(50, 100, 700, 100, TEXT_C)
                text := fmt.ctprintf("Error reading `%v`!", state.current_dir)
                rl.DrawText(text, 70, 140, 20, TEXTF_C)
            }

            rl.DrawRectangle(0, 0, 800, 80, BKGRND_C)
            rl.DrawText("Prospector", 20, 20, 40, TEXT_C)
        rl.EndDrawing()

        free_all(context.temp_allocator)
    }

    rl.CloseWindow()

    // Cleanup
    delete(state.current_dir)
    free_files(state.files)
}

make_button :: proc(ctx: UIContext, file: FileInfo, y: i32) -> bool {
    mouse := rl.Vector2{ cast(f32) ctx.mouse_pos[0], cast(f32) ctx.mouse_pos[1] }
    rect := rl.Rectangle{ 50, f32(y), 700, 50 }
    window_rect := rl.Rectangle{ 0, 0, 800, 600 }

    if !rl.CheckCollisionRecs(rect, window_rect) {
        return false
    }

    collide := rl.CheckCollisionPointRec(mouse, rect)

    color := DIR_FRGRND_C if file.is_dir else FRGRND_C
    if collide && ctx.mouse_state[0] == .Down {
        color.r -= 30
        color.g -= 30
        color.b -= 30
    }

    rl.DrawRectangleRec(rect, color)
    file_name := strings.clone_to_cstring(file.name, context.temp_allocator)
    rl.DrawText(file_name, 70, y + 15, 20, TEXTF_C)
    if collide {
        rl.DrawRectangleLinesEx(rect, 5, rl.DARKGRAY)
    }

    if ctx.mouse_state[0] == .Released && collide {
        return true
    }
    return false
}

read_dir :: proc(path: string) -> (info: []FileInfo) {
    dir_handle, err := os.open(path)

    if err != os.ERROR_NONE {
        return
    }
    defer os.close(dir_handle)

    files: []os.File_Info
    files, err = os.read_dir(dir_handle, 0)

    if err != os.ERROR_NONE {
        return
    }

    info = make([]FileInfo, len(files))
    for i in 0..<(len(files)) {
        info[i].is_dir = files[i].is_dir
        info[i].size = files[i].size
        if files[i].is_dir {
          info[i].fullpath = files[i].fullpath
          info[i].name = files[i].name
        } else {
            delete(files[i].fullpath)
            info[i].fullpath = strings.clone("[REDACTED]")
            info[i].name = info[i].fullpath
        }
    }
    delete(files)

    return info
}

sort_files :: proc(files: []FileInfo) {
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

swap :: proc(lhs, rhs: FileInfo) -> (new_lhs, new_rhs: FileInfo, is_swap: bool) {
    if lhs.is_dir && !rhs.is_dir {
        return lhs, rhs, false
    } else if rhs.is_dir && !lhs.is_dir {
        return rhs, lhs, true
    }
    switch strings.compare(lhs.name, rhs.name) {
        case 1:
            return rhs, lhs, true
        case:
            return lhs, rhs, false
    }
}

free_files :: proc(files: []FileInfo) {
    for file in files {
        delete(file.fullpath)
    }
    delete(files)
}

switch_dir :: proc(state: ^DirState, path: string) {
    if state.current_dir != "" {
        delete(state.current_dir)
    }
    if state.files != nil {
        free_files(state.files)
    }
    state.current_dir = path
    state.files = read_dir(state.current_dir)
    sort_files(state.files)
}
