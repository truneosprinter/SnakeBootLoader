org 0x7c00                        	; Set origin, the code starts at memory address 0x7C00

video = 0x10                      	; BIOS video interrupt
set_cursor_pos = 0x02             	; BIOS function to set cursor position
write_char = 0x0a                 	; BIOS function to write character at cursor position

system_services = 0x15            	; BIOS system services interrupt
wait_service = 0x86               	; BIOS function to wait for a specified interval

keyboard_int = 0x16               	; BIOS keyboard interrupt
keyboard_read = 0x00              	; BIOS function to read a keystroke
keystroke_status = 0x01           	; BIOS function to check keystroke status

timer_int = 0x1a                  	; BIOS timer interrupt
read_time_counter = 0x00          	; BIOS function to read time counter

left_arrow = 0x4b                 	; Scan code for left arrow key
right_arrow = 0x4d                	; Scan code for right arrow key
down_arrow = 0x50                 	; Scan code for down arrow key
up_arrow = 0x48                   	; Scan code for up arrow key

screen_width = 80                 	; Screen width in characters
screen_height = 25                	; Screen height in characters

call clear_screen                 	; Clear screen
mov bx, hello_msg                 	; Move welcome message into bx
call print_string                 	; Print bx at the top of the screen

call handle_food                  	; Initialize and draw the food position

start:                            	; Start of main loop
    mov ah, wait_service          	; Set wait service function
    mov cx, 1                     	; CX = 1 (wait duration high byte)
    mov dx, 0                     	; DX = 0 (wait duration low byte)
    int system_services           	; Call BIOS system services to wait

    mov ah, 0x01                  	; Function 01h - Set Cursor Shape
    mov ch, 0x26                  	; Set CH to 26h to hide cursor (bit 5 set)
    mov cl, 0x07                  	; Set CL to 07h (end scan line)
    int 0x10                      	; Call BIOS video services interrupt

    call handle_keyboard          	; Handle keyboard input

    mov ah, write_char            	; Set write character function
    mov bh, 0                     	; Page number (0)
    mov cx, 1                     	; Number of times to write character (1)
    mov al, ' '                   	; Character to write (space, to clear previous position)
    int video                     	; Call BIOS video interrupt to write character

    mov al, [food_row]            	; Load food row position into AL
    cmp [pos_row], al             	; Compare row position with food row position
    jne regular_flow              	; If not equal, continue normal flow
    mov al, [food_col]            	; Load food column position into AL
    cmp [pos_col], al             	; Compare column position with food column position
    jne regular_flow              	; If not equal, continue normal flow

    inc byte [score]              	; Increment the score
    call display_score            	; Display the updated score
    call handle_food              	; Handle new food position

    cmp byte [score], 255         	; Check if the score is 255
    je you_win                    	; If it is, jump to the you_win label

regular_flow:                     	; Normal execution flow
    mov ah, set_cursor_pos        	; Set cursor position function
    mov dh, [pos_row]             	; Load row position into DH
    mov dl, [pos_col]             	; Load column position into DL
    mov bh, 0                     	; Page number (0)
    int video                     	; Call BIOS video interrupt to set cursor position

    mov ah, write_char            	; Set write character function
    mov bh, 0                     	; Page number (0)
    mov cx, 1                     	; Number of times to write character (1)
    mov al, '*'                   	; Character to write (asterisk, to represent player)
    int video                     	; Call BIOS video interrupt to write character

    cmp byte [scan_code], left_arrow  ; Check if left arrow key was pressed
    jne check_right_arrow         	; If not, check right arrow
    dec byte [pos_col]            	; Decrement column position (move left)
    cmp byte [pos_col], 1         	; Check if position is less than 1
    jge check_wrap_row            	; If not, continue
    mov byte [pos_col], screen_width-2; Wrap around to the right side
    jmp start                     	; Jump back to start

