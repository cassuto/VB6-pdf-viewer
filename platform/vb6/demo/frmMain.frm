VERSION 5.00
Begin VB.Form frmMain 
   Caption         =   "Form1"
   ClientHeight    =   8085
   ClientLeft      =   60
   ClientTop       =   450
   ClientWidth     =   10605
   LinkTopic       =   "Form1"
   ScaleHeight     =   8085
   ScaleWidth      =   10605
   StartUpPosition =   3  '´°¿ÚÈ±Ê¡
   Begin VB.CommandButton cmdZoom 
      Caption         =   "zoom"
      Height          =   255
      Left            =   3240
      TabIndex        =   6
      Top             =   120
      Width           =   735
   End
   Begin VB.HScrollBar hsView 
      Height          =   255
      Left            =   120
      TabIndex        =   5
      Top             =   7800
      Width           =   10215
   End
   Begin VB.VScrollBar vsView 
      Height          =   7335
      Left            =   10320
      TabIndex        =   4
      Top             =   480
      Width           =   255
   End
   Begin VB.CommandButton cmdForward 
      Caption         =   ">>"
      Height          =   255
      Left            =   2160
      TabIndex        =   3
      Top             =   120
      Width           =   735
   End
   Begin VB.CommandButton cmdBackward 
      Caption         =   "<<"
      Height          =   255
      Left            =   240
      TabIndex        =   2
      Top             =   120
      Width           =   735
   End
   Begin VB.PictureBox picView 
      Height          =   7335
      Left            =   120
      ScaleHeight     =   7275
      ScaleWidth      =   10155
      TabIndex        =   0
      Top             =   480
      Width           =   10215
   End
   Begin VB.Label labNavig 
      AutoSize        =   -1  'True
      Caption         =   "0 / 0"
      Height          =   180
      Left            =   1200
      TabIndex        =   1
      Top             =   160
      Width           =   450
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

#Const FULL_FONTS = True

Dim WithEvents m_view As clsViewer
Attribute m_view.VB_VarHelpID = -1

Dim m_currentPage As Long
Dim m_pageCount As Long
Dim m_boundX As Long
Dim m_boundY As Long

Dim rc As Long


Private Sub cmdZoom_Click()
    Dim sx As Single, sy As Single
    
    sx = CSng(InputBox("scale X % = ?"))
    sy = CSng(InputBox("scale Y % = ?"))
    
    If sx < 0 Then sx = 0
    If sy < 0 Then sy = 0
    
    Call m_view.zoom(sx, sy)
    Call m_view.render(m_currentPage, True)
    picView.SetFocus
    picView.Refresh
End Sub

Private Sub Form_Load()
    Dim rc As Long
    Dim fn As String
    
    Form_Resize
    
    Set m_view = New clsViewer ' create a viewer class
    
    '/////////////////////////////////////////////////////////////////////////////////////////
    
    rc = m_view.initViewer()
    
    If (FAILURE(rc)) Then
        ErrorMsg "Initialize the viewer,", rc
        GoTo error
    End If
    
    '/////////////////////////////////////////////////////////////////////////////////////////
    
#If FULL_FONTS Then
    rc = m_view.registerFont("libuvfonts.dll")
#Else
    rc = m_view.registerFont("libuvfonts-tiny.dll")
#End If

    If FAILURE(rc) Then
        Call ErrorMsg("registerFont()", IERR_LOAD_FONT)
    End If

    '/////////////////////////////////////////////////////////////////////////////////////////
    
    fn = winOpenFile(hWnd)
    
    If fn <> "" Then
        Call loadFile(fn)
    
        Call loadPage(1)
    End If
    
error:
End Sub

Private Sub Form_Resize()
    If Me.WindowState = vbMinimized Then Exit Sub
    
    vsView.Left = picView.Width + 120
    hsView.Top = picView.Height + 480
    picView.Width = Me.ScaleWidth - 240 - IIf(vsView.Visible, 255, 0)
    picView.Height = Me.ScaleHeight - 600 - IIf(hsView.Visible, 255, 0)
    vsView.Height = picView.Height
    hsView.Width = picView.Width
End Sub

Private Sub Form_Unload(Cancel As Integer)
    Call m_view.uninitViewer
    
    Set m_view = Nothing ' terminate the viewer class
    
    g_exit = True
End Sub



Private Sub picView_MouseDown(Button As Integer, Shift As Integer, x As Single, y As Single)
    Call m_view.onMouse(x / Screen.TwipsPerPixelX - m_boundX, y / Screen.TwipsPerPixelY - m_boundY, CLng(Button), 1)
