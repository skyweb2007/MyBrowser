unit mbwebpanel;

{$MODE objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ComCtrls, FileUtil, Forms, LCLProc, Graphics,
  ExtCtrls, SyncObjs, StrUtils,
  uCEFChromium, uCEFWindowParent, uCEFTypes, uCEFInterfaces,
  mbfavicongetter;

type

  { TWebPanel }

  TWebPanel = class(TTabSheet)
  private
    FChromium: TChromium;
    FCefWindow: TCEFWindowParent;
    FDevTools: TCEFWindowParent;
    FSplitter: TSplitter;
    FTimer: TTimer;
    FCriticalSection: TCriticalSection;
    FUrl: ustring;
    FDevToolsVisible: boolean;
    FIconGetter: TFaviconGetter;
    procedure DoTimer(Sender: TObject);
    function GetUrl: ustring;
    procedure SetUrl(const AUrl: ustring);
    procedure ShowDevTools;
    procedure DoBeforePopup(Sender: TObject; const browser: ICefBrowser;
      const frame: ICefFrame; const targetUrl, targetFrameName: ustring;
      targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean;
      const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo;
      var client: ICefClient; var settings: TCefBrowserSettings;
      var noJavascriptAccess: Boolean; var Result: Boolean);
    procedure DoAddressChange(Sender: TObject; const browser: ICefBrowser;
      const frame: ICefFrame; const url: ustring);
    procedure DoTitleChange(Sender: TObject; const browser: ICefBrowser; const title: ustring);
    procedure DoFavIconUrlChange(Sender: TObject; const browser: ICefBrowser;
      const iconUrls: TStrings);
    procedure DoIconReady(const Success: Boolean; const AIcon: TIcon; const AUrl: string);
  public
    procedure OpenUrl(const AUrl: ustring);
    procedure DoAction(ActionTag: integer);
    function CanDoAction(ActionTag: integer): boolean;
    procedure InitializeChromium(const AUrl: ustring);
    procedure ChromiumFocus;
    property Url: ustring read GetUrl;
    procedure SetIcon(index: integer);
  end;

const
  ACTION_GO             = 0;
  ACTION_BACK           = 1;
  ACTION_FORWARD        = 2;
  ACTION_REFRESH        = 3;
  ACTION_STOP           = 4;
  ACTION_SHOW_DEVTOOLS  = 5;
  ACTION_MAXINDEX       = 5;

implementation

uses mbmainform;

{ TWebPanel }

procedure TWebPanel.DoTimer(Sender: TObject);
begin
  FTimer.Enabled := False;
  if not(FChromium.CreateBrowser(FCEFWindow, '')) and not(FChromium.Initialized) then
    FTimer.Enabled := True;
end;

function TWebPanel.GetUrl: ustring;
begin
  Result := FUrl;
end;

procedure TWebPanel.SetUrl(const AUrl: ustring);
var
  iconurl: string;
  i: integer;
begin
  FUrl := AUrl;
  if Pos(':', FUrl) < 1 then FUrl := 'http://' + FUrl;
  FormMain.DoWebPanelAddressChanged(Self);
  iconurl := string(FUrl);
  i := Pos('://', iconurl);
  if i > 1 then
  begin
    i := PosEx('/', iconurl, i + 3);
    if i > 0 then iconurl := Copy(iconurl, 1, i)
    else iconurl := iconurl + '/';
    iconurl := iconurl + 'favicon.ico';
    i := FormMain.SearchIcon(iconurl);
    if i >= 0 then SetIcon(i);
  end;
end;

procedure TWebPanel.ShowDevTools;
var
  pt : TPoint;
begin
  if not Assigned(FDevTools) then
  begin
    FSplitter := TSplitter.Create(Self);
    FSplitter.Parent := Self;
    FSplitter.Align := alRight;
    FDevTools := TCEFWindowParent.Create(Self);
    FDevTools.Parent := Self;
    FDevTools.Align := alRight;
    FDevTools.Width := ClientWidth div 4;
    FDevToolsVisible := True;
  end
  else FDevToolsVisible := not FDevToolsVisible;
  pt.x := 0;
  pt.y := 0;
  FSplitter.Visible := FDevToolsVisible;
  FDevTools.Visible  := FDevToolsVisible;
  if FDevToolsVisible then FChromium.ShowDevTools(pt, FDevTools)
  else FChromium.CloseDevTools(FDevTools);
end;

procedure TWebPanel.DoBeforePopup(Sender: TObject; const browser: ICefBrowser;
  const frame: ICefFrame; const targetUrl, targetFrameName: ustring;
  targetDisposition: TCefWindowOpenDisposition; userGesture: Boolean;
  const popupFeatures: TCefPopupFeatures; var windowInfo: TCefWindowInfo; var client: ICefClient;
  var settings: TCefBrowserSettings; var noJavascriptAccess: Boolean; var Result: Boolean);
begin
  Result := targetDisposition in [
    WOD_NEW_FOREGROUND_TAB, WOD_NEW_BACKGROUND_TAB, WOD_NEW_WINDOW, WOD_NEW_POPUP];
  if Result then
  try
    FCriticalSection.Acquire;
    if targetUrl <> 'about:blank' then
      FormMain.AddWebPanel(targetUrl);
    Result := True;
  finally
    FCriticalSection.Release;
  end;
end;

procedure TWebPanel.DoAddressChange(Sender: TObject; const browser: ICefBrowser;
  const frame: ICefFrame; const url: ustring);
begin
  if FChromium.IsSameBrowser(browser) then SetUrl(url);
end;

procedure TWebPanel.DoTitleChange(Sender: TObject; const browser: ICefBrowser; const title: ustring
  );
var
  s: ustring;
begin
  if FChromium.IsSameBrowser(browser) then
  begin
    if Length(title) > 20 then s := Copy(title, 1, 9) + '...'
    else s := title;
    Text := string(s);
  end;
end;

procedure TWebPanel.DoFavIconUrlChange(Sender: TObject; const browser: ICefBrowser;
  const iconUrls: TStrings);
var
  i, j: Integer;
  iconurl: string;
begin
  for i := 0 to iconUrls.Count - 1 do
  begin
    iconurl := iconUrls[i];
    if AnsiEndsText('.ico', iconurl) then
    begin
      j := FormMain.SearchIcon(iconurl);
      if j >= 0 then SetIcon(j)
      else begin
        if Assigned(FIconGetter) then FIconGetter.Cancel;
        FIconGetter := TFaviconGetter.Create(iconurl, @DoIconReady);
        Exit;
      end;
    end;
  end;
end;

procedure TWebPanel.DoIconReady(const Success: Boolean; const AIcon: TIcon; const AUrl: string);
begin
  FIconGetter := nil;
  if Success then SetIcon(FormMain.SetIcon(AIcon, AUrl))
  else SetIcon(-1);
end;

procedure TWebPanel.OpenUrl(const AUrl: ustring);
begin
  SetUrl(AUrl);
  FChromium.LoadURL(FUrl);
  FChromium.SetFocus(True);
end;

procedure TWebPanel.DoAction(ActionTag: integer);
begin
  case ActionTag of
    ACTION_BACK: FChromium.Browser.GoBack;
    ACTION_FORWARD: FChromium.Browser.GoForward;
    ACTION_REFRESH: begin
      FChromium.Browser.Reload;
      FChromium.SetFocus(True);
    end;
    ACTION_STOP: FChromium.Browser.StopLoad;
    ACTION_SHOW_DEVTOOLS: ShowDevTools;
  end;
end;

function TWebPanel.CanDoAction(ActionTag: integer): boolean;
begin
  Result := Assigned(FChromium) and Assigned(FChromium.Browser);
  if Result then
    case ActionTag of
      ACTION_BACK: Result := FChromium.Browser.CanGoBack;
      ACTION_FORWARD: Result := FChromium.Browser.CanGoForward;
      ACTION_REFRESH: Result := not FChromium.Browser.IsLoading;
      ACTION_STOP: Result := FChromium.Browser.IsLoading;
      ACTION_SHOW_DEVTOOLS: Result := not FChromium.Browser.Host.HasDevTools;
      else Result := false;
    end;
end;

procedure TWebPanel.InitializeChromium(const AUrl: ustring);
begin
  if not Assigned(FChromium) then
  begin
    FCriticalSection := TCriticalSection.Create;
    FCEFWindow := TCEFWindowParent.Create(Self);
    FCEFWindow.Parent := Self;
    FCEFWindow.Align := alClient;
    FChromium := TChromium.Create(Self);
    FChromium.WebRTCIPHandlingPolicy := hpDisableNonProxiedUDP;
    FChromium.WebRTCMultipleRoutes := STATE_DISABLED;
    FChromium.WebRTCNonproxiedUDP := STATE_DISABLED;
    SetUrl(AUrl);
    FChromium.DefaultUrl := FUrl;
    FChromium.OnBeforePopup := @DoBeforePopup;
    FChromium.OnTitleChange := @DoTitleChange;
    FChromium.OnFavIconUrlChange := @DoFavIconUrlChange;
    if not(FChromium.CreateBrowser(FCEFWindow, '')) then
    begin
      FTimer := TTimer.Create(Self);
      FTimer.Interval := 300;
      FTimer.OnTimer := @DoTimer;
      FTimer.Enabled := True;
    end;
  end
  else raise Exception.Create('Chromium already initialized.');
end;

procedure TWebPanel.ChromiumFocus;
begin
  FChromium.SetFocus(True);
end;

procedure TWebPanel.SetIcon(index: integer);
begin
  ImageIndex := index;
  PageControl.Repaint;
end;

end.
