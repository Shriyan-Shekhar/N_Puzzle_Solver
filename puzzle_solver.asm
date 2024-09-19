# The solvability of each game board, your answer: (Solvable or No solution)
# Size 3, Type 1: Solvable
# Size 3, Type 2: Solvable
# Size 3, Type 3: No Solution 
# Size 4, Type 1: Solvable
# Size 4, Type 2: No Solution
# Size 4, Type 3: Solvable
# Size 5, Type 1: Solvable
# Size 5, Type 2: Solvable
# Size 5, Type 3: No solution

.data
# messages
Msg1: .asciiz "Please enter the size of the N puzzle(3, 4 or 5):\n"
Msg2: .asciiz "Please enter the type of the game board(1, 2 or 3):\n"

# block list
block_list: 		.byte
5 6 4 3 0 2 1 7 8 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
7 5 2 1 6 8 4 0 3 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
4 6 0 5 8 1 7 3 2 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1
9 2 7 13 8 10 12 11 5 14 15 1 4 3 6 0 -1 -1 -1 -1 -1 -1 -1 -1 -1
0 4 9 13 12 5 11 1 10 14 7 2 8 3 6 15 -1 -1 -1 -1 -1 -1 -1 -1 -1
7 13 0 8 1 5 9 3 14 15 4 12 10 2 11 6 -1 -1 -1 -1 -1 -1 -1 -1 -1
7 3 19 16 14 9 13 17 24 20 1 22 8 12 10 11 23 2 15 4 18 5 6 21 0
2 11 14 19 22 4 24 15 12 1 10 6 5 9 18 21 7 13 0 3 17 8 23 16 20
15 9 5 19 1 11 4 13 8 24 21 0 18 6 22 16 14 20 2 3 10 12 7 17 23

# game setting
game_status:	.word 0 #the status of the game
game_pause: 	.word 0 #the state of game pause
game_step:	.word 0 #the total steps

# game board parameters
size:	.word 0 # the size of the current block list
type:	.word 0 # the type of the current block list
length: .word 0 # the length of the current block list
current_block_list:	.byte 0:25 #the base address of the current block list
space:	.word 0 # the postion of the space

# player instruction
input_key:	.word 0 # input key from the player


.text

main:

init_game: # Initialize the game
	la $s0,size #load the address of size
	la $s1,type #load the address of type
	la $s2,length #load the address of length
	la $s3,current_block_list #load the base address of current_block_list
	la $s4,space #load the address of space
	

	jal set_game_board
	
	# initialize game parameters
	jal set_current_block_list
	jal find_inital_space
	
	li $v0, 101 #syscall 101: create the game
	syscall
	
	#syscall 102: turn on the background music
	li $a0, 0 
	li $a1, 1
	li $v0, 102
	syscall

game_loop:
	jal get_time 
	add $s6, $v0, $zero # $s6: starting time of the game

game_check_win:
	jal check_win
				
game_player_instruction:
	jal get_keyboard_input
	jal process_player_input
	
game_wait_refresh: 
	# check GUI status
	li $v0, 107
	syscall
	# control the refresh rate
	add $a0, $s6, $zero
	addi $a1, $zero, 50 # iteration gap: 100 milliseconds
	jal have_a_nap
	j game_loop	
		
game_exit:	
	#syscall 102: turn off the background music
	li $a0, 0 
	li $a1, 2
	li $v0, 102
	syscall
	#syscall 108: Close the GUI window
	li $v0, 108
	syscall
	# Terminate the program
	li $v0, 10
	syscall
	

