#!/usr/bin/env bash
# AI team setup for macOS / Linux.
# Usage:  ./setup.sh                 -> asks which repos to connect
#         ./setup.sh masrender nitro -> connects these repos
set -uo pipefail
cd "$(dirname "$0")"
TEAM_DIR="$(pwd)"

say()  { printf "\n\033[1;36m▶ %s\033[0m\n" "$*"; }
ok()   { printf "  \033[32m✓ %s\033[0m\n" "$*"; }
warn() { printf "  \033[33m⚠ %s\033[0m\n" "$*"; }
die()  { printf "\033[31m✗ %s\033[0m\n" "$*"; exit 1; }

command -v git    >/dev/null || die "Нет git. Установи: xcode-select --install"
command -v gh     >/dev/null || die "Нет GitHub CLI. Установи: brew install gh"
command -v claude >/dev/null || die "Нет Claude Code CLI. Установи его и запусти setup ещё раз."

# ---------- 1. GitHub login ----------
say "Проверяю вход в GitHub"
gh auth status >/dev/null 2>&1 || gh auth login -h github.com -p https -w
if ! gh auth status 2>&1 | grep -q "workflow"; then
  echo "  Нужен доступ к workflow-файлам — подтверди в браузере."
  gh auth refresh -h github.com -s workflow || die "Не удалось получить доступ workflow"
fi
ME="$(gh api user --jq .login)" || die "Не получилось узнать твой GitHub-логин"
ok "GitHub: $ME"

# ---------- 2. Personalize files ----------
perl -pi -e "s/YOUR_GITHUB/$ME/g" .github/workflows/team.yml templates/ai-team.yml
ok "Файлы настроены под $ME"

# ---------- 3. Local install (symlinks -> edits here apply everywhere) ----------
say "Ставлю агентов локально в ~/.claude"
mkdir -p "$HOME/.claude/agents" "$HOME/.claude/commands"
for f in agents/*.md;   do ln -sf "$TEAM_DIR/$f" "$HOME/.claude/agents/";   done
for f in commands/*.md; do ln -sf "$TEAM_DIR/$f" "$HOME/.claude/commands/"; done
ok "$(ls agents/*.md | wc -l | tr -d ' ') агентов, команды /court /office /full"

# ---------- 4. Push ai-team repo ----------
say "Публикую репо $ME/ai-team"
git rev-parse --git-dir >/dev/null 2>&1 || git init -q -b main
git add -A
git -c user.name="$ME" -c user.email="$ME@users.noreply.github.com" commit -qm "AI team: council + office" >/dev/null 2>&1 || true
if gh repo view "$ME/ai-team" >/dev/null 2>&1; then
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$ME/ai-team.git"
  git push -q -u origin main || die "Не удалось запушить ai-team"
else
  gh repo create ai-team --private --source=. --remote=origin --push \
    --description "Global AI team: council + office agents for Claude Code" >/dev/null || die "Не удалось создать репо ai-team"
fi
ok "https://github.com/$ME/ai-team"

# ---------- 5. Token ----------
say "Токен подписки Claude"
echo "  Сейчас запустится 'claude setup-token'. Войди в аккаунт и СКОПИРУЙ токен (начинается с sk-ant-oat)."
read -r -p "  Enter — продолжить... " _
claude setup-token || warn "setup-token завершился с ошибкой — если токен уже есть, просто вставь его ниже"
read -r -s -p "  Вставь токен и нажми Enter: " TOKEN; echo
[ -n "$TOKEN" ] || die "Токен пустой"

# ---------- 6. Projects ----------
if [ $# -gt 0 ]; then
  REPOS=("$@")
else
  say "Твои репозитории:"
  gh repo list "$ME" --limit 100 --json name,isArchived --jq '.[] | select(.isArchived | not) | .name' | grep -vx "ai-team" | sed 's/^/  - /'
  read -r -p "Какие подключить? (названия через пробел): " -a REPOS
fi

WF_B64="$(base64 < templates/ai-team.yml | tr -d '\n')"
LABELS=(
  "court|7057ff|Совет: только спор и вердикт"
  "office|0e8a16|Офис: сделать задачу"
  "full|d93f0b|Совет + офис + ревью"
  "queue|fbca04|В очереди на ночной прогон"
  "in-progress|1d76db|Агенты работают"
  "in-review|5319e7|Готово, ждёт проверки"
  "needs-owner|b60205|Агентам нужен ответ"
)

for R in "${REPOS[@]}"; do
  [[ "$R" == */* ]] || R="$ME/$R"
  say "$R"
  gh repo view "$R" >/dev/null 2>&1 || { warn "Репо не найдено — пропускаю"; continue; }

  printf '%s' "$TOKEN" | gh secret set CLAUDE_CODE_OAUTH_TOKEN -R "$R" >/dev/null \
    && ok "секрет токена" || warn "не удалось записать секрет"

  for L in "${LABELS[@]}"; do
    IFS='|' read -r NAME COLOR DESC <<< "$L"
    gh label create "$NAME" --color "$COLOR" --description "$DESC" --force -R "$R" >/dev/null 2>&1
  done
  ok "метки"

  gh api -X PUT "repos/$R/actions/permissions/workflow" \
    -f default_workflow_permissions=write -F can_approve_pull_request_reviews=true >/dev/null 2>&1 \
    && ok "Actions может открывать PR" || warn "не удалось включить создание PR для Actions"

  P=".github/workflows/ai-team.yml"
  SHA="$(gh api "repos/$R/contents/$P" --jq .sha 2>/dev/null || true)"
  ARGS=(-X PUT "repos/$R/contents/$P" -f message="Add AI team workflow" -f content="$WF_B64")
  [ -n "$SHA" ] && ARGS+=(-f sha="$SHA")
  gh api "${ARGS[@]}" >/dev/null 2>&1 && ok "workflow добавлен" || warn "не удалось добавить workflow (репо пустое?)"
done
unset TOKEN

# ---------- 7. GitHub App ----------
say "Последний шаг — вручную"
echo "  Установи Claude GitHub App и дай доступ к ai-team и подключённым проектам:"
echo "  https://github.com/apps/claude"
(open "https://github.com/apps/claude" || xdg-open "https://github.com/apps/claude") >/dev/null 2>&1 || true

printf "\n\033[1;32mГотово.\033[0m Создай issue в проекте и повесь метку court / office / full.\n"
