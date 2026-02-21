# Rock, paper scissors vs compute
# This is a 32 bit program
# To assemble: as --32 rps.s -o rps.o
# To link: ld -m elf_i386 rps.o -o rps

# To debug, add the -g flag

# Note: numbers 1-4 are 49-52 in ascii

.section .data
greeting_msg: 
	.ascii "Welcome to Rock, Paper, Scissors. First to 9, I cant be bothered to implement multi digit conversion to strings.\n"
greeting_len = . - greeting_msg # Compute current position - start of greeting to get total 				    # length

choice_msg:
	.ascii "Choose a number:\n 1. Rock\n 2. Paper\n 3. Scissors\n 4. Exit\n"

choice_len = . - choice_msg

computer_chose_txt:
	.ascii "Computer chose: "

computer_chose_len = . - computer_chose_txt

draw_txt:
	.ascii "Draw\n"
draw_txt_len = . - draw_txt

new_line:
	.ascii "\n"
new_line_len = . - new_line

user_win_txt:
	.ascii "User wins\n"
user_win_txt_len = . - user_win_txt

computer_win_txt:
	.ascii "Computer wins\n"
computer_win_txt_len = . - computer_win_txt

user_score_txt:
	.ascii "User score: "
user_score_txt_len = . - user_score_txt

computer_score_txt:
	.ascii "Computer score: "
computer_score_txt_len = . - computer_score_txt

best_streak_txt:
	.ascii "Best streak: "
best_streak_txt_len = . - best_streak_txt

invalid_input_txt:
	.ascii "Invalid input, try again.\n"
invalid_input_txt_len = . - invalid_input_txt

first_to_nine_txt:
	.ascii "Score 9 reached, game ends\n"
first_to_nine_txt_len = . - first_to_nine_txt

.section .bss

user_input:
	.space 4

computer_choice:
	.space 4

addition_result:
	.space 4

user_score:
	.space 4

computer_score:
	.space 4

best_streak:
	.space 4

.section .text

exit:
	movl $1, %eax
	xor %ebx, %ebx # how fancy
	int $0x80

first_to_nine:
	movl $4, %eax
	movl $1, %ebx
	movl $first_to_nine_txt, %ecx
	movl $first_to_nine_txt_len, %edx
	int $0x80

	jmp game_loop_exit
	

replace_best_streak:
	movl -24(%ebp), %eax
	movl %eax, -20(%ebp)
	jmp loop_start

game_draw:
	movl $4, %eax
	movl $1, %ebx
	movl $draw_txt, %ecx
	movl $draw_txt_len, %edx
	int $0x80

	movl $0, -24(%ebp) # current streak = 0

	# Print new line
	movl $4, %eax
	movl $1, %ebx
	movl $new_line, %ecx
	movl $new_line_len, %edx
	int $0x80
	
	jmp loop_start

user_win:
	movl $4, %eax
	movl $1, %ebx
	movl $user_win_txt, %ecx
	movl $user_win_txt_len, %edx
	int $0x80

	incl -12(%ebp) # increment user score
	incl -24(%ebp) # increment current streak
	
	# Print new line
	movl $4, %eax
	movl $1, %ebx
	movl $new_line, %ecx
	movl $new_line_len, %edx
	int $0x80
	
	jmp loop_start


computer_win:
	movl $4, %eax
	movl $1, %ebx
	movl $computer_win_txt, %ecx
	movl $computer_win_txt_len, %edx
	int $0x80

	incl -16(%ebp) # increment computer score	
	movl $0, -24(%ebp) # current streak = 0

	# Print new line
	movl $4, %eax
	movl $1, %ebx
	movl $new_line, %ecx
	movl $new_line_len, %edx
	int $0x80
	
	jmp loop_start



case_rock_paper:
	# paper beats rock
	movl -4(%ebp), %eax
	cmpb $50, (%eax) # paper = 2 = 50 in ascii, user win, and again, compb, not compl
	je user_win
	
	jmp computer_win # else jump to computer win	

