{ Main view: the robot fight, watched from the operator's spot at the ropes.

  The layout (viewport, both robot sprites, labels, command box) is designed in
  data/gameviewmain.castle-user-interface — open it in the Castle Engine editor.
  The game rules live in GameCommands, GameRobot, GameCombat, GameCamera,
  GameEnemyAnim and GamePlayerAnim (unit-tested); this unit only connects them
  to what you see. }
unit GameViewMain;

interface

uses Classes,
  CastleVectors, CastleComponentSerialize,
  CastleUIControls, CastleControls, CastleKeysMouse,
  CastleViewport, CastleTransform, CastleScene,
  GameCommands, GameRobot, GameCombat, GameEnemyAnim, GameCamera, GamePlayerAnim, GameImpact,
  GameVoice;

type
  TViewMain = class(TCastleView)
  published
    { Components designed using CGE editor.
      These fields will be automatically initialized at Start. }
    LabelFps: TCastleLabel;
    LabelLast: TCastleLabel;
    LabelKO: TCastleLabel;
    LabelCamera: TCastleLabel;
    EditCommand: TCastleEdit;
    HPBarBack: TCastleRectangleControl;
    HPBar: TCastleRectangleControl;
    MainViewport: TCastleViewport;
    PlayerCamera: TCastleCamera;
    Enemy: TCastleImageTransform;
    Player: TCastleImageTransform;
    Floor: TCastlePlane;
  private
    Robot: TRobot;
    EnemyState: TEnemyState;
    EnemyAnim: TEnemyAnimator;
    Feel: TImpactFeel;       // hit-stop, impact flash, shake, streak
    { voice: data/voice_listen.ps1 runs hidden and writes what it hears to a file }
    Voice: TVoiceInbox;
    VoiceProcess: THandle;
    VoicePollLeft: Single;
    VoiceStatus: string;
    { Player robot on the floor plane; see GameCombat for the meaning of FacingDeg. }
    PlayerX, PlayerZ, FacingDeg: Single;
    IdleTime: Single;
    FlashTimeLeft: Single;
    ThreeQuarter: Boolean;   // Tab: 3/4 camera instead of the operator camera
    procedure BuildRing;
    procedure StartVoice;
    procedure PollVoice;
    procedure ShowStatus;
    procedure SubmitCommand(const Text: string);
    procedure RobotMoveStart(Sender: TObject; Move: TRobotCommand);
    procedure PunchAt(Sender: TObject; Move: TRobotCommand);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Start; override;
    procedure Stop; override;
    procedure Update(const SecondsPassed: Single; var HandleInput: Boolean); override;
    function Press(const Event: TInputPressRelease): Boolean; override;
  end;

var
  ViewMain: TViewMain;

implementation

uses {$ifdef MSWINDOWS} Windows, {$endif} SysUtils, CastleColors, CastleRenderOptions, CastleUriUtils;

const
  HitFlashTime = 0.15;
  { all sprite sheets share one pixel density: Boxer 07 standing was 261 px = 2.3 m when
    exported with span 5.3; art/export.js now uses span 6.0 (smaller pixels per metre) }
  SpriteMetersPerPixel = 2.3 / 261 * 6.0 / 5.3;
  SheetBlocks = 2;            // both sheets wrap their frames into 2 blocks (art/export.js)
  OperatorHeight = 0.7;       // crouched at the ring apron (user's pick), so the legs show...
  OperatorLookHeight = 1.1;   // ...looking up at the robots; sprites are drawn from 3 deg below to match
  ThreeQuarterHeight = 2.2;
  ThreeQuarterLookHeight = 1.2;

{ Show Frame seen from direction Dir (layout: GameCamera.SheetCell, row 0 at the top of
  the PNG). Size and Pivot refer to the whole sheet, so the pivot goes to the middle of one
  cell; texture Y=0 is the bottom of the image. Cells are cropped at the feet, so lifting
  the sprite by half a cell stands it on the floor. }
procedure ShowCell(const T: TCastleImageTransform; Frame, FrameCount, Dir: Integer);
var
  Col, Row, Cols, Rows: Integer;
