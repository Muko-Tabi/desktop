param(
    [string]$RunID,
    [string]$SignIdentity
)

$ErrorActionPreference = "Stop"

echo "Preparing environment"
mkdir windsign-temp -ErrorAction SilentlyContinue
mkdir engine\obj-x86_64-pc-windows-msvc\dist -ErrorAction SilentlyContinue

pnpm surfer ci --brand alpha

echo "Downloading from runner with ID $RunID"
gh run download $RunID --pattern "windows-x64-obj-*" --dir windsign-temp

function SignAndPackage($name) {
    echo "Executing on $name"
    rmdir engine\obj-x86_64-pc-windows-msvc\dist\ -Recurse -ErrorAction SilentlyContinue
    mv windsign-temp\windows-x64-obj-$name engine\obj-x86_64-pc-windows-msvc\dist
    echo "Signing $name"
    # Find all executables and dlls and sign them
    Get-ChildItem engine\obj-x86_64-pc-windows-msvc\dist -Recurse -Filter *.exe | % {
        echo "Signing $_"
        signtool.exe sign /n "$SignIdentity" /t http://time.certum.pl/ /fd sha1 /v $_.FullName
    }
    Get-ChildItem engine\obj-x86_64-pc-windows-msvc\dist -Recurse -Filter *.dll | % {
        echo "Signing $_"
        signtool.exe sign /n "$SignIdentity" /t http://time.certum.pl/ /fd sha1 /v $_.FullName
    }
    echo "Packaging $name"
    pnpm surfer package
}

SignAndPackage specific
SignAndPackage generic

# Cleaning up

echo "All done!"
Read-Host "Press Enter to continue"

echo "Cleaning up" 
rmdir windsign-temp -Recurse -ErrorAction SilentlyContinue