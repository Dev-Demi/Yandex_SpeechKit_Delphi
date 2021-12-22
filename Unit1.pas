unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UYandexThread, System.Net.URLClient,bass,BASSOPUS ,
  System.Net.HttpClient, System.Net.HttpClientComponent, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Memo2: TMemo;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Procedure GetDataFromYandex(const Data:string);
  end;

var
  Form1: TForm1;
  OAuthToken,FolderId,iamToken:String;
implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin

 // https://console.cloud.yandex.ru/    

 OAuthToken:=''; //Insert you data
 FolderId:='';   //Insert you data
 iamToken:='';

 TYandexThread.Create(OAuthToken,FolderId,iamToken,'Накладная 62 305 приглашается к Терминалу 1. Склад А',1000,3, GetDataFromYandex);
end;

procedure TForm1.GetDataFromYandex(const Data: String);
begin
 memo2.Text:=data;
 iamToken:= Data;
end;

end.
