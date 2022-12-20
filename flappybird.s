#####################################################################
#
# CSC258H5S Winter 2020 Assembly Programming Project
# University of Toronto Mississauga
#
# Group members:
# - Student 1: Wen Hua Tung, 1004767040
# - Student 2 (if any): Mustafa Mughal, 1004108075
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 5 (choose the one the applies)
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. Changing the game difficulty by increasing the speed
# 2. Two birds, one controlled by "f" and one by "j"
# 3. Display the score on screen
# ... (add more if necessary)
#
# Any additional information that the TA needs to know:
# - Highest score is 99
#
#####################################################################


# Demo for painting
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
.data
	displayAddress:	.word	0x10008000
	
	# color 
	blue: 				.word	0x62d9fc
	green: 				.word	0x0dba24
	pink:				.word	0xf576e8
	purple:				.word	0x8d3bcc
	yellow:				.word	0xf5ef42
	black:				.word	0x000000
	exit_screen:			.word	0x03fcd7
	exit_bye:			.word   0xfc03a5
	exit_score:			.word	0xf0fc03
	
	# screen 
	screen_width:			.word 	32  			# 0 ~ 31
	screen_height:			.word 	32  			# 0 ~ 31
	
	# draw digit 
	quotient:			.word 	0
	
	# obstacle
	obstacle_width: 		.word 	3
	obstacle_up_height:		.word 	6
	obstacle_bottom_height:		.word 	8
	obstacle_move_range:		.word 	0
	obstacle_cur_px:		.word 	0			# x axis, pixel to draw, left point
	obstacle_cur_clean_px:		.word 	0			# x axis, pixel to clean, left point
	
	# bird
	bird_cur_py1:			.word	2
	bird_cur_py2:			.word	2
		
	# score(time elapse)
	time_elapse:			.word	0
	curr_score:			.word	0
	prev_score:			.word	0
	
	speed:				.word	300
	speed_move:			.word   100

.globl main  # executes main first
.text

