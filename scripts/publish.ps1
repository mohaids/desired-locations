param([Parameter(Mandatory=$true)][string]$CheckoutPath)
$ErrorActionPreference='Stop'
$env:GIT_TERMINAL_PROMPT='0'
$env:GCM_INTERACTIVE='Never'
$sourceRoot=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$targetPath=[System.IO.Path]::GetFullPath($CheckoutPath)
if(Test-Path -LiteralPath $targetPath){throw 'Choose a NEW empty checkout path; an existing path will not be modified.'}
if($targetPath.StartsWith($sourceRoot+[System.IO.Path]::DirectorySeparatorChar,[System.StringComparison]::OrdinalIgnoreCase)){throw 'Choose a checkout path outside this source folder.'}
git -c credential.username=mohaids clone https://github.com/mohaids/desired-locations.git $targetPath
if($LASTEXITCODE -ne 0){throw 'Clone failed. Check network access and the existing repository-scoped Windows credential, then retry with a new path. No broader sign-in was requested.'}
Push-Location -LiteralPath $targetPath
try {
 git config credential.https://github.com.username mohaids
 git rev-parse --verify --quiet HEAD | Out-Null
 if($LASTEXITCODE -eq 0){throw 'The remote repository has commits. Review and merge the migration in this clone manually; no files were copied.'}
 git symbolic-ref HEAD refs/heads/main
 if($LASTEXITCODE -ne 0){throw 'Could not create main branch.'}
 $entries=@('.github','public','src','supabase','scripts','tests','index.html','package.json','package-lock.json','vite.config.ts','tsconfig.json','README.md','.gitignore','.env.example')
 foreach($entry in $entries){Copy-Item -LiteralPath (Join-Path $sourceRoot $entry) -Destination (Join-Path $targetPath $entry) -Recurse}
 & npm.cmd ci
 if($LASTEXITCODE -ne 0){throw 'Dependency installation failed.'}
 & npm.cmd test
 if($LASTEXITCODE -ne 0){throw 'Tests failed.'}
 & npm.cmd run build
 if($LASTEXITCODE -ne 0){throw 'Build failed.'}
 git add --all
 if($LASTEXITCODE -ne 0){throw 'Staging failed.'}
 git commit -m 'Migrate Elsewhere to GitHub Pages and Supabase'
 if($LASTEXITCODE -ne 0){throw 'Commit failed. Configure your Git name/email locally and retry the reviewed commit.'}
 git push --set-upstream origin main
 if($LASTEXITCODE -ne 0){throw 'Push failed. The local commit is retained; check GitHub authentication and repository permissions.'}
 Write-Host 'Source pushed. Open the repository Actions tab and verify the Pages deployment succeeds.'
 Write-Host 'Expected site: https://mohaids.github.io/desired-locations/'
} finally {Pop-Location}


