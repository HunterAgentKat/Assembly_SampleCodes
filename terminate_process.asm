
;   -------------------------------------------------------------------
;   Author: HunterAgentKat
;   Description:
;       Win32 assembly program that has the following capabilities: 
;       a.	If the command-line parameter /n=processname is specified, 
;           it should terminate all running process with the process 
;           name specified by processname
;       b.	If the command-line parameter /p=PID is specified, it will 
;           terminate the  process with the PID specified by PID
;       c.	It will only accept one command-line parameter.
;       d.	It will inform you if it did not find any process to terminate
;
;   ------------------------------------------------------------------- 

.386
.model flat, stdcall
option casemap:none

include \masm32\include\masm32rt.inc

.const
IDM_TERMINATE equ 2

.data
    
            nextline    	  db 		  13, 10, 0
            fmtString           db          "%lu",0
            slashL		  db		  "/l=", 0
            Err                 db          "An error occured.",0
            msgTerminate        db          9,"Terminated",13,10,0
            procName            db          "Process Name        :  ",0
            procID              db          "Process ID          :  ",0
            procImagepath       db          "Process Image Path  :  ",0
            procDll             db          "Process DLL used    :  ",0
            errNoFile	        db		  "Process not found", 0					
            PE PROCESSENTRY32 <>
            processInfo PROCESS_INFORMATION <>



.data?
            processId           BYTE        16 dup (?)
            hSnapshot           dd          ?
            buf1			  db		  1024 DUP(?)
            buf2			  db		  1024 DUP(?)
            lens2               equ         $-buf2
            szArglist 		  dd 		  ?
            ExitCode            DWORD       ?

    

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
             
                
            checkeq:
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

;____________________________________________________
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
            
            test eax,eax
            mov edx,eax
            jz err_exit


            lea esi, offset buf1
            MOV  AL, BYTE PTR [esi+1] 
                      
            CMP  AL, 6Eh                        ; "n"  
            jz   procnameENUM 

            CMP  AL, 70h                        ; "p"  
            jz  procpidENUM 
     		

procnameENUM:

            push offset PE.szExeFile
            push offset buf2
            call lstrcmpA

            cmp eax, 0
            jne notequal

            push offset procName
            call StdOut
            push offset PE.szExeFile
            call StdOut
            push offset msgTerminate
            call StdOut
            push offset nextline
            call StdOut
            

            comment ! ------------
            push PE.th32ProcessID
            push FALSE
            push PROCESS_TERMINATE
            call OpenProcess

            push 0
            push PE.hProcess
            call TerminateProcess
            ----------------------!
            push offset ExitCode
            push processInfo.hProcess
            call GetExitCodeProcess                ;invoke GetExitCodeProcess,processInfo.hProcess,ADDR ExitCode
            
		.if ExitCode==STILL_ACTIVE
                push 0
                push processInfo.hProcess
                call TerminateProcess               ;invoke TerminateProcess,processInfo.hProcess,0
					
		.endif
                push processInfo.hProcess
                call CloseHandle                    ;invoke CloseHandle,processInfo.hProcess
				
		    mov processInfo.hProcess,0
            
    notequal:
            push offset PE
            push hSnapshot
            call Process32Next                              
            
            test eax,eax
            mov edx,eax
            jne procnameENUM
    
            push 0
            call ExitProcess
            ;====================================

procpidENUM:
       
            push PE.th32ProcessID
            push offset fmtString
            push offset processId
            call wsprintf
            lea  esp,[esp+12]

            push offset processId
            push offset buf2
            call lstrcmpA

            cmp eax, 0
            jne notequal2

            push offset procID
            call StdOut
            push offset processId
            call StdOut
            push offset msgTerminate
            call StdOut
            push offset nextline
            call StdOut
            
            comment !---------------
            push PE.th32ProcessID
            push FALSE
            push PROCESS_TERMINATE
            call OpenProcess

            push 0
            push edx
            call TerminateProcess
             ----------------------!
            push offset ExitCode
            push processInfo.hProcess
            call GetExitCodeProcess                ;invoke GetExitCodeProcess,processInfo.hProcess,ADDR ExitCode
            
		.if ExitCode==STILL_ACTIVE
                push 0
                push processInfo.hProcess
                call TerminateProcess               ;invoke TerminateProcess,processInfo.hProcess,0
					
		.endif
                push processInfo.hProcess
                call CloseHandle                    ;invoke CloseHandle,processInfo.hProcess
				
		    mov processInfo.hProcess,0
                        
notequal2:
            push offset PE
            push hSnapshot
            call Process32Next                              
            
            test eax,eax
            mov edx,eax
            jne procpidENUM
    
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