main:
	initialization_drawing_sky:
		lw $a0, blue
		jal func_draw_sky
		
	initialization_drawing_obstacles:
		lw $t0, obstacle_width 
		lw $t1, screen_width
		sub $t2, $t1, $t0		# 	32 - 3
		sw $t2, obstacle_move_range 	#	29
	
	# start game
	WHILE_LOOP_GAME:
	
		show_score:			
			lw $t0, curr_score	# save $t0 to curr score
			lw $t1, prev_score	# load $t1 to prev score
			
			
			# cover previous score
			move $a0, $t1
			lw $a1, blue
			jal func_draw_score
				
			# draw current score
			lw $a0, curr_score
			lw $a1, black
			jal func_draw_score
	
			
		initialization_cur_frame:
			lw $t0, time_elapse 			# load elapse time
			lw $t1, obstacle_move_range		# 29
			addi $t3, $t1, 1			# in order to get 0 ~ 29
			div $t0, $t3
			mfhi $t2					# get remainder 
			mflo $t5
			
			#rem $t2, $t0, $t3			# get the remainder within obstacle_move_range 
								# which is from 0 ~ 29
			
			sub $t2, $t1, $t2			# set it from 29 ~ 0
								# draw it from right to left, so set it from 28 ~ 0
			sw $t2, obstacle_cur_px
			
			# check if the current obstacle is the most left one
			bne $t2, $t1, Else_set_clean_obstacle
				beqz $t5, End_if_increase_speed
				# add score
				jal func_increase_score
				jal func_speed_up
				End_if_increase_speed:
				li $t4, 0
				sw $t4, obstacle_cur_clean_px		# save clean px
				j Endif_clean
			Else_set_clean_obstacle:
				addi $t2, $t2, 1
				sw $t2, obstacle_cur_clean_px		# save clean px
			Endif_clean:
			
			# increase the time and save it
			lw $t0, time_elapse
			addi $t0, $t0, 1
			sw $t0, time_elapse
		
		sleep_cur_frame:
			# sleep 1 second
			li $v0, 32
			lw $a0, speed # make speed smaller to speed the game up
			syscall
		
		start_clean_obstacle_in_last_frame:
			lw $a0, obstacle_cur_clean_px		# a0 is from 28 ~ 0
			lw $t0, obstacle_width
			add $a1, $a0, $t0			# a1 is from 31 ~ 3
			lw $a2, obstacle_up_height		# the up obstacle height
			lw $a3, obstacle_bottom_height		# the bottom obstacle height

			jal func_cover_sky
		
		start_draw_obstacle_in_cur_frame:
			lw $a0, obstacle_cur_px			# a0 is from 28 ~ 0
			lw $t0, obstacle_width
			add $a1, $a0, $t0			# a1 is from 31 ~ 3
			lw $a2, obstacle_up_height		# the up obstacle height
			lw $a3, obstacle_bottom_height		# the bottom obstacle height
			
			jal func_draw_obstacles
			
		
		charloop1:
			li $v0, 32
			li $a0, 100
			syscall
			IF_F:
				# if get char != f
				jal func_get_char
				beq $v0, 102, THEN_F
				beq $v0, 106, THEN_J
			
			ELSE_F: # if f and j is not pressed
				
				# if f is not pressed
				start_clean_bird1_in_last_frame2:
					lw $t0, bird_cur_py1
					move $a0, $t0
					jal function_cover_bird1
		
				start_draw_bird1_in_cur_frame2:
					lw $t0, bird_cur_py1
					addi $a0, $t0, 1
					beq $a0, 30, Exit
					sw $a0, bird_cur_py1
					jal function_draw_bird1

				 # if j is not pressed
				start_clean_bird2_in_last_frame2:
					lw $t0, bird_cur_py2
					move $a0, $t0
					jal function_cover_bird2
		
				start_draw_bird2_in_cur_frame2:
					lw $t0, bird_cur_py2
					addi $a0, $t0, 1
					beq $a0, 30, Exit
					sw $a0, bird_cur_py2
					jal function_draw_bird2
				j END_F
				
			THEN_F: # if f is pressed
				start_clean_bird1_in_last_frame1:
					lw $t0, bird_cur_py1
					move $a0, $t0
					jal function_cover_bird1
		
				start_draw_bird1_in_cur_frame1:
					lw $t0, bird_cur_py1
					addi $a0, $t0, -1
					beq $a0, 0, Exit
					sw $a0, bird_cur_py1
					jal function_draw_bird1
				j END_F
			
			THEN_J: # if j is pressed
				start_clean_bird2_in_last_frame1:
					lw $t0, bird_cur_py2
					move $a0, $t0
					jal function_cover_bird2
		
				start_draw_bird2_in_cur_frame1:
					lw $t0, bird_cur_py2
					addi $a0, $t0, -1
					beq $a0, 0, Exit
					sw $a0, bird_cur_py2
					jal function_draw_bird2
			END_F:
			
		j WHILE_LOOP_GAME
	j Exit

func_increase_score:
	lw $t0, curr_score
	sw $t0, prev_score
	addi $t0, $t0, 1
	sw $t0, curr_score
	jr $ra

func_speed_up:
	lw $t0, speed
	blt $t0, 50, End_if_speed_up 
	lw $t1 speed_move
	sub $t0, $t0, $t1
	sw $t0, speed
	End_if_speed_up:
		jr $ra
	
func_draw_score:
	# initialization
	move $t9, $ra				# save the return address
	move $t0, $a0				# get the input number
	move $s1, $a1				# get the input color
	li $t3, 1				# we draw at most 2 digit(0, 1)
	while_loop_get_last_digit:	
		li $t1, 10			# divide 10 to get the last digit
		div $t0, $t1
		mfhi $t2			# get the remainder
		mflo $t0			# get the quotient
		sw $t0, quotient
		move $a0, $t2			# to draw last digit
		move $a1, $t3			# position to draw current digit
		move $a2, $s1			# color
		jal func_draw_cur_digit
		subi $t3, $t3, 1
		lw $t0, quotient
		bnez $t0, while_loop_get_last_digit
		jr $t9
		
