
program SubProcess;

uses
  Interfaces,
  uCEFApplication;

begin
  GlobalCEFApp := TCefApplication.Create;
  GlobalCEFApp.FrameworkDirPath     := 'cef';
  GlobalCEFApp.ResourcesDirPath     := 'cef';
  GlobalCEFApp.LocalesDirPath       := 'cef\locales';
  GlobalCEFApp.cache                := 'cache';
  GlobalCEFApp.cookies              := 'cookies';
  GlobalCEFApp.UserDataPath         := 'data';
  GlobalCEFApp.StartSubProcess;
  GlobalCEFApp.Free;
  GlobalCEFApp := nil;
end.

