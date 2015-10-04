EnableExplicit

; 00000000000000000000000000000001 =    1 =    1
; 00000000000000000000000000000010 =    2 =    2
; 00000000000000000000000000000100 =    4 =    4
; 00000000000000000000000000001000 =    8 =    8
; 00000000000000000000000000010000 =   16 =   10
; 00000000000000000000000000100000 =   32 =   20
; 00000000000000000000000001000000 =   64 =   40
; 00000000000000000000000010000000 =  128 =   80
; 00000000000000000000000100000000 =  256 =  100
; 00000000000000000000001000000000 =  512 =  200
; 00000000000000000000010000000000 = 1024 =  400
; 00000000000000000000100000000000 = 2048 =  800
; 00000000000000000001000000000000 = 4096 = 1000
; 00000000000000000010000000000000 = 8192 = 2000
; etc...

Global variable, i

Procedure.s bitstring(number)
  Protected i
  Protected string$
  
  Protected bit = 1
  For i = 0 To 63
    bit = 1 << i
    If (bit & number)
      string$ = "1" + string$
    Else
      string$ = "0" + string$
    EndIf
  Next
  ProcedureReturn string$
EndProcedure

Macro setbit(variable, bit)
  variable | (1 << (bit))
EndMacro

;----------------------------------------------------------
Debug bitstring(%10110)
Debug ""

variable = 0
For i = 0 To 10
  setbit(variable, i)
  Debug bitstring(variable) + ": " + variable
Next
Debug ""

For i = 0 To 10
  variable = 0
  setbit(variable, i)
  Debug bitstring(variable) + ": " + variable
Next
Debug ""




