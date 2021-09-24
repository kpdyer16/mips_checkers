	.data
InV:	.asciiz "Found an invalid piece!\n"
cristobal:	.asciiz ": ("
comma:	.asciiz ","
closP:	.asciiz ")"
redM:	.asciiz "Red's move:\n"
whtM:	.asciiz "White's move:\n"
aJmp:	.asciiz "Another jump can be made!\n"
row1:	.asciiz "R1: "
col1:	.asciiz "C1: "
row2:	.asciiz "R2: "
col2:	.asciiz "C2: "
cong:	.asciiz "Congrats, "
whit:	.asciiz "white, "
redd:	.asciiz "red, "
youwon:	.asciiz "you've won!"
notValidRC:		"Invalid r1,c1. Try again.\n"
notValidJump:	"That's not a valid jump. If one of your pieces can make a jump, you must make a jump.\n"
notValidMove:	"That's not a valid move. Please try again.\n"
invConJump:		"Choose a jump location that's valid please.\n"
newLine: 	"\n"
	.globl main
	.code
main:	addi $sp,$sp,-400 # allocate space for board state
	mov $s0,$sp # copy stack pointer to $s0
	mov $a0,$s0
	addi $a1,$0,-100
	jal init
	jal initBoard
	addi $sp,$sp,-768
	mov $s1,$sp # validMoves array
	mov $a0,$sp
	addi $a1,$0,-192
	jal init
	addi $sp,$sp,-768
	mov $s2,$sp # validJumps array
	mov $a0,$sp
	addi $a1,$0,-192
	jal init
	addi $sp,$sp,-40 # holds all relevant variables in main program ############ Make sure I use all 40 bytes or else change the number of bytes I allocate!!!
	mov $t0,$0
	sw $t0,16($sp) # curColor = red
mainGame:	lw $a0,16($sp)
	jal getValidJumps
	sw $v0,20($sp)
	lw $a0,16($sp)
	jal getValidMoves
	sw $v0,24($sp)
	mov $t1,$v0 # $t1 holds movesNum
	lw $t0,20($sp) # $t0 holds jumpsNum
	bne $t0,$0,makeJump
	bne $t1,$0,makeMove
	lw $a0,16($sp)
	jal changeColor # uses color argument held in $a0
	j mainGame
makeJump:	jal pboard
	lw $a0,16($sp)
	jal redOrWhite # prints prompt for the turn of the current user
	lw $a0,16($sp)
	addi $a1,$0,1 # 1 for jump
	jal getUserTuple # filters out invalid r1,c1 and stores tuple on the stack
	jal isValidJump # r1,c1 needs to be filtered because isValidJump can return true on the incorrect color
	bne $v0,$0,1f # if (validJump) -> 1:
	la $a0,notValidJump
	syscall $print_string
	j makeJump
1:	lw $a0,16($sp)
	jal checkIfKing # returns value of piece after the jump
	mov $a0,$v0
	jal doJump # "moves" the actual pieces
	lw $a0,16($sp) 
	jal getValidJumps
	beq $v0,$0,3f
	sw $v0,20($sp) # stores jumpsNum on stack
	lw $a0,8($sp) # get what was originally r2
	lw $a1,12($sp) # ^and c2, and store them as r1,c1
	sw $a0,0($sp)
	sw $a1,4($sp)
	jal ifConsecutiveJumps
	beq $v0,$0,3f # if no consecutive jumps, go to 3
2:	jal pboard
	la $a0,aJmp
	syscall $print_string
	lw $a0,16($sp)
	jal getConsecutiveJump
	jal isValidJump
	bne $v0,$0,b1 # if valid jump, do jump, rinse and repeat
	la $a0,invConJump
	syscall $print_string
	b 2b
3:	jal checkIfWin
	bne $v0,$0,gameOver 
	jal changeColor
	j mainGame
makeMove:	jal pboard
	lw $a0,16($sp)
	jal redOrWhite # prints prompt for the turn of the current user
	lw $a0,16($sp)
	mov $a1,$0 # 0 for move
	jal getUserTuple # filters out invalid r1,c1 and stores tuple on the stack
	jal isValidMove # r1,c1 needs to be filtered because isValidMove can return true on the incorrect color
	bne $v0,$0,1f # if (validMove)  1:{...}
	la $a0,notValidMove
	syscall $print_string
	j makeMove
1:	lw $a0,16($sp)
	jal checkIfKing # returns value of piece after the jump
	mov $a0,$v0
	jal doMove # "moves" the actual piece
	jal changeColor
	j mainGame