#--------------------------------------------------------------------
# procedure: set_game_board
# Let player choose the size and the type of the game board
# Use Syscall 100 to inform java program of the chosen size and type
# This function will use the size, the type, the length.
# This function has no return value.
#--------------------------------------------------------------------
set_game_board:
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp) # the address of size
	sw $s1, 8($sp) # the address of type
	sw $s2, 12($sp) # the address of length
		
	la $a0, Msg1
	addi $v0, $zero, 4
	syscall
	
	# read the size of N puzzle
	li $v0, 5
	syscall
	move $t0,$v0
	
	la $a0, Msg2
	addi $v0, $zero, 4
	syscall
	
	# read the type of the game board
	li $v0, 5
	syscall
	move $t1,$v0
	
	# save the size, the type and the length

	sw $t0, 0($s0)
	sw $t1, 0($s1)
	mul $t2,$t0,$t0
	sw $t2, 0($s2)
	
	# set game board
	move $a0,$t0
	move $a1,$t1
	li $v0, 100 #syscall 100: set game board
	syscall
	
sgb_exit:	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16
	jr $ra


#--------------------------------------------------------------------
# procedure: set_current_block_list
# Accorinding to the size and type chosen by player, read the block list and store in the current block list
# This function will use the size, the type, the length and base address of current_block_list.
# This function has no return value.
#--------------------------------------------------------------------
set_current_block_list:
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp) # the address of size
	sw $s1, 8($sp) # the address of type
	sw $s2, 12($sp) # the address of length
	sw $s3, 16($sp) # the base address of current_block list
	
	# load value
	lw $t0,0($s0) # load value of size
	lw $t1,0($s1) # load value of type
	lw $t2,0($s2) # load value of length
	
	# calculate the base address of corresponding block list
	addi $t3,$t0,-3 # size - 3
	addi $t4,$zero,3
	mul $t3,$t3,$t4 # (size - 3) times 3
	add $t3,$t3,$t1 # (size - 3) times 3 + type
	addi $t3,$t3,-1 # (size - 3) times 3 + type - 1
	addi $t4,$zero,25
	mul $t3,$t3,$t4 # [(size - 3) times 3 + type - 1] times 25
	
	la $t4, block_list # load base address of block list
	add $t3,$t3,$t4 # base address of block_list + [(size - 3) times 3 + type - 1] times 25
	
	# store the value to current_blcok_list
	move $t4,$zero # $t4 here is index of loop (i)
	
scbl_loop:
	add $t5,$t3,$t4 # base address of block_list + [(size - 3) times 3 + type - 1] times 25 + i
	lb $t6, 0($t5) # load the ith value
	add $t7,$s3,$t4 # base address of current_block_list + i
	sb $t6, 0($t7) # store the ith value into current_block_list
	
	addi $t4,$t4,1 # i++
	blt $t4,$t2,scbl_loop
	
scbl_exit:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	addi $sp, $sp, 20
	jr $ra

#--------------------------------------------------------------------
# procedure: find_inital_space
# find the position of space in the current_block_list and store the position of space into space
# You can assume that the space always exists in the current block list.
# This function will use the base address of current_block_list and the position of space.
# This function has no input parameters and return value.
#--------------------------------------------------------------------
find_inital_space:
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s3, 4($sp)
	sw $s4, 0($sp)
	
	add $t0, $s3, $zero #store address of s3
	add $t2, $zero, $zero #initialize position = 0
	
	loop:
		lb $t1, 0($t0) #load the value
		beq $t1, $zero, found #if (value == 0) update space
		addi $t0, $t0, 1 #get next address
		addi $t2, $t2, 1 #update position
		j loop
	
	found:
	sw $t2, 0($s4) #store position
	
	lw $ra, 8($sp)
	lw $s3, 4($sp)
	lw $s4, 0($sp)
	addi $sp, $sp, 12
	
	jr $ra
	
		
		
		
		
		
		
		



#--------------------------------------------------------------------
# procedure: get_time
# Get the current time
# $v0 = current time
#--------------------------------------------------------------------
get_time:	
	li $v0, 30
	syscall # this syscall also changes the value of $a1
	andi $v0, $a0, 0x3FFFFFFF # truncated to milliseconds from some years ago
	jr $ra

