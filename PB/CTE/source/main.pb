EnableExplicit

; CityTransportGame
; June 2014
; Alexander Nähring

XIncludeFile "init.pbi"
XIncludeFile "engine.pbi"

CTE_init("CityTransport",#true)
CTE_loadCursor("data/sprites/mouse.png")
  
Repeat
  CTE_frame()
ForEver
; IDE Options = PureBasic 5.11 (Windows - x64)
; CursorPosition = 9
; EnableXP