check_right_arrow:
    cmp byte [scan_code], right_arrow ; Check if right arrow key was pressed
    jne check_up_arrow            	; If not, check up arrow
    inc byte [pos_col]            	; Increment column position (move right)
    cmp byte [pos_col], screen_width-2; Check if position is greater than or equal to screen width-1
    jl check_wrap_row             	; If not, continue
    mov byte [pos_col], 1         	; Wrap around to the left side
    jmp start                     	; Jump back to start

check_up_arrow:
    cmp byte [scan_code], up_arrow ; Check if up arrow key was pressed
    jne check_down_arrow          	; If not, check down arrow
    dec byte [pos_row]            	; Decrement row position (move up)
    cmp byte [pos_row], 1         	; Check if position is less than 1
    jge check_wrap_row            	; If not, continue
    mov byte [pos_row], screen_height-2; Wrap around to the bottom
    jmp start                     	; Jump back to start

check_down_arrow:
    cmp byte [scan_code], down_arrow ; Check if down arrow key was pressed
    jne failure                   	; If not, jump to failure (invalid key)
    inc byte [pos_row]            	; Increment row position (move down)
    cmp byte [pos_row], screen_height-2; Check if position is greater than or equal to screen height-1
    jl check_wrap_row             	; If not, continue
    mov byte [pos_row], 1         	; Wrap around to the top

jmp start                         	; Jump back to start

check_wrap_row:                   	; Check for row wrap-around
    jmp start                     	; Jump back to start

failure:
    jmp $                         	; Infinite loop (do nothing)

clear_screen:                     	; Subroutine to clear the screen
    mov ah, 0x02                  	; Set cursor position function
    mov bh, 0                     	; Page number (0)
    mov dh, 0                     	; Set row to 0 (start at top-left)
    mov dl, 0                     	; Set column to 0 (start at top-left part 2)
    int video                     	; Call BIOS video interrupt to set cursor position

    mov ah, write_char            	; Set write character function
    mov bh, 0                     	; Page number (0)
    mov al, ' '                   	; Character to write (space, to clear screen)
    mov cx, 2000                  	; Number of times to write character (80 columns * 25 rows)
    int video                     	; Call BIOS video interrupt to write character
    ret                           	; Return from subroutine

print_char:
    mov ah, 0x0e                  	; Teletype function
    int video                     	; BIOS video interrupt
    ret

print_string:
    .next_char:
        mov al, [bx]
        cmp al, 0
        je exit
        call print_char
        inc bx
        jmp .next_char

you_win:
    call display_score            	; Display the score (which will show "You Win")
    jmp $                         	; Infinite loop to halt the game

exit:
    ret

handle_keyboard:                  	; Subroutine to handle keyboard input
    mov ah, keystroke_status      	; Set keystroke status function
    int keyboard_int              	; Call BIOS keyboard interrupt
    jz end_of_handle_keyboard     	; If zero flag is set (no keystroke), jump to end

    mov ah, keyboard_read         	; Set read keystroke function
    int keyboard_int              	; Call BIOS keyboard interrupt
    mov [scan_code], ah           	; Store scan code in scan_code

end_of_handle_keyboard:
    ret                           	; Return from subroutine

handle_food:                      	; Subroutine to handle food placement
    mov ah, read_time_counter     	; Set read time counter function
    int timer_int                 	; Call BIOS timer interrupt
    mov al, dl                    	; Copy timer low byte to AL

    ; Calculate row position for food
    xor ah, ah                    	; Clear AH
    mov cl, screen_height-4       	; Set CL to screen height - 4
    div cl                        	; Divide AX by screen height - 4
    add ah, 2                     	; Ensure it's within boundary (2 to screen_height - 3)
    mov [food_row], ah            	; Store result in food_row

    ; Calculate column position for food
    mov al, dl                    	; Copy timer low byte to AL
    xor ah, ah                    	; Clear AH
    mov cl, screen_width-4        	; Set CL to screen width - 4
    div cl                        	; Divide AX by screen width - 4
    add ah, 2                     	; Ensure it's within boundary (2 to screen_width - 3)
    mov [food_col], ah            	; Store result in food_col

    mov ah, set_cursor_pos        	; Set cursor position function
    mov dh, [food_row]            	; Load food row position into DH
    mov dl, [food_col]            	; Load food column position into DL
    mov bh, 0                     	; Page number (0)
    int video                     	; Call BIOS video interrupt to set cursor position

    mov ah, write_char            	; Set write character function
    mov bh, 0                     	; Page number (0)
    mov cx, 1                     	; Number of times to write character (1)
    mov al, '&'                   	; Character to write (ampersand, to represent food)
    int video                     	; Call BIOS video interrupt to write character

    mov ah, set_cursor_pos        	; Set cursor position function
    mov dh, 0                     	; Set row to 0 (return cursor to top-left)
    mov dl, 0                     	; Set column to 0 (return cursor to top-left)
    mov bh, 0                     	; Page number (0)
    int video                     	; Call BIOS video interrupt to set cursor position

    ret                           	; Return from subroutine

