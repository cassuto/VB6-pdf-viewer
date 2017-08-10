VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsViewer"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False

Option Explicit

Private m_ctx As Long
Private m_inited As Boolean
Private m_height As Long
Private m_width As Long
Private m_n As Long
Private m_samples As Long   ' Pointer to the pixels buffer
Private m_pixmap As Long
Private m_scale_x As Long, m_scale_y As Long

'
' Events
'
Public Event onCursor(cursor As Long)
Public Event onGotoPage(page As Long)
Public Event onGotoURL(url As String)
Public Event onWarn(msg As String)


Private Sub Class_Initialize()
    m_ctx = 0
    m_height = 0
    m_width = 0
    m_n = 0
    m_samples = 0
    m_pixmap = 0
    m_scale_x = 100
    m_scale_y = 100
    m_inited = False
End Sub

Private Sub Class_Terminate()
    '
    ' ensure that we have called uninitview() before terminate the class,
    ' instead of doing it here.
    '
    If m_inited Then
        Call uninitViewer
        Err.Raise vbObjectError + 1, , "Leakage of memory."
    End If
End Sub


'***********************************************************************************
'Initialize the viewer.
'***********************************************************************************

Public Function initViewer() As Long
    Dim rc As Long
    
    ' check the version
    If uv_validate(0, 0) Then
        initViewer = IERR_VALIDATE
        Exit Function
    End If
    
    m_ctx = uv_create_context()
    If m_ctx = 0 Then
        initViewer = IERR_CREATE_CONTEXT
        Exit Function
    End If
    
    Call registerEvents(m_ctx)
    
    Call addViewClass(Me)
    
    m_inited = True
    initViewer = IOK_SUCCEEDED
End Function


'***********************************************************************************
'Destroy and release the viewer.
'***********************************************************************************

Public Function uninitViewer()
    If m_pixmap <> 0 Then
        Call uv_drop_pixmap(m_ctx, m_pixmap)
        m_pixmap = 0
    End If
    
    If m_ctx <> 0 Then
        Call uv_drop_context(m_ctx)
        m_ctx = 0
    End If
    
    Call removeViewClass(Me)
    
    m_inited = False
End Function

'***********************************************************************************
'Register fonts
'***********************************************************************************

Public Function registerFont(filename As String) As Long
    registerFont = uv_register_font(m_ctx, filename)
End Function

'***********************************************************************************
'Open a document
'***********************************************************************************

Public Function openfile(filename As String) As Long
    openfile = uv_open_file(m_ctx, filename, 0)
End Function

'***********************************************************************************
'Render the doucment to a image buffer
'***********************************************************************************

Public Function render(page As Long, Optional fillInfo As Boolean = False) As Long
    Dim rc As Long
    
    ' release the previous page if needed
    If m_pixmap <> 0 Then
        Call uv_drop_pixmap(m_ctx, m_pixmap)
        m_pixmap = 0
    End If
    
    rc = uv_render_pixmap(m_ctx, page, m_pixmap)
    If (SUCCESS(rc)) Then
        
        rc = uv_pixmap_getinfos(m_ctx, m_pixmap, m_width, m_height, m_n, m_samples)
        If (SUCCESS(rc)) Then
        
            If fillInfo Then
                rc = uv_pixmap_fill_docinfo(m_ctx, m_pixmap)
                If (SUCCESS(rc)) Then

                    render = IOK_SUCCEEDED
                    Exit Function
                End If
            End If
            
        End If
        
    End If
    
    render = rc
End Function


'***********************************************************************************
'Fill the infomation of document
'***********************************************************************************

Public Function fillDocInfo() As Long
    If m_pixmap <> 0 Then
        fillDocInfo = uv_pixmap_fill_docinfo(m_ctx, m_pixmap)
    Else
        fillDocInfo = IERR_FAILED
    End If
End Function


'***********************************************************************************
'Draw the image of page
'***********************************************************************************