case_rock_scissors:
	# rock beats scissors
	movl -4(%ebp), %eax
	cmpb $49, (%eax) # dereferenced
	je user_win

	jmp computer_win # else jump to computer win

case_paper_scissors:
	# scissors beat paper
	movl -4(%ebp), %eax
	cmpb $51, (%eax)
	je user_win

	jmp computer_win # else jump to computer win

.type game_loop, @function
game_loop:
	pushl %ebp
	movl %esp, %ebp
	subl $24, %esp # make room for 6 local vars, user choice, computer choice, scores, best and current streak in that order

	# Initialize them loop_start:
	cmpl $57, -12(%ebp) 
	je game_loop_exit

	cmpl $57, -16(%ebp)
	je game_loop_exit

	# Initialize them to zero to increment them later
	movl $0, -12(%ebp)
	movl $0, -16(%ebp)
	movl $0, -20(%ebp)
	movl $0, -24(%ebp)

loop_start:
	cmpl $9, -12(%ebp) 
	je first_to_nine

	cmpl $9, -16(%ebp)
	je first_to_nine

	# At the start of each loop, if current is greater than best score, copy cur into best
	movl -24(%ebp), %eax
	cmpl -20(%ebp), %eax
	jg replace_best_streak

	# Choice message
	movl $4 , %eax
	movl $1, %ebx
	movl $choice_msg, %ecx
	movl $choice_len, %edx
	int $0x80
	
	# Read input
	movl $3, %eax # read
	movl $0, %ebx # fd	
	movl $user_input, %ecx
	movl $2, %edx # only read 2 bytes, below i check whether the second byte is a new line			    # If not, the rest of the bytes get flushed until the new line is hit
	int $0x80

	# Make sure 2nd character is a new line so user can only type a single digit number
	movl $user_input,  %eax
	cmpb $10, 1(%eax)
	je valid_input
	jmp flush_input_buffer
	
flush_input_buffer:
	movl $3, %eax
	movl $0, %ebx
	movl $user_input, %ecx
	movl $1, %edx # read one byte at a time
	int $0x80
	cmpb $10, user_input # until a new line is hit
	jne flush_input_buffer	
	jmp invalid_input	

valid_input:
	movl $user_input,  -4(%ebp) # store user input in local var 1

	# Case input < 1
	movl -4(%ebp), %eax
	cmpb $49, (%eax) # dereference
	jl invalid_input

	# Case input > 4
	# already in eax
	cmpb $52, (%eax)
	jg invalid_input

	# Compare the ascii for 4 to the contents AT address -4(%ebp)
	# (%eax) dereferences
	# NOTE: compare byte and not long, because in the buffer
	# the enter of the user also gets stored, so only read the first byte
	# in eax: 0x00000a34 (0x34, 0x0a is the newline) 
	movl -4(%ebp), %eax
	cmpb $52, (%eax)
	je game_loop_exit
	
	# Make a random computer choice
	rdrand %eax
	movl $3, %ebx # copy  num to mod with to ebx
	xor %edx, %edx # 0 edx, which is the result of the division
	div %ebx
	addl $49, %edx # +48 to  Convert to ascii and +1 to make it 1-3 instead of 0-2 
	movl %edx, computer_choice # store it a buffer and then in var 2
	movl $computer_choice, -8(%ebp)	

	# Print computer's choice	
	movl $4, %eax
	movl $1, %ebx # stdout
	movl $computer_chose_txt, %ecx # buffer start
	movl $computer_chose_len, %edx # buffer size
	int $0x80 # kernel call

	movl $4, %eax
	movl $1, %ebx # stdout
	movl -8(%ebp), %ecx # buffer start
	movl $4, %edx # buffer size
	int $0x80 # kernel call

	movl $4, %eax
	movl $1, %ebx # stdout
	movl $new_line, %ecx # buffer start
	movl $new_line_len, %edx # buffer size
	int $0x80 # kernel call


	# Add them together for comparisons
	movl -4(%ebp), %eax
	movl -8(%ebp), %ebx # store them in registers
	movzbl (%eax), %eax # load a byte from user choice and zero extend instead of the mem address
	addl (%ebx), %eax # store result in eax
	subl $48, %eax # convert to corresponding ascii
	movl %eax, addition_result # store in buffer

	# Print it
	movl $4, %eax
	movl $1, %ebx # stdout
	movl $addition_result , %ecx # buffer start
	movl $4, %edx # buffer size
	####### int $0x80


	# Case Draw
	movl -4(%ebp), %eax
	movl -8(%ebp), %ebx # store them in registers
	movzbl (%eax), %eax # load a byte from user choice and zero extend instead of the mem address
	cmpl (%ebx), %eax	
	je game_draw

	# note: rock = 1, paper = 2, scissors, 3
	
	# Case rock - paper (1 + 2 = 3)
	movl addition_result, %eax # move value, not address
	cmpl $51, %eax # 3 is 51 in ascii
	je case_rock_paper
	

	# Case rock - scissors (1 + 3 = 4)
	# result already in eax
	cmpl $52, %eax
	je case_rock_scissors

	
	# Case paper - scissors (2 + 3 = 5)
	# result in eax
	cmpl $53, %eax	
	je case_paper_scissors

	# Anything else
	jmp invalid_input

