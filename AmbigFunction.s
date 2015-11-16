*	William Kelly
* * * * * * * * * * * * * * * * * * * * * * * * *
* (Tab Size = 4)
*
* An exercise in translating an ambiguous		
* function F from Java to m68000 Assembly. 		
*												
* Key Elements:									
*	Multilevel recursion					
*	Storing variables on system stack		
*													
*	*denotes a comment							
*	dn where n = 1 to 7 are data registers		
*	an where n = 1 to 7 are address registers	
*		a7 used as address pointer			
*		a6 used as local helper address pointer 
*		d0 designated as return data register  
*												
* Additional references for m68000:	
*    http://www.mathcs.emory.edu/~cheung/Courses
*       /255/Syllabus/7-M68000/M68000-instr.html 
*												
* * * * * * * * * * * * * * * * * * * * * * * * * 
* Java method to be translated:				 	
*												
* int F(int i, int j, int k) {				
*												
*	 int s, t;								
*												
* 	 if ( i <= 0 || j <= 0 ){				
* 		 return(-1);							
*	 }										
*												
*	 else if ( i + j < k ){					
*        return (i+j);						
*	 }										
*												
*    else {									
*		 s = 0;								
*        for (t = 1; t < k; t++){			
*        	 s = s + F(i-t, j-t, k-1) + 1;   
*        }									
*        return(s);							
*	 }		
* }											
* * * * * * * * * * * * * * * * * * * * * * * * *

F:
	
*--------------------------------------------------------------------
*	Setup local variables
*--------------------------------------------------------------------
	move.l 	a6, -(a7)	*Saving a6 from caller subroutine
	move.l 	a7, a6		*Setup a6 to access local vars and params	
	suba.l	#8, a7		*Create space for local variables
*====================================================================


*--------------------------------------------------------------------
*	if (i <= 0 || j <= 0){
* 		return(-1);					
*	}
*--------------------------------------------------------------------
If:
	move.l	16(a6), d1	*d1 = i
	move.l	12(a6), d2	*d2 = j
	
	cmp.l	#0, d1		
	ble		Negative	*if(i <= 0) branch to Negative
	
	cmp.l	#0, d2				
	bgt		ElseIf		*if(j > 0) branch to ElseIf

Negative:
	move.l	#-1, d0		*i or j is negative, set to return
	bra 	Return
*====================================================================


*--------------------------------------------------------------------
*	else if ( i + j < k ){					
*   		return (i+j);						
*	}					
*--------------------------------------------------------------------
ElseIf:	
	move.l 	d1, d3		
	add.l	d2, d3		*d3 = i + j
	
	move.l	8(a6), d4	*d4 = k

	cmp.l	d4, d3		*branch if(i+j >= k)
	bge		Else

	move.l	d3, d0		*sets i + j to be returned 
	bra 	Return
*====================================================================


*--------------------------------------------------------------------
*	else{									
*        s = 0;								
*        for (t = 1; t < k; t++){			
*        	s = s + F(i-t, j-t, k-1) + 1;              
*      	 }									
*   	 return(s);							
*   }	
*--------------------------------------------------------------------
Else:
	move.l	#0, -8(a6)	*s = 0
	move.l	#1, -4(a6)	*t = 1
	
	
While: 
	move.l 	8(a6), d4	*d4 = k
	move.l 	-4(a6), d5	*d5 = t
	cmp.l	d4, d5		*exit while loop if t >= k
	bge 	WhileEnd


	*----------------------------------------------------------------
	*	s = s + F( i-t, j-t, k-1) + 1 		
	*----------------------------------------------------------------
	*Sets up values to call F

		move.l	16(a6), d1	*moves i into d1
		sub.l	-4(a6), d1	*d1 = i - t	 

		move.l	12(a6), d2 	*moves j into d2
		sub.l	-4(a6), d2	*d2 = j - t
		
		move.l	8(a6), d4	*moves k into d4
		sub.l	#1, d4		*d4 = k - 1 
		
	*Pushes values from registers to stack

		move.l	d1, -(a7)	*pushes i-t on stack
		move.l	d2, -(a7)	*pushed j-t on stack
		move.l	d4, -(a7)	*pushes k-1 on stack 
		bsr 	F			*calls F
		adda.l	#12, a7		*moves stack pointer
							*answer now in d0		

	*Adds return value to s

		add.l	-8(a6), d0	*adds s to d0	
		add.l	#1, d0		*adds 1 to d0
		move.l	d0, -8(a6)	*moves s + F(i-t,j-t,k-1) + 1 into s

	*Increments t on system stack
	
		move.l	-4(a6), d5	
		add.l	#1, d5		
		move.l	d5, -4(a6)	*t = t + 1

		bra	While 			
	*================================================================

WhileEnd:
	move.l -8(a6), d0	*sets s to be returned
*====================================================================

*--------------------------------------------------------------------
*	Return routine
*--------------------------------------------------------------------
Return:	
	movea.l a6, a7		*Remove local variables
	movea.l (a7)+, a6	*Restore caller's frame pointer
	rts
*====================================================================


end
