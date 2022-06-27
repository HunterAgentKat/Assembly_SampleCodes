
;   ---------------------------------------------------------------------
;   Author: HunterAgentKat
;   Description:
;       Win32 assembly program that create a Simple Window using MASM32.
;       
;       It accept Inputs from TextBox1 and TextBox2. The button performs
;       the following actions:
;       1.  Button "Run" - takes the input from TextBox1 and runs it as 
;           process. The input from text2 is used as an argument.
;            
;            Ex: Text1: notepad.exe	
;                Text2: new.txt 
;                 = notepad.exe new.txt must be run.
;
;       2.  Button "Write" - takes the input from TextBox1 and opens the 
;           file The input in TextBox2 is now written at the start of the 
;           file. If the file does not exist, a MessageBox should appear, 
;           telling that the file does not exist.
;
;   ---------------------------------------------------------------------

    include 	\masm32\include\masm32rt.inc
	include 	\masm32\include\advapi32.inc
	include 	\masm32\include\shlwapi.inc
	includelib 	\masm32\lib\shlwapi.lib
	includelib 	\masm32\lib\advapi32.lib

	WinMain	proto	:DWORD, :DWORD, :DWORD, :DWORD			
	WndProc	proto	:DWORD, :DWORD, :DWORD, :DWORD						
	textbox	proto	:DWORD, :DWORD, :DWORD,	:DWORD, :DWORD, :DWORD,	:DWORD
	textedit	proto	:DWORD, :DWORD, :DWORD,	:DWORD, :DWORD, :DWORD,	:DWORD
	pushbutton	proto	:DWORD, :DWORD, :DWORD,	:DWORD, :DWORD, :DWORD,	:DWORD

.data														
	finddata		WIN32_FIND_DATA <?>
	windowClass		db	"Exercise7", 0							
	windowName		db	"Form1", 0								
	textclass		db	"STATIC",0
	buttonclass		db	"BUTTON",0
	editclass		db	"EDIT", 0
	closeConfirm	db	"Are you sure you want to Exit?", 0				
	label1		db	"Text 1: ", 0
	label2		db	"Text 2: ", 0
	labelRun		db	"Run", 0
	labelWrite		db	"Write", 0
	lpOperation		db	"open", 0
	errorProcess	db	"Process not found.", 0
	errorFile		db	"File not found. It does not exist.", 0
	processtitle	db	"Notification", 0
	pushAddress		dd	512

.data?
	hInstance		HINSTANCE   ?       							
	CommandLine		LPSTR       ?		
	crrvalue		HANDLE	?									
	ffrvalue		HANDLE	?		
	buttonRun		dd	      ?										
	buttonWrite		dd	      ?										
	text1			dd	      ?										
	text2			dd	      ?										
	buftext1		db	      512	dup(?) 								
	buftext2		db	      512	dup(?) 								

.code

start:
	push 0
	call GetModuleHandle										
	mov hInstance, eax							

	call GetCommandLine                        					 
	mov CommandLine, eax										
     
	push 1														
	push CommandLine											
	push 0														
	push hInstance												
	call WinMain												

	push eax
	call ExitProcess											

; #########################################################################

WinMain	proc	hinst :DWORD, hprevinst :DWORD, cmdline :DWORD, cmdshow :DWORD

      local wc	:WNDCLASSEX										
      local msg	:MSG											
      local hwnd	:HWND
  
	mov	wc.cbSize, sizeof WNDCLASSEX							
	mov wc.style, CS_HREDRAW or CS_VREDRAW or CS_BYTEALIGNWINDOW	
	mov wc.lpfnWndProc, WndProc									
	mov wc.cbClsExtra, NULL										
	mov	wc.cbWndExtra, NULL										
 
	push hInstance
	pop wc.hInstance											

	mov wc.hbrBackground, COLOR_BTNFACE+1						
	mov	wc.lpszMenuName, NULL									
	mov wc.lpszClassName, offset windowClass						
	push IDI_WINLOGO											
	push hinst													
	call LoadIcon
	
	mov	wc.hIcon, eax											
	mov	wc.hIconSm, eax											

	push IDC_ARROW
	push hinst
	call LoadCursor
	
	mov	wc.hCursor, eax											

	xor ecx, ecx												
	lea ecx, wc													
	push ecx													
	call RegisterClassEx

	push 0														
	push hinst													 
	push 0														
	push 0														
	push 300													
	push 400													
	push 300													
	push 400													
	push WS_OVERLAPPED or WS_SYSMENU							
	push offset windowName										
	push offset windowClass										
	push WS_EX_LEFT												
	call CreateWindowEx											

	mov hwnd, eax												

	push cmdshow
	push hwnd
	call ShowWindow												
	
	push hwnd
	call UpdateWindow											