display_score:
    pusha                         	; Save all registers

    mov ah, set_cursor_pos        	; Set cursor position for the score display (e.g., top-right corner)
    mov dh, 0                     	; Row 0 (top)
    mov dl, screen_width - 15     	; Column (near the right edge, adjust as needed)
    mov bh, 0                     	; Page number (0)
    int video                     	; Call BIOS video interrupt to set cursor position

    ; Display "Score: "
    mov bx, score_msg
    call print_string

    ; Check if score is 255 to display "You Win"
    mov al, [score]
    cmp al, 255                   	; Compare score with 255
    jne display_actual_score      	; If not 255, display actual score

    ; Display "You Win" message
    mov bx, you_win_msg
    call print_string
    jmp end_display_score         	; Skip the actual score display

display_actual_score:
    ; Display the score value with a fixed width of 8 digits
    mov ax, [score]
    mov cx, 8                      ; Fixed width for score display
    call print_decimal
    jmp end_display_score          ; Skip the actual score display

end_display_score:
    popa                          	; Restore all registers
    ret                           	; Return from subroutine

score_msg:
    db 'Score: ', 0

you_win_msg:
    db 'You Win!', 0

print_decimal:
    pusha                          ; Save all registers
    mov bx, 10                     ; Set up base 10 divisor
    xor di, di                     ; Clear DI for storing digits
    mov si, cx                     ; SI will hold the width parameter

    .convert_loop:
        xor dx, dx                 ; Clear DX for division
        div bx                     ; AX / 10, remainder in DX, quotient in AX
        add dl, '0'                ; Convert remainder to ASCII
        push dx                    ; Push digit onto stack
        inc di                     ; Increment digit count
        test ax, ax                ; Check if quotient is zero
        jnz .convert_loop          ; If not zero, continue

    ; Ensure leading zeros are printed
    .print_leading_zeros:
        cmp di, si                 ; Compare digit count with specified width
        jge .print_digits          ; If we've printed enough digits, skip to printing digits
        mov dl, '0'                ; Load ASCII for '0'
        push dx                    ; Push zero onto stack
        inc di                     ; Increment digit count
        jmp .print_leading_zeros   ; Repeat until we've printed enough digits

    .print_digits:
        pop dx                     ; Pop digit from stack
        mov al, dl                 ; Move digit to AL
        call print_char            ; Print the digit
        dec di                     ; Decrement digit count
        jnz .print_digits          ; If more digits, continue

    popa                           ; Restore all registers
    ret                            ; Return from subroutine
                        	; Return from subroutine

pos_row:
    db 10                         	; Initial row position for player
pos_col:
    db 5                          	; Initial column position for player
scan_code:
    db left_arrow                 	; Initial scan code (left arrow)
food_row:
    db 15                         	; Initial food row position
food_col:
    db 15                         	; Initial food column position
hello_msg:
    db ' Snake Boot', 0           	; Initialize application title
score:
    db 0                            ; Initialize score to 0

times 510 - ($ - $$) db 0         	; Fill remaining bytes with zeros until 510 bytes total
dw 0xAA55                         	; Boot sector signature (0xAA55)