func_draw_cur_digit:
	bltz $a0, return_draw_cur_digit
	move $t0, $a0 				# digit to draw
	move $t1, $a1				# position to draw
	li $t2, 0				# set drawing x axis offset
	lw $s0, displayAddress			# $s0 stores the base address for display
	move $s1, $a2				# store color
	move $s2, $ra				# save address
	
	beqz $t1, draw_digit
	li, $t2, 4
	
	draw_digit:
		if_draw_zero:
			bne $t0, 0, if_draw_one
			
			li $a0, 0		# 1
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 2
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 3
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 4
			add $a0, $a0, $t2	# px		
			li $a1, 1		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 5
			add $a0, $a0, $t2	# px		
			li $a1, 1		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 6
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 7
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 8
			add $a0, $a0, $t2	# px		
			li $a1, 3		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 9
			add $a0, $a0, $t2	# px		
			li $a1, 3		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 10
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 11
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 12
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			j return_draw_cur_digit
			
		if_draw_one:
			bne $t0, 1, if_draw_two
			
			li $a0, 1	
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1	
			add $a0, $a0, $t2	# px		
			li $a1, 1		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1	
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1	
			add $a0, $a0, $t2	# px		
			li $a1, 3		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1	
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			j return_draw_cur_digit
			
		if_draw_two:
			bne $t0, 2, if_draw_three
			
			li $a0, 0		# 1
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 2
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 3
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
		
			li $a0, 2		# 5
			add $a0, $a0, $t2	# px		
			li $a1, 1		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 7
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 13
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 6
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 8
			add $a0, $a0, $t2	# px		
			li $a1, 3		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 10
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 11
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 12
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			j return_draw_cur_digit
			
		if_draw_three:
			bne $t0, 3, if_draw_four
			
			li $a0, 0		# 1
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 2
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 3
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
		
			li $a0, 2		# 5
			add $a0, $a0, $t2	# px		
			li $a1, 1		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 7
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 13
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 6
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 9
			add $a0, $a0, $t2	# px		
			li $a1, 3		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 10
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 11
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 12
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			j return_draw_cur_digit
		
		if_draw_four:
			bne $t0, 4, if_draw_five
			
			li $a0, 0		# 1
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 3
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
		
			li $a0, 0		# 4
			add $a0, $a0, $t2	# px		
			li $a1, 1		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 5
			add $a0, $a0, $t2	# px		
			li $a1, 1		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 6
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 7
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 9
			add $a0, $a0, $t2	# px		
			li $a1, 3		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 13
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 12
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			
			j return_draw_cur_digit
		
		if_draw_five:
			bne $t0, 5, if_draw_six	
			
			li $a0, 0		# 1
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 2
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 3
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 4
			add $a0, $a0, $t2	# px		
			li $a1, 1		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 6
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 7
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 13
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 9
			add $a0, $a0, $t2	# px		
			li $a1, 3		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 10
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 11
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 12
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			j return_draw_cur_digit
		
		if_draw_six:
			bne $t0, 6, if_draw_seven
			
			li $a0, 0		# 1
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 2
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 3
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 4
			add $a0, $a0, $t2	# px		
			li $a1, 1		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 6
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 7
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 13
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 9
			add $a0, $a0, $t2	# px		
			li $a1, 3		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 10
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 11
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 12
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 8
			add $a0, $a0, $t2	# px		
			li $a1, 3		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			j return_draw_cur_digit
			
		if_draw_seven:
			bne $t0, 7, if_draw_eight
			
			li $a0, 0		# 1
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 2
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 3
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 5
			add $a0, $a0, $t2	# px		
			li $a1, 1		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 7
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 9
			add $a0, $a0, $t2	# px		
			li $a1, 3		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 12
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			j return_draw_cur_digit
			
		if_draw_eight:
			bne $t0, 8, if_draw_nine
			
			li $a0, 0		# 1
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 2
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 3
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 4
			add $a0, $a0, $t2	# px		
			li $a1, 1		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 5
			add $a0, $a0, $t2	# px		
			li $a1, 1		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 6
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 7
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 8
			add $a0, $a0, $t2	# px		
			li $a1, 3		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 9
			add $a0, $a0, $t2	# px		
			li $a1, 3		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 10
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 11
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 12
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 13
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			j return_draw_cur_digit				
				
		if_draw_nine:
			
			li $a0, 0		# 1
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 2
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 3
			add $a0, $a0, $t2	# px		
			li $a1, 0		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 4
			add $a0, $a0, $t2	# px		
			li $a1, 1		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 5
			add $a0, $a0, $t2	# px		
			li $a1, 1		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 0		# 6
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 7
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 9
			add $a0, $a0, $t2	# px		
			li $a1, 3		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 2		# 12
			add $a0, $a0, $t2	# px		
			li $a1, 4		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			li $a0, 1		# 13
			add $a0, $a0, $t2	# px		
			li $a1, 2		# py
			jal function_get_obsolute_offset
			add $v0, $v0, $s0
			sw $s1, 0($v0)
			
			j return_draw_cur_digit
	return_draw_cur_digit:
		jr $s2
	
	