#--------------------------------------------------------------------
# procedure: have_a_nap(last_iteration_time, nap_time)
#--------------------------------------------------------------------
have_a_nap:
	addi $sp, $sp, -8
	sw $ra, 4($sp)
	sw $s0, 0($sp)

	add $s0, $a0, $a1
	jal get_time
	sub $a0, $s0, $v0
	slt $t0, $zero, $a0 
	bne $t0, $zero, han_p
	li $a0, 1 # sleep for at least 1ms
	
han_p:	li $v0, 32 # syscall: let mars java thread sleep $a0 milliseconds
	syscall

	lw $ra, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 8
	jr $ra

#--------------------------------------------------------------------
# procedure: get_keyboard_input
# If an input is available, save its ASCII value in the array input_key,
# otherwise save the value 0 in input_key.
#--------------------------------------------------------------------
get_keyboard_input:
	add $t2, $zero, $zero
	lui $t0, 0xFFFF
	lw $t1, 0($t0)
	andi $t1, $t1, 1
	beq $t1, $zero, gki_exit
	lw $t2, 4($t0)

gki_exit:	
	la $t0, input_key 
	sw $t2, 0($t0) # save input key
	jr $ra
	
#--------------------------------------------------------------------
# procedure: process_player_input
# Check the the data stored in the address of "input_key",
# If there is any latest movement input key, check it whether a valid player input.
# If so, perform the action of the new keyboard input input_key.
# Otherwise, do nothing.
# If an input is processed but it cannot actually move the block 
# due to some restrictions (e.g. boundaries), no more movements will be made in later
# iterations for this input. 
#--------------------------------------------------------------------
process_player_input:
	addi $sp, $sp, -4
	sw $ra, 0($sp)	
	
	la $t0, input_key
	lw $t1, 0($t0) # new input key

ppi_check_game_status:
	li $t0, 27 # corresponds to key 'ESC'
	beq $t1, $t0, game_exit
	
	li $t0, 114 # corresponds to key 'r'
	beq $t1, $t0, ppi_reset

	la $t0,game_status # load address of game_pause
	lw $t0,0($t0) 	  # load value of game_pause
	bne $t0,$zero,ppi_exit
	
	li $t0, 99 # corresponds to key 'c'
	beq $t1, $t0, ppi_check_solvable

ppi_check_pause_and:
	li $t0, 112 # corresponds to key 'p'
	beq $t1, $t0, ppi_pause
	
	la $t0,game_pause # load address of game_pause
	lw $t0,0($t0) 	  # load value of game_pause
	bne $t0,$zero,ppi_exit
	
ppi_process_movement:	
	li $t0, 119 # corresponds to key 'w'
	beq $t1, $t0, ppi_push_up  
	li $t0, 115 # corresponds to key 's'
	beq $t1, $t0, ppi_push_down
	li $t0, 97 # corresponds to key 'a'
	beq $t1, $t0, ppi_push_left
	li $t0, 100 # corresponds to key 'd'
	beq $t1, $t0, ppi_push_right
	j ppi_exit

ppi_push_left:
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall
	jal push_block_left
	j ppi_exit

ppi_push_right:
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall
	jal push_block_right
	j ppi_exit
	
ppi_push_up: 
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall
	jal push_block_up
	j ppi_exit

ppi_push_down:
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall
	jal push_block_down
	j ppi_exit

ppi_pause:
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall	
	jal set_game_pause
	j ppi_exit
	
ppi_reset:
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall	
	jal set_game_reset
	j ppi_exit
					
ppi_check_solvable:
	#syscall 102: play sound of action
	li $a0, 1 
	li $a1, 0
	li $v0, 102
	syscall	
	jal check_solvable
	move $a0,$v0
	li $v0, 109 # syscall 109: update game solvability
	syscall	
	j ppi_exit
	
ppi_exit: 
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra	

#--------------------------------------------------------------------
# procedure: push_block_down
# Move the block above the space downward by one step
# Move the object only when there exits a block above the space
# This function will use the size, the base address of current_block_list 
# and the position of space.
# This function has no return value.
#--------------------------------------------------------------------	
push_block_down:
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp) # the address of size
	sw $s3, 8($sp) # the base address of current_block_list
	sw $s4, 12($sp) # the address of space
	
	# load value
	lw $t0,0($s0) # load value of size
	lw $t1,0($s4) # load value of space

	# check invalid and process the movement
