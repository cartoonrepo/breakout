package engine

import "core:fmt"
import "core:mem"
import "core:os"
import "base:runtime"

ARENA_CAPACITY :: 1 * mem.Megabyte

@(private)
arena: mem.Arena

// /arena
arena_allocate :: proc(loc := #caller_location) {
    arena_mem, error := make([]byte, ARENA_CAPACITY)

    if error != .None {
        fmt.eprintfln("%v: ERROR: Failed to allocate memory", loc)
        delete(arena_mem)
        os.exit(1)
    }

    mem.arena_init(&arena, arena_mem)
}

allocate_memory :: proc($T: typeid/[]$E, #any_int len: int, loc := #caller_location) -> T {
    allocator := get_allocator()

    memory, error := make(T, len, allocator)

    if error != .None {
        fmt.eprintfln("%v: ERROR: Failed to allocate memory", loc)
        fmt.eprintfln("Arena Capacity : %v", ARENA_CAPACITY)
        fmt.eprintfln("Memory asked   : %v", size_of(E) * len)
        destroy_arena()
        os.exit(1)
    }

    return memory
}

get_allocator :: #force_inline proc() -> runtime.Allocator {
    return mem.arena_allocator(&arena)
}

destroy_arena :: proc() {
    delete(arena.data)
}
