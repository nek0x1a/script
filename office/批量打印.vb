Sub doc批量打印()
'Doc批量打印
'需要打印 docx 的话，将模块中的 .doc 换成 .docx （共两处）

Application.DisplayAlerts = False
Application.ScreenUpdating = False
 
Dim fDialog As FileDialog
Set fDialog = Application.FileDialog(msoFileDialogFilePicker)
Dim vrtSelectedItem As Variant
Dim wdDoc As Document
Dim showFolder As Boolean
showFolder = False
With fDialog
'可将 .doc 换成 .docx
.Filters.Add "Word文件", "*.docx", 1
If .Show = -1 Then
For Each vrtSelectedItem In .SelectedItems
If InStrRev(vrtSelectedItem, ThisDocument.Name) = 0 Then
On Error Resume Next
Set wdDoc = Application.Documents.Open(vrtSelectedItem, ReadOnly:=True)
wdDoc.SaveAs Left(vrtSelectedItem, Len(vrtSelectedItem) - 4), wdFormatPDF
wdDoc.Close False
 
End If
Next vrtSelectedItem
If showFolder Then Call Shell("explorer.exe " & Left(fDialog.SelectedItems(1), _
InStrRev(fDialog.SelectedItems(1), "")), vbMaximizedFocus)
End If
End With
 
Set fDialog = Nothing
Application.ScreenUpdating = True
Application.DisplayAlerts = True
End Sub


