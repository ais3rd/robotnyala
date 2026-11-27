unit TestVoice;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

implementation

uses Classes, SysUtils, TinyTest, GameVoice;

const
  FileName = 'voice_test.txt';

procedure Append(const S: string);
var
  F: TFileStream;
  B: AnsiString;
begin
  if FileExists(FileName) then
    F := TFileStream.Create(FileName, fmOpenReadWrite or fmShareDenyNone)
  else
    F := TFileStream.Create(FileName, fmCreate);
  try
    F.Seek(0, soEnd);
    B := AnsiString(S);
    if B <> '' then
      F.WriteBuffer(B[1], Length(B));
  finally
    F.Free;
  end;
end;

procedure TestNoFileNoLines;
var
  Inbox: TVoiceInbox;
  Lines: TStringList;
begin
  DeleteFile(FileName);
  Inbox := TVoiceInbox.Create(FileName);
  Lines := TStringList.Create;
  try
    Inbox.Poll(Lines);
    Check(Lines.Count = 0, 'missing file: nothing yet');
  finally
    Lines.Free;
    Inbox.Free;
  end;
end;

procedure TestNewLinesOnly;
var
  Inbox: TVoiceInbox;
  Lines: TStringList;
begin
  DeleteFile(FileName);
  Inbox := TVoiceInbox.Create(FileName);
  Lines := TStringList.Create;
  try
    Append('#ready'#13#10'left hook'#13#10);
    Inbox.Poll(Lines);
    Check((Lines.Count = 2) and (Lines[0] = '#ready') and (Lines[1] = 'left hook'), 'both lines read');
    Lines.Clear;
    Inbox.Poll(Lines);
    Check(Lines.Count = 0, 'nothing new: nothing returned');
    Append('jab'#13#10);
    Inbox.Poll(Lines);
    Check((Lines.Count = 1) and (Lines[0] = 'jab'), 'only the new line');
  finally
    Lines.Free;
    Inbox.Free;
    DeleteFile(FileName);
  end;
end;

procedure TestPartialLineWaits;
var
  Inbox: TVoiceInbox;
  Lines: TStringList;
begin
  DeleteFile(FileName);
  Inbox := TVoiceInbox.Create(FileName);
  Lines := TStringList.Create;
  try
    Append('upper');
    Inbox.Poll(Lines);
    Check(Lines.Count = 0, 'a half-written line waits');
    Append('cut'#13#10);
    Inbox.Poll(Lines);
    Check((Lines.Count = 1) and (Lines[0] = 'uppercut'), 'then arrives whole');
  finally
    Lines.Free;
    Inbox.Free;
    DeleteFile(FileName);
  end;
end;

initialization
  RegisterTest('Voice.TestNoFileNoLines', TestNoFileNoLines);
  RegisterTest('Voice.TestNewLinesOnly', TestNewLinesOnly);
  RegisterTest('Voice.TestPartialLineWaits', TestPartialLineWaits);
end.