gameOver:	la $a0,cong
	syscall $print_string
	lw $t0,16($sp)
	beq $t0,$0,redWon
whiteWon:	la $a0,whit
	syscall $print_string
	b 5f
redWon:	la $a0,redd
	syscall $print_string
5:	la $a0,youwon
	syscall $print_string
exit:	syscall $exit

####
# getConsecutiveJump gets user or computer input
# for getting the next choice for the jump
####
getConsecutiveJump:	addi $sp,$sp,-4
	sw $ra,0($sp)
	bne $a0,$0,10f # if white, then let the computer take care of choosing a tuple
	la $a0,row2
	syscall $print_string
	syscall $read_int
	sw $v0,12($sp)
	la $a0,col2
	syscall $print_string
	syscall $read_int
	sw $v0,16($sp)
	b 99f
10:	lw $t1,4($sp)
	lw $t2,8($sp)
	mov $t0,$s2
11:	lw $t3,0($t0)
	lw $t4,4($t0)
	beq $t1,$t3,12f
	b 15f
12:	beq $t2,$t4,16f
15:	addi $t0,$t0,16
	b 11b
16:	sw $t3,12($sp)
	sw $t4,16($sp)
99:	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra

####
# ifConsecutiveJumps is a function that matches
# the current position against the validJumpTuples 
# list. This function is needed because valid jumps
# can exist while no valid consecutive jump exists
####
ifConsecutiveJumps:	mov $t0,$s2 # validJumpTuples array
	lw $t9,20($sp)
1:	lw $t1,0($t0)
	lw $t2,4($t0)
	beq $a0,$t1,2f
	b 3f
2:	beq $a1,$t2,10f
3:	addi $t9,$t9,-1
	addi $t0,$t0,16
	bne $t9,$0,1b # while there are still valid jump tuples, keep iterating through loop
	mov $v0,$0
	b 99
10: addi $v0,$0,1
99:	jr $ra

####
# changeColor is a function that changes the turn of the current
# player. It stores the changed color in the color slot on the 
# stack
####
changeColor:	lw $t0,16($sp)
	bne $t0,$0,1f # if white, go to 1
	addi $t0,$0,1
	sw $t0,16($sp)
	b 2f
1:	sw $0,16($sp)
2:	jr $ra

####
# checkIfKing looks at the current color
# and sees if r2 is the row that turns 
# a piece of a certain color into a king
# if not, checkIfKing returns the same piece
# that was originally in r1,c1. $a0 = curColor
####
checkIfKing:	addi $sp,$sp,-4
	sw $ra,0($sp)
	mov $s3,$a0
	lw $a0,4($sp)
	lw $a1,8($sp)
	jal getVal
	andi $t1,$v0,4 # if zero, then it was not a king
	bne $t1,$0,endCheckIfKing # if king, then return current value
	lw $t1,12($sp) # get r2
	bne $s3,$0,1f # if color is white, go to 1
	addi $t0,$0,9
	bne $t0,$t1,endCheckIfKing # if r2 != 9, return current value
	addi $v0,$0,5
	j endCheckIfKing
1:	bne $t1,$0,endCheckIfKing # if r2 != 0, return current value
	addi $v0,$0,7 
endCheckIfKing:	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra

####
# rand is a function that returns a random number
# This function makes a syscall $random, and runs 
# that number through the lfsr 8 times and returns
# the resulting number in $v0
####
rand:	addi $sp,$sp,-4
	sw $ra,0($sp)
	addi $t9,$0,8
	syscall $random
1:	mov $a0,$v0 # state = lfsr(state)
	jal lfsr
	bne $t9,$0,1b # b if count > 0
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra

lfsr:	li $t0,0x1200000 # lfsr taps
	andi $t2,$a0,1 # (state & 0x1)
	nor $t2,$t2,$0 # ~(state & 0x1)
	addi $t2,$t2,1 # -(state & 0x1)
	and $t2,$t0,$t2 # (-(state & -0x1) & taps)
	srl $t3,$a0,1 # (state >> 1)
	xor $v0,$t2,$t3
	jr $ra

####
# getUserTuple is a function that
# prompts the user for r1,c1, and
# r2,c2. If r1,c1 don't match the 
# current color, getUserTuple will
# make sure the user inputs them again
# NOTE: This version of the function uses 
# white as the computer. 
####
getUserTuple:	addi $sp,$sp,-4
	sw $ra,0($sp)
	mov $s4,$a1 # in case it is the computer's turn
	bne $a0,$0,10f # if white, then let the computer take care of choosing a tuple
	mov $s4,$a0 # move $a0 to $s4 for later use
