; #########################################################################

;   -------------------------------------------------------------------
;   Description:
;       This program simulates the capabilities of the DIR command in the 
;       Windows Command Prompt. It display all the contents of the current 
;       directory if there are no filters specified.
;   Author: HunterAgentKat
;   -------------------------------------------------------------------

include \masm32\include\masm32rt.inc

.data
        instruction     db "Enter full path of the folder starting with C:\ and ending with \",13,10,0
        ;szPath         db "C:\masm32\include\",0
        szMask          db "*.*",0
        szMaskC         db "*32*",0
        szFrm           db " ",13,10,0
        fMtStrinG       db "%lu",0
        bytes           db " bytes",0
        space           db "                          ",0
        usageFilter1    db "  (a) All files with (.) extensions",13,10,0
        usageFilter2    db "  (b) All files with particular extension xxx (e.g. exe, dll, etc)",13,10,0
        usageFilter3    db "  (c) All files with (32) in its filename.",13,10,0
        usageFilter4    db "  Choose the letter of choice: ",0
        qFilterB        db "  Enter particular extension *.xxx* (e.g. exe, dll)",0
        err             db "END OF LIST ",13,10,0
        errInvalid      db ".       ERROR: DIRECTORY NOT FOUND ",13,10,0
        errChoice       db "ERROR: INVALID INPUT",13,10,0
        
.data?
        wfd		      WIN32_FIND_DATA <?>
        hWfd	      HANDLE ?
        szSearch        db  MAX_PATH dup(?)
        STR1            db  100 DUP(?)            ; input folder path
        aFilter         db  10 DUP(?)              ; y/n filter
        szPath          db  MAX_PATH DUP(?)
        sizeBuffer      BYTE 16 DUP(?)
.code
start:
        push offset instruction
        call StdOut

        push 255                          
        push offset szPath                  
        call StdIn 
        mov  esi, offset szPath

        MsgBox 0, "Do you want to filter the items?", "Optional", MB_YESNO
	  cmp eax,IDYES
        jnz noFilter

		push offset usageFilter1
            call StdOut
            push offset usageFilter2
            call StdOut
            push offset usageFilter3
            call StdOut
            push offset usageFilter4
            call StdOut
            push 255                          
            push offset aFilter                  
            call StdIn 
            lea  edi, offset aFilter
            MOV  AL, BYTE PTR [edi]                                  
            CMP  AL, 61H
            jz   filterA
            CMP  AL, 62H 
            jz   filterB
            CMP  AL, 63H
            jz   filterC
            jmp  InvalidInput

;################################################################################
noFilter:
        invoke	lstrcpy,addr szSearch,addr szPath
        invoke	lstrcat,addr szSearch,addr szMask

loop1:        
        invoke	FindFirstFile,addr szSearch,addr wfd
    
		.if (eax & eax)
			 mov		hWfd,eax
			 .repeat
                    push offset szFrm
                    call StdOut
                    push offset wfd.cFileName
                    call StdOut
                    push offset space
                    call StdOut
                    invoke wsprintf,ADDR sizeBuffer,ADDR fMtStrinG,wfd.nFileSizeLow
                    push offset sizeBuffer
                    call StdOut
                    push offset bytes
                    call StdOut					 
                    invoke	FindNextFile,hWfd,addr wfd
			 .until (eax == FALSE)
		 .endif
                   push offset szFrm
                   call StdOut
                   push offset err
                   call StdOut
                   push offset szFrm
                   call StdOut
                   push offset szFrm
                   call StdOut
                   push offset szFrm
                   call StdOut
                   jmp start
;#########################################################################



filterA:
            jmp noFilter
filterB:
            push offset qFilterB
            call StdOut
            push 255                          
            push offset szMask                  
            call StdIn 
            invoke	lstrcpy,addr szSearch,addr szPath
            invoke	lstrcat,addr szSearch,addr szMask
            jmp loop1
filterC:
            invoke	lstrcpy,addr szSearch,addr szPath
            invoke	lstrcat,addr szSearch,addr szMaskC
            jmp loop1

InvalidInput:
            push offset errChoice
            call StdOut
            push offset szFrm
            call StdOut
            jmp start
      
	      invoke wait_key
            invoke ExitProcess, 0
        

end start

; #########################################################################

