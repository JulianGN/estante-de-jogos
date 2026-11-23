# Arquitetura — Estante de Jogos

Este documento descreve a arquitetura modular do aplicativo **Estante de Jogos** e serve como referência técnica obrigatória para a evolução do Hub e inclusão de novos jogos.

---

## 1. Visão Geral e Estrutura de Diretórios

```text
res://
├── core/                      # Núcleo do Hub (independente de qualquer jogo)
│   ├── assets/                # Ícone e recursos visuais exclusivos da casca do Hub
│   ├── catalog/               # GameCatalog.gd + arquivos .tres de metadados dos jogos
│   ├── contracts/             # Contratos, enums e Value Objects de fronteira
│   ├── services/              # SaveManager, AudioController, SceneRouter
│   └── ui/                    # AppRoot, MainMenu, GameCard, BaseGameHUD, tema
├── shared/                    # Blocos OPT-IN reutilizáveis entre jogos (ex.: dados, helpers de tabuleiro)
├── games/                     # Módulos isolados de cada jogo (1 pasta por jogo)
│   └── backgammon/            # Módulo do Gamão
│       ├── assets/
│       ├── logic/             # Classes puras RefCounted (sem Node/UI, testáveis em CLI)
│       └── ui/                # Cenas e controladores visuais do jogo
├── tests/                     # Suíte de testes CLI headless (godot --headless --script)
└── tools/                     # Scripts de automação e qualidade (check.ps1)
```

---

## 2. Regras de Dependência (Fronteiras Arquiteturais)

A arquitetura aplica **dependência estritamente unidirecional**:

1. **`core/` é fechado para `games/` e `shared/`:**
   - Scripts dentro de `res://core/` **nunca** podem referenciar `res://games/` ou `res://shared/`.
   - O `MainMenu` descobre os jogos exclusivamente lendo recursos `.tres` (`GameMetadata`) no catálogo.
2. **`shared/` é opcional (opt-in) e fechado para `games/`:**
   - Um jogo simples e totalmente independente (ex.: 2048, Jogo da Memória, Paciência) pode ignorar completamente `shared/` e até mesmo ignorar `BaseGameHUD`, implementando sua própria UI.
   - Scripts em `res://shared/` **nunca** podem referenciar `res://games/`.
3. **Isolamento entre jogos (`games/<A>` vs `games/<B>`):**
   - Um jogo **nunca** importa código, cenas ou assets de outro jogo em `res://games/`.
   - Tudo que precisar ser compartilhado por dois ou mais jogos deve ser promovido para `res://shared/`.
4. **Separação Domínio vs UI dentro de cada jogo:**
   - Regras de jogo, estado e IA devem residir em `games/<id>/logic/` como classes `RefCounted` puras, sem herdar de `Node` nem referenciar UI, garantindo testabilidade 100% via CLI headless.

Essas fronteiras são verificadas automaticamente pelo teste `res://tests/core/test_architecture_boundaries.gd`.

---

## 3. Contratos do Hub (`res://core/contracts/`)

### `CoreTypes`
Centraliza enums fortes e mapeamentos canônicos para eliminar *magic strings*:
- `GameMode`: `VS_AI`, `LOCAL_TWO_PLAYERS`
- `Difficulty`: `EASY`, `MEDIUM`, `HARD`
- `MatchOutcome`: `WIN`, `LOSS`, `DRAW`, `ABORTED`

### `GameMetadata` (`Resource`)
Contrato declarativo de registro de um jogo na estante (`res://core/catalog/<id>.tres`):
- `id`: slug único (`[a-z0-9_-]+`) usado também como namespace no `SaveManager`.
- `title`, `description`, `category`, `icon`, `accent_color`, `sort_order`, `enabled`.
- `scene_path`: caminho `res://.../*.tscn` da cena raiz do jogo.
- `supports_ai`, `supports_local_multiplayer`, `supported_difficulties`.
- Possui validação de domínio própria (`validate()` / `is_valid()`).

