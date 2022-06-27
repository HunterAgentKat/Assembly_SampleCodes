# Assembly_SampleCodes

**! Educational purpose only !**
For practising assembly on masm32 and for understanding malwares (kinda?)

CONTENTS:
-------------------------------------------------------------------
display_directory.asm
       This program simulates the capabilities of the DIR command in the 
       Windows Command Prompt. It display all the contents of the current 
       directory if there are no filters specified.
       
-------------------------------------------------------------------
display_directory_recursive.asm
       This program simulates the capabilities of the DIR command in the 
       Windows Command Prompt. It display all the contents of the current 
       directory if there are no filters specified. The program is able to 
       accept an optional command-line parameter that specifies the search 
       filter. If the command-line parameter /s is present, it also include
       the listing all entries in the subdirectories.
       
-------------------------------------------------------------------
execute_process.asm
       Win32 assembly program that execute any user-defined process with 
       command-line arguments 

-------------------------------------------------------------------
execute_process_argument_withWindow.asm
       Win32 assembly program that create a Simple Window using MASM32.
       It accept Inputs from TextBox1 and TextBox2. The button performs
       the following actions:
       1.  Button "Run" - takes the input from TextBox1 and runs it as 
           process. The input from text2 is used as an argument.
       2.  Button "Write" - takes the input from TextBox1 and opens the 
           file The input in TextBox2 is now written at the start of the 
           file. If the file does not exist, a MessageBox should appear, 
           telling that the file does not exist.
           
-------------------------------------------------------------------
registry_deleter.asm
       Deletes specified registry
       
-------------------------------------------------------------------
registry_name_appender.asm       
       Registry append

-------------------------------------------------------------------
show_process_info.asm      
       Win32 assembly program that enumerates process info if the 
       command-line parameter /l=filename is specified.

-------------------------------------------------------------------
terminate_process.asm    
       Win32 assembly program that terminates all running process 
       with the process name specified by the command-line parameter 
       /n=processname. If the command-line parameter /p=PID is specified, 
       it will terminate the  process with the PID specified by PID
       
       
       
       