pbd_check_valid:
	slt $t3,$t1,$t0 # if space < size, the movement is invalid.
	bne $t3, $zero, pbd_exit # if space < size - 1, exit. Otherwise, process the movement. 
	
pbd_process_movement:
	# the movement is valid, then process the movement
	sub $t2,$t1,$t0 # $t2 = space - size, the next position of space
	
	#calculate the address
	add $t3,$s3,$t2 # base address of current_block_list + $t2
	add $t4,$s3,$t1 # base address of current_block_list + $t1
	lb $t5,0($t3) # load the $t2-th value
	sb $t5,0($t4) # store the $t2-th value into the position of space
	sb $zero,0($t3) # store the space into the position of $t2-th value
	
	#update new space
	sw $t2,0($s4)
	# update the total step
	la $t3,game_step
	lw $t4,0($t3)
	addi $t4,$t4,1
	sw $t4,0($t3)
		
pbd_after_move:
	# set parameters of syscall 103
	move $a0,$t1 
	move $a1,$t2
	move $a2,$t4

	#Syscall103: Update Block List
	li $v0,103
	syscall
	
pbd_exit:		
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s3, 8($sp)
	lw $s4, 12($sp)
	addi $sp, $sp, 16
	jr $ra

#--------------------------------------------------------------------
# procedure: push_block_up
# Move the block below the space upward by one step
# Move the object only when there exits a block below the space
# This function will use the size, the length, the base address 
# of current_block_list and the position of space.
# This function has no return value.
#--------------------------------------------------------------------	
push_block_up:
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp) # the address of size
	sw $s2, 8($sp)
	sw $s3, 12($sp) # the base address of current_block_list
	sw $s4, 16($sp) # the address of space
	
	# load value
	lw $t0,0($s0) # load value of size
	lw $t1,0($s4) # load value of space
	
	pbu_check_valid:
	addi $t4, $t0, -1 #size-1
	mul $t4, $t0, $t4 #(size-1) * size
	slt $t3,$t1,$t4 # if space_position > size*(size-1) - 1 #do if (space  < size *(size -1) true then exit
	beq $t3, $zero, push_up_exit # if space < size - 1, exit. Otherwise, process the movement. #if a space is on top
	
	pbu_process_movement:
	# the movement is valid, then process the movement
	add $t2,$t1,$t0 # $t2 = space + size, the next position of space
	
	#calculate the address
	add $t3,$s3,$t2 # base address of current_block_list + $t2
	add $t4,$s3,$t1 # base address of current_block_list + $t1
	lb $t5,0($t3) # load the $t2-th value
	sb $t5,0($t4) # store the $t2-th value into the position of space
	sb $zero,0($t3) # store the space into the position of $t2-th value
	
	#update new space
	sw $t2,0($s4)
	# update the total step #this works
	la $t3,game_step
	lw $t4,0($t3)
	addi $t4,$t4,1
	sw $t4,0($t3)
	
	
	pbu_after_move:
	# set parameters of syscall 103
	move $a0,$t1 
	move $a1,$t2
	move $a2,$t4

	#Syscall103: Update Block List
	li $v0,103
	syscall
	
	
	push_up_exit:		
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	addi $sp, $sp, 20
	jr $ra
	
	
		
		
		
		
		
		
		


							
