# Roadmap — Estante de Jogos

Projeto mobile Android em **Godot 4.7.2 (GDScript)** concebido como um hub modular e escalável para múltiplos jogos clássicos, com o **Gamão** como primeiro jogo oficial da estante.

---

## Princípios de Entrega
- **Incrementalismo seguro:** cada etapa resulta em código limpo, lintado (`gdlint` / `gdformat --check`), validado com testes CLI headless e pronto para commit semântico.
- **Princípio de Mínima Permissão (Android):** o APK opera 100% offline, armazenando dados apenas no diretório privado do aplicativo (`user://`). Nenhuma permissão invasiva ou desnecessária será declarada no AndroidManifest (`INTERNET`, `CAMERA`, `RECORD_AUDIO`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, etc.).
- **Escopo do primeiro jogo (Gamão v1.0):** suporta **Jogador vs IA** (níveis **Fácil**, **Médio** e **Difícil**) e **2 Jogadores Local (Pass & Play)** no mesmo aparelho.

---

## Etapas do Projeto

### Etapa 0 — Fundação & Qualidade
- [x] Instalar e validar Godot 4.7.2 (`_console.exe` para CLI) e `gdtoolkit` (`gdlint`, `gdformat`).
- [x] Inicializar repositório Git (`main`), `.gitignore` (preservando `*.uid` e ignorando keystores/builds/segredos) e `.gdlintrc`.
- [x] Configurar `project.godot` para mobile Portrait (`1080x1920`, stretch `canvas_items` + `expand`, renderer `gl_compatibility`, `auto_accept_quit=false` e warnings rigorosos de tipagem).
- [x] Criar `docs/ROADMAP.md`, `docs/ARCHITECTURE.md` e `tools/check.ps1`.
- [x] Implementar runner de testes CLI headless (`tests/run_tests.gd` + `tests/test_case.gd`).

### Etapa 1 — Arquitetura Modular do Hub ("Estante de Jogos")
- [x] Implementar contratos em `res://core/contracts/` (`CoreTypes`, `GameMetadata`, `GameSessionConfig`, `GameResult`, `GameModule`).
- [x] Implementar catálogo dinâmico `GameCatalog` com tratamento de `.tres` e `.tres.remap` (compatível com exportação Android).
- [x] Implementar serviços globais `SaveManager` (isolado por `game_id` e versionado via `schema_version`), `AudioController` e `SceneRouter`.
- [x] Implementar UI Portrait do Hub (`AppRoot`, `MainMenu`, `GameCard`, `BaseGameHUD` e `estante_theme.tres`) com fluxo dinâmico de escolha de modo e dificuldade.
- [x] Criar módulo isolado stub do **Gamão** (`res://games/backgammon/`) validando ambos os modos (**Jogador vs IA** e **2 Jogadores Local**), simulação de resultados e retorno à Estante.
- [x] Validar testes unitários do núcleo, smoke test de cenas e verificação automática das fronteiras arquiteturais.

### Etapa 2 — Pipeline Android & Smoke Test no Dispositivo
- [x] Configurar `export_presets.cfg` para Android (arm64-v8a / armeabi-v7a, orientação travada em Portrait).
- [x] Aplicar **Princípio de Mínima Permissão**: auditar `export_presets.cfg` e o `AndroidManifest.xml` gerado garantindo ausência total de permissões desnecessárias (sem rede, localização, câmera, microfone ou armazenamento externo).
- [x] Configurar keystore local de debug (fora do controle de versão) e validar compilação de APK.
- [ ] Instalar e validar resolução, toque, botão Voltar do Android e persistência em dispositivo real/emulador via `adb install`.

### Etapa 3 — Motor Lógico Puro do Gamão
- [ ] Implementar `BackgammonTypes`, `BackgammonMove` e `BackgammonState` (`RefCounted` puro, `clone()`, contagem de Pips, invariante de 15 peças/lado).
- [ ] Implementar `BackgammonRules` com todas as regras oficiais:
  - Saída obrigatória da barra antes de outros movimentos.
  - Bloqueio em casas com 2+ peças adversárias e captura de *blot* (peça isolada).
  - Suporte completo a duplas (4 movimentos).
  - Regras de *bear-off* apenas com todas as peças no quadrante interno (exato e *overshoot* válido).
  - Obrigatoriedade de maximizar dados jogados e usar o dado maior quando apenas um for possível.
  - `get_all_legal_turn_sequences(state, dice)` retornando todas as sequências válidas.
  - Detecção de fim de partida: Vitória Simples (1x), Gammon (2x) e Backgammon (3x).
- [ ] Criar suíte exaustiva de testes unitários para casos de borda na CLI headless.

### Etapa 4 — Inteligência Artificial Offline
- [ ] Implementar `BackgammonAI` (`RefCounted` puro) com função avaliadora heurística (corrida/pips, *blots*, âncoras, primes, peças na barra e bear-off), estruturada para evoluir futuramente para pesos estilo PubEval.
- [ ] Implementar seletor de jogadas por nível de dificuldade:
  - **Fácil:** escolhe aleatoriamente entre jogadas medianas/inferiores.
  - **Médio:** escolhe aleatoriamente entre as top 3 jogadas.
  - **Difícil:** escolhe estritamente a melhor jogada avaliada.
- [ ] Criar testes automatizados garantindo 100% de jogadas legais, simulação IA vs IA sem travamentos e latência adequada para mobile.

### Etapa 5 — Interface Mobile do Gamão & Componentes Compartilhados (`shared/`)
- [ ] Extrair componentes reutilizáveis opt-in em `shared/` (`shared/dice/` para dados roláveis e `shared/board/` para helpers de *Tap-to-Move* e *Tween*).
- [ ] Desenvolver `BackgammonBoard.tscn` e `BackgammonGame.tscn` integrados ao motor puro:
  - Interação **Tap-to-Move** (toque na peça → destaque de destinos válidos → toque no destino), evitando *drag & drop*.
  - Suporte fluido tanto para **Jogador vs IA** quanto para **2 Jogadores Local (Pass & Play)**.
  - Animações `Tween` para movimentação de peças (essencial para acompanhar o turno da IA) e rolagem de dados.
  - Contador de Pips exibido no `extra_slot` do `BaseGameHUD`.

### Etapa 6 — Persistência Final, Polimento e Release v1.0
- [ ] Conectar estatísticas completas de Gamão (Simples, Gammon, Backgammon, sequências de vitórias) ao `SaveManager` e exibir resumo na Estante.
- [ ] Adicionar efeitos sonoros sintetizados/leves via `AudioController` respeitando configuração global de mute.
- [ ] Revisar ergonomia visual e responsividade em diferentes proporções Portrait.
- [ ] Auditar novamente o APK v1.0 quanto ao **Princípio de Mínima Permissão** e gerar build final validada.
- [ ] Remover `plano_de_desenvolvimento_gam_o.md` temporário após confirmar que todo o escopo foi migrado e concluído.
