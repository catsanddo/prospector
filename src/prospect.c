#include <stdio.h>
#include <tinydir.h>
#include <raylib.h>

static Color bkgrnd_c = { 240, 210, 210, 255 };
static Color frgrnd_c = { 240, 100, 100, 255 };
static Color text_c = { 20, 20, 20, 255 };
static Color textf_c = { 210, 210, 210, 255 };

int main(int argc, char ** argv)
{
    InitWindow(800, 600, "Prospector");

    while (!WindowShouldClose()) {
        BeginDrawing();
            ClearBackground(bkgrnd_c);
            DrawRectangle(50, 100, 700, 100, frgrnd_c);
            DrawText("Prospector", 20, 20, 40, text_c);
            DrawText("Red Bar", 70, 140, 20, textf_c);
        EndDrawing();
    }

    CloseWindow();
    return 0;
}
