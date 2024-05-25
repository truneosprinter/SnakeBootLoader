org 0x7c00                        ; Set origin, the code starts at memory address 0x7C00

video = 0x10                      ; BIOS video interrupt
set_cursor_pos = 0x02             ; BIOS function to set cursor position
write_char = 0x0a                 ; BIOS function to write character at cursor position

system_services = 0x15            ; BIOS system services interrupt
wait_service = 0x86               ; BIOS function to wait for a specified interval

keyboard_int = 0x16               ; BIOS keyboard interrupt
keyboard_read = 0x00              ; BIOS function to read a keystroke
keystroke_status = 0x01           ; BIOS function to check keystroke status

timer_int = 0x1a                  ; BIOS timer interrupt
read_time_counter = 0x00          ; BIOS function to read time counter

left_arrow = 0x4b                 ; Scan code for left arrow key
right_arrow = 0x4d                ; Scan code for right arrow key
down_arrow = 0x50                 ; Scan code for down arrow key
up_arrow = 0x48                   ; Scan code for up arrow key
    
call clear_screen                 ; Clears 

mov bx, hello_msg
call print_string

call handle_food                  ; Initialize and draw the food position

start:                            ; Start of main loop

mov ah, wait_service              ; Set wait service function
mov cx, 1                         ; CX = 1 (wait duration high byte)
mov dx, 0                         ; DX = 0 (wait duration low byte)
int system_services               ; Call BIOS system services to wait

call handle_keyboard              ; Handle keyboard input

mov ah, write_char                ; Set write character function
mov bh, 0                         ; Page number (0)
mov cx, 1                         ; Number of times to write character (1)
mov al, ' '                       ; Character to write (space, to clear previous position)
int video                         ; Call BIOS video interrupt to write character

mov al, [food_pos]                ; Load food position into AL
cmp [pos_row], al                 ; Compare row position with food position
jne regular_flow                  ; If not equal, continue normal flow
cmp [pos_col], al                 ; Compare column position with food position
jne regular_flow                  ; If not equal, continue normal flow
call handle_food                  ; If equal, handle new food position

regular_flow:                     ; Normal execution flow

mov ah, set_cursor_pos            ; Set cursor position function
mov dh, [pos_row]                 ; Load row position into DH
mov dl, [pos_col]                 ; Load column position into DL
mov bh, 0                         ; Page number (0)
int video                         ; Call BIOS video interrupt to set cursor position

mov ah, write_char                ; Set write character function
mov bh, 0                         ; Page number (0)
mov cx, 1                         ; Number of times to write character (1)
mov al, '*'                       ; Character to write (asterisk, to represent player)
int video                         ; Call BIOS video interrupt to write character

cmp byte [scan_code], left_arrow  ; Check if left arrow key was pressed
jne check_right_arrow             ; If not, check right arrow
dec byte [pos_col]                ; Decrement column position (move left)
jmp start                         ; Jump back to start

check_right_arrow:
cmp byte [scan_code], right_arrow ; Check if right arrow key was pressed
jne check_up_arrow                ; If not, check up arrow
inc byte [pos_col]                ; Increment column position (move right)
jmp start                         ; Jump back to start

check_up_arrow:
cmp byte [scan_code], up_arrow    ; Check if up arrow key was pressed
jne check_down_arrow              ; If not, check down arrow
dec byte [pos_row]                ; Decrement row position (move up)
jmp start                         ; Jump back to start

check_down_arrow:
cmp byte [scan_code], down_arrow  ; Check if down arrow key was pressed
jne failure                       ; If not, jump to failure (invalid key)
inc byte [pos_row]                ; Increment row position (move down)

jmp start                         ; Jump back to start

failure:
jmp $                             ; Infinite loop (do nothing)

clear_screen:                     ; Subroutine to clear the screen
mov ah, 0x02                      ; Set cursor position funciton
mov bh, 0                         ; Page number (0)
mov dh, 0                         ; Set row to 0 (start at top-left)
mov dl, 0                         ; Set column to 0 (start at top-left part 2)
int video                         ; Call BIOS video interrupt to set cursor position

mov ah, write_char                ; Set write charachter function
mov bh, 0                         ; Page number (0)
mov al, ' '                       ; Charachter to write (space, to clear screen)
mov cx, 2000                      ; Number of times to write charachter (80 columns * 25 rows)
int video                         ; Call BIOS video interrupt to write charachter
ret                               ; Return from subroutine

print_char:
mov ah, 0xe
int 0x10
ret

print_string:
mov ax, [bx]
cmp al, 0
je exit
call print_char
add bx, 1
jmp print_string

exit:
ret

handle_keyboard:                  ; Subroutine to handle keyboard input
mov ah, keystroke_status          ; Set keystroke status function
int keyboard_int                  ; Call BIOS keyboard interrupt
jz end_of_handle_keyboard         ; If zero flag is set (no keystroke), jump to end

mov ah, keyboard_read             ; Set read keystroke function
int keyboard_int                  ; Call BIOS keyboard interrupt
mov [scan_code], ah               ; Store scan code in scan_code

end_of_handle_keyboard:
ret                               ; Return from subroutine

handle_food:                      ; Subroutine to handle food placement
mov ah, read_time_counter         ; Set read time counter function
int timer_int                     ; Call BIOS timer interrupt
mov al, 7                         ; Set AL to 7 (mask for random position)
and al, dl                        ; Perform AND operation with DL (timer value)
mov byte [food_pos], al           ; Store result in food_pos
add byte [food_pos], 7            ; Add 7 to ensure it's within screen boundaries

mov ah, set_cursor_pos            ; Set cursor position function
mov dh, [food_pos]                ; Load food row position into DH
mov dl, [food_pos]                ; Load food column position into DL
mov bh, 0                         ; Page number (0)
int video                         ; Call BIOS video interrupt to set cursor position

mov ah, write_char                ; Set write character function
mov bh, 0                         ; Page number (0)
mov cx, 1                         ; Number of times to write character (1)
mov al, '&'                       ; Character to write (ampersand, to represent food)
int video                         ; Call BIOS video interrupt to write character

mov ah, set_cursor_pos            ; Set cursor position function
mov dh, 0                         ; Set row to 0 (return cursor to top-left)
mov dl, 0                         ; Set column to 0 (return cursor to top-left)
mov bh, 0                         ; Page number (0)
int video                         ; Call BIOS video interrupt to set cursor position

ret                               ; Return from subroutine

pos_row:
db 10                             ; Initial row position for player
pos_col:
db 5                              ; Initial column position for player
scan_code:
db left_arrow                     ; Initial scan code (left arrow)
food_pos:
db 15                             ; Initial food position
hello_msg:
db ' Snake Boot', 0


times 510 - ($ - $$) db 0         ; Fill remaining bytes with zeros until 510 bytes total
dw 0xAA55                         ; Boot sector signature (0xAA55)