#--------------------------------------------------------------------
# procedure: push_block_left
# Move the block on the right side of the space leftward by one step
# Move the object only when there exits a block on the right side of the space
# This function will use the size, the base address of current_block_list 
# and the position of space.
# This function has no return value.
#--------------------------------------------------------------------	
push_block_left:

	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp) # the address of size
	sw $s3, 8($sp) # the base address of current_block_list
	sw $s4, 12($sp) # the address of space	
	
	lw $t0,0($s0) # load value of size
	lw $t1,0($s4) # load value of space
	addi $t2, $t0, -1 #size - 1
	add $t6, $t1, $zero #store space value
	add $t7, $t0, $zero #store value of size
	
	pbl_checkvalid:
	div $t6, $t7 #dividing space/size
	mfhi $t3 #space mod size
	beq $t3, $t2, pbl_exit
	#modloop1:
		#sub $t6, $t6, $t7
		#bgez $t6, modloop1
		#add $t6, $t6, $t7
		
	#beq $t6, $t2, pbl_exit
	
	
	pbl_process_movement:
	# the movement is valid, then process the movement
	lw $t0,0($s0) # load value of size
	lw $t1,0($s4) # load value of space
	addi $t2,$t1, 1# $t2 = space + 1 the next position of space as space is moved left
	
	#calculate the address
	add $t3,$s3,$t2 # base address of current_block_list + $t2
	add $t4,$s3,$t1 # base address of current_block_list + $t1
	lb $t5,0($t3) # load the $t2-th value
	sb $t5,0($t4) # store the $t2-th value into the position of space
	sb $zero,0($t3) # store the space into the position of $t2-th value
	
	#update new space #this works
	sw $t2,0($s4)
	# update the total step #this works
	la $t3,game_step
	lw $t4,0($t3)
	addi $t4,$t4,1
	sw $t4,0($t3)
	
	pbl_after_move:
	# set parameters of syscall 103
	move $a0,$t1 
	move $a1,$t2
	move $a2,$t4

	#Syscall103: Update Block List
	li $v0,103
	syscall
	
	
	pbl_exit:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s3, 8($sp)
	lw $s4, 12($sp)
	addi $sp, $sp, 16
	jr $ra
		
		
		
		
		
		


	
#--------------------------------------------------------------------
# procedure: push_block_right
# Move the block on the left side of the space rightward by one step
# Move the object only when there exits a block on the left side of the space
# This function will use the size, the base address of current_block_list 
# and the position of space.
# This function has no return value.
#--------------------------------------------------------------------	
push_block_right:
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp) # the address of size
	sw $s3, 8($sp) # the base address of current_block_list
	sw $s4, 12($sp) # the address of space
	
	lw $t0,0($s0) # load value of size
	lw $t1,0($s4) # load value of space
	add $t6, $t1, $zero #store space value
	add $t7, $t0, $zero #store value of size
	
	
	pbr_checkvalid:
	div $t6, $t7 #dividing space/size
	mfhi $t2 #space mod size
	beq $t2, $zero, exit_pbr
	#modloop2:
		#sub $t6, $t6, $t7
		#bgez $t6, modloop2
		#add $t6, $t6, $t7
	
	#beq $t6, $zero, exit_pbr
	
	
	pbr_process_movement:
	# the movement is valid, then process the movement
	addi $t2,$t1,-1 # $t2 = space - 1 the next position of space as space is moved left
	
	#calculate the address
	add $t3,$s3,$t2 # base address of current_block_list + $t2
	add $t4,$s3,$t1 # base address of current_block_list + $t1
	lb $t5,0($t3) # load the $t2-th value
	sb $t5,0($t4) # store the $t2-th value into the position of space
	sb $zero,0($t3) # store the space into the position of $t2-th value
	
	#update new space
	sw $t2,0($s4)
	# update the total step #this works
	la $t3,game_step
	lw $t4,0($t3)
	addi $t4,$t4,1
	sw $t4,0($t3)
	
	pbr_after_move:
	# set parameters of syscall 103
	move $a0,$t1 
	move $a1,$t2
	move $a2,$t4

	#Syscall103: Update Block List
	li $v0,103
	syscall
	
	
	exit_pbr:		
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s3, 8($sp)
	lw $s4, 12($sp)
	addi $sp, $sp, 16
	jr $ra
	
		
		
		
		
		