begin
  if T.ImageHeight = 0 then Exit; // image failed to load: nothing to size
  SheetCell(Frame, Dir, FrameCount, SheetBlocks, Col, Row, Cols, Rows);
  T.Size := Vector2(T.ImageWidth * SpriteMetersPerPixel, T.ImageHeight * SpriteMetersPerPixel);
  T.Translation := Vector3(T.Translation.X, T.Size.Y / Rows / 2, T.Translation.Z);
  T.RepeatImage := Vector2(1 / Cols, 1 / Rows);
  T.Pivot := Vector2(0.5 / Cols, 0.5 / Rows);
  T.Shift := Vector2(Col / Cols, (Rows - 1 - Row) / Rows);
end;

{ TViewMain ----------------------------------------------------------------- }

constructor TViewMain.Create(AOwner: TComponent);
begin
  inherited;
  DesignUrl := 'castle-data:/gameviewmain.castle-user-interface';
end;

{ Ring: textured mat on a raised platform (apron skirt), concrete arena floor below,
  4 corner posts (pink = Glitchpop's corner, olive = Boxer 07's), 3 ropes per side at
  0.5 / 0.9 / 1.3 m, and 3 tiers of crowd on every side. Ropes at +-5 m, movement stays
  within +-4.5 m. Textures come from art/arena.html. }
procedure TViewMain.BuildRing;

  procedure Crisp(const P: TCastleAbstractPrimitive; const Url: string; const Scale: TVector2);
  begin
    P.Texture := 'castle-data:/images/' + Url;
    P.TextureScale := Scale;
    P.Color := White;
    P.RenderOptions.MagnificationFilter := magNearest;   // pixel art, no blur
  end;

  procedure AddBox(const Size, Pos: TVector3; const Color: TCastleColor);
  var
    B: TCastleBox;
  begin
    B := TCastleBox.Create(FreeAtStop);
    B.Size := Size;
    B.Translation := Pos;
    B.Color := Color;
    MainViewport.Items.Add(B);
  end;

const
  RopeHeights: array [0..2] of Single = (0.5, 0.9, 1.3);
  PlatformHeight = 0.9;
  CrowdTileW = 4.8;         // crowd.png: 192 x 48 px
  CrowdTileH = 1.2;
var
  Arena: TCastlePlane;
  Platform: TCastleBox;
  Stand: TCastleImageTransform;
  SX, SZ, I, Side, Tier: Integer;
  PostColor: TCastleColor;
  D, Tiles: Single;
begin
  Crisp(Floor, 'ring_mat.png', Vector2(1, 1));
  Floor.Size := Vector2(11, 11);   // rust border shows just outside the ropes

  Platform := TCastleBox.Create(FreeAtStop);
  Platform.Size := Vector3(11, PlatformHeight, 11);
  Platform.Translation := Vector3(0, -PlatformHeight / 2 - 0.01, 0);
  Crisp(Platform, 'ring_apron.png', Vector2(3, 1));
  MainViewport.Items.Add(Platform);

  Arena := TCastlePlane.Create(FreeAtStop);
  Arena.Size := Vector2(40, 40);
  Arena.Translation := Vector3(0, -PlatformHeight, 0);
  Crisp(Arena, 'arena_floor.png', Vector2(20, 20));
  MainViewport.Items.Add(Arena);

  { crowd: 3 rising tiers per side, facing the ring; a still, dark, packed texture }
  for Side := 0 to 3 do
    for Tier := 0 to 2 do
    begin
      D := 9 + Tier * 1.3;
      Tiles := Round(2 * D / CrowdTileW);
      Stand := TCastleImageTransform.Create(FreeAtStop);
      Stand.Url := 'castle-data:/images/crowd.png';
      Stand.SmoothScaling := False;
      Stand.Size := Vector2(CrowdTileW, CrowdTileH);
      Stand.RepeatImage := Vector2(Tiles, 1);                     // tiled along the side
      Stand.Pivot := Vector2(Tiles / 2, 0.5);                     // centred (pivot is per tile)
      Stand.Shift := Vector2(Tier * 0.37 + Side * 0.21, 0);
      Stand.Color := Vector4(0.9 - Tier * 0.12, 0.9 - Tier * 0.12, 0.95 - Tier * 0.1, 1);
      { side 0 is north (-Z) facing +Z; each next side is turned 90 degrees around the ring }
      Stand.Rotation := Vector4(0, 1, 0, Side * Pi / 2);
      Stand.Translation := Vector3(-D * Sin(Side * Pi / 2),
        -PlatformHeight + 0.35 + Tier * 0.8 + CrowdTileH / 2, -D * Cos(Side * Pi / 2));
      MainViewport.Items.Add(Stand);
    end;

  for SX := -1 to 1 do
    for SZ := -1 to 1 do
      if (SX <> 0) and (SZ <> 0) then
      begin
        if (SX > 0) and (SZ > 0) then PostColor := Vector4(1, 0.45, 0.7, 1) else
        if (SX < 0) and (SZ < 0) then PostColor := Vector4(0.4, 0.46, 0.26, 1) else
          PostColor := Vector4(0.9, 0.9, 0.9, 1);
        AddBox(Vector3(0.25, 1.5, 0.25), Vector3(SX * 5, 0.75, SZ * 5), PostColor);
      end;

  for I := 0 to High(RopeHeights) do
  begin
    AddBox(Vector3(10, 0.05, 0.05), Vector3(0, RopeHeights[I], -5), Vector4(0.85, 0.85, 0.85, 1));
    AddBox(Vector3(10, 0.05, 0.05), Vector3(0, RopeHeights[I], 5), Vector4(0.85, 0.85, 0.85, 1));
    AddBox(Vector3(0.05, 0.05, 10), Vector3(-5, RopeHeights[I], 0), Vector4(0.85, 0.85, 0.85, 1));
    AddBox(Vector3(0.05, 0.05, 10), Vector3(5, RopeHeights[I], 0), Vector4(0.85, 0.85, 0.85, 1));
  end;
