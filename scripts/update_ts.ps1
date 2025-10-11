$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location $projectRoot

$sourceFiles = Get-ChildItem -Path "src/" -Recurse -Include "*.py", "*.qml" | ForEach-Object { $_.FullName }

pyside6-lupdate $sourceFiles -ts "assets/locales/en_US.ts"
pyside6-lupdate $sourceFiles -ts "assets/locales/zh_CN.ts"

pyside6-lrelease "assets/locales/en_US.ts"
pyside6-lrelease "assets/locales/zh_CN.ts"

Write-Host "Translation files updated successfully!"
