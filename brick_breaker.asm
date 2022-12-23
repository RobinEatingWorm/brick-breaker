### Configure the bitmap display to the settings below BEFORE running the game!
# Unit Width in Pixels:     8
# Unit Height in Pixels:    8
# Display Width in Pixels:  256
# Display Height in Pixels: 256
# Base address for display: 0x10008000 ($gp)

################################################
    .data
################################################

### Address Data
# The address of the bitmap display.
DISP_ADDR:
    .word 0x10008000
# The address of the keyboard.
KEYB_ADDR:
    .word 0xFFFF0000

### Ball Data
# The width and height of the ball.
BALL_WIDTH:
    .word 0x00000001
BALL_HEIGHT:
    .word 0x00000001
# The address of the ball.
BALL_ADDRESS:
    .space 4
# The direction of the ball.
BALL_DIRECTION:
    .space 8                    # the first 4 bytes are the x-direction and the second 4 bytes are the y-direction

### Border Data
# The thickness of the border.
BORDER_THICKNESS:
    .word 0x00000001

### Brick Data
# The width and height of bricks.
BRICK_WIDTH:
    .word 0x00000005
BRICK_HEIGHT:
    .word 0x00000003
# The number of bricks per row and column.
BRICK_NROW:
    .word 0x00000006
BRICK_NCOL:
    .word 0x00000003
# The addresses of each brick.
BRICK_ADDRESSES:
    .space 72                   # 18 bricks in total
# The number of remaining bricks.
BRICKS_REMAINING:
    .word 0x00000012            # 18 bricks in total
# A boolean reporting whether a red brick has been hit.
# If FAST_SWITCH == 1, the ball doublies its speed.
FAST_SWITCH:
    .word 0x00000000

### Colour Data
# Colours used.
COLOURS:
    .word 0xFFFFFF              # white (ball and paddle)
    .word 0xFF0000              # red (3-hit bricks bricks)
    .word 0x00FF00              # green (2-hit bricks bricks)
    .word 0x0000FF              # blue (1-hit bricks)
    .word 0x7F7F7F              # grey (border and unbreakable bricks)
    .word 0x000000              # black (eraser)

### Lives Data
# The number of lives the player has remaining.
LIVES:
    .word 0x00000003

### Paddle Data
# The width and height of the paddle.
PADDLE_WIDTH:
    .word 0x00000006
PADDLE_HEIGHT:
    .word 0x00000001
# The address of the leftmost unit of the paddle.
PADDLE_ADDRESS:
    .space 4
# A boolean to determine whether the ball has been launched from the paddle.
LAUNCHED:
    .word 0x00000000

################################################
    .text
################################################

    .globl main

# void main()
#   Runs the brick breaker game.
main:
# Initialize the game
# Draw the border
    la $a0, COLOURS                             # $a0 = address of colours
    lw $a0, 16($a0)                             # $a0 = grey
    lw $a1, BORDER_THICKNESS                    # $a1 = border thickness
    jal draw_border                             # draw the border
# Draw the bricks and store their addresses
    jal initialize_bricks                       # draw the initial positions of bricks
    jal store_brick_addresses                   # store the addresses of bricks
# Draw unbreakable bricks (addresses not stored)
    jal initialize_unbreakable_bricks           # draw the initial positions of unbreakable bricks
# Draw the paddle and store its address
    addi $a0, $0, 13                            # $a0 = 13
    addi $a1, $0, 30                            # $a1 = 30
    jal get_location_address                    # get the initial address of the paddle
    add $a0, $v0, $0                            # $a0 = initial address of paddle
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 0($a1)                              # $a1 = white
    jal draw_paddle                             # draw the paddle and store its address
# Draw the ball and store its address
    addi $a0, $0, 16                            # $a0 = 16
    addi $a1, $0, 29                            # $a1 = 29
    jal get_location_address                    # get the initial address of the ball
    add $a0, $v0, $0                            # $a0 = initial address of ball
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 0($a1)                              # $a1 = white
    jal draw_ball                               # draw the ball and store its address
# Load the address of the keyboard
    lw $s0, KEYB_ADDR                           # $s0 = base address of keyboard
# Run the game
game_run:
# Check if any key has been pressed
    lw $t0, 0($s0)                              # load first word from keyboard
    bne $t0, 1, collisions                      # if first word != 1, branch to collisions (no key was pressed)
# Check the specific key pressed
    lw $t0, 4($s0)                              # load second word from keyboard
    beq $t0, 0x61, respond_to_A                 # check if the key a was pressed
    beq $t0, 0x64, respond_to_D                 # check if the key d was pressed
    beq $t0, 0x6C, respond_to_L                 # check if the key l was pressed
    beq $t0, 0x70, respond_to_P                 # check if the key p was pressed
    beq $t0, 0x71, respond_to_Q                 # check if the key q was pressed
    b collisions                                # if no valid keys were pressed, branch to collisions
# Move the paddle left if the key a is pressed
respond_to_A:
    jal move_paddle_left                        # move the paddle left
    b collisions                                # branch to collisions
# Move the paddle right if the key d is pressed
respond_to_D:
    jal move_paddle_right                       # move the paddle right
    b collisions                                # branch to collisions
# Launch the ball if the key l is pressed
# Do nothing if the ball is already launched
respond_to_L:
    lw $t1, LAUNCHED                            # $t1 = whether ball has been launched
    beq $t1, 1, collisions                      # if $t1 = 1 (ball has been launched), branch to collisions
    jal launch_ball                             # launch the ball
    b collisions                                # branch to collisions
# Pause the game if the key p is pressed
respond_to_P:
    li $v0, 32                                  # sleep for 10 milliseconds
    li $a0, 10
    syscall
    lw $t0, 0($s0)                              # load first word from keyboard
    bne $t0, 1, respond_to_P                    # if first word != 1, branch to respond_to_P (no key was pressed)
    lw $t0, 4($s0)                              # load second word from keyboard
    beq $t0, 0x70, collisions                   # check if the key p was pressed again and branch to collisions if true
    beq $t0, 0x71, respond_to_Q                 # check if the key q was pressed
    b respond_to_P                              # branch to respond_to_P (keys p or q were not pressed)
# Quit the game if the key q is pressed
respond_to_Q:
    li $v0, 10                                  # quit the game
    syscall
# Check if the ball has collided with any objects
collisions:
    lw $t0, LAUNCHED                            # $t0 = whether ball has been launched
    bne $t0, 1, game_run                        # if ball has not been launched, branch to game_run
    jal side_collisions                         # handle side collisions
    beq $v0, 1, draw_screen                     # if there were side collisions, branch to draw_screen
    jal corner_collisions                       # handle corner collisions
