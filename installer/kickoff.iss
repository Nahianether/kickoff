; Inno Setup script for KickOff (Flutter Windows app)
; Build the app first:   flutter build windows --release
; Then compile this:     "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\kickoff.iss
; Output:                installer\Output\KickOff-Setup-<version>.exe

#define AppName "KickOff"
#define AppVersion "1.0.0"
#define AppPublisher "KickOff"
#define AppExeName "kickoff.exe"
; Folder produced by `flutter build windows --release`
#define ReleaseDir "..\build\windows\x64\runner\Release"

[Setup]
; A unique GUID for this app. Generated once; keep it stable across versions
; so upgrades replace the previous install instead of installing side-by-side.
AppId={{8F3B2A14-9C7E-4D1A-B6F2-3E5C8A0D7B91}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; Install per-user by default (no admin prompt). Use "admin" for all-users.
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=Output
OutputBaseFilename=KickOff-Setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
; SetupIconFile=..\windows\runner\resources\app_icon.ico
; UninstallDisplayIcon={app}\{#AppExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Pull in the entire release bundle (exe, DLLs, and the data\ folder with assets).
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