1:	la $a0,row1
	syscall $print_string
	syscall $read_int
	mov $t0,$v0
	la $a0,col1
	syscall $print_string
	syscall $read_int
	mov $t1,$v0
	mov $a0,$t0
	mov $a1,$t1
	jal getVal
	andi $t5,$v0,3 # get last two bits
	addi $t6,$t0,1
	beq $t5,$t6,2f # if 1, it is red. if not, then get r1,c1 again
	la $a0,notValidRC
	syscall $print_string
	b 1b
2:	sw $t0,4($sp)
	sw $t1,8($sp)
	la $a0,row2
	syscall $print_string
	syscall $read_int
	sw $v0,12($sp)
	la $a0,col2
	syscall $print_string
	syscall $read_int
	sw $v0,16($sp)
	j endGetUserTuple
10:	jal rand
	mov $t2,$v0
	bne $s4,$0,11f # if 0, look through list of moveTuples
	lw $t1,28($sp)
	mov $t0,$s1
	remu $t1,$t2,$t1 # $t1 = random % movesNum
	b 15f
11:	# if 1, look through list of jumpTuples
	lw $t1,24($sp)
	mov $t0,$s2
	remu $t1,$t2,$t1 # $t1 = random % jumpsNum
15:	sll $t1,$t1,4 # sll by 4 because each variable holds 4 bytes, and there's 4 variables per tuple
	add $t0,$t0,$t1 # add offset to $t0 to get desired tuple
	lw $t2,0($t0) # get tuple
	lw $t3,4($t0)
	lw $t4,8($t0)
	lw $t5,12($t0)
	sw $t2,4($sp) # store tuple in userTuple. this serves as computer's move
	sw $t3,8($sp)
	sw $t4,12($sp)
	sw $t5,16($sp)
endGetUserTuple:	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra

####
# redOrWhite is a function that prints
# either "Red's move:\n" or "White's move:\n"
# It's purely for visual purposes. It takes 
# an argument (color) in $a0
####
redOrWhite: mov $t0,$a0
	beq $t0,$0,1f
	la $a0,whtM
	syscall $print_string
	b 2f
1:	la $a0,redM
	syscall $print_string
2:	jr $ra

####
# init is the initializer for empty arrays. 
# It sets each element in the array to 0.
####
init:	mov $t0,$a0 # copy address of array to $t0
	add $t7,$0,$a1 # holds index in the array
iLoop:	sw $0,0($t0) # set current element to 0
	addi $t0,$t0,4 # get next element in the array
	addi $t7,$t7,1 # increment index
iTest:	bne $t7,$0,iLoop # keep looping until index is equal to 0
	jr $ra

####
# initBoard sets the board up with the correct
# pieces for starting the game. 
####
initBoard:	addi $sp,$sp,-4
	sw $ra,0($sp)
	mov $t1,$0 # row = 0 
	mov $t2,$0 # col = 0
	addi $t3,$0,3 # for comparison
	addi $t4,$0,10 # for comparison
redInit:	mov $a0,$t1
	mov $a1,$t2
	jal isLegalPosition
	beq $v0,$0,redInitTest
	addi $a2,$0,1
	jal storeVal
redInitTest:	addi $t2,$t2,1 # col++
	bne $t2,$t4,redInit
	mov $t2,$0 # col = 0
	addi $t1,$t1,1 # row++
	bne $t1,$t3,redInit
	addi $t5,$0,7 # row = 7
	mov $t2,$0 # col = 0
whiteInit:	mov $a0,$t5
	mov $a1,$t2
	jal isLegalPosition
	beq $v0,$0,whiteInitTest
	addi $a2,$0,3
	jal storeVal
whiteInitTest:	addi $t2,$t2,1 # col++
	bne $t2,$t4,whiteInit
	mov $t2,$0 # col = 0
	addi $t5,$t5,1 # row++
	bne $t5,$t4,whiteInit
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra

####
# The checkIfWin function iterates 
# through the entire array. if it
# can't find one of either color 
# of pieces, then the color with 
# pieces remaining wins. returns 0
# if no win. returns 1 if red or white won
####
checkIfWin:	mov $t0,$s0 # t0 is address of current array index
	mov $t1,$0 # t1 is number of red pieces
	mov $t2,$0 # t2 is number of white pieces
	addi $t9,$0,-100
