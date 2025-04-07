Attribute VB_Name = "批量转文本文件"
'Doc批量转txt
'需要转换 docx 的话，将模块中的 .doc 换成 .docx （共两处）

Sub 批量转文本文件()
    Application.ScreenUpdating = False
    Dim strFolder As String, strFiles As String, strDocNm As String, wdDoc As Document
    strDocNm = ActiveDocument.FullName
    strFolder = GetFolder
    Debug.Print strFolder
    If strFolder = "" Then Exit Sub
    '可将 .doc 换成 .docx
    strFiles = LoopThroughFiles(strFolder, ".docx", True)

    Dim iFiles() As String
    iFiles() = Split(strFiles, vbTab)

    Dim i As Long
    For i = LBound(iFiles) To UBound(iFiles)
        If iFiles(i) <> "" And iFiles(i) <> strDocNm Then
            Set wdDoc = Documents.Open(FileName:=iFiles(i), AddToRecentFiles:=False, Visible:=False)
            With wdDoc
            '可将 .doc 换成 .docx
            .SaveAs FileName:=Split(iFiles(i), ".docx")(0) & ".txt", FileFormat:=wdFormatText, AddToRecentFiles:=False, Encoding:=msoEncodingUTF8
            .Close SaveChanges:=True
            End With
        End If
    Next i
    Set wdDoc = Nothing
    Application.ScreenUpdating = True
    MsgBox "已转换" & UBound(iFiles) & "个文档"
End Sub

Private Function LoopThroughFiles(inputDirectory As String, filenameCriteria As String, doTraverse As Boolean) As String
    Dim tmpOut As String
    Dim StrFile As String

    If doTraverse = True Then
        Dim allFolders As String
        Dim iFolders() As String
        allFolders = TraverseDir(inputDirectory & "\", 1, 100)
        iFolders() = Split(allFolders, vbTab)

        tmpOut = LoopThroughFiles(inputDirectory, filenameCriteria, False)
        Dim j As Long
        For j = LBound(iFolders) To UBound(iFolders)
            If iFolders(j) <> "" Then
                StrFile = LoopThroughFiles(iFolders(j), filenameCriteria, False)
                tmpOut = tmpOut & vbTab & StrFile
            End If
        Next j
        LoopThroughFiles = tmpOut
    Else
        'https://stackoverflow.com/a/45749626/4650297
        StrFile = Dir(inputDirectory & "\*" & filenameCriteria)
        Do While Len(StrFile) > 0
            tmpOut = tmpOut & vbTab & inputDirectory & "\" & StrFile
            StrFile = Dir()
        Loop
        LoopThroughFiles = tmpOut
    End If
End Function

Private Function TraverseDir(path As String, depth As Long, maxDepth As Long) As String
    'https://analystcave.com/vba-dir-function-how-to-traverse-directories/#Traversing_directories
    If depth > maxDepth Then
        TraverseDir = ""
        Exit Function
    End If
    Dim currentPath As String, directory As Variant
    Dim dirCollection As Collection
    Set dirCollection = New Collection
    Dim dirString As String

    currentPath = Dir(path, vbDirectory)

    'Explore current directory
    Do Until currentPath = vbNullString
        ' Debug.Print currentPath
        If Left(currentPath, 1) <> "." And (GetAttr(path & currentPath) And vbDirectory) = vbDirectory Then
            dirString = dirString & vbTab & path & currentPath
            dirCollection.Add currentPath
        End If
        currentPath = Dir()
    Loop

    TraverseDir = dirString
    'Explore subsequent directories
    For Each directory In dirCollection
        TraverseDir = TraverseDir & vbTab & TraverseDir(path & directory & "\", depth + 1, maxDepth)
    Next directory
End Function

Function GetFolder() As String
    Dim oFolder As Object
    GetFolder = ""
    Set oFolder = CreateObject("Shell.Application").BrowseForFolder(0, "请选择包含要处理的 Word 文档的文件夹：", 0)
    If (Not oFolder Is Nothing) Then GetFolder = oFolder.Items.Item.path
    Set oFolder = Nothing
End Function
