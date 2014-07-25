EnableExplicit

; CityTransportEngine
; June 2014
; Alexander Nähring

Structure CTE_Time
  ms.i
  oms.i
  diff.i
  fps.i
EndStructure

Structure CTE_Sprite
  id.i
  x.i
  y.i
  world_x.i
  world_y.i
  width.l
  height.l
  visible.b
EndStructure

Structure CTE_World
  width.i
  height.i
EndStructure

Structure CTE_Camera_Location
  centerX.d ; which world-pixel is shown
  centerY.d ; in the center of the canera
  zoom.i    ; zoom level specifying the visible area
  right.i   ; x
  left.i    ; x+width
  top.i     ; y
  bottom.i  ; y+height 
EndStructure

Structure CTE_Camera_Movement
  targetVelocityX.d
  targetVelocityY.d
  velocityX.d
  velocityY.d
EndStructure

Structure CTE_Camera_Target  
  targetWorldX.i
  targetWorldY.i
  isTarget.b  
EndStructure

Structure CTE_Camera
  pos.CTE_Camera_Location
  move.CTE_Camera_Movement
  target.CTE_Camera_Target
  lastUpdate.i
EndStructure

Global CTE_Time.CTE_Time
Global NewMap CTE_Sprite.CTE_Sprite()
Global CTE_Sprite_Mouse.CTE_Sprite
Global CTE_Sprite_Overlay.CTE_Sprite
Global CTE_Sprite_Debug.CTE_Sprite
Global CTE_Debugging.b = #False
Global CTE_World.CTE_World
Global CTE_Camera.CTE_Camera

#CTE_Transparent = 16711935 ; RGB(255,0,255) = pink
#CTE_VELOCITY = 10  ; Pixel / ms

