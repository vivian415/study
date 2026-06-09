$ApiKey = "apik4293"
$BaseUrl = "http://localhost:3000"

function OPENLIB {
    $response = Invoke-RestMethod `
      -Method POST `
      -Uri "$BaseUrl/sql" `
      -Headers @{"Content-Type"="application/json"; "x-api-key"=$ApiKey} `
      -Body (@{
          sql = "SELECT SCHEMA_NAME AS LIBRARY FROM QSYS2.SYSSCHEMAS ORDER BY SCHEMA_NAME FETCH FIRST 200 ROWS ONLY"
      } | ConvertTo-Json)

    $response.rows | Format-Table
}

function OPENOBJ {
    param([string]$lib)

    $lib = $lib.ToUpper()

    $response = Invoke-RestMethod `
      -Method POST `
      -Uri "$BaseUrl/sql" `
      -Headers @{"Content-Type"="application/json"; "x-api-key"=$ApiKey} `
      -Body (@{
          sql = @"
SELECT
  OBJNAME,
  OBJTYPE,
  OBJTEXT
FROM TABLE(
  QSYS2.OBJECT_STATISTICS('$lib','*ALL')
)
ORDER BY OBJNAME
"@
      } | ConvertTo-Json)

    $response.rows | Format-Table
}

function OPENMBR {

    param([string]$lib, [string]$obj)

    $response = Invoke-RestMethod `
      -Method POST `
      -Uri "$BaseUrl/sql" `
      -Headers @{"Content-Type"="application/json"; "x-api-key"=$ApiKey} `
      -Body (@{
          sql = @"
SELECT *
FROM QSYS2.SYSPARTITIONSTAT
WHERE TABLE_SCHEMA = '$($lib.ToUpper())'
FETCH FIRST 20 ROWS ONLY
"@
      } | ConvertTo-Json)

    $response.rows
}

function CODEMBR {

    param(
        [string]$library,
        [string]$srcFile,
        [string]$member
    )

    $library = $library.ToUpper()
    $srcFile = $srcFile.ToUpper()
    $member  = $member.ToUpper()

    $response = Invoke-RestMethod `
      -Method POST `
      -Uri "$BaseUrl/open-member" `
      -Headers @{
          "Content-Type" = "application/json"
          "x-api-key"    = $ApiKey
      } `
      -Body (@{
          library = $library
          srcFile = $srcFile
          member  = $member
      } | ConvertTo-Json)

    $response
}
function DDS {
    param([string]$mbr)

    CODEMBR KJNML QDDSSRC $mbr dds
}

function CL {
    param([string]$mbr)

    CODEMBR KJNML QCLSRC $mbr cl
}

function RPG {
    param([string]$mbr)

    CODEMBR KJNML QRPGLESRC $mbr rpgle
}

function SAVEMBR {

    param(
        [string]$library,
        [string]$file,
        [string]$member
    )

    Invoke-RestMethod `
      -Method POST `
      -Uri "$BaseUrl/save-member" `
      -Headers @{
          "Content-Type" = "application/json"
          "x-api-key"    = $ApiKey
      } `
      -Body (@{
          library = $library.ToUpper()
          file    = $file.ToUpper()
          member  = $member.ToUpper()
      } | ConvertTo-Json)

}


function CRTRPG {

    param(
        [string]$targetlib,
        [string]$srclib,
        [string]$srcfile,
        [string]$member
    )

    $response = Invoke-RestMethod `
      -Method POST `
      -Uri "$BaseUrl/compile-rpg" `
      -Headers @{
          "Content-Type" = "application/json"
          "x-api-key"    = $ApiKey
      } `
      -Body (@{
          targetlib = $targetlib.ToUpper()
          srclib    = $srclib.ToUpper()
          srcfile   = $srcfile.ToUpper()
          member    = $member.ToUpper()
      } | ConvertTo-Json)

    $response
}

function CRTPF {

    param(
        [string]$targetlib,
        [string]$srclib,
        [string]$srcfile,
        [string]$member
    )

    $response = Invoke-RestMethod `
      -Method POST `
      -Uri "$BaseUrl/compile-pf" `
      -Headers @{
          "Content-Type" = "application/json"
          "x-api-key"    = $ApiKey
      } `
      -Body (@{
          targetlib = $targetlib.ToUpper()
          srclib    = $srclib.ToUpper()
          srcfile   = $srcfile.ToUpper()
          member    = $member.ToUpper()
      } | ConvertTo-Json)

    $response
}