func_get_char:
	li $t0, 0xffff0000 # memory address of the first value
	lw $t1, 0($t0)
	bnez $t1, not_zero
		li $v0, 0
		jr $ra
	not_zero:
		lw $v0, 4($t0) # load the second value to $t2	
	jr $ra


func_draw_sky: 	# paint the whole screen 
#a0 color
	li $t4, 1095
	move $t5, $a0	# move $a0 to $t5
	lw $t0, displayAddress	# $t0 stores the base address for display
	sw $t5, 0($t0)
	
	WHILE_sky:
		beqz $t4, DONE_sky   # if $t4 is 0, exits the while loop
		addi $t0, $t0, 4
		sw $t5, 0($t0)
		   
		addi $t4, $t4, -1 
		j WHILE_sky
	DONE_sky:
	jr $ra
	

func_draw_obstacles:
# a0 a1 a2 a3
	
	move $t7, $ra
	lw $s7, displayAddress 
	lw $s6, green
	li $s5, 32
	li $s4, 4
	move $s0, $a0	# move $a0 to $t5, $a0 = px0 static
	move $s1, $a1	# move $a1 to $t1, $a1 = px1
	move $s2, $a2	# move $a2 to $t2, $a2 = py0
	move $s3, $a3	# move $a3 to $t3, $a3 = py1
	
	move $t0, $a0		# px start point
	move $t1, $a1		# px end point
	move $t2, $a2		# up length
	move $t3, $a3		# down length
		
	WHILE_OBSTACLE_1:
		beq $t0, $s1, DONE_OBSTACLE_1   # if $a0 = $a1, exits the while loop
		move $t2, $s2			# draw from left down side to left top side
		WHILE_OBSTACLE_COL:
			bltz, $t2, DONE_OBSTACLE_COL	#terminate if pass the first row
			
			#call function to get offset
			move $a0, $t0	# $t0 = px0
			move $a1, $t2	# $t2 = py0
			jal function_get_obsolute_offset
			# return value = $v0
			
			# once get offset, apply it to start point s7
			add $v0, $v0, $s7	# $t9 = (py0 * 32 + px0) * 4 + $s7
			sw $s6, 0($v0)
			
			addi, $t2, $t2, -1	# $py0 -= 1
			j WHILE_OBSTACLE_COL
			
		DONE_OBSTACLE_COL:
			addi $t0, $t0, 1
			j WHILE_OBSTACLE_1
		
	DONE_OBSTACLE_1:
	
	move $t0, $s0   # start px  = a0
	li $t2, 31 	# start py
	sub $t8, $t2, $s3 # end py 31 - down_length

	WHILE_OBSTACLE_2:
	# 4 * (32*py + px)
		# check if to meet end px: a1
		beq $t0, $s1, DONE_OBSTACLE_2   # if $a0 = $a1, exits the while loop
		li $t2, 31 	# start py
		WHILE_OBSTACLE_COL_2:
			blt, $t2, $t8, DONE_OBSTACLE_COL_2
			
			#call function to get offset
			move $a0, $t0	# $t0 = px0
			move $a1, $t2	# $t3 = py1
			jal function_get_obsolute_offset
			# return value = $v0
			
			# once get offset, apply it to start point s7
			add $v0, $v0, $s7	
			sw $s6, 0($v0)
			
			addi, $t2, $t2, -1	# $py1 -= 1
			j WHILE_OBSTACLE_COL_2
			
		DONE_OBSTACLE_COL_2:
			addi $t0, $t0, 1
			j WHILE_OBSTACLE_2
		
	DONE_OBSTACLE_2:
	jr $t7


