unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, Fmod, FmodTypes, ComCtrls, StdCtrls, Buttons, PlayListEditor;

type

  { TMain }

  TMain = class(TForm)
    BalanceLabel: TLabel;
    ShowPlaylistCheckbox: TCheckBox;
    ShuffleCheckbox: TCheckBox;
    StopButton: TButton;
    PlayPauseButton: TButton;
    IdleTimer: TIdleTimer;
    SongTicker: TLabel;
    VolumeLabel: TLabel;
    PositionLabel: TLabel;
    SongTrackBar: TTrackBar;
    VolumeTrackbar: TTrackBar;
    BalanceTrackbar: TTrackBar;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IdleTimerTimer(Sender: TObject);
    procedure PlayPauseButtonClick(Sender: TObject);
    procedure ShowPlaylistCheckboxChange(Sender: TObject);
    procedure SongTrackBarEndDrag(Sender, Target: TObject; X, Y: Integer);
    procedure SongTrackBarStartDrag(Sender: TObject; DragObject: TDragObject);
    procedure StopButtonClick(Sender: TObject);
    procedure VolumeTrackbarChange(Sender: TObject);
    procedure PlayCallback(s:string);
    procedure RegisterCallbacks();
  private
    { private declarations }
  public
    { public declarations }
    cf:integer;
    cfs:pFSoundStream;
    cfname:string;
    pos:dword;
    notdragging:boolean;
    killplayback:boolean;
  end; 

var
  Main: TMain;

implementation

{ TMain }

procedure TMain.RegisterCallbacks();
begin
 PlayListWindow.PlayCallback:=@PlayCallback;
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


procedure Tmain.PlayCallback(s:String);
var l:integer;
    buff:pointer;
    fname:string;
begin
     if cfs<>nil then
      begin
       FSOUND_Stream_Stop(cfs);
       FSOUND_Stream_Close(cfs);
      end;
     
     killplayback:=false;
     cfname:=s;
     
     cfs:=FSOUND_Stream_Open(pchar(cfname),FSOUND_HW2D or FSOUND_NORMAL or FSOUND_MPEGACCURATE,0,0);
     cf:=FSOUND_Stream_Play(FSOUND_FREE,cfs);
     FSOUND_SetVolumeAbsolute(cf,VolumeTrackBar.Position);

     //get tags
     if FSOUND_Stream_FindTagField(cfs,FSOUND_TAGFIELD_ID3V1,'ARTIST',buff,l) then fname:=trim(pchar(buff))
                                                                              else fname:=getartistpart(ExtractFilename(cfname));
     if FSOUND_Stream_FindTagField(cfs,FSOUND_TAGFIELD_ID3V1,'TITLE',buff,l) then fname:=fname+' - '+trim(pchar(buff))
                                                                             else fname:=fname+' - '+gettitlepart(ExtractFilename(cfname));
     if FSOUND_Stream_FindTagField(cfs,FSOUND_TAGFIELD_ID3V1,'ALBUM',buff,l) then fname:=fname+' ('+trim(pchar(buff))+')'
                                                                             else fname:=fname+' (Unknown Album)';
                                                                             
     SongTicker.Caption:='Now Playing: '+fname;
end;

procedure TMain.FormCreate(Sender: TObject);
begin
	FSOUND_Init(44100,32,FSOUND_INIT_GLOBALFOCUS);

        IdleTimer.Enabled:=true;
        notdragging:=true;
end;

procedure TMain.FormDestroy(Sender: TObject);
begin
        IdleTimer.Enabled:=false;
        if FSOUND_IsPlayIng(cf) then FSOUND_Stream_Stop(cfs);
        FSOUND_Stream_Close(cfs);
	FSOUND_Close();
end;

procedure TMain.IdleTimerTimer(Sender: TObject);
begin
        if (FSOUND_IsPlaying(cf))and(notdragging) then
         SongTrackBar.position:=FSOUND_Stream_GetTime(cfs) shl 10 div FSOUND_Stream_GetLengthMs(cfs);
        if not(FSOUND_IsPlaying(cf)) then
         begin
          SongTrackBar.Position:=0;
          if not killplayback then
           begin
            PlayCallback(PlayListWindow.GetNextFile(ShuffleCheckbox.checked));
           end;
         end;
        ShowPlayListCheckbox.Checked:=PlayListWindow.Visible;
end;

procedure TMain.PlayPauseButtonClick(Sender: TObject);
begin
     if FSOUND_IsPlaying(cf) then FSOUND_Stream_Stop(cfs)
                             else
      begin
       killplayback:=false;
       cf:=FSOUND_Stream_Play(FSOUND_FREE,cfs);
       FSOUND_Stream_SetTime(cfs,SongTrackBar.Position*FSOUND_Stream_GetLengthMs(cfs) div 1024);
      end
end;

procedure TMain.ShowPlaylistCheckboxChange(Sender: TObject);
begin
  PlayListWindow.visible:= ShowPlayLIstCheckbox.checked;
end;

procedure TMain.SongTrackBarEndDrag(Sender, Target: TObject; X, Y: Integer);
begin
 if FSOUND_IsPlaying(cf) then
  FSOUND_Stream_SetTime(cfs,SongTrackBar.Position*FSOUND_Stream_GetLengthMs(cfs) div 1024);
 notdragging:=true;
end;


procedure TMain.SongTrackBarStartDrag(Sender: TObject; DragObject: TDragObject
  );
begin
   notdragging:=false;
end;

procedure TMain.StopButtonClick(Sender: TObject);
begin
     if  FSOUND_IsPLaying(cf) then
      begin
       FSOUND_Stream_Stop(cfs);
       SongTrackBar.Position:=0;
       killplayback:=true;
      end;
end;

procedure TMain.VolumeTrackbarChange(Sender: TObject);
begin
     if FSOUND_IsPlaying(cf) then FSOUND_SetVolumeAbsolute(cf,VolumeTrackBar.Position);
end;

initialization
  {$I mainform.lrs}

end.

