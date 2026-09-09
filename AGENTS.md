# Проект OSA — Описание для агентов

**OSA** — переиспользуемая библиотека denix-модулей для NixOS + home-manager.
Это НЕ конфигурация машины: здесь нет `hosts/`, `rices/`, пользователя и
`nixosConfigurations`. Всё персональное/машинное живёт в composable
даунстрим-флейке:

```
osa (этот репо)  →  osa-krozzzis (~/osa-user)
модули + интерфейс   личность, косметика, rices, дотфайлы + hosts
```

---

## Архитектура

```
flake.nix        ← СГЕНЕРИРОВАННЫЙ файл (github:vic/flake-file), не редактировать руками
flake-file.nix   ← реальная точка входа: outputs + базовые inputs
modules/osa/     ← все модули, сгруппированы по категориям
│   ├── ai/         AI-инструменты (claude-code, codex, opencode)
│   ├── apps/       приложения
│   ├── browser/    браузеры
│   ├── de/         десктоп-окружения (niri, hyprland, xfce, caelestia) + dms
│   ├── dev/         LSP- и MCP-серверы (opt-in, пишут в user.dev.lsp / user.dev.mcp)
│   ├── editor/     редакторы (nixvim, vim, zed)
│   ├── fileManager/, media/, network/, office/, terminal/
│   ├── shell/      CLI-утилиты (включаются при user.shell.enable, включая rip)
│   ├── system/     системные настройки (audio, polkit, sddm, ...)
│   └── user/       ★ интерфейсный контракт user.* (только опции, см. ниже)
├── check/default.nix ← фейковый хост для полного eval-а всех модулей
└── lib/flake-inputs.nix ← сканер inputs.nix-файлов
```

## flake-file механика

