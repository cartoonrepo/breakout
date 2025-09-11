package main

import "core:fmt"
import "core:os"
import "base:runtime"
import en "engine"

// TODO: check paths
LEVEL_ONE_PATH   :: "assets/levels/one.level"
LEVEL_TWO_PATH   :: "assets/levels/two.level"
LEVEL_THREE_PATH :: "assets/levels/three.level"
LEVEL_FOUR_PATH  :: "assets/levels/four.level"

Select_Level :: enum {
    One, Two, Three, Four,
}

select_level: Select_Level

Levels :: struct {
    one, two, three, four: Level,
}

Level :: struct {
    len    : int,
    row    : int,
    column : int,

    brick_width  : f32,
    brick_height : f32,

    data : []Entity,
}

// /level
load_level_data :: proc(path: string, allocator: ^runtime.Allocator) -> []u8 {
    data, ok := os.read_entire_file(path, allocator^)

    fmt.assertf(ok, "ERROR: failed to load level: %v", path)
    return data
}

get_row_column_from_level :: proc(data: ^[]u8) -> (row, column: int) {
    for i, index in data {
        if i == ' '  do continue // skip spaces
        if i == '\n' do break    // as soon as we hit the new line we bail.
        row += 1
    }

    // total chars in levels divde by total chars in first row (including spaces)
    // row * col = level
    // col = level / row
    column = len(data) / (row * 2) // multiply by 2 to include spaces
    return
}

init_level :: proc(data: ^[]u8, allocator: ^runtime.Allocator) -> Level {
    row, column := get_row_column_from_level(data)

    w, h := en.get_window_size_f32()
    width, height := get_brick_size(w, h, f32(row), f32(column))

    level := make([]Entity, row * column, allocator^)

    assert(level != nil, "Failed to allocate memory to level.")

    return Level {
        len    = len(level),

        row    = row,
        column = column,

        brick_width  = width,
        brick_height = height,

        data   = level[:],
    }
}

load_level :: proc(data: ^[]u8, block_solid, block: en.Texture, allocator: ^runtime.Allocator) -> Level {
    level := init_level(data, allocator)

    line, index, element: int
    for i in data {
        push := true
        brick : Entity

        switch i {
        case ' ': continue

        case '\n':
            index = 0
            line += 1
            continue

        case '0':
            push = false

        case '1':
            brick.color    = BRICK_COLOR_1
            brick.sprite   = block_solid
            brick.is_solid = true

        case '2':
            brick.color  = BRICK_COLOR_2
            brick.sprite = block

        case '3':
            brick.color  = BRICK_COLOR_3
            brick.sprite = block

        case '4':
            brick.color  = BRICK_COLOR_4
            brick.sprite = block

        case '5':
            brick.color  = BRICK_COLOR_5
            brick.sprite = block
        }

        if push {
            brick.pos.x = f32(index) * level.brick_width
            brick.pos.y = f32(line)  * level.brick_height

            brick.size = {level.brick_width, level.brick_height}

            level.data[element] = brick
            element += 1
        }

        index += 1
    }

    level.len = element
    return level
}

load_levels :: proc(block_solid, block: en.Texture, allocator: ^runtime.Allocator) -> Levels {
    temp_alloc := context.temp_allocator

    level_one_data   := load_level_data(LEVEL_ONE_PATH,   &temp_alloc)
    level_two_data   := load_level_data(LEVEL_TWO_PATH,   &temp_alloc)
    level_three_data := load_level_data(LEVEL_THREE_PATH, &temp_alloc)
    level_four_data  := load_level_data(LEVEL_FOUR_PATH,  &temp_alloc)

    level_one   := load_level(&level_one_data,   block_solid, block, allocator)
    level_two   := load_level(&level_two_data,   block_solid, block, allocator)
    level_three := load_level(&level_three_data, block_solid, block, allocator)
    level_four  := load_level(&level_four_data,  block_solid, block, allocator)

    free_all(temp_alloc)

    return Levels {
        one   = level_one,
        two   = level_two,
        three = level_three,
        four  = level_four,
    }
}

draw_levels :: proc(select_level: Select_Level, levels: ^Levels) {
    switch select_level {
    case .One   : draw_level(&levels.one)
    case .Two   : draw_level(&levels.two)
    case .Three : draw_level(&levels.three)
    case .Four  : draw_level(&levels.four)
    }
}

draw_level :: proc(level: ^Level) {
    for e, index in level.data {
        if index >= level.len do break
        en.draw_sprite(e.sprite, e.pos, e.size, e.rotation, e.color)
    }
}

// /brick
get_brick_size :: proc(screen_width, screen_height, level_row, level_column: f32) -> (brick_width, brick_height: f32) {
    brick_width  = screen_width  / level_row
    brick_height = screen_height / (level_column * 2)
    return
}