func_cover_sky:
# a0 a1 a2 a3
	
	move $t7, $ra
	lw $s7, displayAddress 
	lw $s6, blue
	li $s5, 32
	li $s4, 4
	move $s0, $a0	# move $a0 to $t5, $a0 = px0 static
	move $s1, $a1	# move $a1 to $t1, $a1 = px1
	move $s2, $a2	# move $a2 to $t2, $a2 = py0
	move $s3, $a3	# move $a3 to $t3, $a3 = py1
	
	move $t0, $a0		# px start point
	move $t1, $a1		# px end point
	move $t2, $a2		# up length
	move $t3, $a3		# down length
		
	WHILE_sky_1:
		beq $t0, $s1, DONE_sky_1   # if $a0 = $a1, exits the while loop
		move $t2, $s2			# draw from left down side to left top side
		WHILE_sky_COL:
			bltz, $t2, DONE_sky_COL	#terminate if pass the first row
			
			#call function to get offset
			move $a0, $t0	# $t0 = px0
			move $a1, $t2	# $t2 = py0
			jal function_get_obsolute_offset
			# return value = $v0
			
			# once get offset, apply it to start point s7
			add $v0, $v0, $s7	# $t9 = (py0 * 32 + px0) * 4 + $s7
			sw $s6, 0($v0)
			
			addi, $t2, $t2, -1	# $py0 -= 1
			j WHILE_sky_COL
			
		DONE_sky_COL:
			addi $t0, $t0, 1
			j WHILE_sky_1
		
	DONE_sky_1:
	
	move $t0, $s0   # start px  = a0
	li $t2, 31 	# start py
	sub $t8, $t2, $s3 # end py 31 - down_length

	WHILE_sky_2:
	# 4 * (32*py + px)
		# check if to meet end px: a1
		beq $t0, $s1, DONE_sky_2   # if $a0 = $a1, exits the while loop
		li $t2, 31 	# start py
		WHILE_sky_COL_2:
			blt, $t2, $t8, DONE_sky_COL_2
			
			#call function to get offset
			move $a0, $t0	# $t0 = px0
			move $a1, $t2	# $t3 = py1
			jal function_get_obsolute_offset
			# return value = $v0
			
			# once get offset, apply it to start point s7
			add $v0, $v0, $s7	
			sw $s6, 0($v0)
			
			addi, $t2, $t2, -1	# $py1 -= 1
			j WHILE_sky_COL_2
			
		DONE_sky_COL_2:
			addi $t0, $t0, 1
			j WHILE_sky_2
		
	DONE_sky_2:
	jr $t7
	
	
