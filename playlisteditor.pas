unit PlaylistEditor;

{$mode objfpc}{$H+}

interface

uses
  inifiles, Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, ExtCtrls, Buttons, Fmod, FmodTypes;

{$I keycodes.inc}

type

  { TPlaylistWindow }

  TPlaylistWindow = class(TForm)
    AddFileButton: TButton;
    AddDirectoryButton: TButton;
    PlaylistOpenDialog: TOpenDialog;
    PlayListViewer: TListBox;
    OpenDialog: TOpenDialog;
    OpenPlaylistButton: TButton;
    ClearPlayListButton: TButton;
    EditBox: TEdit;
    GroupBox: TGroupBox;
    SelectDirectoryDialog: TSelectDirectoryDialog;
    procedure AddDirectoryButtonClick(Sender: TObject);
    procedure AddFileButtonClick(Sender: TObject);
    procedure ClearPlayListButtonClick(Sender: TObject);
    procedure EditBoxChange(Sender: TObject);
    procedure EditBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure OpenPlaylistButtonClick(Sender: TObject);
    procedure PlayListViewerDblClick(Sender: TObject);
    procedure PlayListViewerKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    procedure PlsRead(filename:string);
    procedure M3uRead(filename:string);
    procedure OpenPlaylist(filename:string);
    cf:integer;
    { private declarations }
  public
    PlayList:TStringList;
    function GetNextFile(shuffle:boolean):string;
    PlayCallback:procedure(s:string)of object;
    procedure AddDir(fname:string);
    { public declarations }
  end; 

var
  PlaylistWindow: TPlaylistWindow;

implementation

{ TPlaylistWindow }

function TPlayListWindow.GetNextFile(shuffle:boolean):string;
begin
 if PlayList.Count>0 then
  begin
   if shuffle then cf:=Random(PlayList.Count-1)
              else cf:=(cf+1) mod (PlayList.Count-1);
//   PlayListViewer.ItemIndex:=cf;
   Result:=PString(PlayList.Objects[cf])^;
  end;
end;

procedure TPlaylistWindow.FormCreate(Sender: TObject);
begin
     Randomize();
     PlayList:=TStringList.Create();
end;

function getartistpart(filename:string):string;
var i:integer;
begin
 for i:=1 to length(filename) do if filename[i]='-' then break;
 result:=copy(filename,1,i-1);
end;

function gettitlepart(filename:string):string;
var i:integer;
begin
 for i:=1 to length(filename) do if filename[i]='-' then break;
 result:=copy(filename,i+1,length(filename)-i);
end;


function GetID3(filename:string):string;
var cfs:pFSoundStream;
    buff:pointer;
    l:integer;
begin
       cfs:=FSOUND_Stream_Open(pchar(filename),FSOUND_NORMAL,0,0);

       if FSOUND_Stream_FindTagField(cfs,FSOUND_TAGFIELD_ID3V1,'ARTIST',buff,l) then GetID3:=trim(pchar(buff))
                                                                                else GetID3:=getartistpart(ExtractFilename(filename));
       if FSOUND_Stream_FindTagField(cfs,FSOUND_TAGFIELD_ID3V1,'TITLE',buff,l) then GetID3:=GetID3+' - '+trim(pchar(buff))
                                                                               else GetID3:=GetID3+' - '+gettitlepart(ExtractFilename(filename));
       if FSOUND_Stream_FindTagField(cfs,FSOUND_TAGFIELD_ID3V1,'ALBUM',buff,l) then GetID3:=GetID3+' ('+trim(pchar(buff))+')'
                                                                               else GetID3:=GetID3+' (Unknown Album)';
       FSOUND_Stream_Close(cfs);
end;

procedure TPlaylistWindow.AddFileButtonClick(Sender: TObject);
var p:PString;
begin
     if OpenDialog.Execute() then
      begin
       new(p);
       p^:=OpenDialog.Filename;
       PlayList.AddObject(GetID3(OpenDialog.filename),TObject(p));
       EditBoxChange(sender);
      end;
end;

function _issupported(s:string):boolean;
const exts:array[1..12] of string=('.AIFF','.ASF','.FLAC','.FSB','.MP2','.MP3','.OGG','.RAV','.S3M','.WAV','.WMA','.XM');
var i:integer;
begin
     for i:=1 to 12 do if s=exts[i] then exit(true);
     exit(false);
end;

procedure TPlayListWindow.AddDir(fname:string);
var t:TSearchRec;
    p:Pstring;
