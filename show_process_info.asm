
;   -------------------------------------------------------------------
;   
;   Author: HunterAgentKat
;   Description:
;       Win32 assembly program that has the following capabilities: 
;       a.	If the command-line parameter /l=filename is specified, it 
;           should enumerate all running processes and write the following 
;           information about the processes to a file as specified by filename:
;           i.	    Process Name
;           ii.	    Process ID
;           iii.    Process ImagePath 
;           iv.	    DLLs used by each process
;   ------------------------------------------------------------------- 

.386
.model flat, stdcall
option casemap:none

include \masm32\include\masm32rt.inc

.data
    
    nextline    	  db 		  13, 10, 0
    fmtString       db          "%lu",0
    slashL		  db		  "/l=", 0
    Err             db          "An error occured.",0
    procName        db          "Process Name        :  ",0
    procID          db          "Process ID          :  ",0
    procImagepath   db          "Process Image Path  :  ",0
    procDll         db          "Process DLL used    :  ",0
    errNoFile	  db		  "Process not found", 0					
    PE PROCESSENTRY32 <>
    mo32 MODULEENTRY32 <>


.data?
    processId           BYTE        16 dup (?)
    hSnapshot           dd          ?
    hSnapshot2          dd          ?
    buf1			db		1024 DUP(?)
    buf2			db		1024 DUP(?)
    lens2               equ         $-buf2
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

            xor ecx, 3
		xor edx, edx
		xor esi, esi
		xor edi, edi

            lea esi, offset buf1                ; esi as pointer of buf1
            lea edi, offset buf2
       
            MOV  AL, BYTE PTR [esi+0]           
            CMP  AL, 2Fh                        ; "/"                      
            JNZ  dispError
            MOV  AL, BYTE PTR [esi+1]                       
            CMP  AL, 6Ch                        ; "l"                      
            JNZ  dispError                       
            MOV  AL, BYTE PTR [esi+2]                       
            CMP  AL, 3Dh                        ; "="                      
            JNZ  dispError 
            
            getCHAR: 
            MOV  AL, BYTE PTR [esi + ecx] 
            CMP  AL, 0                        
            JZ   outHere
            
            MOV  [edi],AL                     
            INC  ecx
            inc  edi
            JMP getCHAR
            outHere:

            push offset nextline
            call StdOut

            ;-------------------------------Process First
            push 0
            push TH32CS_SNAPPROCESS
            call CreateToolhelp32Snapshot                   
            
            cmp eax,-1
            jz err_exit
            mov hSnapshot,eax
            
            mov PE.dwSize,SIZEOF PE
            
            push offset PE
            push hSnapshot
            call Process32First                             
            
            cmp eax, INVALID_HANDLE_VALUE
            jz dispError
            
            ;-------------------------------Module First

            push PE.th32ProcessID
            push TH32CS_SNAPALL
            call CreateToolhelp32Snapshot 

            cmp eax, INVALID_HANDLE_VALUE
            jz dispError

            mov hSnapshot2,eax

		mov mo32.dwSize, sizeof MODULEENTRY32

            push offset mo32
            push hSnapshot2
            call Module32First
            

Rblot:
            push offset PE.szExeFile
            push offset buf2
            call lstrcmpA

            cmp eax, 0
            jne notequal

            ;--------------------------------Process Name
            push offset procName
            call StdOut
            push offset PE.szExeFile
            call StdOut
            push offset nextline
            call StdOut
            ;--------------------------------Process ID
            push offset procID
            call StdOut
            
            push PE.th32ProcessID
            push offset fmtString
            push offset processId
            call wsprintf
            lea  esp,[esp+12]
            
            push offset processId
            call StdOut
            push offset nextline
            call StdOut
            ;--------------------------------image path
            push offset procImagepath
            call StdOut

            push offset mo32.szExePath
            call StdOut

            push offset nextline
            call StdOut
            ;--------------------------------DLL used
            push offset procDll
            call StdOut
            push offset mo32.szModule
            call StdOut
            
            push offset nextline
            call StdOut
            push offset nextline
            call StdOut
            
    notequal:
            push offset PE
            push hSnapshot
            call Process32Next                              
            
            test eax,eax
            jne Rblot

            push 0
            call ExitProcess

;________________________________________________________________



err_exit:
            invoke MessageBox,0, addr Err ,0, MB_OK
            invoke ExitProcess,-1


dispError:
		push offset Err
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