### `GameSessionConfig` e `GameResult` (`RefCounted`)
- **`GameSessionConfig`:** Value Object imutável entregue pelo `SceneRouter` ao jogo no início da sessão (`game_id`, `mode`, `difficulty`, `options`), validado contra o `GameMetadata`.
- **`GameResult`:** Value Object emitido pelo jogo ao encerrar uma partida (`game_id`, `mode`, `difficulty`, `outcome`, `winner_label`, `score_multiplier`, `score_label`, `duration_seconds`, `details`).

### Protocolo Mínimo da Cena de Jogo (`GameModule` opcional)
Para se conectar ao `SceneRouter`, a cena raiz do jogo precisa apenas aderir ao protocolo abaixo (herdando `GameModule` ou declarando diretamente os mesmos métodos/sinais no seu nó raiz):
- Sinais:
  - `signal exit_requested` — solicitado quando o jogador deseja voltar à Estante.
  - `signal game_finished(result: GameResult)` — emitido ao fim de cada partida para registro de estatísticas no `SaveManager`.
- Métodos opcionais:
  - `func setup_session(config: GameSessionConfig) -> void` — chamado imediatamente após instanciar a cena.
  - `func handle_back_request() -> bool` — intercepta o botão Voltar do Android / `Esc` no desktop; retorna `true` se o jogo tratou (ex.: abriu confirmação de saída) ou `false` para o `SceneRouter` retornar direto ao `MainMenu`.

---

## 4. Catálogo Dinâmico e Compatibilidade com Android (`.tres.remap`)

Em builds exportados para Android (PCK), o Godot substitui arquivos `.tres` no sistema de arquivos virtual por `<nome>.tres.remap`. Se o catálogo filtrasse apenas `.ends_with(".tres")`, nenhum jogo apareceria no celular.

O `GameCatalog.normalize_resource_path()` trata ambos:
- `<arquivo>.tres` → `res://core/catalog/<arquivo>.tres`
- `<arquivo>.tres.remap` → remove `.remap` e resolve para `res://core/catalog/<arquivo>.tres`
- Deduplica os caminhos antes de chamar `ResourceLoader.load()`.

---

## 5. Persistência Isolada e Mínima Permissão

O `SaveManager` (Autoload `SaveManager`, script `SaveManagerService`) persiste em `user://estante_save.json` com `schema_version = 1` e estrutura isolada por `game_id`:

```json
{
  "schema_version": 1,
  "settings": { "sfx_enabled": true, "music_enabled": true },
  "games": {
    "backgammon": {
      "stats": {
        "matches_played": 0,
        "wins": 0,
        "losses": 0,
        "draws": 0,
        "current_streak": 0,
        "best_streak": 0,
        "by_difficulty": {},
        "special_wins": {}
      },
      "custom_data": {}
    }
  }
}
```

- **Segurança em testes headless (`--script`):** Autoloads não são montados em `/root/` durante execuções `--script`. Por isso, os componentes resolvem `SaveManager` e `AudioController` via `get_node_or_null("/root/...")` ou injeção direta de dependência.
- **Mínima permissão:** O uso exclusivo de `user://` garante armazenamento privado no Android sem exigir permissões de armazenamento externo, rede ou hardware.

---

## 6. Como Adicionar um Novo Jogo à Estante

1. Crie uma pasta isolada em `res://games/<id_do_jogo>/` (com subpastas `logic/`, `ui/`, `assets/`).
2. Implemente a lógica pura em `logic/` (`RefCounted`) e a cena raiz em `ui/<NomeGame>.tscn`.
3. Na cena raiz, herde `GameModule` (ou emita `exit_requested` / `game_finished(result)` e implemente `setup_session(config)`). Opcionalmente instancie `res://core/ui/BaseGameHUD.tscn`.
4. Crie o arquivo `res://core/catalog/<id_do_jogo>.tres` do tipo `GameMetadata` apontando para a cena e declarando os modos suportados.
5. Adicione os testes unitários do novo jogo em `res://tests/games/<id_do_jogo>/` e execute `.\tools\check.ps1`.
6. O novo jogo aparecerá automaticamente no `MainMenu` na próxima execução, sem alterar nenhuma linha de código do `core/`.