function CRTDSPF {
    param(
        [string]$targetlib,
        [string]$srclib,
        [string]$srcfile,
        [string]$member
    )

    Invoke-RestMethod `
      -Method POST `
      -Uri "$BaseUrl/run" `
      -Headers @{
        "Content-Type"="application/json"
        "x-api-key"=$ApiKey
      } `
      -Body (@{
        command = "CRTDSPF FILE($targetlib/$member) SRCFILE($srclib/$srcfile) SRCMBR($member)"
      } | ConvertTo-Json)
}

function CRTSQLRPG {

    param(
        [string]$targetlib,
        [string]$srclib,
        [string]$srcfile,
        [string]$member
    )

    $response = Invoke-RestMethod `
      -Method POST `
      -Uri "$BaseUrl/compile-sqlrpg" `
      -Headers @{
          "Content-Type" = "application/json"
          "x-api-key"    = $ApiKey
      } `
      -Body (@{
          targetlib = $targetlib.ToUpper()
          srclib    = $srclib.ToUpper()
          srcfile   = $srcfile.ToUpper()
          member    = $member.ToUpper()
      } | ConvertTo-Json)

    $response
}

function CMPLRPG {

    param([string]$member)

    $member = $member.ToUpper()

    Invoke-RestMethod `
      -Method POST `
      -Uri "$BaseUrl/compile-rpg" `
      -Headers @{
          "Content-Type" = "application/json"
          "x-api-key"    = $ApiKey
      } `
      -Body (@{
          member = $member
      } | ConvertTo-Json)

}

function CPYSRC {

    param(
        [string]$fromLib,
        [string]$srcFile,
        [string]$toLib
    )

    $response = Invoke-RestMethod `
      -Method POST `
      -Uri "$BaseUrl/copy-src" `
      -Headers @{
          "Content-Type" = "application/json"
          "x-api-key"    = $ApiKey
      } `
      -Body (@{
          fromLib = $fromLib.ToUpper()
          srcFile = $srcFile.ToUpper()
          toLib   = $toLib.ToUpper()
      } | ConvertTo-Json)

    $response
}

function CPYMBR {

    param(
        [string]$fromLib,
        [string]$srcFile,
        [string]$member,
        [string]$toLib
    )

    $response = Invoke-RestMethod `
      -Method POST `
      -Uri "$BaseUrl/copy-member" `
      -Headers @{
          "Content-Type" = "application/json"
          "x-api-key"    = $ApiKey
      } `
      -Body (@{
          fromLib = $fromLib.ToUpper()
          srcFile = $srcFile.ToUpper()
          member  = $member.ToUpper()
          toLib   = $toLib.ToUpper()
      } | ConvertTo-Json)

    $response
}

function CALLPGM {

    param(
        [string]$library,
        [string]$program
    )

    $response = Invoke-RestMethod `
      -Method POST `
      -Uri "$BaseUrl/call-pgm" `
      -Headers @{
          "Content-Type" = "application/json"
          "x-api-key"    = $ApiKey
      } `
      -Body (@{
          library = $library.ToUpper()
          program = $program.ToUpper()
      } | ConvertTo-Json)

    $response
}

function DEPLOYOBJ {

    param(
        $object,
        $type,
        $fromLib,
        $toLib
    )

    $json = @{
        object  = $object
        type    = $type
        fromLib = $fromLib
        toLib   = $toLib
    } | ConvertTo-Json

    Invoke-RestMethod `
      -Method POST `
      -Uri "http://localhost:3000/deploy-obj" `
      -Headers @{
          "Content-Type" = "application/json"
          "x-api-key"    = $ApiKey
      } `
      -Body $json
}

function DEPLOYMBR {

    param(
        $fromLib,
        $srcFile,
        $member,
        $toLib
    )

    $json = @{
        fromLib = $fromLib
        srcFile = $srcFile
        member  = $member
        toLib   = $toLib
    } | ConvertTo-Json

    $response = Invoke-RestMethod `
      -Method POST `
      -Uri "http://localhost:3000/deploy-member" `
      -Headers @{
          "Content-Type" = "application/json"
          "x-api-key"    = $ApiKey
      } `
      -Body $json

    $response.message
}