function_draw_bird1:
#start_point # a0 = py
# px = 5
	move $t2, $ra
	lw $s0, pink
	lw $s1, displayAddress
	li $s2, 5	# $s2 = px
	move $s3, $a0	# $s3 = py
	li $s5, 32
	li $s4, 4
	
	# check if the current value is obstacles
	lw $t6, green
	
	# last col upper
	move $a0, $s2		# $a0 = 5
	addi $t0, $s3, -1	# $t0 = py - 1
	move $a1, $t0		# $a1 = $t0
	jal function_get_obsolute_offset
	add $v0, $v0, $s1	
	lw $t5, 0($v0)
	beq $t5, $t6, Exit
	sw $s0, 0($v0)	
	
	# last col middle
	move $a0, $s2
	move $a1, $s3
	jal function_get_obsolute_offset
	add $v0, $v0, $s1
	lw $t5, 0($v0)
	beq $t5, $t6, Exit	
	sw $s0, 0($v0)
	
	# last col lower
	move $a0, $s2
	addi $t0, $s3, 1
	move $a1, $t0
	jal function_get_obsolute_offset
	add $v0, $v0, $s1
	lw $t5, 0($v0)
	beq $t5, $t6, Exit	
	sw $s0, 0($v0)	
	
	# middle connect pont
	addi $t0, $s2, 1
	move $a0, $t0
	move $a1, $s3
	jal function_get_obsolute_offset
	add $v0, $v0, $s1
	lw $t5, 0($v0)
	beq $t5, $t6, Exit	
	sw $s0, 0($v0)
	
	# front col upper
	addi $t0, $s2, 2
	move $a0, $t0
	addi $t1, $s3, -1
	move $a1, $t1
	jal function_get_obsolute_offset
	add $v0, $v0, $s1
	lw $t5, 0($v0)
	beq $t5, $t6, Exit	
	sw $s0, 0($v0)	
	
	# front col middle
	addi $t0, $s2, 2
	move $a0, $t0
	move $a1, $s3
	jal function_get_obsolute_offset
	add $v0, $v0, $s1
	lw $t5, 0($v0)
	beq $t5, $t6, Exit	
	sw $s0, 0($v0)	
	
	# front col lower
	addi $t0, $s2, 2
	move $a0, $t0
	addi $t0, $s3, 1
	move $a1, $t0
	jal function_get_obsolute_offset
	add $v0, $v0, $s1
	lw $t5, 0($v0)
	beq $t5, $t6, Exit	
	sw $s0, 0($v0)
	
	# front
	addi $t0, $s2, 3
	move $a0, $t0
	move $a1, $s3
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1
	lw $t5, 0($v0)
	beq $t5, $t6, Exit	
	sw $s0, 0($v0)	
	
	jr $t2

function_cover_bird1:
#start_point # a0 = py
# px = 5
	move $t2, $ra
	lw $s0, blue
	lw $s1, displayAddress
	li $s2, 5	# $s2 = px
	move $s3, $a0	# $s3 = py
	li $s5, 32
	li $s4, 4
	
	# last col upper
	move $a0, $s2		# $a0 = 5
	addi $t0, $s3, -1	# $t0 = py - 1
	move $a1, $t0		# $a1 = $t0
	jal function_get_obsolute_offset
	add $v0, $v0, $s1	
	sw $s0, 0($v0)	
	
	# last col middle
	move $a0, $s2
	move $a1, $s3
	jal function_get_obsolute_offset
	add $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	# last col lower
	move $a0, $s2
	addi $t0, $s3, 1
	move $a1, $t0
	jal function_get_obsolute_offset
	add $v0, $v0, $s1	
	sw $s0, 0($v0)	
	
	# middle connect pont
	addi $t0, $s2, 1
	move $a0, $t0
	move $a1, $s3
	jal function_get_obsolute_offset
	add $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	# front col upper
	addi $t0, $s2, 2
	move $a0, $t0
	addi $t1, $s3, -1
	move $a1, $t1
	jal function_get_obsolute_offset
	add $v0, $v0, $s1	
	sw $s0, 0($v0)	
	
	# front col middle
	addi $t0, $s2, 2
	move $a0, $t0
	move $a1, $s3
	jal function_get_obsolute_offset
	add $v0, $v0, $s1	
	sw $s0, 0($v0)	
	
	# front col lower
	addi $t0, $s2, 2
	move $a0, $t0
	addi $t0, $s3, 1
	move $a1, $t0
	jal function_get_obsolute_offset
	add $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	# front
	addi $t0, $s2, 3
	move $a0, $t0
	move $a1, $s3
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)	
	
	jr $t2