# Redraw the screen
draw_screen:
    la $t0, BALL_DIRECTION                      # $t0 = ball direction
    lw $a0, 0($t0)                              # $a0 = ball x-direction
    lw $a1, 4($t0)                              # $a1 = ball y-direction
    jal move_ball                               # move the ball right by x-direction and down by y-direction
    lw $a0, PADDLE_ADDRESS                      # $a0 = paddle address
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 0($a1)                              # $a1 = white
    jal draw_paddle                             # redraw the paddle (fixes an edge case)
    lw $t0, BRICKS_REMAINING                    # $t0 = number of remaining bricks
    beq $t0, 0, game_win                        # if number of remaining bricks == 0, branch to game_win
    lw $a0, BALL_ADDRESS                        # $a0 = ball address
    jal get_location_position                   # get the position of the ball
    beq $v1, 31, lose_life                      # if ball y-position == 31, branch to lose_life
    j sleep                                     # jump to sleep
# If there are no bricks left, win the game
game_win:
    la $a0, COLOURS                             # $a0 = address of colours
    lw $a0, 8($a0)                              # $a0 = green
    lw $a1, BORDER_THICKNESS                    # $a1 = border thickness
    jal draw_border                             # draw a green border (you win!)
    li $v0, 10                                  # quit the game
    syscall
# If the ball reaches the bottom of the display, lose a life
lose_life:
    la $t0, LIVES                               # $t0 = address of number of lives remaining
    lw $t1, 0($t0)                              # $t1 = number of lives remaining
    addi $t1, $t1, -1                           # $t1 = $t1 - 1
    sw $t1, 0($t0)                              # store the new number of lives remaining
    beq $t1, 0, game_lose                       # if no lives remaining, lose the game
    la $t2, LAUNCHED                            # $t2 = address of whether ball has been launched
    add $t3, $t0, $0                            # $t3 = false
    sw $t3, 0($t2)                              # store that the ball has not been launched
    la $t4, FAST_SWITCH                         # $t4 = address of whether the ball speed is doubled
    add $t5, $0, $0                             # $t5 = 0
    sw $t5, 0($t4)                              # reset the ball speed to its original speed
    lw $a0, BALL_ADDRESS                        # $a0 = ball address
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 20($a1)                             # $a1 = black
    jal draw_ball                               # erase the ball using draw_ball(ball address, black)
    lw $a0, PADDLE_ADDRESS                      # $a0 = paddle address
    jal get_location_position                   # get the position of the paddle
    addi $a0, $v0, 3                            # $a0 = respawn x-position of ball
    addi $a1, $0, 29                            # $a1 = respawn y-position of ball
    jal get_location_address                    # get the respawn address of the ball
    add $a0, $v0, $0                            # $a0 = respawn address
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 0($a1)                              # $a1 = white
    jal draw_ball                               # respawn the ball using draw_ball(respawn address, white)
    j sleep                                     # jump to sleep
# If there are no lives left, lose the game
game_lose:
    la $a0, COLOURS                             # $a0 = address of colours
    lw $a0, 4($a0)                              # $a0 = red
    lw $a1, BORDER_THICKNESS                    # $a1 = border thickness
    jal draw_border                             # draw a red border (you lose!)
    li $v0, 10                                  # quit the game
    syscall
# Sleep (pause the program for a short time)
sleep:
    lw $t0, FAST_SWITCH                         # $t0 = whether a red brick has been hit
    beq $t0, 1, sleep_fast                      # if $t0 == 1, branch to sleep_fast
    li $v0, 32                                  # sleep for 150 milliseconds
    li $a0, 150
    syscall
    b game_run                                  # branch to game_run
sleep_fast:
    li $v0, 32                                  # sleep for 75 milliseconds
    li $a0, 75
    syscall
# Continue running the game
    b game_run                                  # branch to game_run

# int get_location_address(x, y)
#   Returns the address of the unit at (x, y).
#   Precondition: 0 <= x <= 31 and 0 <= y <= 31.
get_location_address:
# body
    sll $a0, $a0, 2                             # $a0 = x * 4
    sll $a1, $a1, 7                             # $a1 = y * 128
    lw $v0, DISP_ADDR                           # $v0 = base address
    add $v0, $v0, $a0                           # $v0 = $v0 + x * 4
    add $v0, $v0, $a1                           # $v0 = $v0 + y * 128
# epilogue
    jr $ra                                      # return location address

# (int, int) get_location_position(address)
#   Returns the x- and y-positions of the unit at address.
get_location_position:
# body
    lw $t0, DISP_ADDR                           # $t0 = base address
    sub $a0, $a0, $t0                           # $a0 = x * 4 + y * 128
    addi $t1, $0, 128                           # $t1 = 128
    div $a0, $t1                                # lo = $a0 // $t1 and hi = $a0 % $t1
    mfhi $v0                                    # $v0 = x * 4
    srl $v0, $v0, 2                             # $v0 = x
    mflo $v1                                    # $v1 = y
# epilogue
    jr $ra                                      # return (x, y)

# void draw_line(address, colour, width)
#   Draw a line with the left at address and with the specified colour and width.
draw_line:
# body
    add $t0, $0, $0                             # $t0 = 0
draw_line_for:
    beq $t0, $a2, draw_line_epilogue            # if $t0 == width, branch to draw_line_epilogue
    sw $a1, 0($a0)                              # set the current unit to colour
    addi $a0, $a0, 4                            # go to the next unit
    addi $t0, $t0, 1                            # $t0 = $t0 + 1
    j draw_line_for
# epilogue
draw_line_epilogue:
    jr $ra                                      # return

# void draw_rectangle(address, colour, width, height)
#   Draw a rectangle with the top-left at address and with the specified colour, width, and height.
draw_rectangle:
# prologue
    addi $sp, $sp, -24
    sw $s0, 20($sp)
    sw $s1, 16($sp)
    sw $s2, 12($sp)
    sw $s3, 8($sp)
    sw $s4, 4($sp)
    sw $ra, 0($sp)
# body
    add $s0, $a0, $0                            # $s0 = address
    add $s1, $a1, $0                            # $s1 = colour
    add $s2, $a2, $0                            # $s2 = width
    add $s3, $a3, $0                            # $s3 = height
    add $s4, $0, $0                             # $s4 = 0
draw_rectangle_for:
    beq $s4, $s3, draw_rectangle_epilogue       # if $s4 == height, branch to draw_rectangle_epilogue
    add $a0, $s0, $0                            # $a0 = current unit
    add $a1, $s1, $0                            # $a1 = colour
    add $a2, $s2, $0                            # $a2 = width
    jal draw_line                               # draw_line(current unit, colour, width)
    addi $s0, $s0, 128                          # go to the unit on the next row
    addi $s4, $s4, 1                            # $s4 = $s4 + 1
    j draw_rectangle_for                        # jump to draw_rectangle_for
# epilogue
draw_rectangle_epilogue:
    lw $ra, 0($sp)
    lw $s4, 4($sp)
    lw $s3, 8($sp)
    lw $s2, 12($sp)
    lw $s1, 16($sp)
    lw $s0, 20($sp)
    addi $sp, $sp, 24
    jr $ra                                      # return