winLoop:	lw $t5,0($t0)
	beq $t5,$0,next # if value equals 0, go to next space in the board
	andi $t5,$t5,2 # isolates the color bit. if result == 0, then we have a red piece. else, white piece
	beq $t5,$0,addRed
	addi $t2,$t2,1
	j next
addRed:	addi $t1,$t1,1
next:	addi $t0,$t0,4
	addi $t9,$t9,1
winTest:	bne $t9,$0,winLoop
	beq $t1,$0,1f
	beq $t2,$0,1f
	mov $v0,$0
	j endWin
1:	addi $v0,$0,1
endWin:	jr $ra

####
# getVal is the function to get the value
# of a specific space found on the gameboard
# takes arguments in $a0 (row) and $a1 (col)
####
getVal:	sll $a2,$a0,3 # row * 8
	sll $a3,$a0,1 # row * 2
	add $a2,$a2,$a3 # row * 10
	add $a2,$a2,$a1 # row * 10 + col
	sll $a2,$a2,2 # (row * 10 + col) * 4 for offset
	mov $a3,$s0 # get address of gameboard
	add $a3,$a2,$a3 # get address of (row,col) by adding offset
	lw $v0,0($a3)
	jr $ra

####
# storeVal is the function to store a value
# on the board. arguments found in $a0 (row) 
# $a1 (col) and $a2 (value). Uses t-registers
# $t6, and $t7
####
storeVal:	sll $t8,$a0,3 # row * 8
	sll $t9,$a0,1 # row * 2
	add $t8,$t8,$t9 # row * 10
	add $t8,$t8,$a1 # row * 10 + col
	sll $t8,$t8,2 # (row * 10 + col) * 4 for offset
	mov $t9,$s0 # get address of gameboard
	add $t8,$t8,$t9 # get address of (row,col) by adding offset
	sw $a2,0($t8)
	jr $ra

####
# pboard is the function for printing the
# game board. $t0 holds the current address in the array
# $s6 holds the row, $s7 holds the column,
####
pboard:	addi $sp,$sp,-4 # needed for calling getVal
	sw $ra,0($sp) # store current $ra onto stack
	addi $t9,$0,10 # for testing if column is within bounds
	addi $s6,$0,9 # start at row 9
	mov $s7,$0 # start at column 0
pLoop:	add $t0,$s6,$s7 # add row and column together. if sum is odd, black square. else, white
	andi $t0,$t0,0x01 # and with 1 to see if odd or even
	beq $t0,$0,white # if even, print white square
	addi $a0,$0,219 # get black square
	syscall $print_char
	j pTest # jump to next step
white:	mov $a0,$s6 # move row into $a0
	mov $a1,$s7 # move col into $a1
	jal getVal
	mov $t0,$v0 # grab return value and enter it into switch statement
	addi $t1,$0,1 # start switch
	beq $t0,$t1,1f
	addi $t1,$0,3
	beq $t0,$t1,3f
	addi $t1,$0,5
	beq $t0,$t1,5f
	addi $t1,$0,7
	beq $t0,$t1,7f
empty:	addi $a0,$0,32 # print spacebar
	syscall $print_char
	j pTest
1:	addi $a0,$0,114 # print 'r'
	syscall $print_char
	j pTest
3:	addi $a0,$0,119 # print 'w'
	syscall $print_char
	j pTest
5:	addi $a0,$0,82 # print 'R'
	syscall $print_char
	j pTest
7:	addi $a0,$0,87 # print 'W'
	syscall $print_char
pTest:	addi $s7,$s7,1 # get next column
	blt $s7,$t9,pLoop 
	li $a0,newLine
	syscall $print_char
	mov $s7,$0 # reset column to 0 for iterating through next row down
	addi $s6,$s6,-1 # go to next row down
	bgez $s6,pLoop # while (row >= 0)
	lw $ra,0($sp) # get original $ra back
	addi $sp,$sp,4 # pop the stack back
	jr $ra
	
####
# isLegalPosition is the function for checking
# whether a spot is legal. It takes a row and
# column as arguments in $a0 (row) and $a1 (column)
####
isLegalPosition:	mov $v0,$0 # set result to false, change if true
	bltz $a0,endLP # if row is less than 0, end function. isLegalPosition is false
	bltz $a1,endLP # if column " "
	slti $a2,$a0,10 # if row is less than 10, then set to true
	slti $a3,$a1,10 # if column is less than 10, then set to true
	and $a2,$a2,$a3 # if both row and column are valid spaces, set to true
	beq $a2,$0,endLP # if false, end function
	add $a2,$a0,$a1 # add row and column together. if sum is odd, false. else, true
	andi $a2,$a2,0x01 # lsb decides if odd. 
	bgtz $a2,endLP
	addi $v0,$0,1 # isLegalPosition is true
