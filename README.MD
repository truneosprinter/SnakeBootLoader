# Snakeboot Improved

This is my take on a project originally by Nir Lichtman, so all credit to him for my initial commit, which is his code. See his video here:
https://www.youtube.com/watch?v=tHO5x_Ha6pE

I made this as a personal project to develop my understanding of x86 assembly (which is pretty non-existant), and also for a cool project to impress Dr Hedges (hope you enjoy this sir!)

I wanted to add more functionality, however there is a large limit with what can be done in the 512 bytes that I have to work with in the bootloader, so I managed to squeeze out about as much functionality from the space I had as I could, and I think I ended up with a pretty functional game

I am definately looking forward to working on more projects in assembly after this one, but to anyone who sees this, I hope you enjoy playing around with it!

To run the file using QEMU and the FASM assembler, use the following commands:
```bash
# assemble the file with FASM assembler
fasm snakeboot.asm

# run a new x86_64 virtual machine with assembled binaries
qemu-system-x86_64 snakeboot.bin
```

To anyone who tries it out, I hope you enjoy!