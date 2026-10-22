# AI Team — суд + офис для всех проектов

Глобальная команда агентов для Claude Code. Работает локально в любом проекте и в облаке через GitHub Actions.

## Состав

**⚖️ Суд (opus, только думают):** `council-visionary`, `council-skeptic`, `council-pragmatist`, `council-user-advocate`, `council-judge`

**🏢 Офис (sonnet, работают):** `office-programmer`, `office-designer`, `office-security`, `office-finance`, `office-qa`, `office-devops`, `office-docs`, `office-marketing`

## Команды (локально в Claude Code)

| Команда | Что делает |
|---|---|
| `/court <идея>` | 2 раунда спора → вердикт судьи → файл в `.council/decisions/` |
| `/office <задача>` | офис делает задачу в ветке `ai/...`, QA + безопасник проверяют |
| `/full <идея>` | суд → офис по плану судьи → финальное ревью скептика |

## Облако (без тебя)

В проекте создай issue и повесь метку:

| Метка | Результат |
|---|---|
| `court` | вердикт комментарием + черновой PR с файлом решения |
| `office` | PR с готовой задачей |
| `full` | суд + офис → PR |
| `queue` | возьмут ночью (03:00 МСК), по одной задаче за ночь, по порядку |

`@claude <что сделать>` в любом комментарии issue/PR — быстрая правка.

Служебные метки: `in-progress` (работают), `in-review` (готово), `needs-owner` (ждут твоего ответа в issue).

В `main` агенты не пушат никогда — только PR. Мержишь ты.

## Установка

macOS:
```
cd ~/ai-team && chmod +x setup.sh && ./setup.sh
```
Windows (PowerShell):
```
cd $HOME\ai-team; powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

Скрипт сам: проверит вход в GitHub, поставит агентов в `~/.claude`, создаст репо `ai-team`, запишет токен в секреты выбранных проектов, создаст метки и добавит workflow. Вручную только: скопировать токен из `claude setup-token` и нажать Install на https://github.com/apps/claude.

Подключить новый проект позже: `./setup.sh имя-репо` (или `.\setup.ps1 имя-репо`).

## Правка агентов

Редактируй файлы в `agents/` и `commands/`, потом `git push`. Облако подхватит сразу. Локально на Mac — тоже сразу (симлинки); на Windows — перезапусти `setup.ps1`.

## Расход

Облачные прогоны идут из твоей подписки Claude (общий лимит с обычным использованием). `full` на opus — самый дорогой. Если ночные прогоны съедают лимит — в `.github/workflows/team.yml` замени `MODE="full"` на `MODE="office"` для nightly.
