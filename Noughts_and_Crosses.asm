
	asect 0xf3
IOReg: # Gives the address 0xf3 the symbolic name IOReg - Holds the id of the button
	
	asect 0xf0
stack: # Gives the address 0xf0 the symbolic name stack
	
	asect 0x00
table: # each triplet below represents a line of three cells
	dc 0,1,2 # horizontal lines
	dc 4,5,6
	dc 8,9,10
	dc 0,4,8 # vertical lines
	dc 1,5,9
	dc 2,6,10
	dc 0,5,10 # diagonal lines
	dc 8,5,2

start:
	ldi r0,stack
	stsp r0 # Sets the initial value of SP to 0xf0
	
readbtn:
	ldi r0, IOReg # Load the button id in r0
	do # Begin the btn read loop
		ld r0,r1 	#r1 = button id			
	tst r1 		# check data has been sent from button
	until pl 	
		
	jsr storebtn
	
	br readbtn
	
	
storebtn:	# (r1=button id)
	ldi r0, IOReg # Load the button id in r0
	ld r1, r2		# r2 = existing symbol id
	
	if
		tst r2
	is eq
		move r1, r3	# r3 = new symbol id
		shl r3
		shl r3	# shift symbol coordinates two places
		inc r3	# r3 = symbol coordinates and id
		st r1,r3	# store cross id in memory location for gamepad cell
		
		push r3	# save existing data
		push r1	# save memory location
		# save data and memory location to free up 
		# registers for use in subroutine
		jsr checkgamestate
		ldi r0, IOReg # Load the button id in r0
		pop r1	# retrieve memory location
		pop r3	# retrieve existing data
	
		add r2, r3	# r3 = game score, symbol coordinates and id
		
		st r1,r3	# store cross id in memory location for gamepad cell
		st r0, r3	# load symbol id into gamepad
		
		if
			tst r2	# check game still in progress
		is eq
			jsr computermove
		fi
	
	fi
	
	
	
	rts
	
	
checkgamestate:
	ldi r3, 24	# table array length
	ldi r0, 0	# current array position
	
	ldi r1, 0	# filled cell counter
	
	while
		cmp r0, r3	# while not end of array
	stays lt
		push r3	# save table array length
		ldi r3, 0	# r3 = current row counter
		
		jsr checkcelldata
		inc r0	# move along array
		
		jsr checkcelldata
		inc r0	# move along array
		
		jsr checkcelldata
		inc r0
		
		if
			ldi r2, 3	# check player wins
			cmp r2, r3
		is eq,
			pop r3	# retrieve table array length
			ldi r2, 0b01000000
			break
		else
			if
				ldi r2, -3	# check AI wins
				cmp r2, r3
			is eq,
				pop r3	# retrieve table array length
				ldi r2, 0b10000000
				break
			fi		
		fi
		pop r3
	wend
	
	
	if
		ldi r3, 0b01000000	# game not won
		cmp r2, r3
	is ne, and
		ldi r3, 0b10000000	# game not lost
		cmp r2, r3
	is ne
		if
			ldi r0, 24	# all cells filled
			cmp r1, r0
		is eq
			ldi r2, 0b11000000	# game is a draw
		else
			ldi r2, 0b00000000	# game is still in progress
		fi
	fi
	
rts

# r0 = data memory address
# r1 = cell value
# r2 = Symbol mask/ ID check
# r3 = win/lose cell counter
checkcelldata:
		push r1	# save filled cell counter
		ldc r0, r1	# r1 = cell address
		ld r1, r1	# r1 = first cell value
		
		ldi r2, 0b00000011	#AND mask to check for symbol
		and r2, r1			# r1 = first symbol id
		
		if
			ldi r2, 1	# if cross (player) then
			cmp r2, r1
		is eq	
			inc r3	# increment win/lose cell counter (cross = +1)
			pop r1 	# retrieve filled cell counter
			inc r1	# increment filled cell counter
			push r1	# store filled cell counter
		else 
			if
				ldi r2, 2	# if nought (AI) then
				cmp r2, r1
			is eq	
				dec r3	# decrement win/lose cell counter (nought = -1)
				pop r1 	# retrieve filled cell counter
				inc r1	# increment filled cell counter
				push r1	# store filled cell counter
			fi
		fi		
		pop r1	# retrieve filled cell counter	
	rts


computermove:
	
	ldi r3, 24	# table array length
	ldi r0, 0	# current array position
	
	while
		cmp r0, r3	# while not end of array
	stays lt
		ldc r0, r1
		ld r1, r2
		if 
			tst r2	# if cell is blank
		is eq
			
			move r1, r3	# r3 = cell coordinates
			shl r3
			shl r3
			inc r3	# r3 = symbol coordinates and id
			inc r3
			st r1,r3	# store cross id in memory location for gamepad cell
	
			push r1	# save memory location
			jsr checkgamestate
			ldi r0, IOReg # Load the button id in r0
			pop r1	# r1 = memory location
		
			move r1, r3	# r3 = new symbol id
			shl r3
			shl r3
			inc r3	# r3 = symbol coordinates and id
			inc r3
			add r2, r3	# r3 = game score, symbol coordinates and id
		
			st r1,r3	# store cross id in memory location for gamepad cell
			st r0, r3	# load symbol id into gamepad
			break
		else
			inc r0
		fi
		ldi r3, 24
	wend
	
	rts
	
end