#--------------------------------------------------------------------
# procedure: check_win
# Check whether	the current block list is in a winning state
# If yes, update game_status, update game win to java program with Syscall 105,
# and play sound of win with Syscall 102
# This function will use the length and the base address of current_block_list.
# This function has no return value.
#--------------------------------------------------------------------	
check_win:
	addi $sp, $sp, -12 #finished this
	sw $ra, 0($sp)
	sw $s2, 4($sp)  #the address of length
	sw $s3, 8($sp) #the base address of current_block_list
	
	la $t0, game_status
	lw $t0, 0($t0)
	bne $t0, $zero, exit_end
	
	lw $t0, 0($s2) #load value of length
	addi $t2, $zero, 1 #inititialize i = 0
	addi $t3, $s3, 0 #stire address sof current_block _list
	addi $t0, $t0, -1
	
	loop3:
		slt $t1, $t2, $t0 #for (int i = 1; i < length - 1 ; i++)
		beq $t1, $zero, passedstep1
		lb $t4, 0($t3) #load value of current
		addi $t5, $t3, 1
		lb $t5, 0($t5) #load value of next bit
		slt $t6, $t4, $t5 #if t4 < t5
		beq $t6, $zero, exit_end #fails above condition
		addi $t3, $t3, 1 #change address by 1
		addi $t2, $t2, 1 #i++
		j loop3
	
	passedstep1:
	add $t3, $s3, $zero
	add $t3, $t3, $t0
	lb $t1, 0($t3)
	bne $t1, $zero, exit_end #if last value does not equal 0 failed
	
	#update everything dont know how to update game_status
	#update game status to not 0 -> make it 1
	la $t6, game_status
	#lw $t6, 0($t6)
	addi $t7, $zero, 1
	sw $t7,0($t6)
	
	#update game win
	li $v0,105
	syscall
	
	#find sound and update sound
	#addi $t6, $zero, 0
	#addi $t7, $zero, 2
	#li $v0, 102
	#syscall 
	
	#addi $t6, $zero, 4
	#addi $t7, $zero, 0 (maybe problem in audio)
	li $a0, 4
	li $a1, 0
	li $v0, 102
	syscall

	
	
	exit_end:
	lw $ra, 0($sp)
	lw $s2, 4($sp)  #the address of length
	lw $s3, 8($sp) #the base address of current_block_list
	addi $sp, $sp, 12
	jr $ra		
		
		
		
		
		
		
		

					
						
