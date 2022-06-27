
;   -------------------------------------------------------------------
;   Author: HunterAgentKat
;   Description:
;       Win32 assembly program that has the following capabilities: 
;       1. Execute any user-defined process with command-line arguments 
;           (/p=program_name /a=parameters).
;	  2. If the specified program name in the command-line arguments 
;           contains notepad.exe (case-insensitive), it should not execute 
;           the file, but instead display a message box and execute calc.exe
;	  *  All command-line switches should be case-insensitive and can be 
;           cascaded in any order.
;                 e.g. 
;			MyProg /p=cmd.exe
;			MyProg /A=D:\test.TXT /p=c:\notEPad.exe
;   ------------------------------------------------------------------- 

include \masm32\include\masm32rt.inc

.data
		nextline    	db 		13, 10, 0
		slashP		db		"/p=", 0
		slashA		db		"/a=", 0
		lpOperation	db		"open", 0
		CALstr		db		"calc.exe", 0
		NPstr			db		"notepad.exe", 0
		adminTitle		db		"Administrator!", 0
		adminText		db		"The system administrator, Katherine, prevented the execution of notepad.exe in your computer.", 0
		errormsg    	db 		"An error occured. Follow the usage: /p=cmd.exe or /A=D:\test.TXT /p=c:\notEPad.exe", 13, 10, 0	
           errNoFile		db		"File not found in the current directory.", 0					

		
.data?
		arg1			db		1024 DUP(?)
		arg2			db		1024 DUP(?)
		buf1			db		1024 DUP(?)
		buf2			db		1024 DUP(?)
		save1			db		1024 DUP(?)
		save2			db		1024 DUP(?)
		szArglist 		dd 		?
.code

start:
		xor eax, eax
		xor ecx, ecx
		push ebp
		mov ebp, esp
		sub esp, 4
		
		call GetCommandLineW

		lea ecx, dword ptr[ebp - 4]
		push ecx
		push eax
		call CommandLineToArgvW
  
		mov [szArglist], eax
		mov esi, eax
		add esi, 4						
  
		push NULL                  		; LPBOOL  lpUsedDefaultChar
		push NULL                   		; LPCSTR  lpDefaultChar
		push SIZEOF buf1            		; int     cbMultiByte
		push OFFSET buf1             		; LPSTR   lpMultiByteStr
		push -1                     		; int     cchWideChar
		push [esi]                  		; LPCWSTR lpWideCharStr (dereferenced esi)
		push 0                      		; DWORD   dwFlags
		push 0                      		; UINT    CodePage
		call WideCharToMultiByte 
		
		cmp buf1, 0					
		je dispError
		
		add esi, 4							
  
		push NULL                  		; LPBOOL  lpUsedDefaultChar
		push NULL                   		; LPCSTR  lpDefaultChar
		push SIZEOF buf2            		; int     cbMultiByte
		push OFFSET buf2             		; LPSTR   lpMultiByteStr
		push -1                     		; int     cchWideChar
		push [esi]                  		; LPCWSTR lpWideCharStr (dereferenced esi)
		push 0                      		; DWORD   dwFlags
		push 0                      		; UINT    CodePage
		call WideCharToMultiByte 
;------------------------------------------------------------------------------		
		
checkpoint1:									
		; for first argument
		xor ecx, ecx
		xor edx, edx
		xor esi, esi
		xor edi, edi
		
		lea ecx, offset buf1
		lea edx, offset save1
		
	ad:	mov bl, [ecx + esi]						
		mov [edx + esi], bl
		
		cmp bl, 0								
		je dispError
		
		cmp bl, 3Dh					; compare to "="
		je getargs1
		
		inc esi
		jmp ad
		
getargs1:
		inc esi
		add ecx, esi					
		lea edx, offset arg1
		
	as:	mov bl, [ecx + edi]
		
		cmp bl, 0
		je checkpoint2
		
		mov [edx + edi], bl
		
		inc edi
		jmp as
		
checkpoint2:									
		; for second argument
		xor ebx, ebx
		xor ecx, ecx
		xor edx, edx
		xor esi, esi
		xor edi, edi
		
		lea ecx, offset buf2
		lea edx, offset save2
		
	ad2:mov bl, [ecx + esi]						
		mov [edx + esi], bl
		
		cmp bl, 3Dh
		je getargs2
		
		inc esi
		jmp ad2
		
getargs2:
		inc esi
		add ecx, esi							
		lea edx, offset arg2
		
	as2:mov bl, [ecx + edi]
		
		cmp bl, 0
		je NPsearch
		
		mov [edx + edi], bl
		
		inc edi
		jmp as2
		
NPsearch:
		push offset NPstr
		push offset arg1
		call lstrcmpiA 					; compare arg1 to "notepad.exe"
		
		cmp eax, 0								
		je dispPrompt
		
		push offset NPstr
		push offset arg2
		call lstrcmpiA  					; compare arg2 to "notepad.exe"
		
		cmp eax, 0
		je dispPrompt
		jmp Psearch
		
dispPrompt:
		push MB_OK					
		push offset adminTitle		
		push offset adminText			
		push 0
		call MessageBox	
		
		cmp eax, 1
		je opencalc					
		
		jmp NPfound
opencalc:
		push SW_SHOW 				; nShowCmd
		push 0					; lpDirectory
		push 0					; lpParameters
		push offset CALstr			; lpFile
		push offset lpOperation
		push 0					; hwnd
		call ShellExecuteA
		jmp NPfound
Psearch:
		push offset slashP
		push offset save1			
		call lstrcmpiA 
		
		cmp eax, 0
		je Asearch
		
		push offset slashP
		push offset save2
		call lstrcmpiA 
		
		cmp eax, 0
		je Asearch
		jmp dispError
Asearch:						
		push offset slashA
		push offset save1
		call lstrcmpiA 
		
		cmp eax, 0
		je Pback			
		
		push offset slashA
		push offset save2
		call lstrcmpiA 
		
		cmp eax, 0					
		je Pfront
		
		cmp save2, 0				
		je Pfront
		
		jmp dispError
Pfront:
		push SW_SHOW 				 ; nShowCmd
		push 0					 ; lpDirectory
		push offset arg2			       ; lpParameters
		push offset arg1			       ; lpFile
		push offset lpOperation
		push 0					  ; hwnd
		call ShellExecuteA			  ; execute the file/ program
		
		cmp eax, ERROR_FILE_NOT_FOUND
		je noFile
		
		cmp eax, 32
		jg Finish
		
		jmp dispError
Pback:
		push SW_SHOW 				; nShowCmd
		push 0	    				; lpDirectory
		push offset arg1			     ; lpParameters
		push offset arg2		           ; lpFile
		push offset lpOperation
		push 0					; hwnd
		call ShellExecuteA			; execute the file/ program
		
		cmp eax, ERROR_FILE_NOT_FOUND
		je noFile
		
		cmp eax, 32
		jg Finish
		
		jmp dispError		
		jmp Finish
		
NPfound:
		
		jmp Finish
		
dispError:
		push offset errormsg
		call StdOut
		push offset nextline
		call StdOut
		
		jmp Finish
		
noFile:
		push offset errNoFile
		call StdOut
		push offset nextline
		call StdOut
		
Finish:		
end start