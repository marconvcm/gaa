# Gauho & Aliens — guia do projeto

## Plataforma e estado atual

- Engine: Godot 4.7, projeto 2D mobile com viewport interno de 480×270 e filtro de textura `nearest`.
- Cena inicial: `game.tscn`.
- A cena possui uma `NavigationRegion2D` que cobre a arena, Player, NPC de patrulha e Enemy de teste.
- Código e cenas reutilizáveis ficam em `components/`; scripts-base ficam em `components/base/`.
- Use GDScript com tabs; `.editorconfig` é a referência de formatação.

## Convenções obrigatórias

- Componentes devem usar o sufixo `Component` (`MoveComponent`, `HPComponent`, `HitboxComponent`) e ser adicionados como nós filhos do ator ou objeto que controlam.
- Objetos de jogo que não são componentes devem usar o sufixo `Object` (`ProjectileObject`).
- Objetos devem ser criados pelo padrão **Project Factory**: cada classe `*Object` expõe uma fábrica estática `create(...)` que devolve a instância já configurada. Chamadores não devem usar `Object.new()` diretamente.
- Prefira ampliar os componentes existentes e comunicar-se por sinais, evitando lógica específica de Enemy dentro de componentes genéricos.
- Preserve ajustes existentes nas cenas herdadas; antes de alterar uma cena, confira sua estrutura atual.

## Arquitetura de atores

`components/actor.tscn` é a base de `Player`, `NPC` e `Enemy`. Contém:

- `MoveComponent`: movimenta `CharacterBody2D`, guarda `facing_direction` em oito direções e pode restringir o movimento a oito direções por `use_eight_direction_movement`.
- `DebugActorComponent`: desenha origem, direção de olhar, velocidade, hitbox melee ativa e barra de vida.
- `ShotComponent`: usa `ProjectileObject.create(...)` para disparar.
- `MeleeComponent`: cria uma `HitboxComponent` temporária à frente do ator; bloqueia movimento enquanto o golpe está ativo.
- `AnimationPlayer`: animação `melee_attack`, que usa `Sprite.self_modulate`: branco no início, preto durante o ataque e normal ao fim.
- `HPComponent` + `ActiveValue`: vida com carga/descarga e sinais de alteração, esgotamento e preenchimento.
- `KnockbackComponent`: aplica recuo com desaceleração e tem prioridade sobre o movimento normal.
- `HurtboxComponent`: recebe `HitboxComponent`; `can_receive_damage` permite tornar um ator invulnerável.
- O plugin `addons/room_discovery` adiciona à Command Palette `Generate Room Areas for Selected TileMap`. Com um `TileMapLayer` selecionado, o comando calcula seu `get_used_rect()` e cria `Area2D`s de 480×270 como filhos do TileMap somente quando a região contém tiles usados; áreas geradas em regiões vazias são removidas. A geração suporta undo/redo, salva as áreas na cena e não cria colisões ativas.
- `Sprite`: usa `shaders/sprite_shine.gdshader` com os parâmetros `is_shining` e `shine_frequency`.

## Input e entidades

- `InputComponent` é o contrato de entrada. `PlayerInputComponent` implementa movimento, shot e melee; `AIInputComponent` faz perseguição ou patrulha por navegação.
- Ações: WASD/setas ou controle para mover; Espaço/botão inferior para `shoot`; F/botão esquerdo para `melee`.
- `Player` inclui `GameCamera` (`Camera2D`) e possui velocidade de 96. A câmera procura `RoomTileMap` na raiz, descobre suas áreas geradas pelo plugin e aplica os limites da área que contém o Player, expandidos por uma margem configurável de 8%. Ao mudar de sala, os limites interpolam com `room_transition_lerp_speed`.
- `RoomManager` é um autoload global. A `GameCamera` define nele a sala atual e sua margem, e sistemas podem chamar `RoomManager.is_position_inside_current_room(global_position)` para limitar ações exatamente à área visual da câmera.
- `NPC` tem `NavigationAgent2D`, patrulha entre offsets locais e é invulnerável (`HurtboxComponent.can_receive_damage = false`).
- `Enemy` não tem movimento voluntário, mas pode sofrer dano, pisca em branco ao ser atingido, recebe knockback e é removido ao zerar HP. O Enemy ajusta o sprite por um material local.

## Combate

- Fluxo único para ataques: `HitboxComponent → HurtboxComponent → HPComponent → reação da entidade`.
- Melee e projectile usam esse mesmo fluxo.
- `HitboxComponent` carrega dano, força de knockback e ator de origem; ela ignora a hurtbox do próprio atacante.
- Knockback é calculado do centro do atacante para o centro do alvo. `MeleeComponent.knockback_force` é 220 por padrão e `ShotComponent.knockback_force` é 120 por padrão.
- `ProjectileObject` é um `Sprite2D` que desenha um círculo vermelho, cria uma hitbox circular, é destruído ao atingir uma hurtbox, uma parede na collision layer 1 ou ao sair da sala atual definida por `RoomManager`. Paredes podem ser `StaticBody2D` ou colisões de `TileMapLayer`; ele expira após 1,5 s.

## Verificação

- Após alterações de scripts/cenas, execute `git diff --check` e abra o projeto em modo headless com `godot --headless --path . --editor --quit`.
- O ambiente pode reportar falhas para salvar configurações globais do editor em `~/.config/godot`; isso é externo ao projeto. Erros de parse, shader ou referência de cena precisam ser corrigidos.
