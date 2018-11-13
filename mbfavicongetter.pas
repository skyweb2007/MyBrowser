unit mbfavicongetter;

{$MODE objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics,
  uCEFInterfaces, uCEFRequest, uCEFUrlRequest, uCEFUrlrequestClient, uCEFTypes;

type
  TIconReady = procedure(const Success: Boolean; const Icon: TIcon; const Url: string) of object;

  { TFaviconGetter }

  TFaviconGetter = class(TCefUrlrequestClientOwn)
  private
    FCallback: TIconReady;
    FStream: TMemoryStream;
    FExt: String;
    FUrlRequest: ICefUrlRequest;
  protected
    procedure OnDownloadData(const request: ICefUrlRequest; data: Pointer; dataLength: NativeUInt); override;
    procedure OnRequestComplete(const request: ICefUrlRequest); override;
  public
    constructor Create(Url: String; Callback: TIconReady); reintroduce;
    procedure Cancel;
  end;

implementation

{ TFaviconGetter }

procedure TFaviconGetter.OnDownloadData(const request: ICefUrlRequest; data: Pointer;
  dataLength: NativeUInt);
begin
  if Assigned(FCallback) then FStream.WriteBuffer(data^, dataLength);
end;

procedure TFaviconGetter.OnRequestComplete(const request: ICefUrlRequest);
var
  Picture: TPicture;
  url: string;
begin
  FUrlRequest := nil;
  if Assigned(FCallback) then
  begin
    url := string(request.GetRequest.Url);
    if (request.GetRequestStatus = UR_SUCCESS) and (request.GetResponse.GetStatus div 100 = 2) then
    begin
      FStream.Position := 0;
      try
        Picture := TPicture.Create;
        Picture.LoadFromStreamWithFileExt(FStream, FExt);
        FCallback(True, Picture.Icon, url);
      except
        on E: Exception do
          FCallback(False, nil, url);
      end;
      Picture.Free;
    end
    else FCallback(False, nil, Url);
  end;
  FStream.Free;
end;

constructor TFaviconGetter.Create(Url: String; Callback: TIconReady);
var
  Request: ICefRequest;
begin
  inherited Create;
  FCallback := Callback;
  FStream := TMemoryStream.Create;
  FExt := ExtractFileExt(Url);
  Request := TCefRequestRef.New;
  Request.Url := Utf8Decode(Url);
  FUrlRequest := TCefUrlRequestRef.New(Request, Self, nil);
end;

procedure TFaviconGetter.Cancel;
begin
  FCallback := nil;
  if Assigned(FUrlRequest) then FUrlRequest.Cancel;
end;

end.