MessageReadLoop:													
	xor ebx, ebx
	lea ebx, msg

	push 0
	push 0
	push NULL
	push ebx													
	call GetMessage

	cmp eax, 0
	je MessageReadLoopEnd

	push ebx													
	call TranslateMessage

	push ebx													
	call DispatchMessage
	jmp MessageReadLoop

MessageReadLoopEnd:
	mov	eax, msg.wParam
	ret

WinMain endp

; #########################################################################

WndProc proc	hwin :dword, umsg :dword, wparam :dword, lparam :dword

	LOCAL hDC  :DWORD

	cmp umsg, WM_COMMAND										
	je command

	cmp umsg, WM_CREATE											
	je create
	
	cmp umsg, WM_CLOSE									
	je close
	
	cmp umsg, WM_DESTROY									
	je destroy

defwin:
	push lparam
	push wparam
	push umsg
	push hwin
	call DefWindowProc
	
	ret

command:
	cmp wparam, 500											
	je brunc													
	
	cmp wparam, 501												
	je bwritec												
	
	jmp defwin
	
	brunc:
		call runprocess										
		ret 
	
	bwritec:
		call writeprocess							
		ret
create:
	
	push 0														
	push 25													
	push 200										
	push 30													
	push 62													
	push hwin												
	push offset label1										
	call textbox											

	push 0									
	push 25													
	push 200												
	push 105												
	push 62													
	push hwin												
	push offset label2										
	call textbox												

	push 700												
	push hwin													
	push 30													
	push 270													
	push 55												
	push 62														
	push 0											
	call textedit
	mov text1, eax											

	push 701												
	push hwin													
	push 30														
	push 270													
	push 130													
	push 62														
	push 0												
	call textedit												 
	mov text2, eax												

	push 500													
	push 30												 		
	push 100											 		
	push 200													
	push 72														
	push hwin												 
	push offset labelRun									
	call pushbutton
	mov buttonRun, eax

	push 501													
	push 30												 		
	push 100											 		
	push 200													
	push 222													
	push hwin												 	
	push offset labelWrite										
	call pushbutton
	mov buttonWrite, eax

	jmp defwin

close:															
	push MB_YESNO												
	push offset windowName									
	push offset closeConfirm										
	push hwin													
	call MessageBox
	
	cmp eax, IDYES												
	je destroy
	
	ret

destroy:
	push 0
	call PostQuitMessage
	
	xor eax, eax

	ret

WndProc endp


; ########################################################################

textedit proc	szMsg:DWORD,a:DWORD,b:DWORD,wd:DWORD,ht:DWORD,hParent:DWORD,ID:DWORD
; invoke EditSl,ADDR adrTxt,200,10,150,25,hWnd,700

	LOCAL hndle:DWORD

	push NULL																; lpParam.
	push hInstance															; hinstance. from .data?
	push ID																	; hMenu.
	push hParent															; hWndParent.
	push ht																	; nHeight.	CW_USEDEFAULT
	push wd																	; nWidth.	CW_USEDEFAULT
	push b																	; int y.	CW_USEDEFAULT
	push a																	; int x.	CW_USEDEFAULT
	push WS_VISIBLE or WS_CHILDWINDOW or ES_AUTOHSCROLL or ES_NOHIDESEL		; dwStyle.	WS_OVERLAPPEDWINDOW
	push szMsg																; lpWindowName.
	push offset editclass													; lpClassName. EDIT
	push WS_EX_CLIENTEDGE													; dwExStyle. can be null. WS_EX_APPWINDOW
	call CreateWindowEx

	mov hndle, eax

	ret
