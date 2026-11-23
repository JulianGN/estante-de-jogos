# Módulos Compartilháveis (`res://shared/`)

Esta pasta reúne componentes **opcionais (opt-in)** reutilizáveis por múltiplos jogos da Estante:

- `shared/dice/` *(Etapa 5)*: componente visual e animação de rolagem de dados.
- `shared/board/` *(Etapa 5)*: utilitários visuais de *Tap-to-Move* e animação `Tween` de peças.

## Regras
- Jogos independentes **não** são obrigados a usar nada desta pasta.
- Scripts em `res://shared/` **nunca** podem importar ou referenciar `res://games/`.
