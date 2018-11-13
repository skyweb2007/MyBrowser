program MyBrowser;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  uCEFApplication,
  mbmainform, mbwebpanel, mbfavicongetter;

{$R *.res}

begin
  GlobalCEFApp := TCefApplication.Create;
  GlobalCEFApp.FrameworkDirPath     := 'cef';
  GlobalCEFApp.ResourcesDirPath     := 'cef';
  GlobalCEFApp.LocalesDirPath       := 'cef\locales';
  GlobalCEFApp.cache                := 'cache';
  GlobalCEFApp.cookies              := 'cookies';
  GlobalCEFApp.UserDataPath         := 'data';
  GlobalCEFApp.CustomFlashPath      := 'flash';
  GlobalCEFApp.FlashEnabled         := true;
  GlobalCEFApp.BrowserSubprocessPath:= 'subprocess.exe';
  GlobalCEFApp.EnableGPU            := true;
  if GlobalCEFApp.StartMainProcess then
  begin
    RequireDerivedFormResource:=True;
    Application.Scaled:=True;
    Application.Initialize;
    Application.CreateForm(TFormMain, FormMain);
    Application.Run;
  end;
  DestroyGlobalCEFApp;
end.