end;

procedure TViewMain.Start;
begin
  inherited;
  Robot := TRobot.Create;
  Robot.OnMoveStart := {$ifdef FPC}@{$endif}RobotMoveStart;
  Robot.OnImpact := {$ifdef FPC}@{$endif}PunchAt;
  EnemyState := TEnemyState.Create;
  EnemyAnim := TEnemyAnimator.Create;
  Feel := TImpactFeel.Create;

  PlayerX := 0;
  PlayerZ := 0;
  FacingDeg := 0;
  IdleTime := 0;
  FlashTimeLeft := 0;
  ThreeQuarter := False;
  BuildRing;
  StartVoice;
  ShowStatus;

  { all keys go to the command box (typing and dictation tools like Wispr Flow still work) }
  Container.ForceCaptureInput := EditCommand;
end;

procedure TViewMain.Stop;
begin
  if Container.ForceCaptureInput = EditCommand then
    Container.ForceCaptureInput := nil;
  {$ifdef MSWINDOWS}
  if VoiceProcess <> 0 then
  begin
    TerminateProcess(VoiceProcess, 0);
    CloseHandle(VoiceProcess);
    VoiceProcess := 0;
  end;
  {$endif}
  FreeAndNil(Voice);
  FreeAndNil(Robot);
  FreeAndNil(EnemyState);
  FreeAndNil(EnemyAnim);
  FreeAndNil(Feel);
  inherited;
end;

{ Start the hidden speech helper (Windows' offline recognizer, restricted to the
  command phrases). It writes each recognized phrase as a line to VoiceFile. }
procedure TViewMain.StartVoice;
{$ifdef MSWINDOWS}
var
  VoiceFile, Cmd: string;
  SI: TStartupInfo;
  PI: TProcessInformation;
begin
  VoiceFile := GetTempDir + 'robotnyala_voice.txt';
  DeleteFile(VoiceFile);
  Voice := TVoiceInbox.Create(VoiceFile);
  Cmd := 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "' +
    UriToFilenameSafe('castle-data:/voice_listen.ps1') + '" -Out "' + VoiceFile +
    '" -Phrases "' + AllPhrases + '" -ParentPid ' + IntToStr(GetCurrentProcessId);
  UniqueString(Cmd); // CreateProcess may write into the command line
  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  if CreateProcess(nil, PChar(Cmd), nil, nil, False, CREATE_NO_WINDOW, nil, nil, SI, PI) then
  begin
    CloseHandle(PI.hThread);
    VoiceProcess := PI.hProcess;
    VoiceStatus := 'Mic: starting...';
  end else
    VoiceStatus := 'Mic: off (PowerShell not found)';
