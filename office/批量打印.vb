Sub word批量打印()
    Application.DisplayAlerts = False
    Application.ScreenUpdating = False

    Dim fDialog As FileDialog
    Set fDialog = Application.FileDialog(msoFileDialogFilePicker)
    Dim vrtSelectedItem As Variant
    Dim wdDoc As Document
    Dim showFolder As Boolean
    showFolder = False

    With fDialog
        .Filters.Clear
        .Filters.Add "Word文件", "*.doc; *.docx", 1
        If .Show = -1 Then
            For Each vrtSelectedItem In .SelectedItems
                ' 避免处理脚本自身所在的文件
                If InStrRev(vrtSelectedItem, ThisDocument.Name) = 0 Then
                    On Error Resume Next
                    Set wdDoc = Application.Documents.Open(vrtSelectedItem, ReadOnly:=True)
                    ' 自动识别原后缀名长度，动态生成PDF文件名
                    Dim savePath As String
                    savePath = Left(vrtSelectedItem, InStrRev(vrtSelectedItem, ".") - 1) & ".pdf"
                    
                    wdDoc.ExportAsFixedFormat OutputFileName:=savePath, ExportFormat:=wdExportFormatPDF
                    wdDoc.Close False
                End If
            Next vrtSelectedItem
            If showFolder Then 
                Call Shell("explorer.exe " & Left(fDialog.SelectedItems(1), _
                InStrRev(fDialog.SelectedItems(1), "\")), vbMaximizedFocus)
            End If
        End If
    End With

    Set fDialog = Nothing
    Application.ScreenUpdating = True
    Application.DisplayAlerts = True
End Sub
