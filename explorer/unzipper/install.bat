@echo off
setlocal

set "INSTALL_DIR=%LOCALAPPDATA%\UnzipHere"
set "EXE=%INSTALL_DIR%\unzip.exe"
set "PROJ=%~dp0unzip.csproj"

where dotnet >nul 2>&1
if %errorlevel% neq 0 (
    echo Could not find dotnet. Install .NET 8 SDK from https://dot.net
    pause
    exit /b 1
)

echo Building...
dotnet publish "%PROJ%" -c Release -o "%INSTALL_DIR%" --nologo -v quiet
if %errorlevel% neq 0 (
    echo Build failed.
    pause
    exit /b 1
)

:: Register per-user cascading menu (no admin needed)
:: Structure: .zip -> Unzipper (submenu) -> Unzip Here
set "PARENT=HKCU\Software\Classes\SystemFileAssociations\.zip\shell\Unzipper"
set "CHILD=%PARENT%\shell\UnzipHere"

reg add "%PARENT%"             /v "MUIVerb"      /t REG_SZ /d "Unzipper"           /f >nul
reg add "%PARENT%"             /v "Icon"         /t REG_SZ /d "shell32.dll,-1614"  /f >nul
reg add "%PARENT%"             /v "SubCommands"  /t REG_SZ /d ""                   /f >nul
reg add "%CHILD%"              /v ""             /t REG_SZ /d "Unzip Here"         /f >nul
reg add "%CHILD%\command"      /v ""             /t REG_SZ /d "\"%EXE%\" \"%%1\""  /f >nul

echo.
echo Done! Right-click any .zip file and choose "Unzipper" > "Unzip Here".
pause