endLP:	jr $ra
	
####
# isValidMove is a function that checks
# whether a desired move is valid or not
# Arguments are found on the stack in this order:
# r1 ($t6), c1 ($t7), r2 ($t8), c2 ($t9)
####
isValidMove:	addi $sp,-4 # allocate space on the stack for saving the return address to leave this function
	sw $ra,0($sp) # store return address onto the stack
	lw $s4,4($sp) # load r1 into $s4
	lw $s5,8($sp) # load c1 into $s5
	lw $s6,12($sp) # load r2 into $s6
	lw $s7,16($sp) # load c2 into $s7
	mov $a0,$s4 # move r1 into $a0 # isLegalPosition function call preparation
	mov $a1,$s5 # move c1 into $a1
	jal isLegalPosition # call isLegalPosition function
	mov $v1,$v0 # move result of first isLegalPositionCall to $v1
	mov $a0,$s6 # move r2 into $a0 # isLegalPosition function call preparation
	mov $a1,$s7 # move c2 into $a1
	jal isLegalPosition # call isLegalPosition function for the next pair of coordinates
	and $t0,$v0,$v1 # and on both return values of isLegalPosition calls. if 1, both are legal positions
	beq $t0,$0,false # if false, end function # Next phase: find out if r1,c1 is a valid piece and if r2,c2 is an empty space
	mov $a0,$s6 # move r2 into $a0 # getVal function call preparation
	mov $a1,$s7 # move c2 into $a1
	jal getVal # check if r2,c2 is empty
	bne $v0,$0,false # if r2,c2 is not an empty space, isValidMove is false 
	mov $a0,$s4 # move r1 into $a0 # getVal function call preparation
	mov $a1,$s5 # move c1 into $a1
	jal getVal # get value of r1,c1
	blez $v0,false # if no piece stored onto space, then isValidMove is false
	sub $t2,$s4,$s6 # r1 - r2 
	sub $t3,$s5,$s7 # c1 - c2
	addi $t0,$0,1
	beq $v0,$t0,isRed # branch if red piece
	addi $t0,$0,3
	beq $v0,$t0,isWht
	andi $t1,$v0,5 # get K and E bits of the value of (r1,c1), currently stored in $v0, and store result in $t1
	addi $t0,$0,5
	beq $t1,$t0,isKng # if K and E bits are on, then it is a king no matter the color
	j false # if nothing branched at this point, then the value is invalid for a game space. jump to false
isRed:	addi $t0,$0,-1
	bne $t0,$t2,false #r1-r2 must equal -1 for a red piece
	beq $t0,$t3,true # if c1-c2 = -1 and we know r1-r2 = -1, then we’ve found a valid move
	addi $t0,$0,1
	beq $t0,$t3,true # c1-c2 = 1 is also valid
	j false
isWht:	addi $t0,$0,1
	bne $t0,$t2,false # r1-r2 must equal 1 for a white piece
	beq $t0,$t3,true # if c1-c2 = 1 and we know r1-r2 = 1, then we’ve found a valid move
	addi $t0,$0,-1
	beq $t0,$t3,true # c1-c2 = -1 is also valid
	j false
isKng:	addi $t4,$0,1
	addi $t5,$0,-1
	beq $t4,$t2,KVert # if king moved down by one row, go to next step
	beq $t5,$t2,KVert # if king moved up by one row, go to next step
	j false # if king moved by more or less than one row, then the move is invalid
KVert:	beq $t4,$t3,true # if c1-c2 = 1
	beq $t5,$t3,true # ^or c1-c2 = -1, then move is valid
	j false # otherwise, move is invalid
true:	addi $v0,$0,1
	j endVM
false:	mov $v0,$0
endVM:	lw $ra,0($sp) # reload return address to leave this function
	addi $sp,$sp,4 # pop the stack back to where it was before this function was called
	jr $ra

