program linamp;

{$mode objfpc}{$H+}
{$r linamp.res}

uses
  Interfaces, // this includes the LCL widgetset
  Forms
  { add your units here }, MainForm, PlaylistEditor;

begin
  Application.Title:='Linamp';
  Application.Initialize;
  Application.CreateForm(TMain, Main);
  Application.CreateForm(TPlaylistWindow, PlaylistWindow);
  Main.RegisterCallbacks();
  Application.Run;
end.

