package main

import "core:testing"

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