# void draw_border(colour, thickness)
#   Draw borders with the specified colour and thickness.
draw_border:
# prologue
    addi $sp, $sp, -12
    sw $s0, 8($sp)
    sw $s1, 4($sp)
    sw $ra, 0($sp)
# body
    add $s0, $a0, $0                            # $s0 = colour
    add $s1, $a1, $0                            # $s1 = thickness
    lw $a0, DISP_ADDR                           # $a0 = base address
    add $a1, $s0, $0                            # $a1 = colour
    addi $a2, $0, 32                            # $a2 = 32
    lw $a3, BORDER_THICKNESS                    # $a3 = border thickness
    jal draw_rectangle                          # draw top border using draw_rectangle(base address, colour, 32, border thickness)
    lw $a0, DISP_ADDR                           # $a0 = base address
    add $a1, $s0, $0                            # $a1 = colour
    lw $a2, BORDER_THICKNESS                    # $a2 = border thickness
    addi $a3, $0, 32                            # $a3 = 32
    jal draw_rectangle                          # draw left border using draw_rectangle(base address, colour, border thickness, 32)
    addi $a0, $0, 31                            # $a0 = 31
    addi $a1, $0, 0                             # $a1 = 0
    jal get_location_address                    # get top-left address using get_location_address(31, 0)
    add $a0, $v0, $0                            # $a0 = top-left address
    add $a1, $s0, $0                            # $a1 = colour
    lw $a2, BORDER_THICKNESS                    # $a2 = border thickness
    addi $a3, $0, 32                            # $a3 = 32
    jal draw_rectangle                          # draw right border using draw_rectangle(top-left address, colour, border thickness, 32)
# epilogue
    lw $ra, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    addi $sp, $sp, 12
    jr $ra                                      # return

# void draw_brick(address, colour)
#   Draw a brick with the top-left at address and with the specified colour, width, and height.
draw_brick:
# prologue
    addi $sp, $sp, -4
    sw $ra, 0($sp)
# body
    lw $a2, BRICK_WIDTH                         # $a2 = brick width
    lw $a3, BRICK_HEIGHT                        # $a3 = brick height
    jal draw_rectangle                          # draw brick using draw_rectangle(address, colour, brick width, brick height)
# epilogue
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# void draw_brick_row(address, colour)
#   Draw a row of bricks with the top-left of the first brick at address and with the specified colour.
draw_brick_row:
# prologue
    addi $sp, $sp, -28
    sw $s0, 24($sp)
    sw $s1, 20($sp)
    sw $s2, 16($sp)
    sw $s3, 12($sp)
    sw $s4, 8($sp)
    sw $s5, 4($sp)
    sw $ra, 0($sp)
# body
    add $s0, $a0, $0                            # $s0 = address
    add $s1, $a1, $0                            # $s1 = colour
    add $s2, $a2, $0                            # $s2 = width
    add $s3, $a3, $0                            # $s3 = height
    add $s4, $0, $0                             # $s4 = 0
    lw $s5, BRICK_NROW                          # $s5 = number of bricks per row
draw_brick_row_for:
    beq $s4, $s5, draw_brick_row_epilogue       # if $s4 == number of bricks per row, branch to draw_brick_row_epilogue
    add $a0, $s0, $0                            # $a0 = address of current brick
    add $a1, $s1, $0                            # $a1 = colour
    jal draw_brick                              # draw brick using draw_brick(address of current brick, colour)
    lw $t0, BRICK_WIDTH                         # $t0 = brick width
    sll $t0, $t0, 2                             # $t0 = $t0 * 4
    add $s0, $s0, $t0                           # $s0 = address of next brick
    addi $s4, $s4, 1                            # $s4 = $s4 + 1
    j draw_brick_row_for                        # jump to draw_brick_row_for
# epilogue
draw_brick_row_epilogue:
    lw $ra, 0($sp)
    lw $s5, 4($sp)
    lw $s4, 8($sp)
    lw $s3, 12($sp)
    lw $s2, 16($sp)
    lw $s1, 20($sp)
    lw $s0, 24($sp)
    addi $sp, $sp, 28
    jr $ra                                      # return

# void intialize_bricks()
#   Draw the initial placement of all bricks.
initialize_bricks:
# prologue
    addi $sp, $sp, -12
    sw $s0, 8($sp)
    sw $s1, 4($sp)
    sw $ra, 0($sp)
# body
    lw $s0, BORDER_THICKNESS                    # $s0 = border thickness
    add $a0, $s0, $0                            # $a0 = x position of top-left unit of first row inside border
    add $a1, $s0, $0                            # $a1 = y position of top-left unit of first row inside border
    jal get_location_address                    # get address of top-left unit of first row inside border
    add $a0, $v0, $0                            # $a0 = address of first row
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 4($a1)                              # $a1 = red
    jal draw_brick_row                          # draw a row of bricks using draw(first row, red)
    add $a0, $s0, $0                            # $a0 = y position of top-left unit of second row inside border
    lw $t0, BRICK_HEIGHT                        # $t0 = brick height
    add $s1, $s0, $t0                           # $s1 = y position of top-left unit of second row inside border
    add $a1, $s1, $0                            # $a1 = y position of top-left unit of second row inside border
    jal get_location_address                    # get address of top-left unit of second row inside border
    add $a0, $v0, $0                            # $a0 = address of second row
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 8($a1)                              # $a1 = green
    jal draw_brick_row                          # draw a row of bricks using draw(second row, red)
    add $a0, $s0, $0                            # $a0 = x position of top-left unit of third row inside border
    lw $t0, BRICK_HEIGHT                        # $t0 = brick height
    add $s1, $s1, $t0                           # $s1 = y position of top-left unit of third row inside border
    add $a1, $s1, $0                            # $a1 = y position of top-left unit of third row inside border
    jal get_location_address                    # get address of top-left unit of third row inside border
    add $a0, $v0, $0                            # $a0 = address of third row
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 12($a1)                             # $a1 = blue
    jal draw_brick_row                          # draw a row of bricks using draw(third row, red)
# epilogue
    lw $ra, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    addi $sp, $sp, 12
    jr $ra                                      # return

# void store_brick_addresses()
#   Stores the addresses of the top-left unit in each brick to BRICK_ADDRESSES
store_brick_addresses:
# prologue
    addi $sp, $sp, -12
    sw $s0, 8($sp)
    sw $s1, 4($sp)
    sw $ra, 0($sp)
# body
    la $t0, BRICK_ADDRESSES                            # $t0 = address of brick addresses
    lw $t1, BORDER_THICKNESS                           # $t1 = border thickness
    add $s0, $t1, $0                                   # $s0 = x position of top-left unit of first brick
    add $s1, $t1, $0                                   # $s1 = y position of top-left unit of first brick
    lw $t2, BRICK_HEIGHT                               # $t2 = brick height
    lw $t3, BRICK_WIDTH                                # $t3 = brick width
    add $t4, $0, $0                                    # $t4 = 0
    lw $t5, BRICK_NCOL                                 # $t5 = number of bricks per column