####
# isValidJump is a function that checks
# whether a desired jump is legal or not
# Arguments are found on the stack in this order: 
# r1 ($t6), c1 ($t7), r2 ($t8), c2 ($t9)
####
isValidJump:	addi $sp,-4 # allocate space on the stack for saving the return address to leave this function
	sw $ra,0($sp) # store return address onto the stack
	lw $s4,4($sp) # load r1 into $s4
	lw $s5,8($sp) # load c1 into $s5
	lw $s6,12($sp) # load r2 into $s6
	lw $s7,16($sp) # load c2 into $s7
	mov $a0,$s4 # move r1 into $a0 # isLegalPosition function call preparation
	mov $a1,$s5 # move c1 into $a1
	jal isLegalPosition # call isLegalPosition function
	mov $v1,$v0 # move result of first isLegalPositionCall to $v1
	mov $a0,$s6 # move r2 into $a0 # isLegalPosition function call preparation
	mov $a1,$s7 # move c2 into $a1
	jal isLegalPosition # call isLegalPosition function for the next pair of coordinates
	and $t0,$v0,$v1 # and on both return values of isLegalPosition calls. if 1, both are legal positions
	beq $t0,$0,noJump # if false, end function # Next phase: find out if r1,c1 is a valid piece and if r2,c2 is an empty space
	mov $a0,$s6 # move r2 into $a0 # getVal function call preparation
	mov $a1,$s7 # move c2 into $a1
	jal getVal # check if r2,c2 is empty
	bne $v0,$0,noJump # if r2,c2 is not an empty space, isValidJump is false 
	mov $a0,$s4 # move r1 into $a0 # getVal function call preparation
	mov $a1,$s5 # move c1 into $a1
	jal getVal # get value of r1,c1
	blez $v0,noJump # if no piece stored onto space, then isValidJump is false
	mov $t8,$v0
	sub $t2,$s4,$s6 # r1 - r2 
	sub $t3,$s5,$s7 # c1 - c2
	add $t4,$s4,$s6 # r1 + r2
	add $t5,$s5,$s7 # c1 + c2
	srl $a1,$t5,1 # (c1 + c2)/2 ****This block of code is for figuring out the value of the intermediate piece****
	srl $a0,$t4,1 # (r1 + r2)/2 
	jal getVal
	mov $t4,$v0
	addi $t0,$0,1
	beq $t8,$t0,redJ # branch if red piece
	addi $t0,$0,3
	beq $t8,$t0,whtJ # branch if white piece 
	addi $t0,$0,5
	beq $t8,$t0,rKgJ # branch if red king
	addi $t0,$0,7
	beq $t8,$t0,wKgJ # branch if white king
	j noJump # if nothing branched at this point, then the value is invalid for a game space. jump to false
redJ:	addi $t0,$0,-2
	bne $t0,$t2,noJump # r1-r2 must equal -2
	abs $t3,$t3
	addi $t0,$0,2
	bne $t3,$t0,noJump
	andi $t4,$t4,3 # isolate the bits that decide if a checker is there and is a white checker
	addi $t0,$0,3
	beq $t0,$t4,yesJump
	j noJump
whtJ:	addi $t0,$0,2
	bne $t0,$t2,noJump # r1-r2 must equal 2
	abs $t3,$t3
	addi $t0,$0,2 # ****** Note: I could probs just optimize by taking this and putting it before the switch. it'll take out quite a few lines
	bne $t3,$t0,noJump 
	andi $t4,$t4,3 # isolate the lsb. if 1 then that means there's a checker and it is a red checker
	addi $t0,$0,1
	beq $t0,$t4,yesJump
	j noJump
rKgJ:	addi $t0,$0,2
	abs $t2,$t2
	abs $t3,$t3
	bne $t0,$t2,noJump
	bne $t0,$t3,noJump
	andi $t4,$t4,3 # must be white piece, regardless if king or not
	addi $t0,$0,3
	beq $t0,$t4,yesJump
	j noJump
wKgJ:	addi $t0,$0,2
	abs $t2,$t2
	abs $t3,$t3
	bne $t0,$t2,noJump
	bne $t0,$t3,noJump
	andi $t4,$t4,1
	addi $t0,$0,1
	beq $t0,$t4,yesJump
	j noJump	
yesJump:	addi $v0,$0,1
	j endVJ
noJump:	mov $v0,$0
endVJ:	lw $ra,0($sp)	
	addi $sp,$sp,4 # pop the stack back to where it was before this function was called
	jr $ra

####
# doMove performs the actual action
# of moving the pieces on the gameboard
####
doMove:	addi $sp,$sp,-4
	sw $ra,0($sp)
	mov $s3,$a0
	lw $s4,4($sp)
	lw $s5,8($sp)
	lw $s6,12($sp)
	lw $s7,16($sp)
	mov $a0,$s4
	mov $a1,$s5
	mov $a2,$0
	jal storeVal
	mov $a0,$s6
	mov $a1,$s7
	mov $a2,$s3
	jal storeVal
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra
	