textedit endp
; ########################################################################
textbox proc	lpText:DWORD,hParent:DWORD,a:DWORD,b:DWORD,wd:DWORD,ht:DWORD,ID:DWORD
;	invoke Static,ADDR szText,hWnd,20,20,100,15,500

	LOCAL hndle:DWORD

	push NULL																; lpParam.
	push hInstance															; hinstance. from .data?
	push ID																	; hMenu.
	push hParent															; hWndParent.
	push ht																	; nHeight.	CW_USEDEFAULT
	push wd																	; nWidth.	CW_USEDEFAULT
	push b																	; int y.	CW_USEDEFAULT
	push a																	; int x.	CW_USEDEFAULT
	push WS_CHILD or WS_VISIBLE or SS_LEFT									; dwStyle. WS_OVERLAPPEDWINDOW
	push lpText																; lpWindowName.
	push offset textclass													; lpClassName. STATIC
	push WS_EX_LEFT															; dwExStyle. can be null. WS_EX_APPWINDOW
	call CreateWindowEx

	mov hndle, eax

	ret
textbox endp

; ###############################################################
pushbutton proc	lpText:DWORD,hParent:DWORD,a:DWORD,b:DWORD,wd:DWORD,ht:DWORD,ID:DWORD
;	invoke PushButton,ADDR szText,hWnd,20,20,100,25,500

	LOCAL hndle:DWORD

	push NULL																; lpParam.
	push hInstance															; hinstance. from .data?
	push ID																	; hMenu.
	push hParent															; hWndParent.
	push ht																	; nHeight.	CW_USEDEFAULT
	push wd																	; nWidth.	CW_USEDEFAULT
	push b																	; int y.	CW_USEDEFAULT
	push a																	; int x.	CW_USEDEFAULT
	push WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON							; dwStyle. WS_OVERLAPPEDWINDOW
	push lpText																; lpWindowName.
	push offset buttonclass													; lpClassName. BUTTON
	push 0																	; dwExStyle. can be null. WS_EX_APPWINDOW
	call CreateWindowEx
	
	mov hndle, eax

    ret
pushbutton endp
; ###############################################################
runprocess proc
	push 512														
	push offset buftext1											
	push text1														
	call GetWindowText												
	
	push 512														
	push offset buftext2											
	push text2														
	call GetWindowText												

	push SW_SHOW 													
	push 0															
	push offset buftext2											
	push offset buftext1											
	push offset lpOperation
	push 0															
	call ShellExecuteA	
	
	cmp eax, 32
	ja suceeded
	
	push MB_OK													
	push offset processtitle										
	push offset errorProcess										
	push 0															
	call MessageBox
	
	suceeded:
	ret
runprocess endp
; ###############################################################

writeprocess proc
	push 512													
	push offset buftext1										
	push text1													
	call GetWindowText											
	
	push 512													
	push offset buftext2										
	push text2													
	call GetWindowText											

	push 0														
    push FILE_ATTRIBUTE_NORMAL									
    push OPEN_EXISTING											
    push 0														
    push 0														
    push FILE_APPEND_DATA										 
    push offset buftext1										
    call CreateFileA						; to open the file

	cmp eax, INVALID_HANDLE_VALUE								
	je done														
    mov crrvalue, eax											

	;For append 	
	push 0														
    push offset pushAddress										
    push lengthof buftext2 										
    push offset buftext2										
    push crrvalue												
    call WriteFile												
	
	push crrvalue												
	call FindClose													
	ret 
done:
	push MB_OK													
	push offset processtitle									
	push offset errorFile										
	push 0														
	call MessageBox
	
	push crrvalue												
	call FindClose												

	ret
writeprocess endp
;###############################################################

end start