function_draw_bird2:
#start_point # a0 = py
# px = 5
	move $t2, $ra
	lw $s0, yellow
	lw $s1, displayAddress
	li $s2, 10	# $s2 = px
	move $s3, $a0	# $s3 = py
	li $s5, 32
	li $s4, 4
	
	# check if the current value is obstacles
	lw $t6, green
	
	# last col upper
	move $a0, $s2		# $a0 = 10
	addi $t0, $s3, -1	# $t0 = py - 1
	move $a1, $t0		# $a1 = $t0
	jal function_get_obsolute_offset
	add $v0, $v0, $s1	
	lw $t5, 0($v0)
	beq $t5, $t6, Exit
	sw $s0, 0($v0)	
	
	# last col middle
	move $a0, $s2
	move $a1, $s3
	jal function_get_obsolute_offset
	add $v0, $v0, $s1
	lw $t5, 0($v0)
	beq $t5, $t6, Exit	
	sw $s0, 0($v0)
	
	# last col lower
	move $a0, $s2
	addi $t0, $s3, 1
	move $a1, $t0
	jal function_get_obsolute_offset
	add $v0, $v0, $s1
	lw $t5, 0($v0)
	beq $t5, $t6, Exit	
	sw $s0, 0($v0)	
	
	# middle connect pont
	addi $t0, $s2, 1
	move $a0, $t0
	move $a1, $s3
	jal function_get_obsolute_offset
	add $v0, $v0, $s1
	lw $t5, 0($v0)
	beq $t5, $t6, Exit	
	sw $s0, 0($v0)
	
	# front col upper
	addi $t0, $s2, 2
	move $a0, $t0
	addi $t1, $s3, -1
	move $a1, $t1
	jal function_get_obsolute_offset
	add $v0, $v0, $s1
	lw $t5, 0($v0)
	beq $t5, $t6, Exit	
	sw $s0, 0($v0)	
	
	# front col middle
	addi $t0, $s2, 2
	move $a0, $t0
	move $a1, $s3
	jal function_get_obsolute_offset
	add $v0, $v0, $s1
	lw $t5, 0($v0)
	beq $t5, $t6, Exit	
	sw $s0, 0($v0)	
	
	# front col lower
	addi $t0, $s2, 2
	move $a0, $t0
	addi $t0, $s3, 1
	move $a1, $t0
	jal function_get_obsolute_offset
	add $v0, $v0, $s1
	lw $t5, 0($v0)
	beq $t5, $t6, Exit	
	sw $s0, 0($v0)
	
	# front
	addi $t0, $s2, 3
	move $a0, $t0
	move $a1, $s3
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1
	lw $t5, 0($v0)
	beq $t5, $t6, Exit	
	sw $s0, 0($v0)	
	
	jr $t2

function_cover_bird2:
#start_point # a0 = py
# px = 10
	move $t2, $ra
	lw $s0, blue
	lw $s1, displayAddress
	li $s2, 10	# $s2 = px
	move $s3, $a0	# $s3 = py
	li $s5, 32
	li $s4, 4
	
	# last col upper
	move $a0, $s2		# $a0 = 10
	addi $t0, $s3, -1	# $t0 = py - 1
	move $a1, $t0		# $a1 = $t0
	jal function_get_obsolute_offset
	add $v0, $v0, $s1	
	sw $s0, 0($v0)	
	
	# last col middle
	move $a0, $s2
	move $a1, $s3
	jal function_get_obsolute_offset
	add $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	# last col lower
	move $a0, $s2
	addi $t0, $s3, 1
	move $a1, $t0
	jal function_get_obsolute_offset
	add $v0, $v0, $s1	
	sw $s0, 0($v0)	
	
	# middle connect pont
	addi $t0, $s2, 1
	move $a0, $t0
	move $a1, $s3
	jal function_get_obsolute_offset
	add $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	# front col upper
	addi $t0, $s2, 2
	move $a0, $t0
	addi $t1, $s3, -1
	move $a1, $t1
	jal function_get_obsolute_offset
	add $v0, $v0, $s1	
	sw $s0, 0($v0)	
	
	# front col middle
	addi $t0, $s2, 2
	move $a0, $t0
	move $a1, $s3
	jal function_get_obsolute_offset
	add $v0, $v0, $s1	
	sw $s0, 0($v0)	
	
	# front col lower
	addi $t0, $s2, 2
	move $a0, $t0
	addi $t0, $s3, 1
	move $a1, $t0
	jal function_get_obsolute_offset
	add $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	# front
	addi $t0, $s2, 3
	move $a0, $t0
	move $a1, $s3
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)	
	
	jr $t2

