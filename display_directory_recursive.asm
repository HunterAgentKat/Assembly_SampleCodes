comment * --------------------------------------------------------

   Description:
       This program simulates the capabilities of the DIR command in the 
       Windows Command Prompt. It display all the contents of the current 
       directory if there are no filters specified. The program is able to 
       accept an optional command-line parameter that specifies the search 
       filter. If the command-line parameter /s is present, it also include
       the listing all entries in the subdirectories.
   Author: HunterAgentKat

        -------------------------------------------------------- *
	include 	\masm32\include\masm32rt.inc
	include 	\masm32\include\advapi32.inc
	includelib 	\masm32\lib\advapi32.lib
	includelib 	\masm32\lib\comdlg32.lib
	includelib 	\masm32\lib\COMCTL32.lib
	includelib 	\masm32\lib\user32.lib
	includelib 	\masm32\lib\GDI32.lib
	
	file_tree    PROTO :DWORD,:DWORD,:DWORD

.data
	nextLine        db 	13, 10, 0
	tab		        db 	9, 0
	errUsage    	db 	9,"Invalid input! Follow the usage:", 13, 10, 9
					db 	"Exercise3.5.exe *         to display all the contents of the directory", 13, 10, 9
					db 	"Exercise3.5.exe * /s      to display all the contents of the directory including subdirectories", 13, 10, 9
					db 	"Exercise3.5.exe *.xxx     to display all files ending with preferred file extension (e.g. exe, dll, etc)", 13, 10, 0

	errNotFound		db 	"File not found", 13, 10, 0	
	testinglang		db 	"----- Entered a Folder -----", 13, 10, 0		
	slash			db 	"\",0
	slashS			db	"/s",0
	fmtString		db	"%lu",0
	strFile			db  "File Name       : ", 0
	strBytes		db 	"File Size       : ", 0	
	strAttri		db 	"File Attribute  : ", 0	
	strDate			db 	"Date created    : ", 0	
	dat				db	"00/00/0000",0
		  
.data?
	hSearch		DWORD	?			
	wfd			WIN32_FIND_DATA	<?>		
	systim		SYSTEMTIME <?>
	szArglist 	dd 	?
	bufpath		db  1024 DUP(?)
	buf			db	1024 DUP(?)
	buf2		db	1024 DUP(?)
	fbuffer		db	MAX_PATH dup(?)
	sizeBuffer	db	16 DUP(?)
	
;############################################################################
		
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
	
	;push NULL                  			; LPBOOL  lpUsedDefaultChar
	;push NULL                   		; LPCSTR  lpDefaultChar
	;push SIZEOF bufpath            		; int     cbMultiByte
	;push OFFSET bufpath             	; LPSTR   lpMultiByteStr
	;push -1                     		; int     cchWideChar
	;push [esi]                  		; LPCWSTR lpWideCharStr (dereferenced esi)
	;push 0                      		; DWORD   dwFlags
	;push 0                      		; UINT    CodePage
	;call WideCharToMultiByte 	
	
	add esi, 4							; next argument after the exe file

	push NULL                  			; LPBOOL  lpUsedDefaultChar
	push NULL                   		; LPCSTR  lpDefaultChar
	push SIZEOF buf            			; int     cbMultiByte
	push OFFSET buf             		; LPSTR   lpMultiByteStr
	push -1                     		; int     cchWideChar
	push [esi]                  		; LPCWSTR lpWideCharStr (dereferenced esi)
	push 0                      		; DWORD   dwFlags
	push 0                      		; UINT    CodePage
	call WideCharToMultiByte 	
	
	cmp buf, 0							; if no search filter
	je diplayError
	
	add esi, 4							; next argument after the filter

	push NULL                  			; LPBOOL  lpUsedDefaultChar
	push NULL                   		; LPCSTR  lpDefaultChar
	push SIZEOF buf2            		; int     cbMultiByte
	push OFFSET buf2             		; LPSTR   lpMultiByteStr    for /restore
	push -1                     		; int     cchWideChar
	push [esi]                  		; LPCWSTR lpWideCharStr (dereferenced esi)
	push 0                      		; DWORD   dwFlags
	push 0                      		; UINT    CodePage
	call WideCharToMultiByte 		
	
	cmp buf2, 0							; if no search filter
	je	dispALL
	
	call main							; if meron, proceed to main
	push 0
	call ExitProcess
	