invalid_input:	
	# Remaining case, invalid input		
	movl $4, %eax
	movl $1, %ebx
	movl $invalid_input_txt, %ecx
	movl $invalid_input_txt_len, %edx
	int $0x80	

	movl $4, %eax
	movl $1, %ebx
	movl $new_line, %ecx
	movl $new_line_len, %edx
	int $0x80
	jmp loop_start


game_loop_exit:
	movl -12(%ebp), %eax
	addl $48, %eax # convert to ascii
	movl %eax, user_score
	movl -16(%ebp), %eax
	addl $48, %eax # same
	movl %eax, computer_score

	# Printing
	
	movl $4, %eax
	movl $1, %ebx
	movl $user_score_txt, %ecx
	movl $user_score_txt_len, %edx
	int $0x80


	movl $4, %eax # Write sys call
	movl $1, %ebx # stdout
	movl $user_score, %ecx # buffer start
	movl $4, %edx # buffer size
	int $0x80 # kernel call

	movl $4, %eax
	movl $1, %ebx
	movl $new_line, %ecx
	movl $new_line_len, %edx
	int $0x80
		
	movl $4, %eax
	movl $1, %ebx
	movl $computer_score_txt, %ecx
	movl $computer_score_txt_len, %edx
	int $0x80

	movl $4, %eax
	movl $1, %ebx
	movl $computer_score, %ecx
	movl $4, %edx
	int $0x80
	
	movl $4, %eax
	movl $1, %ebx
	movl $new_line, %ecx
	movl $new_line_len, %edx
	int $0x80

	movl -20(%ebp), %eax # return streak
	movl %ebp, %esp
	popl %ebp
	ret	

.globl _start
_start:
	movl $4, %eax # Write sys call
	movl $1, %ebx # stdout
	movl $greeting_msg, %ecx # buffer start
	movl $greeting_len, %edx # buffer size
	int $0x80 # kernel call
	
	call game_loop

	# best streak in eax
	addl $48, %eax # convert to ascii
	movl %eax, best_streak
	
	movl $4, %eax
	movl $1, %ebx
	movl $best_streak_txt, %ecx
	movl $best_streak_txt_len, %edx
	int $0x80		

	movl $4, %eax
	movl $1, %ebx
	movl $best_streak, %ecx
	movl $4, %edx
	int $0x80
		
	movl $4, %eax
	movl $1, %ebx
	movl $new_line, %ecx
	movl $new_line_len, %edx
	int $0x80

	jmp exit