store_brick_positions_for_col:
    beq $t4, $t5, store_brick_positions_epilogue       # if $t4 == number of bricks per column, go to store_brick_positions_epilogue
    add $t6, $0, $0                                    # $t6 = 0
    lw $t7, BRICK_NROW                                 # $t7 = number of bricks per row
store_brick_positions_for_row:
    beq $t6, $t7, store_brick_positions_for_col_end    # if $t6 == number of bricks per row, go to store_brick_positions_for_col_end
    add $a0, $s0, $0                                   # $a0 = x position of top-left unit of current brick
    add $a1, $s1, $0                                   # $a1 = y position of top-left unit of current brick
    addi $sp, $sp, -32                                 # create space to save all caller-save registers
    sw $t0, 28($sp)
    sw $t1, 24($sp)
    sw $t2, 20($sp)
    sw $t3, 16($sp)
    sw $t4, 12($sp)
    sw $t5, 8($sp)
    sw $t6, 4($sp)
    sw $t7, 0($sp)
    jal get_location_address                           # get address of top-left unit of current brick
    lw $t7, 0($sp)
    lw $t6, 4($sp)
    lw $t5, 8($sp)
    lw $t4, 12($sp)
    lw $t3, 16($sp)
    lw $t2, 20($sp)
    lw $t1, 24($sp)
    lw $t0, 28($sp)
    addi $sp, $sp, 32                                  # all caller-save registers have been loaded
    sw $v0, 0($t0)                                     # store the address in brick addresses
    add $s0, $s0, $t3                                  # $s0 = x position of top-left unit of next brick
    addi $t0, $t0, 4                                   # shift the brick addresses by 4
    addi $t6, $t6, 1                                   # $t6 = $t6 + 1
    j store_brick_positions_for_row                    # jump to store_brick_positions_for_row
store_brick_positions_for_col_end:
    add $s0, $t1, $0                                   # $s0 = x position of top-left unit of first brick in next row
    add $s1, $s1, $t2                                  # $s1 = y position of top-left unit of first brick in next row
    addi $t4, $t4, 1                                   # $t4 = $t4 + 1
    j store_brick_positions_for_col                    # jump to store_brick_positions_for_col
# epilogue
store_brick_positions_epilogue:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    addi $sp, $sp, 12
    jr $ra                                             # return

# void initialize_unbreakable_bricks()
#   Draw the initial placement of unbreakable bricks.
#   These are distince from (other) bricks, despite the similar names.
#   Notably, the addresses of unbreakable bricks are not stored.
#   Only one unbreakable brick is drawn because multiple would be too difficult.
initialize_unbreakable_bricks:
# prologue
    addi $sp, $sp, -4
    sw $ra, 0($sp)
# body
    li $v0, 42                                  # generate a number between 0 and 19
    li $a0, 0
    li $a1, 20
    syscall
    add $a0, $a0, 4                             # $a0 = x-position of unbreakable brick
    addi $a1, $0, 13                            # $a1 = y-position of unbreakable brick
    jal get_location_address                    # get the address of the unbreakable brick
    add $a0, $v0, $0                            # $a0 = address of unbreakable brick
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 16($a1)                             # $a1 = grey
    jal draw_brick                              # draw the unbreakable brick using draw_brick(address of unbreakable brick, grey)
# epilogue
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra                                         # return

# void draw_paddle(address, colour)
#   Draws the paddle at the specified address and stores its address.
draw_paddle:
# prologue
    addi $sp, $sp, -4
    sw $ra, 0($sp)
# body
    la $t0, PADDLE_ADDRESS                      # $t0 = address of paddle address
    add $a0, $a0, $0                            # $a0 = address
    sw $a0, 0($t0)                              # store the address in paddle address
    add $a1, $a1, $0                            # $a1 = colour
    lw $a2, PADDLE_WIDTH                        # $a2 = paddle width
    lw $a3, PADDLE_HEIGHT                       # $a3 = paddle height
    jal draw_rectangle                          # draw the paddle using draw_rectangle(address, colour, paddle width, paddle height)
# epilogue
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra                                      # return

# void draw_ball(address, colour)
#   Draws the ball at the specified address and stores its address.
draw_ball:
# prologue
    addi $sp, $sp, -4
    sw $ra, 0($sp)
# body
    la $t0, BALL_ADDRESS                        # $t0 = address of ball address
    add $a0, $a0, $0                            # $a0 = address
    sw $a0, 0($t0)                              # store the address in ball address address
    add $a1, $a1, $0                            # $a1 = colour
    lw $a2, BALL_WIDTH                          # $a2 = ball width
    lw $a3, BALL_HEIGHT                         # $a3 = ball height
    jal draw_rectangle                          # draw the ball using draw_rectangle(address, colour, ball width, ball height)
# epilogue
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra                                      # return

# void move_paddle_left()
#   Moves the paddle one unit to the left if possible.
move_paddle_left:
# prologue
    addi $sp, $sp, -4
    sw $ra, 0($sp)
# body
    lw $a0, PADDLE_ADDRESS                      # $a0 = paddle address
    jal get_location_position                   # get the position of the paddle using get_location_position(paddle address)
    lw $t0, BORDER_THICKNESS                    # $t0 = minimum x-position of paddle
    sgt $t1, $v0, $t0                           # if x-position of paddle > minimum x-position of paddle, $t1 = 1
    bne $t1, 1, move_paddle_left_epilogue       # if $t1 != 1, branch to move_paddle_left_epilogue
    lw $a0, PADDLE_ADDRESS                      # $a0 = paddle address
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 20($a1)                             # $a1 = black
    jal draw_paddle                             # erases the paddle using draw_paddle(paddle address, black)
    addi $a0, $v0, -1                           # $a0 = x-position of paddle - 1
    add $a1, $v1, $0                            # $a1 = y-position of paddle
    jal get_location_address                    # get the new address of the paddle
    add $a0, $v0, $0                            # $a0 = new paddle address
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 0($a1)                              # $a1 = black
    jal draw_paddle                             # redraws the paddle using draw_paddle(new paddle address, black)
    lw $t2, LAUNCHED                            # $t2 = whether ball has been launched
    beq $t2, 1, move_paddle_left_epilogue       # if ball has been launched, branch to move_paddle_left_epilogue
    addi $a0, $0, -1                            # $a0 = -1
    add $a1, $0, $0                             # $a1 = 0
    jal move_ball                               # move the ball one unit left using move_ball(-1, 0)
# epilogue
move_paddle_left_epilogue:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra                                      # return

# void move_paddle_right()
#   Moves the paddle one unit to the right if possible.
move_paddle_right:
# prologue
    addi $sp, $sp, -4
    sw $ra, 0($sp)
