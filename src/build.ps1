param(
    [String] $majorMinor = "0.0",  # 2.0
    [String] $patch = "0",         # $env:APPVEYOR_BUILD_VERSION
    [String] $customLogger = "",   # C:\Program Files\AppVeyor\BuildAgent\Appveyor.MSBuildLogger.dll
    [Switch] $notouch
)

function Set-AssemblyVersions($informational, $assembly)
{
    (Get-Content src/WebJobSentinel/Properties/AssemblyInfo.cs) |
        ForEach-Object { $_ -replace """1.0.0.0""", """$assembly""" } |
        ForEach-Object { $_ -replace """1.0.0""", """$informational""" } |
        ForEach-Object { $_ -replace """1.1.1.1""", """$($informational).0""" } |
        Set-Content src/WebJobSentinel/Properties/AssemblyInfo.cs
}

function Install-NuGetPackages()
{
    nuget restore "src/WebJobSentinel.sln"
}

function Invoke-MSBuild($solution, $customLogger)
{
    if ($customLogger)
    {
        msbuild "$solution" /verbosity:minimal /p:Configuration=Release /logger:"$customLogger"
    }
    else
    {
        msbuild "$solution" /verbosity:minimal /p:Configuration=Release
    }
}

function Invoke-NuGetPackProj($csproj)
{
    nuget pack -Prop Configuration=Release -Symbols $csproj
}

function Invoke-NuGetPackSpec($nuspec, $version)
{
    nuget pack $nuspec -Version $version  -Verbosity detailed
}

function Invoke-NuGetPack($version)
{
    ls src/WebJobSentinel/*.nuspec | 
        ForEach-Object { Invoke-NuGetPackSpec $_  $version}
}

function Invoke-Build($majorMinor,  $customLogger, $notouch)
{
    $package="$majorMinor"

    Write-Output "Building WebJobSentinel $package"

    if (-not $notouch)
    {
        $assembly = "$majorMinor"

        Write-Output "Assembly version will be set to $assembly"
        Set-AssemblyVersions $package $assembly
    }

    Install-NuGetPackages

    
    Invoke-MSBuild "src/WebJobSentinel.sln" $customLogger

    Invoke-NuGetPack $package
}

$ErrorActionPreference = "Stop"
Invoke-Build $majorMinor $customLogger $notouch