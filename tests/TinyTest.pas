{ Minimal test runner that compiles with both Delphi and Free Pascal.
  Register plain procedures, call Check/CheckNear inside them,
  then RunAllTests prints PASS/FAIL per test and returns the failure count. }
unit TinyTest;

{$ifdef FPC}{$mode delphi}{$H+}{$endif}

interface

type
  TTestProc = procedure;

procedure RegisterTest(const Name: string; Proc: TTestProc);
procedure Check(Condition: Boolean; const Msg: string);
procedure CheckNear(Actual, Expected: Single; const Msg: string);
function RunAllTests: Integer;

implementation

uses SysUtils;

type
  ETestFailed = class(Exception);

var
  TestNames: array of string;
  TestProcs: array of TTestProc;

procedure RegisterTest(const Name: string; Proc: TTestProc);
var
  N: Integer;
begin
  N := Length(TestNames);
  SetLength(TestNames, N + 1);
  SetLength(TestProcs, N + 1);
  TestNames[N] := Name;
  TestProcs[N] := Proc;
end;

procedure Check(Condition: Boolean; const Msg: string);
begin
  if not Condition then
    raise ETestFailed.Create(Msg);
end;

procedure CheckNear(Actual, Expected: Single; const Msg: string);
begin
  if Abs(Actual - Expected) > 1e-3 then
    raise ETestFailed.CreateFmt('%s (expected %.4f, got %.4f)', [Msg, Expected, Actual]);
end;

function RunAllTests: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(TestNames) do
  try
    TestProcs[I]();
    WriteLn('PASS ', TestNames[I]);
  except
    on E: Exception do
    begin
      WriteLn('FAIL ', TestNames[I], ': ', E.Message);
      Inc(Result);
    end;
  end;
  WriteLn(Length(TestNames) - Result, '/', Length(TestNames), ' passed');
end;

end.