function_end_screen:
	
	lw $a0, exit_screen
	jal func_draw_sky
	
	lw $a0, curr_score
	lw $a1, exit_score
	jal func_draw_score

	lw $s0, exit_bye
	lw $s1, displayAddress
	# B
	li $a0, 4
	li $a1, 12
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 4
	li $a1, 13
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 4
	li $a1, 14
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 4
	li $a1, 15
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 4
	li $a1, 16
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 4
	li $a1, 17
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 4
	li $a1, 18
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 4
	li $a1, 19
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 4
	li $a1, 20
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 5
	li $a1, 12
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 6
	li $a1, 12
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 7
	li $a1, 12
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 8
	li $a1, 12
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 9
	li $a1, 13
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 9
	li $a1, 14
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 9
	li $a1, 15
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 5
	li $a1, 16
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 6
	li $a1, 16
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 7
	li $a1, 16
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 8
	li $a1, 16
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 9
	li $a1, 17
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 9
	li $a1, 18
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 9
	li $a1, 19
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 5
	li $a1, 20
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 6
	li $a1, 20
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 7
	li $a1, 20
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 8
	li $a1, 20
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	# Y
	li $a0,11
	li $a1, 12
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 12
	li $a1, 13
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 13
	li $a1, 14
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 17
	li $a1, 12
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 16
	li $a1, 13
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 15
	li $a1, 14
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 14
	li $a1, 15
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 14
	li $a1, 16
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 14
	li $a1, 17
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 14
	li $a1, 18
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 14
	li $a1, 19
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 14
	li $a1, 20
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	# E
	li $a0, 19
	li $a1, 12
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 20
	li $a1, 12
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 21
	li $a1, 12
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 22
	li $a1, 12
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 23
	li $a1, 12
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 19
	li $a1, 13
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 19
	li $a1, 14
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 19
	li $a1, 15
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 19
	li $a1, 16
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 19
	li $a1, 17
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 19
	li $a1, 18
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 19
	li $a1, 19
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 19
	li $a1, 20
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 20
	li $a1, 16
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 21
	li $a1, 16
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 22
	li $a1, 16
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 23
	li $a1, 16
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 20
	li $a1, 20
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 21
	li $a1, 20
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 22
	li $a1, 20
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 23
	li $a1, 20
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	# !
	li $a0, 27
	li $a1, 12
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 27
	li $a1, 13
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 27
	li $a1, 14
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 27
	li $a1, 15
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 27
	li $a1, 16
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 27
	li $a1, 17
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 28
	li $a1, 12
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 28
	li $a1, 13
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 28
	li $a1, 14
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 28
	li $a1, 15
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 28
	li $a1, 16
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 28
	li $a1, 17
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 27
	li $a1, 19
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 28
	li $a1, 19
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 27
	li $a1, 20
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	li $a0, 28
	li $a1, 20
	jal function_get_obsolute_offset
	addu $v0, $v0, $s1	
	sw $s0, 0($v0)
	
	
	
	jr $ra
	
function_get_obsolute_offset:
# a0 = x, a1 = y
	li $s5, 32
	li $s4, 4
	
	mult $s5, $a1	# $s5 = 32
	mflo $a1	
	add $a0, $a1, $a0	# $t5 = py * 32 + px
	mult $a0, $s4	# $t4 = 4
	mflo $v0	# $t5 = (py * 32 + px) * 4
	
	jr $ra		
	
Exit:
	jal function_end_screen
	li $v0, 10 # terminate the program gracefully
	syscall
	
