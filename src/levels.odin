package main

import "core:fmt"
import "core:os"
import en "engine"

// TODO: check paths
LEVEL_ONE_PATH   :: "assets/levels/one.level"
LEVEL_TWO_PATH   :: "assets/levels/two.level"
LEVEL_THREE_PATH :: "assets/levels/three.level"
LEVEL_FOUR_PATH  :: "assets/levels/four.level"

BRICK_COLOR_1 :: en.Color {220, 220, 200, 255}
BRICK_COLOR_2 :: en.Color {50, 100, 220, 255}
BRICK_COLOR_3 :: en.Color {0, 220, 100, 255}
BRICK_COLOR_4 :: en.Color {220, 220, 100, 255}
BRICK_COLOR_5 :: en.Color {220, 140, 0, 255}

Levels :: enum {
    One, Two, Three, Four,
}

select_level: Levels

Level :: struct {
    row, column  : int,
    brick_width  : f32,
    brick_height : f32,
    data         : []Entity,
}

// /level
load_level_data :: proc(path: string) -> []u8 {
    data, ok := os.read_entire_file(path, context.temp_allocator)

    fmt.assertf(ok, "ERROR: failed to load level: %v", path)
    return data
}

get_row_column_from_level :: proc(data: ^[]u8) -> (row, column: int) {
    for i in data {
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

init_level :: proc(data: ^[]u8, loc := #caller_location) -> Level {
    row, column := get_row_column_from_level(data)

    w, h := en.get_window_size_f32()
    width, height := get_brick_size(w, h, f32(row), f32(column))

    level := en.allocate_memory([]Entity, row * column)

    return Level {
        row          = row,
        column       = column,
        brick_width  = width,
        brick_height = height,
        data         = level[:],
    }
}

load_level :: proc(level_file: string, block_solid, block: ^en.Texture) -> Level {
    level_data := load_level_data(level_file)
    level      := init_level(&level_data)

    row, column, element: int
    for e in level_data {
        brick : Entity

        switch e {
        case ' ': continue

        case '\n':
            column = 0
            row += 1
            continue

        case '0':
            brick.destroyed = true

        case '1':
            brick.color    = BRICK_COLOR_1
            brick.sprite   = block_solid^
            brick.is_solid = true

        case '2':
            brick.color  = BRICK_COLOR_2
            brick.sprite = block^

        case '3':
            brick.color  = BRICK_COLOR_3
            brick.sprite = block^

        case '4':
            brick.color  = BRICK_COLOR_4
            brick.sprite = block^

        case '5':
            brick.color  = BRICK_COLOR_5
            brick.sprite = block^
        }

        brick.pos.x = f32(column) * level.brick_width
        brick.pos.y = f32(row)    * level.brick_height

        brick.size = {level.brick_width, level.brick_height}

        level.data[element] = brick

        column += 1
        element += 1
    }

    return level
}

load_levels :: proc(block_solid, block: ^en.Texture, loc := #caller_location) -> []Level {
    levels := en.allocate_memory([]Level, len(Levels))

    for i in Levels {
        switch i {
        case .One   : levels[i] = load_level(LEVEL_ONE_PATH,   block_solid, block)
        case .Two   : levels[i] = load_level(LEVEL_TWO_PATH,   block_solid, block)
        case .Three : levels[i] = load_level(LEVEL_THREE_PATH, block_solid, block)
        case .Four  : levels[i] = load_level(LEVEL_FOUR_PATH,  block_solid, block)
       }
    }

    free_all(context.temp_allocator)
    return levels[:]
}

update_level :: proc(level: ^Level, screen_width, screen_heigth: f32) {
    width, height := get_brick_size(screen_width, screen_heigth, f32(level.row), f32(level.column))

    column, row: int
    for &e in level.data {
        if row >= level.row {
            column += 1
            row = 0
        }

        e.pos.x = f32(row)    * width
        e.pos.y = f32(column) * height

        e.size  = {width, height}

        row += 1
    }
}

draw_level :: proc(level: ^Level) {
    for e in level.data {
        if e.destroyed do continue
        en.draw_sprite(e.sprite, e.pos, e.size, e.rotation, e.color)
    }
}

// /brick
get_brick_size :: proc(screen_width, screen_height, level_row, level_column: f32) -> (brick_width, brick_height: f32) {
    brick_width  = screen_width  / level_row
    brick_height = screen_height / (level_column * 2)
    return
}
