# AI team setup for Windows (PowerShell).
# Usage:  powershell -ExecutionPolicy Bypass -File .\setup.ps1
#         powershell -ExecutionPolicy Bypass -File .\setup.ps1 masrender nitro
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Repos)

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [Text.Encoding]::UTF8
Set-Location -Path $PSScriptRoot
$TeamDir = (Get-Location).Path

function Say($m)  { Write-Host "`n> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "  + $m" -ForegroundColor Green }
function Warn($m) { Write-Host "  ! $m" -ForegroundColor Yellow }
function Die($m)  { Write-Host "x $m" -ForegroundColor Red; exit 1 }

foreach ($c in "git", "gh", "claude") {
  if (-not (Get-Command $c -ErrorAction SilentlyContinue)) {
    switch ($c) {
      "git"    { Die "Нет git. Установи: winget install Git.Git" }
      "gh"     { Die "Нет GitHub CLI. Установи: winget install GitHub.cli" }
      "claude" { Die "Нет Claude Code CLI. Установи его и запусти setup ещё раз." }
    }
  }
}

# ---------- 1. GitHub login ----------
Say "Проверяю вход в GitHub"
gh auth status *> $null
if ($LASTEXITCODE -ne 0) { gh auth login -h github.com -p https -w }
if (-not ((gh auth status 2>&1 | Out-String) -match "workflow")) {
  Write-Host "  Нужен доступ к workflow-файлам — подтверди в браузере."
  gh auth refresh -h github.com -s workflow
  if ($LASTEXITCODE -ne 0) { Die "Не удалось получить доступ workflow" }
}
$Me = (gh api user --jq .login).Trim()
if (-not $Me) { Die "Не получилось узнать GitHub-логин" }
Ok "GitHub: $Me"

# ---------- 2. Personalize ----------
foreach ($f in ".github\workflows\team.yml", "templates\ai-team.yml") {
  $p = Join-Path $TeamDir $f
  $t = [IO.File]::ReadAllText($p) -replace "YOUR_GITHUB", $Me
  [IO.File]::WriteAllText($p, $t)
}
Ok "Файлы настроены под $Me"

# ---------- 3. Local install (copy; re-run setup after editing agents) ----------
Say "Ставлю агентов локально в $env:USERPROFILE\.claude"
$ca = Join-Path $env:USERPROFILE ".claude\agents"
$cc = Join-Path $env:USERPROFILE ".claude\commands"
New-Item -ItemType Directory -Force -Path $ca, $cc | Out-Null
Copy-Item "$TeamDir\agents\*.md"   $ca -Force
Copy-Item "$TeamDir\commands\*.md" $cc -Force
Ok "$((Get-ChildItem "$TeamDir\agents\*.md").Count) агентов, команды /court /office /full"

# ---------- 4. Push ai-team ----------
Say "Публикую репо $Me/ai-team"
git rev-parse --git-dir *> $null
if ($LASTEXITCODE -ne 0) { git init -q -b main }
git add -A
git -c user.name="$Me" -c user.email="$Me@users.noreply.github.com" commit -qm "AI team: council + office" *> $null
gh repo view "$Me/ai-team" *> $null
if ($LASTEXITCODE -eq 0) {
  git remote get-url origin *> $null
  if ($LASTEXITCODE -ne 0) { git remote add origin "https://github.com/$Me/ai-team.git" }
  git push -q -u origin main
  if ($LASTEXITCODE -ne 0) { Die "Не удалось запушить ai-team" }
} else {
  gh repo create ai-team --public --source=. --remote=origin --push --description "Global AI team: council + office agents for Claude Code" | Out-Null
  if ($LASTEXITCODE -ne 0) { Die "Не удалось создать репо ai-team" }
}
Ok "https://github.com/$Me/ai-team"

# ---------- 5. Token ----------
Say "Токен подписки Claude"
Write-Host "  Сейчас запустится 'claude setup-token'. Войди и СКОПИРУЙ токен (начинается с sk-ant-oat)."
Read-Host "  Enter — продолжить" | Out-Null
claude setup-token
$sec = Read-Host "  Вставь токен и нажми Enter" -AsSecureString
$Token = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
if (-not $Token) { Die "Токен пустой" }

# ---------- 6. Projects ----------
if (-not $Repos -or $Repos.Count -eq 0) {
  Say "Твои репозитории:"
  gh repo list $Me --limit 100 --json name,isArchived --jq '.[] | select(.isArchived | not) | .name' |
    Where-Object { $_ -ne "ai-team" } | ForEach-Object { Write-Host "  - $_" }
  $Repos = (Read-Host "Какие подключить? (названия через пробел)") -split "\s+" | Where-Object { $_ }
}

$WfB64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $TeamDir "templates\ai-team.yml")))
$Labels = @(
  @("court", "7057ff", "Совет: только спор и вердикт"),
  @("office", "0e8a16", "Офис: сделать задачу"),
  @("full", "d93f0b", "Совет + офис + ревью"),
  @("queue", "fbca04", "В очереди на ночной прогон"),
  @("in-progress", "1d76db", "Агенты работают"),
  @("in-review", "5319e7", "Готово, ждёт проверки"),
  @("needs-owner", "b60205", "Агентам нужен ответ")
)

foreach ($R in $Repos) {
  if ($R -notmatch "/") { $R = "$Me/$R" }
  Say $R
  gh repo view $R *> $null
  if ($LASTEXITCODE -ne 0) { Warn "Репо не найдено — пропускаю"; continue }

  gh secret set CLAUDE_CODE_OAUTH_TOKEN -R $R --body $Token *> $null
  if ($LASTEXITCODE -eq 0) { Ok "секрет токена" } else { Warn "не удалось записать секрет" }

  foreach ($l in $Labels) { gh label create $l[0] --color $l[1] --description $l[2] --force -R $R *> $null }
  Ok "метки"

  gh api -X PUT "repos/$R/actions/permissions/workflow" -f default_workflow_permissions=write -F can_approve_pull_request_reviews=true *> $null
  if ($LASTEXITCODE -eq 0) { Ok "Actions может открывать PR" } else { Warn "не удалось включить создание PR для Actions" }

  $P = ".github/workflows/ai-team.yml"
  $Sha = gh api "repos/$R/contents/$P" --jq .sha 2>$null
  $args2 = @("-X", "PUT", "repos/$R/contents/$P", "-f", "message=Add AI team workflow", "-f", "content=$WfB64")
  if ($LASTEXITCODE -eq 0 -and $Sha) { $args2 += @("-f", "sha=$Sha") }
  gh api @args2 *> $null
  if ($LASTEXITCODE -eq 0) { Ok "workflow добавлен" } else { Warn "не удалось добавить workflow (репо пустое?)" }
}
$Token = $null

# ---------- 7. GitHub App ----------
Say "Последний шаг — вручную"
Write-Host "  Установи Claude GitHub App и дай доступ к ai-team и подключённым проектам:"
Write-Host "  https://github.com/apps/claude"
Start-Process "https://github.com/apps/claude"

Write-Host "`nГотово. Создай issue в проекте и повесь метку court / office / full." -ForegroundColor Green