Public Sub paint(hWnd As Long, x As Long, y As Long)
    Dim rc As Long
    Dim hDC As Long
    Dim hBufferDC As Long
    
    If m_pixmap = 0 Then GoTo out
    
    hDC = GetDC(hWnd)
    If hDC = 0 Then _
        GoTo error
    hBufferDC = CreateCompatibleDC(hDC)
    
    '
    ' Create the DIB section
    '
    Dim bmInfo As BITMAPINFO
    bmInfo.bmiHeader.biSize = LenB(bmInfo)
    bmInfo.bmiHeader.biWidth = m_width
    bmInfo.bmiHeader.biHeight = -m_height
    bmInfo.bmiHeader.biSizeImage = m_height * 4
    bmInfo.bmiHeader.biPlanes = 1
    bmInfo.bmiHeader.biBitCount = 32
    bmInfo.bmiHeader.biCompression = BI_RGB
    bmInfo.bmiHeader.biXPelsPerMeter = 2834
    bmInfo.bmiHeader.biYPelsPerMeter = 2834
    
    '
    ' Paint the image
    '
    Select Case m_n
        Case 4: ' 4 BPP (Bytes Per Pixel)
            rc = SetDIBitsToDevice(hDC, x, y, m_width, m_height, 0, 0, 0, m_height, m_samples, bmInfo, 0)
        Case 2: ' 2 BPP
            Dim color As Long
            rc = uv_convert_2_bpp(m_ctx, m_pixmap, color)
            
            If (SUCCESS(rc)) Then
                rc = SetDIBitsToDevice(hDC, x, y, m_width, m_height, 0, 0, 0, m_height, color, bmInfo, 0)
                
                Call uv_drop_mem(m_ctx, color)
            End If
        Case Else: ' UNKNOWN
            Debug.Print "paint(): unknown n = "; m_n
    End Select
    
    GoTo out
error:
    Debug.Print "paint(): err = "; GetLastError()
out:
    If hDC <> 0 Then Call ReleaseDC(hWnd, hDC)
    If hBufferDC <> 0 Then Call ReleaseDC(hWnd, hBufferDC)
End Sub


'***********************************************************************************
'Get the pointer of context
'***********************************************************************************

Public Function getContext() As Long
    getContext = m_ctx
End Function

'***********************************************************************************
'Get the number of pages
'***********************************************************************************

Public Function getPageCount() As Long
    getPageCount = uv_get_page_count(m_ctx)
End Function

'***********************************************************************************
'Scale the page, but not refresh the samples
'***********************************************************************************

Public Function zoom(sx As Single, sy As Single) As Long
    zoom = uv_scale(m_ctx, sx, sy)
    m_scale_x = sx
    m_scale_y = sy
End Function

'***********************************************************************************
'Rotate the page, but not refresh the samples
'***********************************************************************************

Public Function rotate(th As Single) As Long
    rotate = uv_rotate(m_ctx, th)
End Function

'***********************************************************************************
'Get the width of document
'***********************************************************************************

Public Function getWidth() As Long
    getWidth = m_width
End Function

'***********************************************************************************
'Get the height of document
'***********************************************************************************

Public Function getHeight() As Long
    getHeight = m_height
End Function

'***********************************************************************************
'Handle the mouse event
'***********************************************************************************

Public Function onMouse(x As Long, y As Long, btn As Long, state As Long) As Long
    If m_pixmap <> 0 Then
        onMouse = uv_mouse_event(m_ctx, m_pixmap, x, y, btn, 0, state)
    Else
        onMouse = IERR_FAILED
    End If
End Function


'***********************************************************************************
'Handle the callback
'***********************************************************************************

Public Sub invokeCursor(ByVal cursor As Long)
    RaiseEvent onCursor(cursor)
End Sub
Public Sub invokeGotoPage(ByVal page As Long)
    RaiseEvent onGotoPage(page)
End Sub
Public Sub invokeGotoURL(ByVal url As String)
    RaiseEvent onGotoURL(url)
End Sub
Public Sub invokeWarn(ByVal msg As String)
    RaiseEvent onWarn(msg)
End Sub