Declare CTE_error(id.i, exit.i = #True)
Declare CTE_mouse(flag.i)
Declare CTE_loadCursor(file$)
Declare CTE_init(title$,debugging.b = #False)
Declare CTE_Update_FPS()
Declare CTE_Update_Camera()
Declare CTE_Draw_Overlay()
Declare CTE_Draw_Debug()
Declare CTE_Draw_Sprites()
Declare CTE_close()
Declare CTE_frame()

;{ Mutex
Enumeration 0
  #CTE_MUTEX_SPRITES
  
  #CTE_MUTEX_COUNT  
EndEnumeration
Global Dim CTE_Mutex(#CTE_MUTEX_COUNT)
;}

;{ Error Codes
Enumeration 0
  #CTE_ERROR_INIT_SPRITE        ; 1001
  #CTE_ERROR_INIT_KEYBOARD      ; 1002
  #CTE_ERROR_INIT_MOUSE         ; 1003
  #CTE_ERROR_INIT_PNG           ; 1004
  #CTE_ERROR_START_THREAD_MOUSE ; 1005
  #CTE_ERROR_OPENSCREEN         ; 1006
  #CTE_ERROR_START_DESKTOP      ; 1007
  
  #CTE_ERROR_COUNT
EndEnumeration

Global Dim CTE_ErrorCode.s(#CTE_ERROR_COUNT)
CTE_ErrorCode(#CTE_ERROR_INIT_SPRITE) = "Can not initialize screen"
CTE_ErrorCode(#CTE_ERROR_INIT_KEYBOARD) = "Can not initialize  keyboard"
CTE_ErrorCode(#CTE_ERROR_INIT_MOUSE) = "Can not initialize mouse"
CTE_ErrorCode(#CTE_ERROR_INIT_PNG) = "Can not initialize PNG image decoder"
CTE_ErrorCode(#CTE_ERROR_START_THREAD_MOUSE) = "Failed to start mouse thread"
CTE_ErrorCode(#CTE_ERROR_OPENSCREEN) = "Failed to open screen"
CTE_ErrorCode(#CTE_ERROR_START_DESKTOP) = "Failed to retrieve desktop resolution"

;}

Procedure CTE_error(id.i, exit.i = #True)
  Protected title$, message$
  If exit
    title$ = "Critical Error"
  Else
    title$ = "Error"
  EndIf
  message$ = "Error #"+Str(1001+id)
  If CTE_ErrorCode(id)
    message$ = message$ + ":" + Chr(13) + CTE_ErrorCode(id)
  EndIf
  If exit
    CTE_close()
  EndIf
  MessageRequester(title$, message$, #PB_MessageRequester_Ok|#MB_ICONERROR)
  If exit
    End
  EndIf
  
EndProcedure

Procedure CTE_mouse(flag.i)
  Static quit
  If flag
    MouseLocate(ScreenWidth()/2,ScreenHeight()/2)
    Repeat
      If IsScreenActive()
        ExamineMouse()
        CTE_Sprite_Mouse\x = MouseX()
        CTE_Sprite_Mouse\y = MouseY()
      EndIf
      
      Delay(0)
    Until quit
    quit=#False
  Else
    quit=#True
    While quit
      Delay(1)
    Wend
  EndIf
EndProcedure

Procedure CTE_loadCursor(file$)
  Protected id.i
  If FileSize(file$) > 0
    id = LoadSprite(#PB_Any, file$)
    If id
      CTE_Sprite_Mouse\id = id
      ProcedureReturn #True
    EndIf
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure CTE_init(title$,debugging.b = #False)
  If Not InitSprite()
   CTE_error(#CTE_ERROR_INIT_SPRITE)
  EndIf
  If Not InitKeyboard()
    CTE_error(#CTE_ERROR_INIT_KEYBOARD)
  EndIf
  If Not InitMouse()
    CTE_error(#CTE_ERROR_INIT_MOUSE)
  EndIf
  If Not UsePNGImageDecoder()
    CTE_error(#CTE_ERROR_INIT_PNG)
  EndIf
  If Not CreateThread(@CTE_mouse(),#True)
    CTE_error(#CTE_ERROR_START_THREAD_MOUSE)
  EndIf
  If Not ExamineDesktops()
    CTE_error(#CTE_ERROR_START_DESKTOP)
  EndIf
  If Not OpenScreen(DesktopWidth(0), DesktopHeight(0), DesktopDepth(0), title$, #PB_Screen_SmartSynchronization)
    CTE_ERROR(#CTE_ERROR_OPENSCREEN)
  EndIf
  TransparentSpriteColor(#PB_Default,#CTE_Transparent)
  
  ; Init Overlay
  CTE_Sprite_Overlay\id = CreateSprite(#PB_Any, 1920, 1080)
  ; Init Debugging
  CTE_Sprite_Debug\id = CreateSprite(#PB_Any, 1920, 1080)
  
  CTE_Debugging = debugging
  
  CTE_Mutex(#CTE_MUTEX_SPRITES) = CreateMutex()
EndProcedure

Procedure CTE_Update_FPS()
  With CTE_Time
    \oms = \ms
    \ms = ElapsedMilliseconds()
    \diff = \ms-\oms
    If(\diff > 0)
      \fps = 1000/(\diff)
    EndIf
  EndWith
EndProcedure

Procedure CTE_Update_Camera()
  Protected time.i, elapsedTime.i
  With CTE_Camera
    ; update time and calculate elapsedTime since last update
    time = ElapsedMilliseconds()
    elapsedTime = time - \lastUpdate
    \lastUpdate = time
    ; use elapsed time for smooth movement
    ; elapsed time in ms -> use values as movement / ms
    
    ; look for target! (overwrites everything else)
    If \target\isTarget
      ; move to target!
      \move\targetVelocityX = Pow(-1, Bool(\target\targetWorldX < \pos\centerX)) * #CTE_VELOCITY
      \move\targetVelocityY = Pow(-1, Bool(\target\targetWorldY < \pos\centerY)) * #CTE_VELOCITY
    EndIf
    
    ; update Velocoity
  EndWith 
EndProcedure

Procedure CTE_Camera_MoveTo(worldX.i ,worldY.i)
  CTE_Camera\target\isTarget = #True
  CTE_Camera\target\targetWorldX = worldX
  CTE_Camera\target\targetWorldY = worldY
;/ Check for valid target!  
EndProcedure

Procedure CTE_Draw_Overlay()
  If IsSprite(CTE_Sprite_Overlay\id)
    If StartDrawing(SpriteOutput(CTE_Sprite_Overlay\id))
      DrawingMode(#PB_2DDrawing_Default )
      Box(0, 0, SpriteWidth(CTE_Sprite_Overlay\id), SpriteHeight(CTE_Sprite_Overlay\id), #CTE_Transparent)  ; clear overlay
      
      
      DrawingMode(#PB_2DDrawing_Transparent)
      If Not CTE_Debugging
        DrawText(10, 10, "press F1 to enable debugging output", #Red)
      EndIf 
    EndIf
    StopDrawing()
    DisplayTransparentSprite(CTE_Sprite_Overlay\id,0,0)
  EndIf
EndProcedure

Procedure CTE_Draw_Debug()
  If IsSprite(CTE_Sprite_Debug\id) And CTE_Debugging
    If StartDrawing(SpriteOutput(CTE_Sprite_Debug\id))
      DrawingMode(#PB_2DDrawing_Default )
      Box(0, 0, SpriteWidth(CTE_Sprite_Debug\id), SpriteHeight(CTE_Sprite_Debug\id), #CTE_Transparent)  ; clear debug
      
      DrawingMode(#PB_2DDrawing_Transparent)
      DrawText(10, 10, ProgramFilename() + " - " + GetCurrentDirectory(), #Red)
      DrawText(10, 30, "Resolution: " + Str(ScreenWidth()) + "x" + Str(ScreenHeight()) + "x" + Str(ScreenDepth()), #Red)
      DrawText(10, 50, "FPS: "+Str(CTE_Time\fps) + " - " + "ms: "+Str(CTE_Time\diff), #Red)
      Protected tmp.i, tmp2.d
      tmp = AvailableScreenMemory() : tmp2 = tmp
      If tmp < 0  ; 32-bit exe with 64-bit memory: really bad workaround
        tmp = tmp & %01111111111111111111111111111111 : tmp2 = tmp*2
      EndIf
      DrawText(10, 70, "Memory: "+Str(tmp2/1024/1024) +" MByte", #Red)
      
      DrawingMode(#PB_2DDrawing_Outlined)
      Box(0,0, SpriteWidth(CTE_Sprite_Debug\id), SpriteHeight(CTE_Sprite_Debug\id), #Red)
    EndIf
    StopDrawing()
    DisplayTransparentSprite(CTE_Sprite_Debug\id,0,0)
  EndIf
EndProcedure

Procedure CTE_Draw_Cursor()
  If IsSprite(CTE_Sprite_Mouse\id)
    DisplayTransparentSprite(CTE_Sprite_Mouse\id, CTE_Sprite_Mouse\x-SpriteWidth(CTE_Sprite_Mouse\id)/2, CTE_Sprite_Mouse\y-SpriteHeight(CTE_Sprite_Mouse\id)/2)
  EndIf
EndProcedure

Procedure CTE_Draw_Sprites()
  LockMutex(CTE_Mutex(#CTE_MUTEX_SPRITES))
  ForEach CTE_Sprite()
    With CTE_Sprite()
      \x = \world_x - CTE_Camera\pos\right
      \y = \world_y - CTE_Camera\pos\top
      DisplayTransparentSprite(\id, \x, \y)
    EndWith
  Next
  UnlockMutex(CTE_Mutex(#CTE_MUTEX_SPRITES))
EndProcedure

Procedure CTE_close()
  CTE_mouse(#False)
  CloseScreen()
  ;End
EndProcedure

Procedure CTE_frame()
  ExamineKeyboard()
  ClearScreen(RGB(100,100,100))
  
  If KeyboardPushed(#PB_Key_Escape)
    CTE_close()
    End
  EndIf
  
  If KeyboardReleased(#PB_Key_F1)
    CTE_Debugging = Bool(CTE_Debugging = 0)
  EndIf 
  
  CTE_Update_FPS()
  CTE_Update_Camera()
  
  CTE_Draw_Sprites()
  CTE_Draw_Overlay()
  CTE_Draw_Debug()
  CTE_Draw_Cursor()
  
  FlipBuffers()
EndProcedure
; IDE Options = PureBasic 5.11 (Windows - x86)
; CursorPosition = 30
; Folding = AG0
; EnableXP