# body
    lw $a0, PADDLE_ADDRESS                      # $a0 = paddle address
    jal get_location_position                   # get the position of the paddle using get_location_position(paddle address)
    lw $t0, BORDER_THICKNESS                    # $t0 = border thickness
    lw $t3, PADDLE_WIDTH                        # $t3 = paddle width
    addi $t4, $0, 31                            # $t4 = 31
    sub $t4, $t4, $t0                           # $t4 = 31 - border thickness
    sub $t4, $t4, $t3                           # $t4 = 31 - border thickness - paddle width
    addi $t4, $t4, 1                            # $t4 = maximum x-position of paddle
    slt $t1, $v0, $t4                           # if x-position of paddle < maximum x-position of paddle, $t1 = 1
    bne $t1, 1, move_paddle_right_epilogue      # if $t1 != 1, branch to move_paddle_right_epilogue
    lw $a0, PADDLE_ADDRESS                      # $a0 = paddle address
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 20($a1)                             # $a1 = black
    jal draw_paddle                             # erases the paddle using draw_paddle(paddle address, black)
    addi $a0, $v0, 1                            # $a0 = x-position of paddle + 1
    add $a1, $v1, $0                            # $a1 = y-position of paddle
    jal get_location_address                    # get the new address of the paddle
    add $a0, $v0, $0                            # $a0 = new paddle address
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 0($a1)                              # $a1 = black
    jal draw_paddle                             # redraws the paddle using draw_paddle(new paddle address, black)
    lw $t2, LAUNCHED                            # $t2 = whether ball has been launched
    beq $t2, 1, move_paddle_right_epilogue      # if ball has been launched, branch to move_paddle_right_epilogue
    addi $a0, $0, 1                             # $a0 = 1
    add $a1, $0, $0                             # $a1 = 0
    jal move_ball                               # move the ball one unit right using move_ball(1, 0)
# epilogue
move_paddle_right_epilogue:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra                                      # return


# void launch_ball()
#   Launches the ball.
launch_ball:
# body
    la $t0, LAUNCHED                            # $t0 = whether ball has been launched
    addi $t1, $0, 1                             # $t1 = 1
    sw $t1, 0($t0)                              # the ball has been launched
# epilogue
    jr $ra                                      # return

# void move_ball(dx, dy)
#   Moves the ball dx units right and dy units down.
#   Precondition, -1 <= dx <= 1 and -1 <= dy <= 1.
move_ball:
# prologue
    addi $sp, $sp, -12
    sw $s0, 8($sp)
    sw $s1, 4($sp)
    sw $ra, 0($sp)
# body
    add $s0, $a0, $0                            # $s1 = dx
    add $s1, $a1, $0                            # $s2 = dy
    lw $a0, BALL_ADDRESS                        # $a0 = ball address
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 20($a1)                             # $a1 = black
    jal draw_ball                               # erases the ball using draw_ball(ball address, black)
    lw $a0, BALL_ADDRESS                        # $a0 = ball address
    jal get_location_position                   # get the position of the ball using get_location_position(ball address)
    add $a0, $v0, $s0                           # $a0 = x-position of ball + dx
    add $a1, $v1, $s1                           # $a1 = y-position of ball + dy
    jal get_location_address                    # get the new address of the ball using get_location_address(new x-position, new y-position)
    add $a0, $v0, $0                            # $a0 = new ball address
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 0($a1)                              # $a1 = white
    jal draw_ball                               # redraws the ball using draw_ball(new ball address, white)
# epilogue
    lw $ra, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    addi $sp, $sp, 12
    jr $ra                                      # return

# bool in_brick_addresses(address)
#   Returns true if address is a brick address and false otherwise.
in_brick_addresses:
# body
    la $t0, BRICK_ADDRESSES                     # $t0 = address of brick addresses
    add $t1, $a0, $0                            # $t1 = address
    lw $t2, BRICK_NROW                          # $t2 = number of bricks per row
    lw $t3, BRICK_NCOL                          # $t3 = number of bricks per column
    mul $t4, $t2, $t3                           # $t4 = total number of bricks
    add $t5, $0, $0                             # $t5 = 0
in_brick_addresses_for:
    beq $t5, $t4, in_brick_addresses_false      # if $t5 == total number of bricks (all bricks checked), branch to in_brick_addresses_false
    lw $t6, 0($t0)                              # $t6 = address of current brick
    beq $t1, $t6, in_brick_addresses_true       # if $t1 == address of some brick, branch to in_brick_addresses_true
    addi $t0, $t0, 4                            # $t0 = address of brick addresses starting on next brick
    addi $t5, $t5, 1                            # $t5 = $t5 + 1
    j in_brick_addresses_for                    # jump to in_brick_addresses_for
in_brick_addresses_true:
    addi $v0, $0, 1                             # $v0 = 1
    j in_brick_addresses_epilogue               # jump to in_brick_addresses_epilogue
in_brick_addresses_false:
    add $v0, $0, $0                             # $v0 = 0
# epilogue
in_brick_addresses_epilogue:
    jr $ra                                      # return true if address is brick addres and false otherwise


# int get_brick_address(x, y)
#   Get the address of the top-left unit of the brick containing (x, y).
#   Precondition: there is a brick that contains the address at the location (x, y).
get_brick_address:
# prologue
    addi $sp, $sp, -24
    sw $s0, 20($sp)
    sw $s1, 16($sp)
    sw $s2, 12($sp)
    sw $s3, 8($sp)
    sw $s4, 4($sp)
    sw $ra, 0($sp)
# body
    add $s0, $a0, $0                             # $s0 = x
    add $s1, $a1, $0                             # $s1 = y
    lw $s2, BRICK_WIDTH                          # $s2 = brick width
    sub $s2, $s0, $s2                            # $s2 = x bound
get_brick_address_for_x:
    beq $s0, $s2, get_brick_address_error        # if $s0 == x bound, branch to get_brick_address_error
    add $s3, $s1, $0                             # $s3 = y
    lw $s4, BRICK_HEIGHT                         # $s4 = brick height
    sub $s4, $s1, $s4                            # $s4 = y bound
get_brick_address_for_y:
    beq $s3, $s4, get_brick_address_for_x_end    # if $s3 == y bound, branch to get_brick_address_for_x_end
    add $a0, $s0, $0                             # $a0 = current x
    add $a1, $s3, $0                             # $a1 = current y
    jal get_location_address                     # get the address of the current unit using get_location_address(current x, current y)
    add $a0, $v0, $0                             # $a0 = address of current unit
    jal in_brick_addresses                       # check if the address of the current unit is a brick address
    beq $v0, 1, get_brick_address_store          # if yes, store the address to return it
    addi $s3, $s3, -1                            # $s3 = next possible y
    j get_brick_address_for_y                    # jump to get_brick_address_for_y