`flake.nix` генерируется из `flake-file.nix` через
[flake-file](https://github.com/vic/flake-file). Любой flake input
объявляется в файле `inputs.nix` рядом с модулем, который его использует
(пример: `modules/osa/de/dms/inputs.nix`). `lib/flake-inputs.nix`
сканирует эти файлы и подмешивает их во flake.

После добавления/изменения любого `inputs.nix` или `flake-file.nix`:

```bash
nix run .#write-flake
```

`nix flake check` упадёт (`flake-file-in-sync`), если `flake.nix`
рассинхронизирован. Базовые inputs (`nixpkgs`, `home-manager`, `denix`,
`flake-file`) объявлены прямо в `flake-file.nix`.

## Интерфейсный контракт `user.*`

`modules/osa/user/default.nix` объявляет опции, которые читают модули osa.
Даунстрим (osa-krozzzis/другие host-флейки) **только проставляет значения**, ничего не
объявляет:

| Опция | Тип | Default | Кто заполняет |
|---|---|---|---|
| `user.constants.username` | str | **нет — обязателен** | osa-user |
| `user.constants.useremail` | str | **нет — обязателен** | osa-user |
| `user.gui.enable` | bool | `false` | osa-user (rice/desktop-профиль) |
| `user.shell.enable` | bool | `false` | osa-user |
| `user.shell.default` | nullOr attrs | `null` | хост: `{ pkg = myconfig.osa.shell.fish.pkg; }` |
| `user.editor.default` | attrs с `.pkg` | `{ pkg = myconfig.osa.editor.nixvim.pkg; }` | CLI-редактор; опционально |
| `user.editor.gui` | attrs с `.pkg` | `{ pkg = myconfig.osa.editor.zed.pkg; }` | GUI-редактор; опционально |
| `user.dev.lsp.<name>` | attrsOf submodule | `{}` | модули `osa.dev.lsp.*` |
| `user.dev.mcp.<name>` | attrsOf submodule | `{}` | модули `osa.dev.mcp.*` |
| `user.gui.fonts.nerdfonts` | bool | `false` | osa-user |
| `user.input.keyboard.layout` | str | `"us"` | osa-user keyboard profile |
| `user.input.keyboard.options` | str | `""` | osa-user keyboard profile |

Editor handle — attrset с обязательным package-полем `.pkg`; обычно это весь
`myconfig.osa.editor.<name>`. Бинарник получают через `lib.getExe app.pkg`.

При добавлении в любой модуль чтения новой опции `myconfig.user.*` —
сначала объяви её в `modules/osa/user/default.nix`.

## Как устроен модуль

```nix
{ delib, lib, pkgs, ... }:
delib.module {
  name = "osa.категория.имя";

  options = { myconfig, ... }: {
    osa.категория.имя.enable = delib.boolOption myconfig.user.gui.enable;
    # многие модули также выставляют .pkg:
    osa.категория.имя.pkg = delib.packageOption pkgs.имя;
  };

  nixos.ifEnabled = { ... }: { /* NixOS config */ };
  home.ifEnabled = { ... }: { /* home-manager config */ };
  myconfig.ifEnabled = { ... }: { /* запись в чужие myconfig-опции */ };
}
```

- Пространство имён опций: `myconfig.osa.<категория>.<имя>`.
- Если включение не нужно — `options = delib.singleEnableOption false;`.
- Жизненные циклы: `nixos/home/myconfig` × `.always` / `.ifEnabled` /
  `.ifDisabled`. Модули `osa.dev.*` — opt-in: у каждого своя опция
  `osa.dev.<категория>.<имя>.enable` (default `false`); при включении
  модуль сам регистрирует сервер в `user.dev.lsp/mcp` и ставит пакет.
- Доступ к чужим опциям — через `myconfig.osa....`; свой cfg — через аргумент `cfg`.
- Если модуль выставляет `.pkg`, установка должна использовать `cfg.pkg`, чтобы
  downstream override действительно работал.
- У локального `user.dev.mcp` обязателен непустой `command`, у remote — `url`;
  тип интерфейса проверяет это во время eval.

### Изменяемые конфиги приложений

Home Manager обычно создаёт config-файл как read-only symlink в Nix store. Для
программ, которые сами пишут runtime state в тот же файл, это неприемлемо.
Например, `osa.ai.codex` держит `~/.codex/config.toml` обычным файлом,
рекурсивно накладывает `osa.ai.codex.settings`, сохраняет runtime-ключи Codex и
отдельно отслеживает MCP-серверы, которыми управляет OSA. Не возвращай Codex к
прямому `programs.codex.settings`, иначе сохранение trust снова сломается.

### Граница DMS

В `osa.de.dms` живут пакет и inputs DMS, greeter, системные/Niri-интеграции,
power behavior, plugins, default wallpapers, mutable runtime-механика
`settings.json` и базовые значения, вычисляемые из глобальных
`osa.ui.*`/`user.fonts.*`. Персональный
downstream может дополнять `osa.de.dms.settings` только косметическими
пресетами (bar, widgets, control center, раскладка элементов). Не переноси
greeter или системные зависимости DMS в персональный репозиторий.

### Plymouth

`osa.system.plymouth` использует готовый пакет из input
`plymouth-theme-material`. Исправления Plymouth Script и Material You-визуал
живут в исходном репозитории темы; не добавляй отдельный upstream-пакет в
downstream. OSA принудительно выбирает одну версию `material`, чтобы
одноимённая директория не могла её затенить.

### Flake input модулю

Создай/дополни `inputs.nix` рядом с модулем:

```nix
{ ... }:
{
  flake-file.inputs.<name> = {
    url = "github:...";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Затем `nix run .#write-flake`. В модуле input доступен через `inputs.<name>`.

## Проверки

```bash
# Полный eval всех модулей (gui+shell профиль, niri+dms+walker, fish)
# через фейковый хост check/default.nix + сборка toplevel-деривации:
nix flake check

# Перегенерировать flake.nix после правки inputs.nix/flake-file.nix
nix run .#write-flake
```

## OSA CLI и повышение привилегий

Модуль `osa.system.osa-cli` включён по умолчанию и устанавливает команду
`osa`. Она работает с downstream-флейком из `~/osa-user`, если путь не
переопределён через `--config`:

```bash
osa update
osa switch nixlaptop-niri
osa update-switch --run0 nixlaptop-niri
osa build-iso pi-backup
osa build-installer nixlaptop-niri
```

`osa` запускается от обычного пользователя. Только `nixos-rebuild switch/boot`
повышает привилегии: по умолчанию через `sudo`, а с аргументом `--run0` — через
интерактивный launcher systemd `run0`. Агентам при необходимости root-доступа
следует предпочитать `run0 <command>` (или `osa ... --run0`) и не запускать всю
сессию/весь workflow от root.

`check/` виден только внутри этого флейка — даунстрим сканирует только
`${osa}/modules`. Реальную сборку машин проверяем в объединённом
`~/osa-user` (репозиторий `osa-krozzzis`):

```bash
cd ~/osa-user
nix eval .#nixosConfigurations.nixlaptop.config.system.build.toplevel.drvPath \
  --override-input osa ~/osa
```

## Как добавить модуль

1. `modules/osa/<category>/<name>.nix` по шаблону выше.
2. Нужен input — `inputs.nix` рядом + `nix run .#write-flake`.
3. Проверь: `nix flake check`.
