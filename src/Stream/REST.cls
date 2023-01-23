Class Stream.REST Extends %CSP.REST
{

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/image" Method="POST" Call="SaveImage"/>
</Routes>
}

Parameter CHARSET = "utf-8";

Parameter CONTENTTYPE = "application/json";

Parameter CONVERTINPUTSTREAM = 1;

/// <pre>
/// curlコマンドのテスト例
/// 1) フォームデータとして変数名に紐づいてファイルを渡す場合
/// curl -X POST http://localhost:52773/abc/image -F file1=@C:\WorkSpace\StreamTest\imagetest1.png
/// 2) データのBody全部をファイルとして送付する場合
/// curl -X POST http://localhost:52773/abc/image -H "Content-Type:image/png" --data-binary @C:\WorkSpace\StreamTest\imagetest1.png
/// </pre>
ClassMethod SaveImage() As %Status
{
    #dim ex As %Exception.AbstractException
    #dim %request As %CSP.Request
    set savename="c:\temp\post-imagetest1.png"
    set status=$$$OK
    try {
        //ファイルのバイナリストリーム
        set bin=##class(%Stream.FileBinary).%New()
        do bin.LinkToFile(savename)       
        
        /*
         1) フォームデータとして画像が渡る場合のマルチパートのフォーム名がわからない場合
            指定した名称の次の名称を探すメソッドを使用。
            引数に空（""）を指定すると、最初のフォーム名が返る
        */
        set mimedata = %request.NextMimeData("")

        /*
         2) データのBody全部をファイルとして送付した場合変数mimedataは空（""）
            この場合は、%request.Contentにストリームとしてファイルの中身が収納されている
            ストリームをコピーする CopyFrom()を使用して、%request.Contentの中身を
            変数bin(ファイルのバイナリストリーム)にコピーする 
        */
        if $get(mimedata)="" {
            do bin.CopyFrom(%request.Content)
        }
        else {
            /*
            マルチパートで受け取った場合、%reques.GetMimeData(フォーム名)でストリームを取得できるため
            ストリームをコピーする CopyFrom()を使用して、%request.GetMimeData(フォーム名)で取得できる
            ストリームを変数bin(ファイルのバイナリストリーム)にコピーする
            */
            do bin.CopyFrom(%request.GetMimeData(mimedata))
        }
        //ファイル保存
        $$$ThrowOnError(status=bin.%Save())
        
        //保存が成功した場合、HTTP応答のJSON作成
        set result={}
        set result.Message=savename_"に保存しました"
        set result.Status=status
        do result.%ToJSON()
    }
    catch ex {
        set status=ex.AsStatus()
    }
    return status
}

}