end;
{$else}
begin
  VoiceStatus := 'Mic: off (voice needs Windows)';
end;
{$endif}

{ New lines from the speech helper: status lines start with '#', the rest are commands. }
procedure TViewMain.PollVoice;
var
  Lines: TStringList;
  I: Integer;
begin
  if Voice = nil then Exit;
  Lines := TStringList.Create;
  try
    Voice.Poll(Lines);
    for I := 0 to Lines.Count - 1 do
      if Lines[I] = '#ready' then
        VoiceStatus := 'Mic: listening'
      else
      if Copy(Lines[I], 1, 6) = '#error' then
        VoiceStatus := 'Mic: off (' + Trim(Copy(Lines[I], 7, MaxInt)) + ')'
      else
      if Lines[I] <> '' then
        SubmitCommand(Lines[I]);
  finally
    Lines.Free;
  end;
  ShowStatus;
end;

procedure TViewMain.ShowStatus;
begin
  if ThreeQuarter then
    LabelCamera.Caption := 'Camera: 3/4 (Tab)   ' + VoiceStatus
  else
    LabelCamera.Caption := 'Camera: operator (Tab)   ' + VoiceStatus;
end;

{ Robot.OnImpact: the punch reaches full extension (halfway through the move) }
procedure TViewMain.PunchAt(Sender: TObject; Move: TRobotCommand);
begin
  if EnemyState.IsKO then
    LabelLast.Caption := CommandName(Move)
  else
  if PunchHits(PlayerX, PlayerZ, FacingDeg, Enemy.Translation.X, Enemy.Translation.Z) then
  begin
    EnemyState.Hit(MoveDamage(Move));
    EnemyAnim.Hit(Move);
    Feel.Hit(MoveDamage(Move), EnemyState.IsKO);
    FlashTimeLeft := HitFlashTime;
    if Feel.Streak >= 2 then
      LabelLast.Caption := CommandName(Move) + ' - HIT! x' + IntToStr(Feel.Streak)
    else
      LabelLast.Caption := CommandName(Move) + ' - HIT!';
  end else
  begin
    Feel.Miss;
    LabelLast.Caption := CommandName(Move) + ' - miss';
  end;
end;

procedure TViewMain.RobotMoveStart(Sender: TObject; Move: TRobotCommand);
var
  FX, FZ: Single;
begin
  { Right of the facing direction (FX, FZ) is (-FZ, FX). Duck and dodge are only
    shown by the sprite now (no first-person camera to move). }
  FacingVector(FacingDeg, FX, FZ);
  case Move of
    rcForward:   ClampedStep(PlayerX, PlayerZ,  FX * StepSize,  FZ * StepSize, Enemy.Translation.X, Enemy.Translation.Z);
    rcBack:      ClampedStep(PlayerX, PlayerZ, -FX * StepSize, -FZ * StepSize, Enemy.Translation.X, Enemy.Translation.Z);
    rcStepLeft:  ClampedStep(PlayerX, PlayerZ,  FZ * StepSize, -FX * StepSize, Enemy.Translation.X, Enemy.Translation.Z);
    rcStepRight: ClampedStep(PlayerX, PlayerZ, -FZ * StepSize,  FX * StepSize, Enemy.Translation.X, Enemy.Translation.Z);
    rcTurnLeft:  FacingDeg := FacingDeg + TurnStepDeg;
    rcTurnRight: FacingDeg := FacingDeg - TurnStepDeg;
  else ;
  end;
end;

procedure TViewMain.SubmitCommand(const Text: string);
var
  Cmd: TRobotCommand;
begin
  if CleanCommandText(Text) = '' then
    Exit;
  if not ParseCommand(Text, Cmd) then
  begin
    LabelLast.Caption := 'Didn''t understand: ' + Trim(Text);
    Exit;
  end;
  if Robot.Busy and (Cmd <> rcStop) then
  begin
    LabelLast.Caption := CommandName(Cmd) + ' (ignored: still moving)';
    Exit;
  end;
  LabelLast.Caption := CommandName(Cmd);
  Robot.Command(Cmd); // punches overwrite the caption with HIT / miss