begin
       FindFirst(fname+'\*',faAnyFile,t);
       repeat
       
        if (t.name<>'.')and(t.name<>'..') then
         begin
          if (t.Attr and faDirectory<>faDirectory) then
           begin
            if _issupported(UpCase(ExtractFileExt(t.name))) then
             begin
              new(p);
              p^:=fname+'\'+t.name;
              PlayList.AddObject(GetID3(p^),TObject(p));
             end;
           end
                                                   else AddDir(fname+'\'+t.name);
         end;
         
       until FindNext(t)<>0;
       findClose(t);
end;

procedure TPlaylistWindow.AddDirectoryButtonClick(Sender: TObject);
begin
     if SelectDirectoryDialog.Execute then
      begin
           AddDir(SelectDirectoryDialog.Filename);
           EditBoxChange(sender);
      end;
end;

procedure TPlaylistWindow.ClearPlayListButtonClick(Sender: TObject);
var i:integer;
begin
  for i:=0 to Playlist.Count-1 do Dispose(PString(PlayList.Objects[i]));
  PlayList.Clear();
  EditBoxChange(sender);
end;

procedure TPlaylistWindow.EditBoxChange(Sender: TObject);
var i:integer;
begin
  PlayListViewer.Items.Assign(PlayList);
  i:=0;
  if EditBox.Text<>'' then
    while i<PlayListViewer.Items.Count do
     begin
      if pos(upcase(EditBox.Text),upcase(PlayListViewer.Items.Strings[i]))=0 then PlayListViewer.Items.Delete(i)
                                                             else inc(i);
     end;
  if PlayListViewer.Items.Count>0 then PlayListViewer.ItemIndex:=0;
end;

procedure TPlaylistWindow.EditBoxKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (key=VK_DOWN)or(key=VK_UP) then ActiveControl:=PlayListViewer;
  if (key=VK_RETURN)and(PLayListViewer.ItemIndex>=0) then
   PlayCallback(PString(PlayListViewer.Items.Objects[PlayListViewer.ItemIndex])^);
end;

procedure TPlaylistWindow.FormActivate(Sender: TObject);
begin
  ActiveControl:=EditBox;
end;


procedure TPlaylistWindow.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  ClearPlayListButtonClick(sender);
end;

procedure TPlaylistWindow.FormCloseQuery(Sender: TObject; var CanClose: boolean
  );
begin
  canclose:=false;
  visible:=false;
end;

procedure TPlaylistWindow.FormResize(Sender: TObject);
var b:integer;
begin
  GroupBox.Width:=Width-8;
  EditBox.Width:=Width-20;
  PlayListViewer.Width:=Width-8;
  PlayListViewer.Height:=Height-30-PlayLIstViewer.Top;
  b:=(width-300) div 5;
  AddFileButton.Top:=Height-28;
  AddFileButton.Left:=b;
  AddDirectoryButton.Top:=Height-28;
  AddDirectoryButton.Left:=2*b+75;
  ClearPlaylistButton.Top:=Height-28;
  ClearPlaylistButton.Left:=3*b+150;
  OpenPlaylistButton.Top:=Height-28;
  OpenPlaylistButton.Left:=4*b+225;
end;

procedure TPlayListWindow.PlsRead(filename:string);
var f:TIniFile;
    n,i:integer;
    s:string;
    p:Pstring;
begin
     f:=TIniFile.Create(filename);
     n:=f.ReadInteger('Playlist','numberofentries',0);
     for i:=1 to n do
      begin
       s:=f.ReadString('Playlist','File'+IntToStr(i),'');
       if _issupported(UpCase(ExtractFileExt(s))) then
        begin
         new(p);
         p^:=s;
         PlayList.AddObject(GetID3(p^),TObject(p));
        end;
      end;
     f.Destroy();
end;

procedure TPlayLIstWindow.M3uRead(filename:string);
begin
end;

procedure TPlaylistWindow.OpenPlaylist(filename:string);
var f:System.text;
    header:string;
begin
     System.assign(f,filename);
     reset(f);
     readln(f,header);
     System.close(f);
     if header='[playlist]' then PlsRead(filename)
                            else
     if header='#EXTM3U' then M3uRead(filename);
end;

procedure TPlaylistWindow.OpenPlaylistButtonClick(Sender: TObject);
begin
  if PlayListOpenDialog.Execute then
   begin
    //clear everything
    ClearPlayListButtonClick(sender);
    //open
    OpenPlayList(PlayListOpenDialog.Filename);
    //refresh
    EditBoxChange(sender);
   end;
end;

procedure TPlaylistWindow.PlayListViewerDblClick(Sender: TObject);
begin
  if PlayListViewer.ItemIndex>=0 then
   PlayCallback(PString(PlayListViewer.Items.Objects[PlayListViewer.ItemIndex])^);
end;

procedure TPlaylistWindow.PlayListViewerKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
     if ((key>=VK_A)and(key<=VK_Z))or(key=VK_SPACE)or(key=VK_BACK) then
      begin
       if key=VK_BACK then EditBox.Text:=Copy(EditBox.Text,1,length(EditBox.Text)-1) else
       if key=VK_SPACE then EditBox.Text:=EditBox.text+' ' else EditBox.Text:=EditBox.Text+char(Key);
       ActiveControl:=EditBox;
      end;
     if key=VK_RETURN then
      if PlayListViewer.ItemIndex>=0 then PlayCallback(PString(PlayListViewer.Items.Objects[PlayListViewer.ItemIndex])^);
end;

initialization
  {$I playlisteditor.lrs}

end.

