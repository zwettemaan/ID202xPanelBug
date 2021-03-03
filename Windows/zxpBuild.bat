@ECHO OFF

SETLOCAL EnableDelayedExpansion

REM
REM Setup the panel so we can run it in a live debug session 
REM

SET timestampServer=http://timestamp.globalsign.com/scripts/timstamp.dll

SET scriptDir=%~dp0
PUSHD "%scriptDir%.."
SET projectHomeDir=%cd%\
CD devtools
SET devtoolsDir=%cd%\
cd ..\BuildSettings
SET buildSettingsDir=%cd%\
POPD

PUSHD "%projectHomeDir%"

REM Check whether we have administrative permissions

NET SESSION >NUL 2>&1

IF NOT %errorLevel% == 0 (
    ECHO Error: this script must be run from a command line shell
    ECHO with administrative privileges. Aborting.
    POPD
    EXIT /B
) 

IF NOT EXIST BuildSettings\ExtensionDirName.txt (
    ECHO Error: This CEPSparker folder has not been initialized. Make
    ECHO sure to run the CEPSparkerConfig.exe command first. Aborting.
    POPD
    EXIT /B
) 

CALL "%scriptDir%clean.bat"

SET /P EXTENSION_DIRNAME=< BuildSettings\ExtensionDirName.txt

IF "%EXTENSION_DIRNAME%" == "" (
    ECHO Error: Cannot determine the directory name for this
    ECHO extension. Aborting.
    POPD
    EXIT /B
)

SET /P EXTENSION_VERSION=< BuildSettings\ExtensionVersion.txt

IF "%EXTENSION_VERSION%" == "" (
    ECHO Error: Cannot determine the version for this
    ECHO extension. Aborting.
    POPD
    EXIT /B
)

IF NOT EXIST "%buildSettingsDir%certinfo.bat" (
    ECHO Error: certinfo.bat not found. 
    ECHO Probably this CEPSparker folder has not been initialized. Make
    ECHO sure to run the Windows\CEPSparkerConfig.exe command first.
    ECHO Aborting.
    POPD
    EXIT /B
)

IF NOT EXIST "%devToolsDir%ZXPSignCmd.exe" (
    ECHO Error: ZXPSignCmd.exe not found. 
    ECHO Use the devtools\downloadZXPSignCmd.bat script to download it. 
    ECHO Aborting.
    POPD
    EXIT /B
)

CALL "%buildSettingsDir%certinfo.bat"

IF NOT EXIST "%buildSettingsDir%\%certfile%" (

    ECHO Error: certificate file
    ECHO   %buildSettingsDir%\%certfile%
    ECHO not found.
    ECHO Need to provide a certificate file, or create a self-signed one first. See devtools\makeSelfSignedCert.bat
    ECHO Aborting.
    POPD
    EXIT /B
)

SET buildDir=%projectHomeDir%build\

IF NOT EXIST "%buildDir%" (
    MKDIR "%buildDir%"
)

SET EXTENSION_HOMEDIR=%buildDir%%EXTENSION_DIRNAME%\

CALL "%scriptDir%clearPlayerDebugMode.bat"
CALL "%scriptDir%adjustVersionInManifest.bat"

RD /s /q "%EXTENSION_HOMEDIR%" >NUL 2>&1

MKDIR "%EXTENSION_HOMEDIR%"

XCOPY "%projectHomeDir%css" "%EXTENSION_HOMEDIR%css\" /y /s /e >NUL 2>&1
XCOPY "%projectHomeDir%CSXS" "%EXTENSION_HOMEDIR%CSXS\" /y /s /e >NUL 2>&1
XCOPY "%projectHomeDir%html" "%EXTENSION_HOMEDIR%html\" /y /s /e >NUL 2>&1
XCOPY "%projectHomeDir%js" "%EXTENSION_HOMEDIR%js\" /y /s /e >NUL 2>&1
XCOPY "%projectHomeDir%jsx" "%EXTENSION_HOMEDIR%jsx\" /y /s /e >NUL 2>&1

CD "%buildDir%"

"%devtoolsDir%ZXPSignCmd" -sign "%EXTENSION_DIRNAME%" "%EXTENSION_DIRNAME%.zxp" "%buildSettingsDir%\%certfile%" "%password%" -tsa "%timestampServer%"

RD /s /q "%EXTENSION_HOMEDIR%" >NUL 2>&1

SET /p EXTENSION_VERSION=< ..\BuildSettings\ExtensionVersion.txt

REN "%EXTENSION_DIRNAME%.zxp" "%EXTENSION_DIRNAME%.%EXTENSION_VERSION%.zxp"

POPD
