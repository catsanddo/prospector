package main

import "core:fmt"
import rl "vendor:raylib"

BKGRND_C : rl.Color : { 240, 210, 210, 255 }
FRGRND_C : rl.Color : { 240, 100, 100, 255 }
TEXT_C : rl.Color : { 20, 20, 20, 255 }
TEXTF_C : rl.Color : { 210, 210, 210, 255 }

main :: proc() {
    rl.InitWindow(800, 600, "Prospector")

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
            rl.ClearBackground(BKGRND_C)
            rl.DrawRectangle(50, 100, 700, 100, FRGRND_C)
            rl.DrawText("Prospector", 20, 20, 40, TEXT_C)
            rl.DrawText("Red Bar", 70, 140, 20, TEXTF_C)
        rl.EndDrawing()
    }

    rl.CloseWindow()
}