get_brick_address_for_x_end:
    addi $s0, $s0, -1                            # $s0 = next possible x
    j get_brick_address_for_x                    # jump to get_brick_address_for_x
get_brick_address_store:
    add $a0, $s0, $0                             # $a0 = x-position of top-left unit of brick
    add $a1, $s3, $0                             # $a1 = y-position of top-left unit of brick
    jal get_location_address                     # get the address of the top-left unit of the brick
    j get_brick_address_epilogue                 # jump to get_brick_address_epilogue
get_brick_address_error:
    addi $v0, $0, -1                             # $v0 = -1 (something went wrong)
# epilogue
get_brick_address_epilogue:
    lw $ra, 0($sp)
    lw $s4, 4($sp)
    lw $s3, 8($sp)
    lw $s2, 12($sp)
    lw $s1, 16($sp)
    lw $s0, 20($sp)
    addi $sp, $sp, 24
    jr $ra                                       # return the address

# void set_ball_direction(x-direction, y-direction)
#   Set the ball direction to the specified x and y values.
set_ball_direction:
# body
    la $t0, BALL_DIRECTION                      # $t0 = address of ball direction
    sw $a0, 0($t0)                              # store the x-direction
    sw $a1, 4($t0)                              # store the y-direction
# epilogue
    jr $ra                                      # return

# void break_brick(address)
#   Breaks the brick located at address.
#   If any red bricks have been broken during this life, the ball's speed is doubled.
#   If a blue brick is broken, reduce the number of remaining bricks by 1.
#   If an error occurs, returns -1.
#   Precondition: a brick is at the address and it is red, green, or blue.
break_brick:
# prologue
    addi $sp, $sp, -4
    sw $ra, 0($sp)
# body
    lw $t0, 0($a0)                              # $t0 = colour of brick
    lw $a2, BRICK_WIDTH                         # $a2 = brick width
    beq $t0, 0xFF0000, break_brick_red          # if $t0 == red, branch to break_brick_red
    beq $t0, 0x00FF00, break_brick_green        # if $t0 == green, branch to break_brick_green
    beq $t0, 0x0000FF, break_brick_blue         # if $t0 == blue, branch to break_brick_blue
    b break_brick_error                         # else, branch to break_brick_error
break_brick_red:
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 8($a1)                              # $a1 = green
    jal draw_brick                              # draw a new brick using draw_brick(address, green)
    la $t1, FAST_SWITCH                         # $t1 = whether a red brick has been hit
    addi $t2, $0, 1                             # $t2 = 1
    sw $t2, 0($t1)                              # a red brick has been hit
    j break_brick_epilogue                      # jump to break_brick_epilogue
break_brick_green:
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 12($a1)                             # $a1 = blue
    jal draw_brick                              # draw a new brick using draw_brick(address, blue)
    j break_brick_epilogue                      # jump to break_brick_epilogue
break_brick_blue:
    la $a1, COLOURS                             # $a1 = address of colours
    lw $a1, 20($a1)                             # $a1 = black
    jal draw_brick                              # erase the brick using draw_brick(address, black)
    la $t3, BRICKS_REMAINING                    # $t3 = address of number of remaining bricks
    lw $t4, 0($t3)                              # $t4 = number of remaining bricks
    addi $t4, $t4, -1                           # $t4 = number of remaining bricks - 1
    sw $t4, 0($t3)                              # store number of remaining bricks - 1
    j break_brick_epilogue                      # jump to break_brick_epilogue
break_brick_error:
    addi $v0, $0, -1                            # $v0 = -1 (something went wrong)
# epilogue
break_brick_epilogue:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra                                      # return

# bool side_collisions()
#   Handle collisions where the side of the ball is hit.
#   Returns true if any side collision occurred and false otherwise.
side_collisions:
# prologue
    addi $sp, $sp, -8
    sw $s0, 4($sp)
    sw $ra, 0($sp)
# body
    add $s0, $0, $0                             # $s0 = false
    jal top_collision                           # check if there is a top collision using top_collision()
    or $s0, $s0, $v0                            # $s0 = $s0 OR whether there is a top collision
    jal bottom_collision                        # check if there is a bottom collision using bottom_collision()
    or $s0, $s0, $v0                            # $s0 = $s0 OR whether there is a bottom collision
    jal left_collision                          # check if there is a left collision using left_collision()
    or $s0, $s0, $v0                            # $s0 = $s0 OR whether there is a left collision
    jal right_collision                         # check if there is a right collision using right_collision()
    or $s0, $s0, $v0                            # $s0 = $s0 OR whether there is a right collision
    add $v0, $s0, $0                            # $v0 = whether any side of the ball is hit
# epilogue
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    addi $sp, $sp, 8
    jr $ra                                      # return true if any side collision occurred

# bool top_collision()
#   Returns true if there is a top collision and false otherwise.
top_collision:
# prologue
    addi $sp, $sp, -8
    sw $s0, 4($sp)
    sw $ra, 0($sp)
# body
    lw $a0, BALL_ADDRESS                        # $a0 = ball address
    jal get_location_position                   # get the position of the ball using get_location_position(ball address)
    add $a0, $v0, $0                            # $a0 = x-position of unit above ball (x)
    addi $a1, $v1, -1                           # $a1 = y-position of unit above ball (y)
    jal get_location_address                    # get the address of the unit above the ball using get_location_address(x, y)
    add $s0, $v0, $0                            # $s0 = address of unit above ball
    lw $t0, 0($s0)                              # $t0 = colour or unit above ball
    la $t1, COLOURS                             # $t1 = address of colours
    lw $t2, 4($t1)                              # $t2 = red
    beq $t0, $t2, top_collision_brick           # if colour is red, branch to top_collision_brick
    lw $t2, 8($t1)                              # $t2 = green
    beq $t0, $t2, top_collision_brick           # if colour is green, branch to top_collision_brick
    lw $t2, 12($t1)                             # $t2 = blue
    beq $t0, $t2, top_collision_brick           # if colour is blue, branch to top_collision_brick
    lw $t2, 20($t1)                             # $t2 = black
    beq $t0, $t2, top_collision_false           # if colour is black (nothing is there), branch to top_collision_false
    j top_collision_true                        # jump to top_collision_true
top_collision_brick:
    add $a0, $s0, $0                            # $a0 = address of unit above ball (address)
    jal get_location_position                   # get the position of the unit above the ball using get_location_position(address)
    add $a0, $v0, $0                            # $a0 = x-position of unit above ball (x)
    add $a1, $v1, $0                            # $a1 = y-position of unit above ball (y)
    jal get_brick_address                       # get the address of the top-left unit of the brick using get_brick_address(x, y)
    add $a0, $v0, $0                            # $a0 = address of top-left unit of brick
    jal break_brick                             # break the brick using break_brick(address of top-left unit of brick)
