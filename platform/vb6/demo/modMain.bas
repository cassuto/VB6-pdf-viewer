Attribute VB_Name = "modMain"
Option Explicit

Public g_exit As Boolean

Const CP_UTF8 = 65001
Declare Function WideCharToMultiByte Lib "kernel32" (ByVal CodePage As Long, ByVal dwFlags As Long, ByVal lpWideCharStr As Long, ByVal cchWideChar As Long, ByVal lpMultiByteStr As Long, ByVal cchMultiByte As Long, ByVal lpDefaultChar As Long, ByVal lpUsedDefaultChar As Long) As Long

Type OPENFILENAME
    lStructSize As Long
    hwndOwner As Long
    hInstance As Long
    lpstrFilter As String
    lpstrCustomFilter As String
    nMaxCustFilter As Long
    nFilterIndex As Long
    lpstrFile As String
    nMaxFile As Long
    lpstrFileTitle As String
    nMaxFileTitle As Long
    lpstrInitialDir As String
    lpstrTitle As String
    flags As Long
    nFileOffset As Integer
    nFileExtension As Integer
    lpstrDefExt As String
    lCustData As Long
    lpfnHook As Long
    lpTemplateName As String
End Type

Const OFN_FILEMUSTEXIST = &H1000

Declare Function GetOpenFileName Lib "comdlg32.dll" Alias "GetOpenFileNameA" (pOpenfilename As OPENFILENAME) As Long


'///////////////////////////////////////////////////////////////////////////////////
' Main Entry
'///////////////////////////////////////////////////////////////////////////////////

Sub Main()
    g_exit = False

    Load frmMain
    frmMain.Show

    '
    ' Message loop
    '
    Do
        DoEvents
    Loop Until g_exit
    
    '
    ' Release resources and end
    '
    Unload frmMain
    
    End
End Sub

'***********************************************************************************
'Report the error
'***********************************************************************************

Public Sub ErrorMsg(msg As String, rc As Long)
retry: '!todo: implement retry.

    Select Case MsgBox("error:" & msg & vbCrLf & _
            "rc = " & errGetMsg(rc) & " (" & errGetMsg(rc, True) & ")", vbRetryCancel + vbExclamation, App.Title)
        Case vbCancel
            Exit Sub
        Case vbRetry
            GoTo retry
        Case vbAbort ' unused
            g_exit = True
    End Select
End Sub


'***********************************************************************************
'Report the error
'***********************************************************************************

Public Function winOpenFile(hWnd As Long) As String
    Dim rc As Long
    Dim ofn As OPENFILENAME
    ofn.lStructSize = LenB(ofn)
    ofn.hwndOwner = hWnd
    ofn.lpstrFile = String(1024, 0)
    ofn.nMaxFile = 1023
    ofn.lpstrInitialDir = 0
    ofn.lpstrTitle = "Open a document file"
    ofn.lpstrFilter = "Documents (*.pdf;*.xps;*.cbz;*.epub;*.zip;*.png;*.jpeg;*.tiff)\0*.zip;*.cbz;*.xps;*.epub;*.pdf;*.jpe;*.jpg;*.jpeg;*.jfif;*.tif;*.tiff\0PDF Files (*.pdf)\0*.pdf\0XPS Files (*.xps)\0*.xps\0CBZ Files (*.cbz;*.zip)\0*.zip;*.cbz\0EPUB Files (*.epub)\0*.epub\0Image Files (*.png;*.jpeg;*.tiff)\0*.png;*.jpg;*.jpe;*.jpeg;*.jfif;*.tif;*.tiff\0All Files\0*\0\0"
    ofn.flags = OFN_FILEMUSTEXIST
    
    rc = GetOpenFileName(ofn)
    
    If rc = 0 Then
        winOpenFile = ""
    Else
        ofn.lpstrFile = Trim(ofn.lpstrFile)
        
        Dim out(1024) As Byte
        Call WideCharToMultiByte(CP_UTF8, 0, StrPtr(ofn.lpstrFile), -1, VarPtr(out(0)), 1023, 0, 0)
        winOpenFile = StrConv(out, vbUnicode)
    End If
End Function
