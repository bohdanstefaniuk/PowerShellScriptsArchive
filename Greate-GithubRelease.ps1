[CmdletBinding()]
param (
	[string]$version = "",                      # version
	[string]$assetPath,                         # Relative path to asset folder (like publish etc)
	[string]$assetFileNamePrefix = "release_",  # Prefix for asset file name
	[string]$releaseNoteText = "",              # Release note body text
	[string]$userName,                          # Github username
	[string]$password                           # Github password
)

$AssetFileName = Get-AssetName
$AssetSourcePath = Join-Path -Path $CurrentDirectory -ChildPath ($assetPath + "\*")
$AssetZipPath = Join-Path -Path $CurrentDirectory -ChildPath $assetFileName

# URL
$CreateReleaseUrl = "https://api.github.com/repos/teamkiller7112/WindowsServerManager/releases"
# $CreateReleaseUrl = "https://api.github.com/repos/Advance-Technologies-Foundation/bpmcli/releases"

# Requests headers
$CreateReleaseHeaders = @{
	"Authorization"=""; 
	"content-type"="application/json"; 
	"x-github-otp"="OTP"};
$UploadAssetHeaders =@{
	"Authorization"="Basic "; 
	"content-type"="application/zip"; 
	"x-github-otp"="OTP";}
$CreateReleaseHeaders["Authorization"] = Get-BasicAuthToken
$UploadAssetHeaders["Authorization"] = Get-BasicAuthToken

# Create release request body
$releaseNoteText = $releaseNoteText.replace("`n","").replace("`r","\n")
$CreateReleaseBody = "
{
	""tag_name"": ""$version"",
	""target_commitish"": ""master"",
	""name"": ""$version"",
	""body"": ""$releaseNoteText"",
	""draft"": false,
	""prerelease"": false
}"

function Get-AssetName {
	return $assetFileNamePrefix + $version + ".zip";
}

function Create-AssetZip {
	Compress-Archive -Path $AssetSourcePath -DestinationPath $AssetZipPath
}

function Get-BasicAuthToken {
	$Text = $userName + ":" + $password
	$Bytes = [System.Text.Encoding]::ASCII.GetBytes($Text)
	$EncodedText =[Convert]::ToBase64String($Bytes)
	return "Basic " + $EncodedText;
}

function Get-CorrectUploadUrl {
	param (
		[string]$inputUrl
	)
	$assetFileName = Get-AssetName;
	$correctUrl = $inputUrl -replace  [regex]::escape("{?name,label}"), "";
	$correctUrl = $correctUrl + "?name=" + $assetFileName;
	return $correctUrl;
}

function Create-Release {
	Write-Host "Creating Release"
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
	$Result = Invoke-RestMethod -Method Post -Uri $CreateReleaseUrl -Headers $CreateReleaseHeaders -Body $CreateReleaseBody
	return $Result
}

function Upload-ReleaseAsset {
	Write-Host "Uploading assets to new release"
	Invoke-RestMethod -Method Post -Uri $UploadAssetUrl -Headers $UploadAssetHeaders -InFile $AssetZipPath -ContentType "application/zip"
}

Write-Host "#######################################"
Write-Host "# Github release powershell"
Write-Host "# Create release URL: $CreateReleaseUrl"
Write-Host "# Upload assets url: $UploadAssetUrl"
Write-Host "# Param - version: $version"
Write-Host "# Param - assetPath: $assetPath"
Write-Host "# Param - assetFileNamePrefix: $assetFileNamePrefix"
Write-Host "# Param - releaseNoteText: $releaseNoteText"
Write-Host "# Creating release request body: $CreateReleaseBody"
Write-Host "#######################################"

$Result = Create-Release
$UploadAssetUrl = Get-CorrectUploadUrl -inputUrl $Result.upload_url
Create-AssetZip
Upload-ReleaseAsset -url $UploadAssetUrl

Write-Host "# Done"
