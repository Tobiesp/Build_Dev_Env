[CmdletBinding()]
param (
    [String]
    $version = "v3.15.4"
)

$url = "https://get.helm.sh/helm-${version}-windows-amd64.zip"
Write-Host $url
$path_to_file = "${HOME}\helm-${version}-windows-amd64.zip"
Invoke-WebRequest $url -OutFile $path_to_file -Verbose

if (-not (Test-Path $path_to_file)) {
    Write-Error "Unable to find downloaded file."
}

Expand-Archive $path_to_file -DestinationPath "${HOME}\.helm-tmp"
if (-not (Test-Path "${HOME}\.helm-tmp")) {
    Write-Error "Failed to expand zip: ${path_to_file}"
    exit 1
}

remove-item "${path_to_file}"

$helm_dir = "${HOME}\.helm"
if (Test-Path -Path "${helm_dir}") {
    Write-Error "Helm already installed."
    exit 1
}

Copy-Item -Recurse "${HOME}\.helm-tmp\windows-amd64" "${helm_dir}"

Remove-Item -Recurse -Force "${HOME}\.helm-tmp"

$new_path = "${env:Path};${helm_dir}"

if ("${env:Path}" -match '.*\.helm') {
    Write-Host "Path already set."
} else {
    [System.Environment]::SetEnvironmentVariable('Path',"${new_path}", 'User')
}