####
# doJump does the actual legwork
# of performing a jump on the board
####
doJump:	addi $sp,$sp,-4
	sw $ra,0($sp)
	mov $s3,$a0
	lw $s4,4($sp)
	lw $s5,8($sp)
	lw $s6,12($sp)
	lw $s7,16($sp)
	mov $a0,$s4 # store white space in r1,c1
	mov $a1,$s5
	mov $a2,$0
	jal storeVal
	mov $a0,$s6 # store piece previously in r1,c1 in r2,c2
	mov $a1,$s7
	mov $a2,$s3
	jal storeVal
	add $a0,$s4,$s6 # get space that is in between r1,c1 and r2,c2
	add $a1,$s5,$s7 
	srl $a0,$a0,1 # (r1 + r2) / 2
	srl $a1,$a1,1 # (c1 + c2) / 2
	mov $a2,$0
	jal storeVal # store white space in piece that is jumped over
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra

####
# getValidMoves collects a list of valid
# tuples and returns them through an array
# It takes a tupleList array ($s1), a color ($a0),
# and the board address ($s0) as arguments. 
####
getValidMoves:	mov $v0,$0
	mov $s3,$a0
	sll $s3,$s3,1 # move lsb into second to last bit. if 0, you get 0b00. if 1, you get 0b10
	addi $s3,$s3,1 # add 1. makes comparison easy. if 0, you get 0b01 (red). if 0b10, you get 0b11 (white)
	addi $sp,$sp,-32 # allocate space for the following in this order: isValidMove arguments (4 ints), $t2,$t3,$t4,$ra
	sw $ra,28($sp)
	mov $t9,$s1
	mov $t0,$0 # r1 = 0
	mov $t1,$0 # c1 = 0
	addi $t2,$0,-1 # r2 = -1
	addi $t3,$0,-1 # c2 = -1
	mov $t4,$0 # total = 0
getValidMovesLoop:	sw $t0,0($sp)
	sw $t1,4($sp)
	mov $a0,$t0 # prepare for getVal function call
	mov $a1,$t1
	jal getVal
	andi $v0,$v0,3
	bne $v0,$s3,outerM
	lw $t0,0($sp)
	lw $t1,4($sp)
	add $t5,$t0,$t2 # get r2
	add $t6,$t1,$t3 # get c2
	sw $t5,8($sp) # store r2
	sw $t6,12($sp) # store c2
	sw $t2,16($sp) # store -1 or 1
	sw $t3,20($sp) # store -1 or 1
	sw $t4,24($sp) # store total
	jal isValidMove
	lw $t0,0($sp)
	lw $t1,4($sp)
	lw $t2,16($sp) # recover $t2 for this function's for loops
	lw $t3,20($sp) # recover $t3 for this function's for loops
	lw $t4,24($sp) # recover total number of tuples saved, and load into $t4
	lw $t5,8($sp) # r2     <-get coordinates of space to move to if valid move
	lw $t6,12($sp) # c2
	beq $v0,$0,outerM
	sw $t0,0($t9) # tuples[total][0] = r1
	sw $t1,4($t9) # tuples[total][1] = c1
	sw $t5,8($t9) # tuples[total][2] = r2
	sw $t6,12($t9) # tuples[total][3] = c2
	addi $t9,$t9,16 # go to next 4-tuple
	addi $t4,$t4,1 # total++
	addi $t6,$0,48 # 48 for comparison
	beq $t4,$t6,endGVM
outerM:	lw $t0,0($sp)
	lw $t1,4($sp)
	addi $t5,$0,1 # 1 for comparison
	addi $t3,$t3,2 # c2 += 2
	ble $t3,$t5,getValidMovesLoop
	addi $t3,$0,-1
3:	addi $t2,$t2,2 # r2 += 2
	ble $t2,$t5,getValidMovesLoop
	addi $t2,$0,-1
2:	addi $t1,$t1,1 # c1++
	slti $t8,$t1,10
	bnez $t8,getValidMovesLoop
	mov $t1,$0
1:	addi $t0,$t0,1 # r1++
	slti $t8,$t0,10
	bnez $t8,getValidMovesLoop
endGVM:	lw $ra,28($sp)
	addi $sp,$sp,32 # return $sp back to its state before calling this function
	mov $v0,$t4 # move total number of tuples saved into $v0
	jr $ra

