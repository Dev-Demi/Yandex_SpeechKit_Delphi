unit UYandexThread;

interface

uses
  System.Classes,System.Net.URLClient,sysutils,bass, BASSOPUS,
  System.Net.HttpClient, System.JSON, System.Generics.Collections,system.NetConsts;

type
  TGetDataEvent = procedure(const aStrParam:string) of object;
  TYandexThread = class(TThread)
  private
    { Private declarations }
    FOnGetDataEvent : TGetDataEvent;
    FHTTPClient : THTTPClient;
    FTextData : String;
    FOAuthToken,FFolderId,FiamToken,FText:String;
    fDelay,fCount:integer;
    Procedure GenerateEvent;
  protected
    procedure Execute; override;
  public
///   <summary>
///   Создает отдельный поток, в котором будет вопроизводиться звук. </summary>
///   <param name="OAuthToken"> токен, берется в админке яндекса </param>
///   <param name="FolderId"> FolderId, берется в админке яндекса
///   </param>
///   <param name="iamToken"> iamToken, Если параметр пустой - то при запуске этот
///    параметр получается автоматически и возвращается в событии OnGetDataEvent, звук при этом не воспроизводится.
///    Если параметр указан - идет вопроизведение звука.
///   </param>
///   <param name="Text"> Текст для синтеза речи, параметры речи указаны в строках 110-115
///   </param>
///   <param name="Delay"> Задержка в мс, замораживает поток, добавляет паузу в мс между повторами.
///   </param>
///  <param name="Count"> Количество сколько раз будет повторяться воспроизводение
///   </param>
///  <param name="AFOnGetDataEvent"> Событие в котором возврящается временный iamToken токен, время жизни около часа.
///   </param>
///   <code>https://t.me/devdemi</code>

    constructor Create(OAuthToken,FolderId,iamToken,Text:String;Delay,Count:integer; AFOnGetDataEvent: TGetDataEvent);
    destructor Destroy; override;
    property OnGetDataEvent : TGetDataEvent read FOnGetDataEvent write FOnGetDataEvent;
  end;

implementation

{ TYandexThread }

constructor TYandexThread.Create(OAuthToken,FolderId,iamToken,Text:String;Delay,Count:integer;AFOnGetDataEvent: TGetDataEvent);
begin
  FOnGetDataEvent:=AFOnGetDataEvent;
  FHTTPClient:=THTTPClient.Create;
  FHTTPClient.ContentType := 'application/json';
  FHTTPClient.Accept      := 'application/json';
  BASS_Init(-1, 44100, 0, 0, nil);
  FOAuthToken:=OAuthToken;
  FFolderId:=FolderId;
  FiamToken:=iamToken;
  FText:=Text;
  fDelay:=Delay;
  fCount:=Count;
  Inherited Create(False);
end;

destructor TYandexThread.Destroy;
begin
  if Assigned(FHTTPClient) then
    FHTTPClient.Free;
  inherited Destroy;
end;

procedure TYandexThread.Execute;
var
 AJSON : TJSONObject;
 HTTPResponse : IHTTPResponse;
 Params : TStringStream ;
 RecStr:string;
 fs:TMemoryStream;
 strm:DWORD;
 playingLength:double;
 i:integer;
begin
 RecStr:='{"yandexPassportOauthToken": "' + FOAuthToken + '"}';
 Params := TStringStream.Create(RecStr, TEncoding.UTF8);
 Params.Position := 0;

  if FiamToken = '' then
  begin
    HTTPResponse := FHTTPClient.Post
      ('https://iam.api.cloud.yandex.net/iam/v1/tokens', Params);

    if HTTPResponse.StatusCode = 200 then
    begin
      FTextData := HTTPResponse.ContentAsString;
      AJSON := TJSONObject.ParseJSONValue(FTextData) as TJSONObject;
      if AJSON = nil then
      begin
        FOnGetDataEvent('Error parse json');
        exit;
      end;

      FTextData := AJSON.GetValue('iamToken').Value;
      Synchronize(GenerateEvent);
    end
    else
      FOnGetDataEvent('Error HTTP:' + HTTPResponse.StatusCode.ToString + ' ' +
        HTTPResponse.ContentAsString);
  end
  else
  begin
    Params.Clear;
    Params.WriteString('text=' + FText);
    Params.WriteString('&lang=ru-RU');
    Params.WriteString('&speed=0.9');
    Params.WriteString('&voice=alena');
    Params.WriteString('&emotion=good');
    Params.WriteString('&folderId=' + FFolderId);

    Params.Position := 0;

    FHTTPClient.CustomHeaders['Authorization'] := 'Bearer ' +  FiamToken;
    FHTTPClient.CustomHeaders['Content-Type'] :='application/x-www-form-urlencoded;';

    HTTPResponse := FHTTPClient.Post
      ('https://tts.api.cloud.yandex.net/speech/v1/tts:synthesize', Params);

    fs := TMemoryStream.Create;
    if HTTPResponse.StatusCode = 200 then
    begin
      fs.CopyFrom(HTTPResponse.ContentStream, HTTPResponse.ContentStream.Size);
      fs.Position := 0;
      strm := BASS_OPUS_StreamCreateFile(true, fs.Memory, 0, fs.Size, 0);

      playingLength:=BASS_ChannelBytes2Seconds(strm,
        BASS_ChannelGetLength(strm,BASS_POS_BYTE));
      for I := 1 to fCount do
      begin
       BASS_ChannelPlay(strm, False);
       sleep(Round(playingLength*1000) + fDelay);
      end;
    end;
     fs.Free;
  end;

 BASS_Free;
 Params.Free;

end;

procedure TYandexThread.GenerateEvent;
begin
 if Assigned(FOnGetDataEvent) then
    FOnGetDataEvent(FTextData);
end;

end.
