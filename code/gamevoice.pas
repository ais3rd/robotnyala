{ Voice commands arrive as lines in a text file written by the speech helper
  (data/voice_listen.ps1). This reads the lines that are new since the last poll.
  No Castle Game Engine units here, so it can be unit-tested. }
unit GameVoice;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

uses Classes;

type
  TVoiceInbox = class
  private
    FFileName: string;
    FPos: Int64;          // bytes already consumed
  public
    constructor Create(const FileName: string);
    { Appends each complete new line to Lines. A line still being written waits
      for its line break. A missing file just means nothing has been said yet. }
    procedure Poll(Lines: TStrings);
  end;

implementation

uses SysUtils;

constructor TVoiceInbox.Create(const FileName: string);
begin
  inherited Create;
  FFileName := FileName;
end;

procedure TVoiceInbox.Poll(Lines: TStrings);
var
  F: TFileStream;
  Buf: AnsiString;
  I, Start: Integer;
begin
  if not FileExists(FFileName) then
    Exit;
  try
    F := TFileStream.Create(FFileName, fmOpenRead or fmShareDenyNone);
  except
    on EFOpenError do Exit; // the helper is writing right now: try next poll
  end;
  try
    if F.Size <= FPos then
      Exit;
    SetLength(Buf, F.Size - FPos);
    F.Seek(FPos, soBeginning);
    F.ReadBuffer(Buf[1], Length(Buf));
  finally
    F.Free;
  end;

  { hand over complete lines only; FPos stops before an unfinished one }
  Start := 1;
  for I := 1 to Length(Buf) do
    if Buf[I] = #10 then
    begin
      Lines.Add(Trim(string(Copy(Buf, Start, I - Start))));
      Start := I + 1;
    end;
  FPos := FPos + Start - 1;
end;

end.
