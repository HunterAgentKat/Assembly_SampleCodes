; #########################################################################

;   -------------------------------------------------------------------
;   Description: Registry Deleter
;   Author: HunterAgentKat
;   -------------------------------------------------------------------


include \masm32\include\masm32rt.inc
include \masm32\include\advapi32.inc
includelib \masm32\lib\comdlg32.lib
includelib \masm32\lib\COMCTL32.lib
includelib \masm32\lib\advapi32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\GDI32.lib

.data
		errNotFound    		db "Registry Value not found", 0
            errDeleted			db "Deleted", 0
		registerPath     		db "SOFTWARE\Microsoft\Windows\CurrentVersion\Run1", 0
		linebreak      		db  13, 10, 0
		
.data?
		
		lpdwDisposition		dd 		?
		phkResult       	      PHKEY 	?
		szArglist 			dd 		?
		buf				db		1024 DUP(?)
.code

start:
		xor eax, eax
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
  
		push NULL                   
		push NULL                   
		push SIZEOF buf             
		push OFFSET buf             
		push -1                     
		push [esi]                  
		push 0                      
		push 0                      
		call WideCharToMultiByte 
		
		
		push lpdwDisposition
		push offset phkResult
		push 0								
		push KEY_ALL_ACCESS					
		push 0							
		push 0							
		push 0							
		push offset registerPath					
		push HKEY_CURRENT_USER				
		call RegCreateKeyEx

RegDive:
		push offset buf
		push phkResult
		call RegDeleteValueA
		cmp eax, ERROR_SUCCESS
		jne catchError

delDONE:
		push offset errDeleted
		call StdOut
		push offset linebreak
		call StdOut
		jmp Finish
		
catchError:
		push offset errNotFound
		call StdOut
		push offset linebreak
		call StdOut

Finish:
		push 0
		call ExitProcess

end start
