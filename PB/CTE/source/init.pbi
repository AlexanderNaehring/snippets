EnableExplicit

; CityTransportInit
; June 2014
; Alexander Nähring


CompilerIf Not #PB_Editor_CreateExecutable
  SetCurrentDirectory("../bin")
  #DEBUG = #True
CompilerElse
  #DEBUG = #False
CompilerEndIf

; IDE Options = PureBasic 5.22 LTS (Windows - x64)
; CursorPosition = 7
; EnableXP