End Sub

Private Sub picView_MouseUp(Button As Integer, Shift As Integer, x As Single, y As Single)
    Call m_view.onMouse(x / Screen.TwipsPerPixelX - m_boundX, y / Screen.TwipsPerPixelY - m_boundY, CLng(Button), -1)
End Sub

Private Sub picView_MouseMove(Button As Integer, Shift As Integer, x As Single, y As Single)
    Call m_view.onMouse(x / Screen.TwipsPerPixelX - m_boundX, y / Screen.TwipsPerPixelY - m_boundY, CLng(Button), 0)
End Sub


Private Sub picView_Paint()
    Call updateSrcollbars
    Call m_view.paint(picView.hWnd, m_boundX, m_boundY)
End Sub

Private Sub cmdBackward_Click()
    If m_currentPage - 1 > 0 Then
        Call loadPage(m_currentPage - 1)
    End If
End Sub

Private Sub cmdForward_Click()
    If m_currentPage + 1 <= m_pageCount Then
        Call loadPage(m_currentPage + 1)
    End If
End Sub


Private Sub vsView_Scroll()
    m_boundY = -vsView.Value
    picView.SetFocus
    Call picView_Paint
End Sub
Private Sub vsView_Change()
    vsView_Scroll
End Sub

Private Sub hsView_Scroll()
    m_boundX = -hsView.Value
    picView.SetFocus
    Call picView_Paint
End Sub
Private Sub hsView_Change()
    hsView_Scroll
End Sub


Private Sub updateSrcollbars()
    Dim docH As Long, docW As Long
    
    docH = m_view.getHeight()
    docW = m_view.getWidth()
    
    If docH * Screen.TwipsPerPixelY > picView.Height Then
        vsView.LargeChange = picView.Height / Screen.TwipsPerPixelY
        vsView.Min = 0
        vsView.Max = docH - picView.Height / Screen.TwipsPerPixelY
        vsView.Visible = True
    Else
        vsView.Visible = False
    End If
    
    If docW * Screen.TwipsPerPixelX > picView.Width Then
        hsView.LargeChange = picView.Width / Screen.TwipsPerPixelX
        hsView.Min = 0
        hsView.Max = docW - picView.Width / Screen.TwipsPerPixelX
        hsView.Visible = True
    Else
        hsView.Visible = False
    End If
    
    Form_Resize
End Sub



Private Sub m_view_onCursor(cursor As Long)
    Screen.MouseIcon = LoadResPicture(100, vbResCursor)
    Select Case cursor
        Case NORMAL: Screen.MousePointer = vbDefault '!fixme: resizing cursor is gone when we drag the border of a Window
        Case ARROW: Screen.MousePointer = vbArrow
        Case HAND: Screen.MousePointer = vbCustom
        Case WAIT: Screen.MousePointer = vbHourglass
        Case CARET: Screen.MousePointer = vbArrowQuestion
    End Select
End Sub

Private Sub m_view_onGotoPage(page As Long)
    Call loadPage(page)
End Sub

Private Sub m_view_onGotoURL(url As String)
    MsgBox "onGotoURL: " & url
End Sub

Private Sub m_view_onWarn(msg As String)
    MsgBox "onWarn:" & vbCrLf & msg
End Sub



'***********************************************************************************
'load a document file (within UI)
'***********************************************************************************

Private Sub loadFile(filename As String)
    
    rc = m_view.openfile(filename)
    
    If (FAILURE(rc)) Then
        ErrorMsg "Open doucment file.", rc
        GoTo error
    End If
    
    m_pageCount = m_view.getPageCount()
    
error:
End Sub


'***********************************************************************************
'load a page (within UI)
'***********************************************************************************

Private Sub loadPage(n As Long)
    
    rc = m_view.render(n, True)
    
    If (FAILURE(rc)) Then
        ErrorMsg "Render the document page.", rc
        GoTo error
    End If
    
    picView.Refresh
    
    m_boundX = 0
    m_boundY = 0
    
    hsView.Value = 0
    vsView.Value = 0
    
    Call updateSrcollbars
    
    '
    ' update UI
    '
    m_currentPage = n
    labNavig.Caption = n & "/" & m_pageCount
    
    cmdBackward.Enabled = (m_currentPage - 1 > 0)
    cmdForward.Enabled = (m_currentPage + 1 <= m_pageCount)
    
error:
End Sub