#--------------------------------------------------------------------
# procedure: check_solvable
# Check whether the current game board is solvable
# Note that any rule-compliant movement of blocks will not change the solvability of the game board
# This function will use the size, the length, base address of current_block_list and the position of space.
# Output: $v0,1 means the game is solvable, 0 means the game has no solution.
#--------------------------------------------------------------------	
check_solvable:
	addi $sp, $sp, -20
	sw $ra, 0 ($sp)
	sw $s0, 4($sp) #size
	sw $s2, 8($sp) #address of the length
	sw $s3, 12($sp) #the address of current_block
	sw $s4, 16($sp) #address of space
	
	lw $t1, 0($s0) #value of size
	
	
	total_inversions: #this code works to find total inversion -> have to find row and column of empty space and add its indices
	addi $t3, $zero, 0 #number of inversions
	addi $t4, $zero, 0 #i=0
	lw $t5, 0($s2) #load length
	loop_outside:
		slt $t6, $t4, $t5 #for  (int i = 0; i < length; i++)
		beq $t6,  $zero, exit_whole
		add $t7, $t4, $s3 #update address of block 
		#check and compare and update number of inversions accordingly
		addi $t8, $zero, 0
		loop_inside:
			add $t9, $t4, $zero #value of i
			slt $t2, $t8, $t9 #for (int j = 0; j < i; j++)
			beq $t2, $zero, exit_inner
			lb $t0, 0($t7) #load value of position
			add $t1, $s3, $t8 #address of block + j
			lb $t1, 0($t1) #load value of j position value
			slt $t2, $t0, $t1 #if j value is greater than position value (position < others)
			beq $t2, $zero, exit_if
			addi $t3, $t3, 1
			exit_if:
			addi $t8, $t8, 1
			j loop_inside
			
		exit_inner:
		addi $t4, $t4, 1
		j loop_outside
	
	
	exit_whole:
	#finishing total inversions
	lw $t0, 0($s4) #value of space
	lw $t1, 0($s0) #value of size
	addi $t7, $zero, 0 #quotient or mflo
	#easiest method
	div $t0, $t1
	mfhi $t6
	mflo $t7
	#modloop3:
		#sub $t0, $t0, $t1
		#bgez $t0, incrementquotient
		#add $t0, $t0, $t1 #t0 is the mod or mfhi
		#j exitmod
	#incrementquotient:
		#addi $t7, $t7, 1
		#j modloop3
		
	#exitmod:

	add $t8, $t6, $t7
	add $t8, $t3, $t8 #total inversions
	
	#check whether even or odd for S and number of inversions and update v0 accordingly
	#parity of size
	addi $t0, $zero, 2 #t0 is 2
	lw $t1, 0($s0) #value of size
	
	div $t1, $t0 #size/2
	mfhi $t2 #t2 = size mod 2
	addi $t0, $zero, 2 #t0 is 2
	div $t8, $t0 #totalinversions/2
	mfhi $t4 #totalinversions mod 2
	beq $t2, $zero, even #if size is even
	
	#modloop4:
		#sub $t1, $t1, $t0
		#bgez $t1, modloop4
		#add $t1, $t1, $t0 #t1 stores size mod 2
	
	#parity of total inversions
	#addi $t0, $zero, 2 #t0 is 2
	
	
	#add $t4, $t8, $zero
	#modloop5:
		#sub $t4, $t4, $t0
		#bgez $t4, modloop5
		#add $t4, $t4, $t0 #totalinversions mod 2
	
	#final condition to branch
	#beq $t1, $zero, even #if size is even
	
	
	odd:
	beq $t4, $zero, return_true #if size is odd and inversions is even
	j return_false
	
	even:
	#check condition 
	beq $t4, $zero, return_false #inversions is even 
	bne $t4, $zero, return_true #inversions is odd
	
	
	
	
	
	return_true:
	li $v0, 1
	j exit_overall
	
	return_false:
	li $v0, 0
	j exit_overall
	
	
	#exiting code
	exit_overall:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	addi $sp, $sp, 20
	jr $ra
        
		
		
	
		
		
		
		
		
		


	
#--------------------------------------------------------------------
# procedure: get_total_inversion
# Calculate the total inversion
# The total inversion is the sum of the inversion of each value in current block list
# and the row number and column number where the space sits
# This function will use the size, the length, the base address of current_block_list
# and the position of space
# Output: $v0, the total inversion of the current block list
#--------------------------------------------------------------------	
get_total_inversion:

	li $v0, 1
        jr $ra
		
		
		
		
		
		
		
		

			
															
#--------------------------------------------------------------------
# Procedure: set_game_pause
# Switch the state of game_pause.
# This function has no input parameters and return value.
#--------------------------------------------------------------------
set_game_pause:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t0,game_pause
	lw $t1,0($t0)
	addi $t1,$t1,1
	
	addi $t2,$zero,2
	slt $t3,$t1,$t2
	bne $t3,$zero,sgp_process
	
spg_mod2:
	move $t1,$zero
	
sgp_process:
	sw $t1,0($t0)
	# set parameters of syscall 104
	move $a0,$t1
	
	#Syscall104: Game Set pause
	li $v0,104
	syscall

sgp_exit:    
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#--------------------------------------------------------------------
# Procedure: set_game_reset
# Reset the current block list and the value of game_step, game_pause and the game_status
# This function has no input parameters and return value.
#--------------------------------------------------------------------
set_game_reset:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal set_current_block_list
	jal find_inital_space
	la $t0,game_step
	sw $zero,0($t0)
	la $t0,game_pause
	sw $zero,0($t0)
	la $t0,game_status
	sw $zero,0($t0)
	
	#Syscall106: Game Reset
	li $v0,106
	syscall
			
sgr_exit:    
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	




