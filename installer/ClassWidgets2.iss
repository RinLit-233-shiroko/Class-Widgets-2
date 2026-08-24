; Class Widgets 2 Windows installer
; Builds a per-user EXE installer while retaining the ZIP portable package.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef BuildDir
  #define BuildDir "..\dist\Class Widgets 2"
#endif
#ifndef OutputDir
  #define OutputDir "..\dist"
#endif

#define AppName "Class Widgets 2"
#define AppPublisher "Class Widgets"
#define MainExe "Class Widgets 2.exe"
#define SettingsExe "Class Widgets 2 Settings.exe"
#define PluginPlazaExe "Class Widgets 2 Plugin Plaza.exe"

[Setup]
AppId={{FA5A58DE-9A84-46D0-9255-2F5D4F72B4D5}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={localappdata}\Programs\Class Widgets 2
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
DisableWelcomePage=yes
DisableDirPage=yes
DisableReadyPage=yes
DisableFinishedPage=yes
DisableStartupPrompt=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir={#OutputDir}
OutputBaseFilename=ClassWidgets-2-Setup
SetupIconFile=assets\logo.ico
UninstallDisplayIcon={app}\{#MainExe}
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no
WizardStyle=modern light hidebevels
WizardSizePercent=100

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "assets\.cw2-installed"; DestDir: "{app}"; Flags: ignoreversion
Source: "assets\logo.png"; Flags: dontcopy
Source: "assets\next-button.png"; Flags: dontcopy

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#MainExe}"; WorkingDir: "{app}"
Name: "{autoprograms}\{#AppName}\{#AppName} Settings"; Filename: "{app}\{#SettingsExe}"; WorkingDir: "{app}"
Name: "{autoprograms}\{#AppName}\{#AppName} Plugin Plaza"; Filename: "{app}\{#PluginPlazaExe}"; WorkingDir: "{app}"
Name: "{autoprograms}\{#AppName}\Uninstall {#AppName}"; Filename: "{uninstallexe}"

[Code]
const
  CanvasWidth = 800;
  CanvasHeight = 600;
  CornerRadius = 22;
  WelcomeAnimationInterval = 16;
  FireworkAnimationInterval = 30;
  WelcomeAnimationFrames = 56;
  FireworkAnimationFrames = 24;
  ColorPrimary = $00FF924F;
  ColorText = $0030241E;
  ColorMuted = $0099877C;
  ColorPanel = $00FCF8F5;

function SetTimer(hWnd, nIDEvent, uElapse, lpTimerFunc: Integer): Integer;
  external 'SetTimer@user32.dll stdcall';
function KillTimer(hWnd, uIDEvent: Integer): Integer;
  external 'KillTimer@user32.dll stdcall';
function CreateRoundRectRgn(nLeftRect, nTopRect, nRightRect, nBottomRect, nWidthEllipse, nHeightEllipse: Integer): Integer;
  external 'CreateRoundRectRgn@gdi32.dll stdcall';
function SetWindowRgn(hWnd, hRgn: Integer; bRedraw: Boolean): Integer;
  external 'SetWindowRgn@user32.dll stdcall';

var
  WelcomePage: TWizardPage;
  InstallPathPage: TWizardPage;
  FinishPage: TWizardPage;
  BrandLogo: TBitmapImage;
  WelcomeName: TNewStaticText;
  WelcomeVersion: TNewStaticText;
  WelcomeCaption: TNewStaticText;
  WelcomeNextButton: TBitmapButton;
  InstallPathTitle: TNewStaticText;
  InstallPathDescription: TNewStaticText;
  InstallPathEdit: TNewPathEdit;
  InstallBrowseButton: TNewButton;
  InstallConfirmButton: TNewButton;
  InstallBackButton: TNewButton;
  ProgressTitle: TNewStaticText;
  ProgressDescription: TNewStaticText;
  ProgressBar: TNewProgressBar;
  ProgressPercent: TNewStaticText;
  FinishLogo: TBitmapImage;
  FinishName: TNewStaticText;
  FinishReady: TNewStaticText;
  FinishOpenButton: TNewButton;
  Particle: array [0..11] of TNewStaticText;
  WelcomeTimerId: Integer;
  FireworkTimerId: Integer;
  WelcomeFrame: Integer;
  FireworkFrame: Integer;

function LerpInt(const StartValue, EndValue, StepValue, StepCount: Integer): Integer;
begin
  Result := StartValue + ((EndValue - StartValue) * StepValue) div StepCount;
end;

procedure ApplyStaticFont(const Control: TNewStaticText; const Size: Integer; const Color: TColor; const Bold: Boolean);
begin
  Control.Font.Name := 'Segoe UI';
  Control.Font.Size := Size;
  Control.Font.Color := Color;
  if Bold then
    Control.Font.Style := [fsBold]
  else
    Control.Font.Style := [];
end;

procedure ApplyButtonFont(const Control: TNewButton; const Size: Integer; const Color: TColor; const Bold: Boolean);
begin
  Control.Font.Name := 'Segoe UI';
  Control.Font.Size := Size;
  Control.Font.Color := Color;
  if Bold then
    Control.Font.Style := [fsBold]
  else
    Control.Font.Style := [];
end;

procedure ApplyPathEditFont(const Control: TNewPathEdit; const Size: Integer; const Color: TColor);
begin
  Control.Font.Name := 'Segoe UI';
  Control.Font.Size := Size;
  Control.Font.Color := Color;
  Control.Font.Style := [];
end;

procedure ApplyRoundedWindow;
var
  Region: Integer;
begin
  Region := CreateRoundRectRgn(0, 0, WizardForm.Width + 1, WizardForm.Height + 1,
    ScaleX(CornerRadius), ScaleY(CornerRadius));
  if Region <> 0 then
    SetWindowRgn(WizardForm.Handle, Region, True);
end;

procedure HideNativeWizardChrome;
begin
  WizardForm.NextButton.Hide;
  WizardForm.BackButton.Hide;
  WizardForm.CancelButton.Hide;
  WizardForm.PageNameLabel.Hide;
  WizardForm.PageDescriptionLabel.Hide;
  WizardForm.WizardSmallBitmapImage.Hide;
  WizardForm.BeveledLabel.Hide;
  WizardForm.StatusLabel.Hide;
  WizardForm.FilenameLabel.Hide;
  WizardForm.ProgressGauge.Hide;
  WizardForm.MainPanel.Color := clWhite;
  WizardForm.OuterNotebook.Top := 0;
  WizardForm.OuterNotebook.Height := WizardForm.ClientHeight;
  WizardForm.InnerNotebook.Top := 0;
  WizardForm.InnerNotebook.Height := WizardForm.ClientHeight;
end;

procedure ExtractInstallerAssets;
begin
  ExtractTemporaryFile('logo.png');
  ExtractTemporaryFile('next-button.png');
end;

procedure LoadBrandIcon(const Image: TBitmapImage; const Size: Integer);
begin
  Image.PngImage.LoadFromFile(ExpandConstant('{tmp}\logo.png'));
  Image.Width := ScaleX(Size);
  Image.Height := ScaleY(Size);
  Image.Stretch := True;
end;

procedure StopWelcomeAnimation;
begin
  if WelcomeTimerId <> 0 then begin
    KillTimer(0, WelcomeTimerId);
    WelcomeTimerId := 0;
  end;
end;

procedure StopFireworkAnimation;
begin
  if FireworkTimerId <> 0 then begin
    KillTimer(0, FireworkTimerId);
    FireworkTimerId := 0;
  end;
end;

procedure WelcomeTimerProc(Arg1, Arg2, Arg3, Arg4: Integer);
var
  StepValue: Integer;
  TargetLeft: Integer;
  StartNameLeft: Integer;
  FinalNameLeft: Integer;
  VersionLeft: Integer;
  LogoSize: Integer;
begin
  Inc(WelcomeFrame);
  TargetLeft := (WelcomePage.SurfaceWidth - ScaleX(126)) div 2;
  StartNameLeft := TargetLeft + ScaleX(126) + ScaleX(12);
  FinalNameLeft := (WelcomePage.SurfaceWidth - ScaleX(300)) div 2;
  VersionLeft := FinalNameLeft + ScaleX(192);

  if WelcomeFrame <= 18 then begin
    StepValue := WelcomeFrame;
    LogoSize := LerpInt(ScaleX(64), ScaleX(126), StepValue, 18);
    BrandLogo.Width := LogoSize;
    BrandLogo.Height := LogoSize;
    BrandLogo.Left := LerpInt(ScaleX(64), TargetLeft, StepValue, 18);
    BrandLogo.Top := LerpInt(ScaleY(92), ScaleY(50), StepValue, 18);
  end else if WelcomeFrame <= 30 then begin
    WelcomeName.Visible := True;
    StepValue := WelcomeFrame - 18;
    WelcomeName.Left := LerpInt(StartNameLeft, FinalNameLeft + ScaleX(88), StepValue, 12);
  end else if WelcomeFrame <= 42 then begin
    StepValue := WelcomeFrame - 30;
    WelcomeName.Left := LerpInt(FinalNameLeft + ScaleX(88), FinalNameLeft, StepValue, 12);
    WelcomeVersion.Visible := True;
    WelcomeVersion.Left := VersionLeft;
    WelcomeVersion.Font.Color := ColorMuted;
  end else if WelcomeFrame = 43 then begin
    WelcomeCaption.Visible := True;
    WelcomeNextButton.Visible := True;
  end else if WelcomeFrame >= WelcomeAnimationFrames then begin
    StopWelcomeAnimation;
  end;
end;

procedure StartWelcomeAnimation;
begin
  StopWelcomeAnimation;
  WelcomeFrame := 0;
  WelcomeName.Visible := False;
  WelcomeVersion.Visible := False;
  WelcomeCaption.Visible := False;
  WelcomeNextButton.Visible := False;
  BrandLogo.Left := ScaleX(64);
  BrandLogo.Top := ScaleY(92);
  BrandLogo.Width := ScaleX(64);
  BrandLogo.Height := ScaleY(64);
  WelcomeTimerId := SetTimer(0, 0, WelcomeAnimationInterval, CreateCallback(@WelcomeTimerProc));
end;

procedure WelcomeNextClick(Sender: TObject);
begin
  StopWelcomeAnimation;
  WizardForm.NextButton.OnClick(WizardForm.NextButton);
end;

procedure BrowseInstallPathClick(Sender: TObject);
var
  SelectedDirectory: String;
begin
  SelectedDirectory := InstallPathEdit.Text;
  if BrowseForFolder('选择 Class Widgets 2 的安装位置', SelectedDirectory, False) then
    InstallPathEdit.Text := SelectedDirectory;
end;

procedure ConfirmInstallClick(Sender: TObject);
begin
  if Trim(InstallPathEdit.Text) = '' then begin
    MsgBox('请选择安装路径后再继续。', mbError, MB_OK);
    Exit;
  end;
  WizardForm.DirEdit.Text := InstallPathEdit.Text;
  WizardForm.NextButton.OnClick(WizardForm.NextButton);
end;

procedure InstallBackClick(Sender: TObject);
begin
  WizardForm.BackButton.OnClick(WizardForm.BackButton);
end;

procedure FireworkTimerProc(Arg1, Arg2, Arg3, Arg4: Integer);
var
  I: Integer;
  CenterX: Integer;
  CenterY: Integer;
  Direction: Integer;
begin
  Inc(FireworkFrame);
  CenterX := (FinishPage.SurfaceWidth div 2) - ScaleX(8);
  CenterY := ScaleY(110);
  for I := 0 to 11 do begin
    if (I mod 2) = 0 then
      Direction := -1
    else
      Direction := 1;
    Particle[I].Left := CenterX + Direction * ScaleX(14 + (I div 2) * 15) * FireworkFrame div FireworkAnimationFrames;
    Particle[I].Top := CenterY + ScaleY(((I mod 3) - 1) * 20) + ScaleY(I div 4) * FireworkFrame div 4;
    Particle[I].Visible := FireworkFrame < (FireworkAnimationFrames - (I mod 4) * 2);
  end;
  if FireworkFrame >= FireworkAnimationFrames then
    StopFireworkAnimation;
end;

procedure StartFireworkAnimation;
begin
  StopFireworkAnimation;
  FireworkFrame := 0;
  FireworkTimerId := SetTimer(0, 0, FireworkAnimationInterval, CreateCallback(@FireworkTimerProc));
end;

procedure FinishOpenClick(Sender: TObject);
var
  ResultCode: Integer;
begin
  Exec(ExpandConstant('{app}\{#MainExe}'), '', '', SW_SHOWNORMAL, ewNoWait, ResultCode);
  WizardForm.Close;
end;

procedure CreateWelcomePage;
begin
  WelcomePage := CreateCustomPage(wpWelcome, '', '');
  WelcomePage.Surface.Color := clWhite;

  BrandLogo := TBitmapImage.Create(WelcomePage);
  BrandLogo.Parent := WelcomePage.Surface;
  BrandLogo.BackColor := clWhite;
  LoadBrandIcon(BrandLogo, 126);

  WelcomeName := TNewStaticText.Create(WelcomePage);
  WelcomeName.Parent := WelcomePage.Surface;
  WelcomeName.Caption := 'Class Widgets';
  WelcomeName.AutoSize := False;
  WelcomeName.Width := ScaleX(190);
  WelcomeName.Height := ScaleY(38);
  WelcomeName.Top := ScaleY(202);
  ApplyStaticFont(WelcomeName, 20, ColorText, True);

  WelcomeVersion := TNewStaticText.Create(WelcomePage);
  WelcomeVersion.Parent := WelcomePage.Surface;
  WelcomeVersion.Caption := 'v{#AppVersion}';
  WelcomeVersion.AutoSize := False;
  WelcomeVersion.Width := ScaleX(110);
  WelcomeVersion.Height := ScaleY(30);
  WelcomeVersion.Top := ScaleY(208);
  ApplyStaticFont(WelcomeVersion, 11, ColorMuted, False);

  WelcomeCaption := TNewStaticText.Create(WelcomePage);
  WelcomeCaption.Parent := WelcomePage.Surface;
  WelcomeCaption.Caption := '准备好开始安装了吗？';
  WelcomeCaption.AutoSize := False;
  WelcomeCaption.Alignment := taCenter;
  WelcomeCaption.Width := ScaleX(320);
  WelcomeCaption.Height := ScaleY(28);
  WelcomeCaption.Left := (WelcomePage.SurfaceWidth - WelcomeCaption.Width) div 2;
  WelcomeCaption.Top := ScaleY(325);
  ApplyStaticFont(WelcomeCaption, 11, ColorMuted, False);

  WelcomeNextButton := TBitmapButton.Create(WelcomePage);
  WelcomeNextButton.Parent := WelcomePage.Surface;
  WelcomeNextButton.Width := ScaleX(64);
  WelcomeNextButton.Height := ScaleY(64);
  WelcomeNextButton.Left := (WelcomePage.SurfaceWidth - WelcomeNextButton.Width) div 2;
  WelcomeNextButton.Top := ScaleY(390);
  WelcomeNextButton.Stretch := True;
  WelcomeNextButton.PngImage.LoadFromFile(ExpandConstant('{tmp}\next-button.png'));
  WelcomeNextButton.OnClick := @WelcomeNextClick;
end;

procedure CreateInstallPathPage;
begin
  InstallPathPage := CreateCustomPage(WelcomePage.ID, '', '');
  InstallPathPage.Surface.Color := clWhite;

  InstallPathTitle := TNewStaticText.Create(InstallPathPage);
  InstallPathTitle.Parent := InstallPathPage.Surface;
  InstallPathTitle.Caption := '选择安装位置';
  InstallPathTitle.AutoSize := False;
  InstallPathTitle.Width := ScaleX(460);
  InstallPathTitle.Height := ScaleY(46);
  InstallPathTitle.Left := ScaleX(84);
  InstallPathTitle.Top := ScaleY(126);
  ApplyStaticFont(InstallPathTitle, 24, ColorText, True);

  InstallPathDescription := TNewStaticText.Create(InstallPathPage);
  InstallPathDescription.Parent := InstallPathPage.Surface;
  InstallPathDescription.Caption := '默认安装到当前用户目录，无需管理员权限。你也可以选择其他可写位置。';
  InstallPathDescription.AutoSize := False;
  InstallPathDescription.Width := ScaleX(590);
  InstallPathDescription.Height := ScaleY(34);
  InstallPathDescription.Left := ScaleX(84);
  InstallPathDescription.Top := ScaleY(183);
  ApplyStaticFont(InstallPathDescription, 10, ColorMuted, False);

  InstallPathEdit := TNewPathEdit.Create(InstallPathPage);
  InstallPathEdit.Parent := InstallPathPage.Surface;
  InstallPathEdit.Left := ScaleX(84);
  InstallPathEdit.Top := ScaleY(248);
  InstallPathEdit.Width := ScaleX(500);
  InstallPathEdit.Height := ScaleY(42);
  InstallPathEdit.Text := WizardForm.DirEdit.Text;
  InstallPathEdit.Color := ColorPanel;
  ApplyPathEditFont(InstallPathEdit, 10, ColorText);

  InstallBrowseButton := TNewButton.Create(InstallPathPage);
  InstallBrowseButton.Parent := InstallPathPage.Surface;
  InstallBrowseButton.Caption := '浏览';
  InstallBrowseButton.Left := ScaleX(594);
  InstallBrowseButton.Top := ScaleY(248);
  InstallBrowseButton.Width := ScaleX(108);
  InstallBrowseButton.Height := ScaleY(42);
  InstallBrowseButton.OnClick := @BrowseInstallPathClick;
  ApplyButtonFont(InstallBrowseButton, 10, ColorPrimary, True);

  InstallBackButton := TNewButton.Create(InstallPathPage);
  InstallBackButton.Parent := InstallPathPage.Surface;
  InstallBackButton.Caption := '← 返回';
  InstallBackButton.Left := ScaleX(84);
  InstallBackButton.Top := ScaleY(390);
  InstallBackButton.Width := ScaleX(112);
  InstallBackButton.Height := ScaleY(42);
  InstallBackButton.OnClick := @InstallBackClick;
  ApplyButtonFont(InstallBackButton, 10, ColorMuted, False);

  InstallConfirmButton := TNewButton.Create(InstallPathPage);
  InstallConfirmButton.Parent := InstallPathPage.Surface;
  InstallConfirmButton.Caption := '确认并安装';
  InstallConfirmButton.Left := ScaleX(516);
  InstallConfirmButton.Top := ScaleY(390);
  InstallConfirmButton.Width := ScaleX(186);
  InstallConfirmButton.Height := ScaleY(42);
  InstallConfirmButton.OnClick := @ConfirmInstallClick;
  ApplyButtonFont(InstallConfirmButton, 11, ColorPrimary, True);
end;

procedure CreateProgressOverlay;
begin
  ProgressTitle := TNewStaticText.Create(WizardForm);
  ProgressTitle.Parent := WizardForm.InstallingPage;
  ProgressTitle.Caption := '正在安装 Class Widgets';
  ProgressTitle.AutoSize := False;
  ProgressTitle.Width := ScaleX(520);
  ProgressTitle.Height := ScaleY(48);
  ProgressTitle.Left := ScaleX(84);
  ProgressTitle.Top := ScaleY(160);
  ApplyStaticFont(ProgressTitle, 24, ColorText, True);

  ProgressDescription := TNewStaticText.Create(WizardForm);
  ProgressDescription.Parent := WizardForm.InstallingPage;
  ProgressDescription.Caption := '正在准备应用文件…';
  ProgressDescription.AutoSize := False;
  ProgressDescription.Width := ScaleX(570);
  ProgressDescription.Height := ScaleY(30);
  ProgressDescription.Left := ScaleX(84);
  ProgressDescription.Top := ScaleY(218);
  ApplyStaticFont(ProgressDescription, 10, ColorMuted, False);

  ProgressBar := TNewProgressBar.Create(WizardForm);
  ProgressBar.Parent := WizardForm.InstallingPage;
  ProgressBar.Left := ScaleX(84);
  ProgressBar.Top := ScaleY(286);
  ProgressBar.Width := ScaleX(618);
  ProgressBar.Height := ScaleY(18);
  ProgressBar.Min := 0;
  ProgressBar.Max := 100;
  ProgressBar.Position := 0;

  ProgressPercent := TNewStaticText.Create(WizardForm);
  ProgressPercent.Parent := WizardForm.InstallingPage;
  ProgressPercent.Caption := '0%';
  ProgressPercent.AutoSize := False;
  ProgressPercent.Alignment := taRightJustify;
  ProgressPercent.Width := ScaleX(80);
  ProgressPercent.Height := ScaleY(24);
  ProgressPercent.Left := ScaleX(622);
  ProgressPercent.Top := ScaleY(320);
  ApplyStaticFont(ProgressPercent, 10, ColorPrimary, True);
end;

procedure CreateFinishPage;
var
  I: Integer;
  ParticleColors: array [0..3] of TColor;
begin
  FinishPage := CreateCustomPage(wpInstalling, '', '');
  FinishPage.Surface.Color := clWhite;
  ParticleColors[0] := ColorPrimary;
  ParticleColors[1] := $00F0A14E;
  ParticleColors[2] := $00E08593;
  ParticleColors[3] := $00D675A8;

  FinishLogo := TBitmapImage.Create(FinishPage);
  FinishLogo.Parent := FinishPage.Surface;
  FinishLogo.BackColor := clWhite;
  LoadBrandIcon(FinishLogo, 126);
  FinishLogo.Left := (FinishPage.SurfaceWidth - FinishLogo.Width) div 2;
  FinishLogo.Top := ScaleY(50);

  for I := 0 to 11 do begin
    Particle[I] := TNewStaticText.Create(FinishPage);
    Particle[I].Parent := FinishPage.Surface;
    Particle[I].Caption := '✦';
    Particle[I].AutoSize := False;
    Particle[I].Width := ScaleX(20);
    Particle[I].Height := ScaleY(20);
    Particle[I].Alignment := taCenter;
    Particle[I].Visible := False;
    ApplyStaticFont(Particle[I], 8 + (I mod 3) * 2, ParticleColors[I mod 4], True);
  end;

  FinishName := TNewStaticText.Create(FinishPage);
  FinishName.Parent := FinishPage.Surface;
  FinishName.Caption := 'Class Widgets';
  FinishName.AutoSize := False;
  FinishName.Alignment := taCenter;
  FinishName.Width := ScaleX(360);
  FinishName.Height := ScaleY(42);
  FinishName.Left := (FinishPage.SurfaceWidth - FinishName.Width) div 2;
  FinishName.Top := ScaleY(216);
  ApplyStaticFont(FinishName, 22, ColorText, True);

  FinishReady := TNewStaticText.Create(FinishPage);
  FinishReady.Parent := FinishPage.Surface;
  FinishReady.Caption := '已准备就绪';
  FinishReady.AutoSize := False;
  FinishReady.Alignment := taCenter;
  FinishReady.Width := ScaleX(360);
  FinishReady.Height := ScaleY(28);
  FinishReady.Left := (FinishPage.SurfaceWidth - FinishReady.Width) div 2;
  FinishReady.Top := ScaleY(264);
  ApplyStaticFont(FinishReady, 11, ColorMuted, False);

  FinishOpenButton := TNewButton.Create(FinishPage);
  FinishOpenButton.Parent := FinishPage.Surface;
  FinishOpenButton.Caption := '进入应用';
  FinishOpenButton.Left := (FinishPage.SurfaceWidth - ScaleX(196)) div 2;
  FinishOpenButton.Top := ScaleY(344);
  FinishOpenButton.Width := ScaleX(196);
  FinishOpenButton.Height := ScaleY(44);
  FinishOpenButton.OnClick := @FinishOpenClick;
  ApplyButtonFont(FinishOpenButton, 11, ColorPrimary, True);
end;

procedure InitializeWizard;
begin
  WizardForm.Width := ScaleX(CanvasWidth);
  WizardForm.Height := ScaleY(CanvasHeight);
  WizardForm.Position := poScreenCenter;
  HideNativeWizardChrome;
  ApplyRoundedWindow;
  ExtractInstallerAssets;
  CreateWelcomePage;
  CreateInstallPathPage;
  CreateProgressOverlay;
  CreateFinishPage;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = WelcomePage.ID then begin
    StartWelcomeAnimation;
  end else if CurPageID = InstallPathPage.ID then begin
    InstallPathEdit.Text := WizardForm.DirEdit.Text;
  end else if CurPageID = wpInstalling then begin
    ProgressBar.Position := 0;
    ProgressPercent.Caption := '0%';
    ProgressDescription.Caption := '正在准备应用文件…';
  end else if CurPageID = FinishPage.ID then begin
    StartFireworkAnimation;
  end;
end;

procedure CurInstallProgressChanged(CurProgress, MaxProgress: Integer);
var
  Percent: Integer;
begin
  if MaxProgress <= 0 then
    Exit;
  Percent := (CurProgress * 100) div MaxProgress;
  ProgressBar.Position := Percent;
  ProgressPercent.Caption := IntToStr(Percent) + '%';
  if Percent >= 100 then
    ProgressDescription.Caption := '正在完成最后设置…'
  else
    ProgressDescription.Caption := '正在安装应用文件…';
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then begin
    SaveStringToFile(ExpandConstant('{app}\.cw2-portable-source'), ExpandConstant('{src}'), False);
  end else if CurStep = ssPostInstall then begin
    ProgressBar.Position := 100;
    ProgressPercent.Caption := '100%';
    ProgressDescription.Caption := '安装已完成。';
  end;
end;

procedure DeinitializeSetup;
begin
  StopWelcomeAnimation;
  StopFireworkAnimation;
end;