end;

procedure TViewMain.Update(const SecondsPassed: Single; var HandleInput: Boolean);
var
  EX, EZ, CamX, CamZ, CamY, LookY, GameTime, S: Single;
  CamPos: TVector3;
begin
  inherited;
  LabelFps.Caption := 'FPS: ' + Container.Fps.ToString;

  { hit-stop: the fight itself stands still while Feel freezes it }
  GameTime := Feel.Update(SecondsPassed);
  Robot.Update(GameTime);
  EnemyState.Update(GameTime);
  EnemyAnim.Update(GameTime, EnemyState.IsKO);
  IdleTime := IdleTime + GameTime;

  EX := Enemy.Translation.X;
  EZ := Enemy.Translation.Z;
  if ThreeQuarter then
  begin
    ThreeQuarterCamera(PlayerX, PlayerZ, FacingDeg, EX, EZ, CamX, CamZ);
    CamY := ThreeQuarterHeight;
    LookY := ThreeQuarterLookHeight;
  end else
  begin
    OperatorCamera(PlayerX, PlayerZ, FacingDeg, CamX, CamZ);
    CamY := OperatorHeight;
    LookY := OperatorLookHeight;
  end;
  S := Feel.Shake;   // screen shake: jitter the camera, keep it aimed at the fight
  CamPos := Vector3(CamX + (Random - 0.5) * S, CamY + (Random - 0.5) * S, CamZ + (Random - 0.5) * S);
  PlayerCamera.SetView(CamPos,
    (Vector3((PlayerX + EX) / 2, LookY, (PlayerZ + EZ) / 2) - CamPos).Normalize,
    Vector3(0, 1, 0));

  Player.Translation := Vector3(PlayerX, 0, PlayerZ);
  ShowCell(Player, PlayerFrame(Robot.HasCurrent, Robot.Current, Robot.Elapsed, IdleTime),
    PlayerFrameCount, SpriteDirection(PlayerX, PlayerZ, FacingDeg, CamX, CamZ));
  { Boxer 07 always squares up to Glitchpop }
  ShowCell(Enemy, EnemyAnim.Frame, EnemyFrameCount,
    SpriteDirection(EX, EZ, FacingToward(EX, EZ, PlayerX, PlayerZ), CamX, CamZ));

  if FlashTimeLeft > 0 then
    FlashTimeLeft := FlashTimeLeft - SecondsPassed;
  if Feel.White then
    Enemy.Color := Vector4(4, 4, 4, 1)          // impact frame: blown-out white
  else
  if FlashTimeLeft > 0 then
    Enemy.Color := Vector4(1, 0.35, 0.35, 1)
  else
    Enemy.Color := White;

  HPBar.Width := HPBarBack.Width * EnemyState.HP / MaxHP;
  LabelKO.Exists := EnemyState.IsKO;

  VoicePollLeft := VoicePollLeft - SecondsPassed;
  if VoicePollLeft <= 0 then
  begin
    VoicePollLeft := 0.1;
    PollVoice;
  end;
end;

function TViewMain.Press(const Event: TInputPressRelease): Boolean;
begin
  Result := inherited;
  if Result then Exit; // allow the ancestor to handle keys

  { The command box doesn't handle Enter or Tab, so they reach us. }
  if Event.IsKey(keyEnter) then
  begin
    SubmitCommand(EditCommand.Text);
    EditCommand.Text := '';
    Exit(true);
  end;
  if Event.IsKey(keyTab) then
  begin
    ThreeQuarter := not ThreeQuarter;
    { each camera has sprite sheets drawn from its own height (art/export.js exportViews) }
    if ThreeQuarter then
    begin
      Enemy.Url := 'castle-data:/images/enemy_sheet_high.png';
      Player.Url := 'castle-data:/images/glitchpop_sheet_high.png';
    end else
    begin
      Enemy.Url := 'castle-data:/images/enemy_sheet.png';
      Player.Url := 'castle-data:/images/glitchpop_sheet.png';
    end;
    ShowStatus;
    Exit(true);
  end;
end;

end.
