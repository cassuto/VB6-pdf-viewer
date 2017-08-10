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
Public Declare Function uv_strlen Lib "libuview.dll" (ByVal str As Long) As Long
Public Declare Function uv_strcpy Lib "libuview.dll" (ByVal dest As Long, ByVal src As Long) As Long
Public Declare Function uv_error_msg Lib "libuview.dll" (ByVal rc As Long, msg As Long) As Long
Public Declare Function uv_error_def Lib "libuview.dll" (ByVal rc As Long, def As Long) As Long
Public Declare Function uv_register_event Lib "libuview.dll" (ByVal ctx As Long, ByVal t As Long, ByVal pf As Long) As Long
Public Declare Function uv_mouse_event Lib "libuview.dll" (ByVal ctx As Long, ByVal pix As Long, ByVal x As Long, ByVal y As Long, ByVal btn As Long, ByVal modifiers As Long, ByVal state As Long) As Long


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
Public Const HAND As Long = 2
Public Const WAIT As Long = 3
Public Const CARET As Long = 4

'
' Error codes (internal)
'
Public Const IOK_SUCCEEDED As Long = 0
Public Const IERR_FAILED As Long = -1
Public Const IERR_OFFSET As Long = -1000
Public Const IERR_VALIDATE As Long = IERR_OFFSET - 1
Public Const IERR_CREATE_CONTEXT As Long = IERR_OFFSET - 2
Public Const IERR_LOAD_FONT As Long = IERR_OFFSET - 3

Private g_view_pool As New Collection


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
    Dim s As String, d As String
    Select Case rc
        Case IOK_SUCCEEDED:
            s = "IOK_SUCCEEDED"
            d = "Operation succeeded."
            
        Case IERR_FAILED:
            s = "IERR_FAILED"
            d = "Operation failed."
            
        Case IERR_VALIDATE:
            s = "IERR_VALIDATE"
            d = "Failed on validating module."
            
        Case IERR_CREATE_CONTEXT:
            s = "IERR_CREATE_CONTEXT":
            d = "Failed on creating context."
            
        Case IERR_LOAD_FONT:
            s = "IERR_LOAD_FONT"
            d = "Failed to load font."
            
        Case Else:
            If uvGetErrorDef(rc, s) Then
                Call uvGetErrorMsg(rc, d)
            Else
                s = CStr(rc)
                d = "Unknown"
            End If
    End Select
    
    ' select the content
    If detail Then
        errGetMsg = d
    Else
        errGetMsg = s ' short name
    End If
End Function


'***********************************************************************************
'Copy the string from C to VB
'***********************************************************************************

Public Function copy_string(ByVal src As Long) As String
    
    Dim lenS As Long
    Dim str() As Byte
    Dim dest As String
    
    lenS = uv_strlen(src)
    
    If lenS > 0 Then
        ReDim str(lenS) As Byte
        
        If SUCCESS(uv_strcpy(VarPtr(str(0)), src)) Then
            dest = StrConv(str, vbUnicode)
        Else
            dest = Space(1)
        End If
        
        Erase str
    End If
    
    copy_string = dest
    
End Function


'***********************************************************************************
'Get the error message (only used by libuview)
'***********************************************************************************

Private Function uvGetErrorDef(rc As Long, ByRef out As String) As Boolean
    Dim i As Long
    Dim def As Long
    
    i = uv_error_def(rc, def)
    
    If SUCCESS(i) Then
        out = copy_string(def)
        uvGetErrorDef = True
    Else
        uvGetErrorDef = False
    End If
End Function


'***********************************************************************************
'Get the error definition (only used by libuview)
'***********************************************************************************

Private Function uvGetErrorMsg(rc As Long, ByRef out As String) As Boolean
    Dim i As Long
    Dim msg As Long
    
    i = uv_error_msg(rc, msg)
    
    If SUCCESS(i) Then
        out = copy_string(msg)
        uvGetErrorMsg = True
    Else
        uvGetErrorMsg = False
    End If
End Function



'***********************************************************************************
'Events processing
'***********************************************************************************

Private Sub eventCursor(ByVal ctx As Long, ByVal cursor As Long)
    Dim obj As clsViewer
    Set obj = getClass(ctx)
    If Not obj Is Nothing Then Call obj.invokeCursor(ByVal cursor)
End Sub

Private Sub eventGotoPage(ByVal ctx As Long, ByVal page As Long)
    Dim obj As clsViewer
    Set obj = getClass(ctx)
    If Not obj Is Nothing Then Call obj.invokeGotoPage(ByVal page)
End Sub

Private Sub eventGotoURL(ByVal ctx As Long, ByVal url As Long)
    
    Dim lenURL As Long
    Dim str() As Byte
    
    lenURL = uv_strlen(url)
    
    If lenURL > 0 Then
        ReDim str(lenURL) As Byte
        
        If SUCCESS(uv_strcpy(VarPtr(str(0)), url)) Then
        
            Dim obj As clsViewer
            Set obj = getClass(ctx)
            If Not obj Is Nothing Then Call obj.invokeGotoURL(ByVal StrConv(str, vbUnicode))
        
        End If
        
        Erase str
    End If
    
End Sub

Private Sub eventWarn(ByVal ctx As Long, ByVal msg As Long)
    Dim obj As clsViewer
    Set obj = getClass(ctx)
    If Not obj Is Nothing Then Call obj.invokeWarn(ByVal copy_string(msg))
End Sub



'***********************************************************************************
'Register generic events
'***********************************************************************************

Public Function registerEvents(ctx As Long) As Long
    Call uv_register_event(ctx, EVENT_CURSOR, AddressOf eventCursor)
    Call uv_register_event(ctx, EVENT_GOTO_PAGE, AddressOf eventGotoPage)
    Call uv_register_event(ctx, EVENT_GOTO_URL, AddressOf eventGotoURL)
    Call uv_register_event(ctx, EVENT_WARN, AddressOf eventWarn)
End Function


'***********************************************************************************
'Manage all the classes in global
'***********************************************************************************

Public Sub addViewClass(obj As clsViewer)
    g_view_pool.Add obj
End Sub

Public Sub removeViewClass(obj As clsViewer)
    Dim i As Integer
    For i = 1 To g_view_pool.Count
        If g_view_pool.Item(i) Is obj Then
            g_view_pool.Remove i
            Exit For
        End If
    Next i
End Sub

'***********************************************************************************
'Get a viewer class according to the pointer of context
'***********************************************************************************

Private Function getClass(pCtx As Long) As clsViewer
    Dim i As Integer
    Dim obj As clsViewer
    
    For i = 1 To g_view_pool.Count
        Set obj = g_view_pool.Item(i)
        If Not obj Is Nothing Then
        
            ' match with pointer
            If obj.getContext() = pCtx Then
                Set getClass = obj
                Exit Function
            End If
            
        End If
    Next i
    
    ' not found
    Set getClass = Nothing
End Function