top_collision_true:
    la $t3, BALL_DIRECTION                      # $t3 = address of ball direction
    addi $t4, $0, 1                             # $t4 = 1
    sw $t4, 4($t3)                              # store 1 (down) as the ball y-direction
    addi $v0, $0, 1                             # $v0 = true
    j top_collision_epilogue                    # jump to top_collision_epilogue
top_collision_false:
    add $v0, $0, $0                             # $v0 = false
# epilogue
top_collision_epilogue:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    addi $sp, $sp, 8
    jr $ra                                      # return true if there is a top collision

# bool bottom_collision()
#   Returns true if there is a bottom collision and false otherwise.
bottom_collision:
# prologue
    addi $sp, $sp, -8
    sw $s0, 4($sp)
    sw $ra, 0($sp)
# body
    lw $a0, BALL_ADDRESS                        # $a0 = ball address
    jal get_location_position                   # get the position of the ball using get_location_position(ball address)
    add $a0, $v0, $0                            # $a0 = x-position of unit below ball (x)
    addi $a1, $v1, 1                            # $a1 = y-position of unit below ball (y)
    jal get_location_address                    # get the address of the unit below the ball using get_location_address(x, y)
    add $s0, $v0, $0                            # $s0 = address of unit below ball
    lw $t0, 0($s0)                              # $t0 = colour or unit below ball
    la $t1, COLOURS                             # $t1 = address of colours
    lw $t2, 0($t1)                              # $t2 = white
    beq $t0, $t2, bottom_collision_paddle       # if colour is white, branch to bottom_collision_paddle
    lw $t2, 4($t1)                              # $t2 = red
    beq $t0, $t2, bottom_collision_brick        # if colour is red, branch to bottom_collision_brick
    lw $t2, 8($t1)                              # $t2 = green
    beq $t0, $t2, bottom_collision_brick        # if colour is green, branch to bottom_collision_brick
    lw $t2, 12($t1)                             # $t2 = blue
    beq $t0, $t2, bottom_collision_brick        # if colour is blue, branch to bottom_collision_brick
    lw $t2, 20($t1)                             # $t2 = black
    beq $t0, $t2, bottom_collision_false        # if colour is black (nothing is there), branch to bottom_collision_false
    j bottom_collision_true                     # jump to bottom_collision_true
bottom_collision_paddle:
    lw $a0, BALL_ADDRESS                        # $a0 = ball address
    jal get_location_position                   # get the position of the ball using get_location_position(ball address)
    add $s1, $v0, $0                            # $a1 = x-position of ball
    lw $a0, PADDLE_ADDRESS                      # $a0 = paddle address
    jal get_location_position                   # get the position of the paddle using get_location_position(paddle address)
    add $t5, $v0, $0                            # $t5 = x-position of paddle
    sub $t5, $s1, $t5                           # $t5 = difference in x-positions
    ble $t5, 2, bottom_collision_paddle_l       # if difference in x-positions <= 2, branch to bottom_collision_paddle_l
    bge $t5, 3, bottom_collision_paddle_r       # if difference in x-positions >= 3, branch to bottom_collision_paddle_r
bottom_collision_paddle_l:
    la $t3, BALL_DIRECTION                      # $t3 = address of ball direction
    addi $t4, $0, -1                            # $t4 = -1
    sw $t4, 0($t3)                              # store -1 (left) as the ball x-direction
    j bottom_collision_true                     # jump to bottom_collision_true
bottom_collision_paddle_r:
    la $t3, BALL_DIRECTION                      # $t3 = address of ball direction
    addi $t4, $0, 1                             # $t4 = 1
    sw $t4, 0($t3)                              # store 1 (right) as the ball x-direction
    j bottom_collision_true                     # jump to bottom_collision_true
bottom_collision_brick:
    add $a0, $s0, $0                            # $a0 = address of unit below ball (address)
    jal get_location_position                   # get the position of the unit below the ball using get_location_position(address)
    add $a0, $v0, $0                            # $a0 = x-position of unit below ball (x)
    add $a1, $v1, $0                            # $a1 = y-position of unit below ball (y)
    jal get_brick_address                       # get the address of the top-left unit of the brick using get_brick_address(x, y)
    add $a0, $v0, $0                            # $a0 = address of top-left unit of brick
    jal break_brick                             # break the brick using break_brick(address of top-left unit of brick)
bottom_collision_true:
    la $t3, BALL_DIRECTION                      # $t3 = address of ball direction
    addi $t4, $0, -1                            # $t4 = -1
    sw $t4, 4($t3)                              # store -1 (up) as the ball y-direction
    addi $v0, $0, 1                             # $v0 = true
    j bottom_collision_epilogue                 # jump to bottom_collision_epilogue
bottom_collision_false:
    add $v0, $0, $0                             # $v0 = false
# epilogue
bottom_collision_epilogue:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    addi $sp, $sp, 8
    jr $ra                                      # return true if there is a bottom collision

# bool left_collision()
#   Returns true if there is a left collision and false otherwise.
left_collision:
# prologue
    addi $sp, $sp, -8
    sw $s0, 4($sp)
    sw $ra, 0($sp)
# body
    lw $a0, BALL_ADDRESS                        # $a0 = ball address
    jal get_location_position                   # get the position of the ball using get_location_position(ball address)
    addi $a0, $v0, -1                           # $a0 = x-position of unit left of ball (x)
    add $a1, $v1, $0                            # $a1 = y-position of unit left of ball (y)
    jal get_location_address                    # get the address of the unit left of the ball using get_location_address(x, y)
    add $s0, $v0, $0                            # $s0 = address of unit left of ball
    lw $t0, 0($s0)                              # $t0 = colour or unit left of ball
    la $t1, COLOURS                             # $t1 = address of colours
    lw $t2, 4($t1)                              # $t2 = red
    beq $t0, $t2, left_collision_brick          # if colour is red, branch to left_collision_brick
    lw $t2, 8($t1)                              # $t2 = green
    beq $t0, $t2, left_collision_brick          # if colour is green, branch to left_collision_brick
    lw $t2, 12($t1)                             # $t2 = blue
    beq $t0, $t2, left_collision_brick          # if colour is blue, branch to left_collision_brick
    lw $t2, 20($t1)                             # $t2 = black
    beq $t0, $t2, left_collision_false          # if colour is black (nothing is there), branch to left_collision_false
    j left_collision_true                       # jump to left_collision_true
left_collision_brick:
    add $a0, $s0, $0                            # $a0 = address of unit left of ball (address)
    jal get_location_position                   # get the position of the unit left of the ball using get_location_position(address)
    add $a0, $v0, $0                            # $a0 = x-position of unit left of ball (x)
    add $a1, $v1, $0                            # $a1 = y-position of unit left of ball (y)
    jal get_brick_address                       # get the address of the top-left unit of the brick using get_brick_address(x, y)
    add $a0, $v0, $0                            # $a0 = address of top-left unit of brick
    jal break_brick                             # break the brick using break_brick(address of top-left unit of brick)
