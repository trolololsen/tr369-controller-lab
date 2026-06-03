param(
    [Parameter(Mandatory = $true)]
    [string]$File
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $File)) {
    throw "Control file not found: $File"
}

$resolved = Resolve-Path -LiteralPath $File
$containerPath = "/tmp/$(Split-Path -Leaf $resolved)"

docker cp $resolved "usp-controller:$containerPath"
docker exec usp-controller ./obuspa -p -v 4 -x $containerPath -a /certs/controller.pem -t /certs/ca.crt
