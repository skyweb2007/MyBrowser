unit mbmainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ActnList,
  ComCtrls, StdCtrls, LCLType, ExtCtrls,
  uCEFTypes,
  mbwebpanel;

type
  TProgramState = (psInitializing, psRunning, psTerminating);

  { TFormMain }

  TFormMain = class(TForm)
    acBack: TAction;
    acCloseAllPages: TAction;
    acCloseCurrentPage: TAction;
    acCloseLeftPages: TAction;
    acCloseOtherPages: TAction;
    acCloseRightPages: TAction;
    acForward: TAction;
    acRefresh: TAction;
    acShowDevTools: TAction;
    acStop: TAction;
    acGO: TAction;
    acNewPanel: TAction;
    ActionList: TActionList;
    cbUrl: TComboBox;
    ilSiteIcons: TImageList;
    ilToolbar: TImageList;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    pcWebPanels: TPageControl;
    pmWebPanel: TPopupMenu;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    TrayIcon: TTrayIcon;
    procedure ActionListExecute(AAction: TBasicAction; var Handled: Boolean);
    procedure ActionListUpdate(AAction: TBasicAction; var Handled: Boolean);
    procedure cbUrlKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure cbUrlSelect(Sender: TObject);
    procedure edUrlKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure pcWebPanelsChange(Sender: TObject);
    procedure ToolBar1Resize(Sender: TObject);
  private
    FAppPath: string;
    FProgramState: TProgramState;
    FIconList: TStringList;
    procedure UpdateUrl(const AUrl: ustring);
    function OpenDefaultPage: TWebPanel;
    procedure CloseWebPanels(CloseAction: integer; WebPanel: TWebPanel);
  protected
    function Initialize: boolean;
    procedure Finalize;
  public
    procedure OpenURL(const AUrl: ustring);
    function AddWebPanel(AUrl: ustring): TWebPanel;
    procedure DoWebPanelAddressChanged(aPanel: TWebPanel);
    function SearchIcon(const aUrl: string): integer;
    function SetIcon(aIcon: TCustomIcon; const aUrl: string): integer;
  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

const
  csIndexPageUrl = 'chrome:about';

const
  ACTION_OPEN_NEW_PAGE      = 100;
  ACTION_CLOSE_CURRENT_PAGE = 101;
  ACTION_CLOSE_RIGHT_PAGES  = 102;
  ACTION_CLOSE_LEFT_PAGES   = 103;
  ACTION_CLOSE_OTHER_PAGES  = 104;
  ACTION_CLOSE_ALL_PAGES    = 105;

{ TFormMain }

procedure TFormMain.ToolBar1Resize(Sender: TObject);
var
  w, i: integer;
begin
  with TToolBar(Sender) do
  begin
    w := Indent;
    for i := 0 to ControlCount - 1 do
      if Controls[i] is TToolButton then
        inc(w, Controls[i].Width);
    cbUrl.Width := ClientWidth - w;
  end;
end;

function TFormMain.OpenDefaultPage: TWebPanel;
begin
  Result := AddWebPanel(csIndexPageUrl);
end;

function TFormMain.AddWebPanel(AUrl: ustring): TWebPanel;
begin
  Result := TWebPanel.Create(pcWebPanels);
  Result.Parent := pcWebPanels;
  pcWebPanels.ActivePage := Result;
  Result.InitializeChromium(AUrl);
  UpdateUrl(Result.Url);
end;

procedure TFormMain.DoWebPanelAddressChanged(aPanel: TWebPanel);
begin
  if aPanel = pcWebPanels.ActivePage then
    UpdateUrl(aPanel.Url);
end;

function TFormMain.SearchIcon(const aUrl: string): integer;
begin
  Result := FIconList.IndexOf(aUrl);
end;

function TFormMain.SetIcon(aIcon: TCustomIcon; const aUrl: string): integer;
var
  i: integer;
begin
  if not Assigned(aIcon) then Result := -1
  else begin
    Result := SearchIcon(aUrl);
    if Result < 0 then
    begin
      i := ilSiteIcons.AddIcon(aIcon);
      Result := FIconList.Add(aUrl);
      if i <> Result then
        ShowMessage('SetIcon Failed!');
    end;
  end
end;

procedure TFormMain.CloseWebPanels(CloseAction: integer; WebPanel: TWebPanel);
  procedure CloseTabSheet(aTabSheet: TTabSheet);
  begin
    aTabSheet.Free;
  end;
begin
  case CloseAction of
    ACTION_CLOSE_CURRENT_PAGE: CloseTabSheet(WebPanel);
    ACTION_CLOSE_RIGHT_PAGES:
      while pcWebPanels.PageCount > WebPanel.TabIndex + 1 do
        CloseTabSheet(pcWebPanels.Pages[WebPanel.TabIndex + 1]);
    ACTION_CLOSE_LEFT_PAGES:
      while pcWebPanels.Pages[1] <> WebPanel do
        CloseTabSheet(pcWebPanels.Pages[1]);
    ACTION_CLOSE_OTHER_PAGES: begin
      while pcWebPanels.PageCount > WebPanel.TabIndex + 1 do
        CloseTabSheet(pcWebPanels.Pages[WebPanel.TabIndex + 1]);
      while pcWebPanels.Pages[1] <> WebPanel do
        CloseTabSheet(pcWebPanels.Pages[1]);
    end;
    ACTION_CLOSE_ALL_PAGES: while pcWebPanels.PageCount > 1 do
      CloseTabSheet(pcWebPanels.Pages[1]);
  end;