####
# getValidJumps collects a list of valid
# tuples and returns them through an array
# It takes a tupleList array ($s2), a color ($a0),
# and the board address ($s0) as arguments. 
####
getValidJumps:	mov $v0,$0
	mov $s3,$a0
	sll $s3,$s3,1 # move lsb into second to last bit. if 0, you get 0b00. if 1, you get 0b10
	addi $s3,$s3,1 # add 1. makes comparison easy. if 0, you get 0b01 (red). if 0b10, you get 0b11 (white)
	addi $sp,$sp,-32 # allocate space for the following in this order: isValidMove arguments (4 ints), $t2,$t3,$t4,$ra
	sw $ra,28($sp)
	mov $t9,$s2
	mov $t0,$0 # r1 = 0
	mov $t1,$0 # c1 = 0
	addi $t2,$0,-2 # r2 = -2
	addi $t3,$0,-2 # c2 = -2
	mov $t4,$0 # total = 0
getValidJumpsLoop:	sw $t0,0($sp)
	sw $t1,4($sp)
	mov $a0,$t0 # prepare for getVal function call
	mov $a1,$t1
	jal getVal
	andi $v0,$v0,3
	bne $v0,$s3,outerJ
	lw $t0,0($sp)
	lw $t1,4($sp)
	add $t5,$t0,$t2 # get r2
	add $t6,$t1,$t3 # get c2
	sw $t5,8($sp) # store r2
	sw $t6,12($sp) # store c2
	sw $t2,16($sp) # store -2 or 2
	sw $t3,20($sp) # store -2 or 2
	sw $t4,24($sp) # store total
	jal isValidJump
	lw $t0,0($sp)
	lw $t1,4($sp)
	lw $t2,16($sp) # recover $t2 for this function's for loops
	lw $t3,20($sp) # recover $t3 for this function's for loops
	lw $t4,24($sp) # recover total number of tuples saved, and load into $t4
	lw $t5,8($sp) # r2     <-get coordinates of space to move to if valid move
	lw $t6,12($sp) # c2
	beq $v0,$0,outerJ
	sw $t0,0($t9) # tuples[total][0] = r1
	sw $t1,4($t9) # tuples[total][1] = c1
	sw $t5,8($t9) # tuples[total][2] = r2
	sw $t6,12($t9) # tuples[total][3] = c2
	addi $t9,$t9,16 # go to next 4-tuple
	addi $t4,$t4,1 # total++
	addi $t6,$0,48 # 48 for comparison
	beq $t4,$t6,endGVJ
outerJ:	lw $t0,0($sp)
	lw $t1,4($sp)
	addi $t5,$0,2 # 2 for comparison
	addi $t3,$t3,4 # c2 += 4
	ble $t3,$t5,getValidJumpsLoop
	addi $t3,$0,-2
3:	addi $t2,$t2,4 # r2 += 4
	ble $t2,$t5,getValidJumpsLoop
	addi $t2,$0,-2
2:	addi $t1,$t1,1 # c1++
	slti $t8,$t1,10
	bnez $t8,getValidJumpsLoop
	mov $t1,$0
1:	addi $t0,$t0,1 # r1++
	slti $t8,$t0,10
	bnez $t8,getValidJumpsLoop
endGVJ:	lw $ra,28($sp)
	addi $sp,$sp,32 # return $sp back to its state before calling this function
	mov $v0,$t4 # move total number of tuples saved into $v0
	jr $ra

####
# printTuples is a debug function which prints
# the list of valid tuples returned in getTuples
# $a0 holds the address of the tuples list
# $a1 holds the number of tuples held in list
####
printTuples:	mov $t0,$a0
	mov $t1,$a1
	mov $t5,$0
	j pTuplesTest
pTuplesLoop:	addi $t5,$t5,1	
	mov $a0,$t5
	syscall $print_int
	la $a0,cristobal
	syscall $print_string
	lw $a0,0($t0)
	syscall $print_int
	la $a0,comma
	syscall $print_string
	lw $a0,4($t0)
	syscall $print_int
	la $a0,comma
	syscall $print_string
	lw $a0,8($t0)
	syscall $print_int
	la $a0,comma
	syscall $print_string
	lw $a0,12($t0)
	syscall $print_int
	la $a0,closP
	syscall $print_string
	li $a0,newLine
	syscall $print_char
	addi $t0,$t0,16
pTuplesTest:	blt $t5,$t1,pTuplesLoop
	jr $ra