; ================================================================================
main proc
		push offset slashS
		push offset buf2
		call lstrcmpiA
		
		cmp eax,0
		je dispSUBD
		
		jmp diplayError
		
main endp
; ================================================================================
dispSUBD proc

		push offset buf
		push offset fbuffer
		call szCatStr
		
	Find_First:
		push offset wfd
		push offset fbuffer
		call FindFirstFile
		
		mov esi, eax
	FileorFolder:
		cmp wfd.dwFileAttributes, FILE_ATTRIBUTE_DIRECTORY
		jne PrintFile
		
		cmp wfd.cFileName,"."
		je Find_Next
		
		push esi
		push offset RestoreHandle
		jmp ProcessFolder
		
	RestoreHandle:
		pop esi
	Find_Next:
		push offset wfd
		push esi
		call FindNextFile
		
		cmp eax,0
		jne FileorFolder
		
		push esi
		call FindClose
		
		ret
	PrintFile:
		call Printers
		jmp Find_Next
	ProcessFolder:
		mov [fbuffer],0
		
		push offset testinglang
		call StdOut
		
		push offset wfd.cFileName
		push offset fbuffer
		call szCatStr
		
		push offset slash
		push offset fbuffer
		call szCatStr
		
		push offset buf
		push offset fbuffer
		call szCatStr
		
		jmp Find_First
dispSUBD endp
		
		
; =============================================================================
Printers proc
		;---display file name---
		push offset nextLine
		call StdOut
		
		push offset strFile
		call StdOut
		
		push offset wfd.cFileName		
		call StdOut
		
		push offset nextLine
		call StdOut
		
		;---display file size---
		push offset strBytes
		call StdOut
		
		push wfd.nFileSizeLow
		push offset fmtString
		push offset sizeBuffer
		call wsprintf					
		lea esp, [esp +12]
		
		push offset nextLine
		call StdOut
		
		;---display attributes---
		push offset strAttri
		call StdOut						
		
		push wfd.dwFileAttributes
		push offset fmtString
		push offset fbuffer
		call wsprintf
		lea esp, [esp +12]
		
		push offset fbuffer				
		call StdOut	
		
		push offset nextLine
		call StdOut
		
		;---display creation date---
		push offset strDate
		call StdOut	
		
		push offset systim
		push offset wfd.ftCreationTime
		call FileTimeToSystemTime
		
		mov bl, 10
		mov ax, systim.wMonth
		div bl
		add dat[0],al
		add dat[1],ah
		
		mov ax, systim.wDay
		div bl
		add dat[3],al
		add dat[4],ah
		
		mov bl, 10
		mov ax, systim.wYear
		div bl
		add dat[9],ah
		movzx ax,al
		div bl
		add dat[8],ah
		movzx ax,al
		div bl
		add dat[7],ah
		add dat[8],al
		
		push offset dat
		call StdOut
		push offset nextLine
		call StdOut
		
		mov dat[0],"0"
		mov dat[1],"0"
		mov dat[3],"0"
		mov dat[4],"0"
		mov dat[9],"0"
		mov dat[6],"0"
		mov dat[7],"0"
		mov dat[8],"0"
		
		ret
Printers endp

		
; =============================================================================

dispALL:
		push offset wfd						; return value
		push offset	buf						; mask file extension
		call FindFirstFile
	
		mov hSearch, eax				; move return value of FindFirstFile
		mov al, [wfd.cFileName]
		cmp al, "."
		je nextItem						; skip current item if "."
	disp:
		call Printers
		
	nextItem:		
		push offset wfd					
		push hSearch					
		call FindNextFile		

		cmp eax, 0						
		je closeSearch
		
		mov al, [wfd.cFileName]
		cmp al, "."
		je nextItem							; skip current item if "."
		jmp disp
		
diplayError:
		push offset errUsage
		call StdOut
		jmp done
		
closeSearch:
		push hSearch						; stop the searching process
		call FindClose						; prevent program memory leaks
		
done:
end start