end;

function TFormMain.Initialize: boolean;
begin
  Result := true;
  FIconList := TStringList.Create;
  OpenDefaultPage;
end;

procedure TFormMain.Finalize;
begin
  FreeAndNil(FIconList);
end;

procedure TFormMain.OpenURL(const AUrl: ustring);
var
  panel: TWebPanel;
begin
  panel := TWebPanel(pcWebPanels.ActivePage);
  if not Assigned(panel) then AddWebPanel(AUrl)
  else panel.OpenUrl(AUrl);
end;

procedure TFormMain.UpdateUrl(const AUrl: ustring);
var
  i: integer;
  s: string;
begin
  s := string(aUrl);
  i := cbUrl.Items.IndexOf(s);
  if i < 0 then
  begin
    cbUrl.Items.Insert(0, s);
    cbUrl.ItemIndex := 0;
  end
  else begin
    cbUrl.Items.Move(i, 0);
    cbUrl.ItemIndex := 0;
  end;
end;

procedure TFormMain.ActionListUpdate(AAction: TBasicAction; var Handled: Boolean
  );
var
  WebPanel: TWebPanel;
  ac: TAction;
begin
  ac := AAction as TAction;
  if pcWebPanels.ActivePage = nil then ac.Enabled := false
  else begin
    WebPanel := (pcWebPanels.ActivePage as TWebPanel);
    Handled := true;
    case ac.Tag of
      ACTION_GO: ac.Enabled := Trim(cbUrl.Text) <> '';
      ACTION_BACK..ACTION_MAXINDEX: ac.Enabled := WebPanel.CanDoAction(ac.Tag);
      ACTION_OPEN_NEW_PAGE: ac.Enabled := true;
      ACTION_CLOSE_CURRENT_PAGE: ac.Enabled := WebPanel.TabIndex > 0;
      ACTION_CLOSE_RIGHT_PAGES: ac.Enabled := WebPanel.TabIndex < pcWebPanels.PageCount - 1;
      ACTION_CLOSE_LEFT_PAGES: ac.Enabled := WebPanel.TabIndex > 1;
      ACTION_CLOSE_OTHER_PAGES:
        ac.Enabled := ((WebPanel.TabIndex = 0) and (pcWebPanels.PageCount > 1)) or (pcWebPanels.PageCount > 2);
      ACTION_CLOSE_ALL_PAGES: ac.Enabled := pcWebPanels.PageCount > 1;
      else Handled := false;
    end;
  end;
end;

procedure TFormMain.cbUrlKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 13 then
  begin
    Key := 0;
    acGo.Execute;
  end;
end;

procedure TFormMain.cbUrlSelect(Sender: TObject);
begin
  OpenUrl(ustring(cbUrl.Text));
end;

procedure TFormMain.edUrlKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then OpenUrl(ustring(cbUrl.Text));
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  w, h: integer;
begin
  Position := poScreenCenter;
  w := Screen.Width;
  h := Screen.Height;
  if w > 1440 then w := 1440;
  if h > 960 then h := 960;
  BoundsRect := Classes.Rect(0, 0, w, h);
  FAppPath := Application.ExeName;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  if FProgramState = psRunning then
  begin
    FProgramState := psTerminating;
    Finalize;
  end;
end;

procedure TFormMain.FormShow(Sender: TObject);
begin
  if FProgramState = psInitializing then
  begin
    if Initialize then FProgramState := psRunning
    else begin
      FProgramState := psTerminating;
      Application.Terminate;
    end;
  end;
end;

procedure TFormMain.pcWebPanelsChange(Sender: TObject);
begin
  if pcWebPanels.PageCount > 0 then
    UpdateUrl((pcWebPanels.ActivePage as TWebPanel).Url)
  else
    UpdateUrl('');
end;

procedure TFormMain.ActionListExecute(AAction: TBasicAction;
  var Handled: Boolean);
var
  WebPanel: TWebPanel;
  ac: TAction;
begin
  ac := AAction as TAction;
  WebPanel := (pcWebPanels.ActivePage as TWebPanel);
  Handled := true;
  case ac.Tag of
    ACTION_GO: OpenUrl(ustring(cbUrl.Text));
    ACTION_BACK..ACTION_MAXINDEX: WebPanel.DoAction(ac.Tag);
    ACTION_OPEN_NEW_PAGE: AddWebPanel('about:blank');
    ACTION_CLOSE_CURRENT_PAGE..ACTION_CLOSE_ALL_PAGES: CloseWebPanels(ac.Tag, WebPanel);
    else Handled := false;
  end;
end;

end.

