Attribute VB_Name = "modViewer"
'****************************************************************************
'
'  uViewer (a tiny document viewer) is Copyleft (C) 2017
'
'  This project is free software; you can redistribute it and/or
'  modify it under the terms of the GNU Lesser General Public License(GPL)
'  as published by the Free Software Foundation; either version 2.1
'  of the License, or (at your option) any later version.
'
'  This project is distributed in the hope that it will be useful,
'  but WITHOUT ANY WARRANTY; without even the implied warranty of
'  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
'  Lesser General Public License for more details.
'
'****************************************************************************

Option Explicit

'
' Vierer APIs
'
Public Declare Function uv_validate Lib "libuview.dll" (ByVal major As Long, ByVal minor As Long) As Long
Public Declare Function uv_create_context Lib "libuview.dll" () As Long
Public Declare Sub uv_drop_context Lib "libuview.dll" (ByVal ctx As Long)
Public Declare Function uv_register_font Lib "libuview.dll" (ByVal ctx As Long, ByVal fn As String) As Long
Public Declare Function uv_open_file Lib "libuview.dll" (ByVal ctx As Long, ByVal fn As String, ByVal flags As Long) As Long
Public Declare Function uv_render_pixmap Lib "libuview.dll" (ByVal ctx As Long, ByVal page As Long, ByRef pix As Long) As Long
Public Declare Function uv_pixmap_getinfos Lib "libuview.dll" (ByVal ctx As Long, ByVal pix As Long, ByRef w As Long, ByRef h As Long, ByRef n As Long, ByRef samples As Long) As Long
Public Declare Function uv_pixmap_fill_docinfo Lib "libuview.dll" (ByVal ctx As Long, ByVal pix As Long) As Long
Public Declare Sub uv_drop_pixmap Lib "libuview.dll" (ByVal ctx As Long, ByVal pix As Long)
Public Declare Function uv_get_page_count Lib "libuview.dll" (ByVal ctx As Long) As Long
Public Declare Function uv_scale Lib "libuview.dll" (ByVal ctx As Long, ByVal sx As Single, ByVal sy As Single) As Long
Public Declare Function uv_rotate Lib "libuview.dll" (ByVal ctx As Long, ByVal th As Single) As Long
Public Declare Function uv_convert_2_bpp Lib "libuview.dll" (ByVal ctx As Long, ByVal pix As Long, ByRef out As Long) As Long
Public Declare Function uv_drop_mem Lib "libuview.dll" (ByVal ctx As Long, ByVal mem As Long) As Long
Public Declare Function uv_register_event Lib "libuview.dll" (ByVal ctx As Long, ByVal t As Long, ByVal pf As Long) As Long
Public Declare Function uv_mouse_event Lib "libuview.dll" (ByVal ctx As Long, ByVal pix As Long, ByVal X As Long, ByVal Y As Long, ByVal btn As Long, ByVal modifiers As Long, ByVal state As Long) As Long


'
' Events
'
Public Const EVENT_UNKNOWN As Long = 0
Public Const EVENT_SHOW_INPUTBOX As Long = 1
Public Const EVENT_SHOW_CHECKBOX As Long = 2
Public Const EVENT_REPAINT_VIEW As Long = 3
Public Const EVENT_GOTO_PAGE As Long = 4
Public Const EVENT_GOTO_URL As Long = 5
Public Const EVENT_CURSOR As Long = 6
Public Const EVENT_WARN As Long = 7

'
' Cursors
'
Public Const NORMAL As Long = 0
Public Const ARROW As Long = 1
Public Const HANDWAIT As Long = 2
Public Const CARET As Long = 3

'
' Error codes (internal)
'
Public Const IOK_SUCCEEDED As Long = 0
Public Const IERR_FAILED As Long = -1
Public Const IERR_OFFSET As Long = -1000
Public Const IERR_VALIDATE As Long = IERR_OFFSET - 1
Public Const IERR_CREATE_CONTEXT As Long = IERR_OFFSET - 2


Public Function SUCCESS(rc As Long) As Boolean
    SUCCESS = (rc >= 0)
End Function

Public Function FAILURE(rc As Long) As Boolean
    FAILURE = (rc < 0)
End Function


'***********************************************************************************
'a mapping between error code and message text
'***********************************************************************************

Public Function errGetMsg(rc As Long, Optional detail As Boolean = False) As String
    Dim S As String, d As String
    Select Case rc
        Case IOK_SUCCEEDED:
            S = "IOK_SUCCEEDED"
            d = "Operation succeeded."
            
        Case IERR_FAILED:
            S = "IERR_FAILED"
            d = "Operation failed."
            
        Case IERR_VALIDATE:
            S = "IERR_VALIDATE"
            d = "Failed on validating module."
            
        Case IERR_CREATE_CONTEXT:
            S = "IERR_CREATE_CONTEXT":
            d = "Failed on creating context."
            
        Case Else:
            S = CStr(rc)
            d = "Unknown"
    End Select
    
    If detail Then
        errGetMsg = d
    Else
        errGetMsg = S ' short name
    End If
End Function


'***********************************************************************************
'Events processing
'***********************************************************************************

Private Function eventShowInputbox(ByVal ctx As Long, ByVal currentText As String, ByVal retry As Long) As String
    eventShowInputbox = InputBox("Value = ")
End Function

Private Function eventGotoPage(ByVal ctx As Long, page As Long)
    MsgBox page, , "page"
End Function

Private Function eventCursor(ByVal ctx As Long, cursor As Long)
    MsgBox cursor, , "cursor"
End Function

'***********************************************************************************
'Register generic events
'***********************************************************************************

Public Function registerEvents(ctx As Long) As Long
    Call uv_register_event(ctx, EVENT_SHOW_INPUTBOX, AddressOf eventShowInputbox)
    Call uv_register_event(ctx, EVENT_CURSOR, AddressOf eventCursor)
    Call uv_register_event(ctx, EVENT_GOTO_PAGE, AddressOf eventGotoPage)
End Function