left_collision_true:
    la $t3, BALL_DIRECTION                      # $t3 = address of ball direction
    addi $t4, $0, 1                             # $t4 = 1
    sw $t4, 0($t3)                              # store 1 (right) as the ball x-direction
    addi $v0, $0, 1                             # $v0 = true
    j left_collision_epilogue                   # jump to left_collision_epilogue
left_collision_false:
    add $v0, $0, $0                             # $v0 = false
# epilogue
left_collision_epilogue:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    addi $sp, $sp, 8
    jr $ra                                      # return true if there is a left collision

# bool right_collision()
#   Returns true if there is a right collision and false otherwise.
right_collision:
# prologue
    addi $sp, $sp, -8
    sw $s0, 4($sp)
    sw $ra, 0($sp)
# body
    lw $a0, BALL_ADDRESS                        # $a0 = ball address
    jal get_location_position                   # get the position of the ball using get_location_position(ball address)
    addi $a0, $v0, 1                            # $a0 = x-position of unit right of ball (x)
    add $a1, $v1, $0                            # $a1 = y-position of unit right of ball (y)
    jal get_location_address                    # get the address of the unit right of the ball using get_location_address(x, y)
    add $s0, $v0, $0                            # $s0 = address of unit right of ball
    lw $t0, 0($s0)                              # $t0 = colour or unit right of ball
    la $t1, COLOURS                             # $t1 = address of colours
    lw $t2, 4($t1)                              # $t2 = red
    beq $t0, $t2, right_collision_brick         # if colour is red, branch to right_collision_brick
    lw $t2, 8($t1)                              # $t2 = green
    beq $t0, $t2, right_collision_brick         # if colour is green, branch to right_collision_brick
    lw $t2, 12($t1)                             # $t2 = blue
    beq $t0, $t2, right_collision_brick         # if colour is blue, branch to right_collision_brick
    lw $t2, 20($t1)                             # $t2 = black
    beq $t0, $t2, right_collision_false         # if colour is black (nothing is there), branch to right_collision_false
    j right_collision_true                      # jump to right_collision_true
right_collision_brick:
    add $a0, $s0, $0                            # $a0 = address of unit right of ball (address)
    jal get_location_position                   # get the position of the unit right of the ball using get_location_position(address)
    add $a0, $v0, $0                            # $a0 = x-position of unit right of ball (x)
    add $a1, $v1, $0                            # $a1 = y-position of unit right of ball (y)
    jal get_brick_address                       # get the address of the top-left unit of the brick using get_brick_address(x, y)
    add $a0, $v0, $0                            # $a0 = address of top-left unit of brick
    jal break_brick                             # break the brick using break_brick(address of top-left unit of brick)
right_collision_true:
    la $t3, BALL_DIRECTION                      # $t3 = address of ball direction
    addi $t4, $0, -1                            # $t4 = -1
    sw $t4, 0($t3)                              # store -1 (left) as the ball x-direction
    addi $v0, $0, 1                             # $v0 = true
    j right_collision_epilogue                  # jump to right_collision_epilogue
right_collision_false:
    add $v0, $0, $0                             # $v0 = false
# epilogue
right_collision_epilogue:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    addi $sp, $sp, 8
    jr $ra                                      # return true if there is a right collision

# bool corner_collisions()
#   Handles collisions when only the corner of the ball is hit.
#   Returns true if any corner collision occurred and false otherwise.
corner_collisions:
# prologue
    addi $sp, $sp, -12
    sw $s0, 8($sp)
    sw $s1, 4($sp)
    sw $ra, 0($sp)
# body
    lw $a0, BALL_ADDRESS                        # $a0 = ball address
    jal get_location_position                   # get the position of the ball using get_location_position(ball address)
    add $t0, $v0, $0                            # $t0 = x-position of ball
    add $t1, $v1, $0                            # $t1 = y-position of ball
    la $s0, BALL_DIRECTION                      # $s0 = address of ball direction
    lw $t2, 0($s0)                              # $t2 = ball x-direction
    lw $t3, 4($s0)                              # $t3 = ball y-direction
    add $a0, $t0, $t2                           # $a0 = x-position of unit touching ball (x)
    add $a1, $t1, $t3                           # $a3 = y-position of unit touching ball (y)
    jal get_location_address                    # get the address of the unit touching the ball using get_location_address(x, y)
    add $s1, $v0, $0                            # $s1 = address of unit touching ball
    lw $t4, 0($s1)                              # $t4 = colour of unit touching ball
    la $t5, COLOURS                             # $t5 = address of colours
    lw $t6, 4($t5)                              # $t6 = red
    beq $t4, $t6, corner_collision_brick        # if colour is red, branch to corner_collision_brick
    lw $t6, 8($t5)                              # $t6 = green
    beq $t4, $t6, corner_collision_brick        # if colour is green, branch to corner_collision_brick
    lw $t6, 12($t5)                             # $t6 = blue
    beq $t4, $t6, corner_collision_brick        # if colour is blue, branch to corner_collision_brick
    lw $t6, 20($t5)                             # $t6 = black
    beq $t4, $t6, corner_collision_false        # if colour is black (nothing is there), branch to corner_collision_false
    j corner_collision_true                     # jump to corner_collision_true
corner_collision_brick:
    add $a0, $s1, $0                            # $a0 = address of unit touching ball (address)
    jal get_location_position                   # get the postion of the unit touching the ball using get_location_position_address
    add $a0, $v0, $0                            # $a0 = x-position of unit touching ball (x)
    add $a1, $v1, $0                            # $a1 = y-position of unit touching ball (y)
    jal get_brick_address                       # get the address of the top-left unit of the brick using get_brick_address(x, y)
    add $a0, $v0, $0                            # $a0 = address of top-left unit of brick
    jal break_brick                             # break the brick using break_brick(address of top-left unit of brick)
corner_collision_true:
    la $t7, BALL_DIRECTION                      # $t7 = address of ball direction
    lw $t8, 0($t7)                              # $t8 = ball x-direction
    mul $t8, $t8, -1                            # $t8 = $t8 * -1 (inverted ball x-direction)
    sw $t8, 0($t7)                              # store the inverted ball x-direction as the ball x-direction
    lw $t9, 4($t7)                              # $t9 = ball y-direction
    mul $t9, $t9, -1                            # $t9 = $t9 * -1 (inverted ball y-direction)
    sw $t9, 4($t7)                              # store the inverted ball y-direction as the ball y-direction
    addi $v0, $0, 1                             # $v0 = true
    j corner_collisions_epilogue                # jump to corner_collisions_epilogue
corner_collision_false:
    add $v0, $0, $0                             # $v0 = false
# epilogue
corner_collisions_epilogue:
    lw $ra, 0($sp)
    lw $s1, 4($sp)
    lw $s0, 8($sp)
    addi $sp, $sp, 12
    jr $ra                                      # return true if any corner collision occurred
