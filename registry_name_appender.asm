;  Registry Name Appender

include \masm32\include\masm32rt.inc
include \masm32\include\advapi32.inc
includelib \masm32\lib\comdlg32.lib
includelib \masm32\lib\COMCTL32.lib
includelib \masm32\lib\advapi32.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\GDI32.lib

.data
            keyPath       db    "\Software\Microsoft\Windows\CurrentVersion\Run",0
            LineBreak	  db    13,10,0
            errListEnd    db    "List ends here",13,10,0
            errMsg        db    "Error Occured",13,10,0
            XX            db    "_XX"
            myType        db    "REG_SZ",0
.data?
            ValName       db    255 dup(?)
            lpcbVN        dd    ?
            count      DWORD    ?
            lpcValue      dd    ?
            hKey          dd    ?
            phkResult     dd    ?
            lpdwDsposition  LPDWORD  ? 
            myNewFile         BYTE  MAX_PATH dup(?)
            

.code
start:
            xor eax,eax

            push lpdwDsposition
            push offset phkResult
            push 0
            push KEY_ALL_ACCESS
            push 0
            push 0
            push 0
            push offset keyPath
            push HKEY_CURRENT_USER
            call RegCreateKeyEx

            cmp eax, ERROR_SUCCESS
            jne errorprint

loopcall:
            mov count, 0
      as:   mov lpcbVN, 100
            push 0  
            push 0  
            push offset myType
            push 0        
            push offset lpcbVN
            push offset ValName
            push count
            push phkResult
            call RegEnumValue

            cmp eax, ERROR_MORE_DATA
            je errorprint
            cmp eax, ERROR_NO_MORE_ITEMS
            je nomore
            
            inc count

            push offset ValName
            call StdOut

            push offset ValName
            push offset myNewFile
            call szCatStr                    ; myNewFile = ValName
    
            push offset XX
            push offset myNewFile
            call szCatStr                    ; myNewFile = ValName + "_XX"
         
            push sizeof newdata
            push offset newdata
            push REG_SZ
            push 0
            push offset myNewFile
            push phkResult
            call RegSetValueExA
            
            ;push offset myNewFile
            ;push offset ValName
            ;call MoveFile                   ; rename file

            push offset LineBreak
            call StdOut

            jmp as
            
errorprint:
            push offset  errMsg
            call StdOut
            invoke ExitProcess, 0
nomore:
            push offset  errListEnd
            call StdOut                      

invoke ExitProcess, 0
end start

