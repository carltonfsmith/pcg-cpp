# PCG Random Number Generation for C++
# 
# Copyright 2014-2017 Melissa O'Neill <oneill@pcg-random.org>,
#                     and the PCG Project contributors.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)
#
# Licensed under the Apache License, Version 2.0 (provided in
# LICENSE-APACHE.txt and at http://www.apache.org/licenses/LICENSE-2.0)
# or under the MIT license (provided in LICENSE-MIT.txt and at
# http://opensource.org/licenses/MIT), at your option. This file may not
# be copied, modified, or distributed except according to those terms.

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

# Find the binaries
$binDir = "."
$testPaths = @(
    ".",
    "../build/test-high/Debug",
    "../build/test-high/Release",
    "../build/test-high"
)

foreach ($path in $testPaths) {
    if (Test-Path "$path/check-pcg32.exe") {
        $binDir = $path
        break
    }
}

Write-Host "Performing a quick sanity check..."
Write-Host "Testing using binaries from: $binDir"

if (!(Test-Path "actual")) {
    New-Item -ItemType Directory -Path "actual" | Out-Null
} else {
    Remove-Item -Path "actual/*" -Force -ErrorAction SilentlyContinue
}

function Run-Test($name, $outputFile = $null) {
    $exe = Join-Path $binDir "$name.exe"
    if (!(Test-Path $exe)) {
        $exe = Join-Path $binDir $name
    }
    
    if (Test-Path $exe) {
        if ($outputFile) {
            & $exe | Out-File -FilePath "actual/$outputFile" -Encoding ascii
        } else {
            & $exe | Out-Null
        }
    } else {
        Write-Error "ERROR: $name not found in $binDir"
    }
}

# Running tests
Run-Test "check-pcg32" "check-pcg32.out"
Run-Test "check-pcg32_oneseq" "check-pcg32_oneseq.out"
Run-Test "check-pcg32" # dev/null equivalent
Run-Test "check-pcg32_fast" "check-pcg32_fast.out"

Run-Test "check-pcg64" "check-pcg64.out"
Run-Test "check-pcg64_oneseq" "check-pcg64_oneseq.out"
Run-Test "check-pcg64_unique" # dev/null equivalent
Run-Test "check-pcg64_fast" "check-pcg64_fast.out"

Run-Test "check-pcg8_once_insecure" "check-pcg8_once_insecure.out"
Run-Test "check-pcg16_once_insecure" "check-pcg16_once_insecure.out"
Run-Test "check-pcg32_once_insecure" "check-pcg32_once_insecure.out"
Run-Test "check-pcg64_once_insecure" "check-pcg64_once_insecure.out"
Run-Test "check-pcg128_once_insecure" "check-pcg128_once_insecure.out"

Run-Test "check-pcg8_oneseq_once_insecure" "check-pcg8_oneseq_once_insecure.out"
Run-Test "check-pcg16_oneseq_once_insecure" "check-pcg16_oneseq_once_insecure.out"
Run-Test "check-pcg32_oneseq_once_insecure" "check-pcg32_oneseq_once_insecure.out"
Run-Test "check-pcg64_oneseq_once_insecure" "check-pcg64_oneseq_once_insecure.out"
Run-Test "check-pcg128_oneseq_once_insecure" "check-pcg128_oneseq_once_insecure.out"

Run-Test "check-pcg32_k2" "check-pcg32_k2.out"
Run-Test "check-pcg32_k2_fast" "check-pcg32_k2_fast.out"

Run-Test "check-pcg32_k64" "check-pcg32_k64.out"
Run-Test "check-pcg32_k64_oneseq" "check-pcg32_k64_oneseq.out"
Run-Test "check-pcg32_k64_fast" "check-pcg32_k64_fast.out"

Run-Test "check-pcg32_c64" "check-pcg32_c64.out"
Run-Test "check-pcg32_c64_oneseq" "check-pcg32_c64_oneseq.out"
Run-Test "check-pcg32_c64_fast" "check-pcg32_c64_fast.out"

Run-Test "check-pcg64_k32" "check-pcg64_k32.out"
Run-Test "check-pcg64_k32_oneseq" "check-pcg64_k32_oneseq.out"
Run-Test "check-pcg64_k32_fast" "check-pcg64_k32_fast.out"

Run-Test "check-pcg64_c32" "check-pcg64_c32.out"
Run-Test "check-pcg64_c32_oneseq" "check-pcg64_c32_oneseq.out"
Run-Test "check-pcg64_c32_fast" "check-pcg64_c32_fast.out"

Run-Test "check-pcg32_k1024" "check-pcg32_k1024.out"
Run-Test "check-pcg32_k1024_fast" "check-pcg32_k1024_fast.out"

Run-Test "check-pcg32_c1024" "check-pcg32_c1024.out"
Run-Test "check-pcg32_c1024_fast" "check-pcg32_c1024_fast.out"

Run-Test "check-pcg64_k1024" "check-pcg64_k1024.out"
Run-Test "check-pcg64_k1024_fast" "check-pcg64_k1024_fast.out"

Run-Test "check-pcg64_c1024" "check-pcg64_c1024.out"
Run-Test "check-pcg64_c1024_fast" "check-pcg64_c1024_fast.out"

Run-Test "check-pcg32_k16384" "check-pcg32_k16384.out"
Run-Test "check-pcg32_k16384_fast" "check-pcg32_k16384_fast.out"

# Clean up empty/small files (similar to find -size -80c -delete)
Get-ChildItem "actual" | Where-Object { $_.Length -lt 80 } | Remove-Item

# Compare with expected
$diff = Compare-Object (Get-ChildItem "expected" -Exclude .gitignore) (Get-ChildItem "actual")
if ($null -eq $diff) {
    # Perform actual content comparison
    $failed = $false
    Foreach ($file in Get-ChildItem "expected" -Exclude .gitignore) {
        $expectedFile = $file.FullName
        $actualFile = Join-Path "actual" $file.Name
        if (Test-Path $actualFile) {
            $diffContent = Compare-Object (Get-Content $expectedFile) (Get-Content $actualFile)
            if ($diffContent) {
                Write-Host "Difference in $($file.Name)" -ForegroundColor Red
                $failed = $true
            }
        }
    }
    
    if (!$failed) {
        Write-Host "All tests succeeded." -ForegroundColor Green
    } else {
        Write-Host "ERROR: Some tests failed." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "ERROR: File list mismatch between expected and actual." -ForegroundColor Red
    exit 1
}
