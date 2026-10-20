# CyberPong

CyberPong é um jogo de Pong 2D feito em Godot 4 e GDScript. Duas equipes disputam em uma arena neon: Cyan Circuit joga à esquerda em ciano, e Magenta Volt joga à direita em magenta. A partida termina quando uma delas alcança três pontos, o equivalente a uma melhor de cinco.

## Como jogar

- No menu inicial, escolha **Jogador VS Jogador**, **Jogador VS AI**, **AI VS AI** ou **Sair**, que fecha o jogo. Use **↑/↓** e **Enter**, ou clique em um cartão.
- No modo Jogador VS AI, o lado esquerdo é humano e o direito é controlado pela IA.
- No modo Jogador VS Jogador, o lado esquerdo usa **W/S** ou as setas **↑/↓**, e o direito usa as setas **↑/↓**.
- No modo AI VS AI, as duas raquetes são controladas automaticamente.
- A primeira equipe a marcar três pontos vence.
- Pressione **ESC** ou **P** durante a partida para pausar. No menu de pausa, escolha **Continuar** para retomar o rally ou **Menu principal** para encerrar a partida e restaurar os valores padrão.
- Pressione **Enter** depois do fim da partida para começar outra no mesmo modo.
- Pressione **F3** para mostrar ou ocultar o HUD de debug.

As IAs acompanham a trajetória da bola, mas têm velocidade limitada e uma pequena zona de tolerância. Quando há um power-up disponível, a IA tenta alcançar os efeitos benéficos — raquete dobrada, freio na bola, rebote potente e defesa extra — e evitar a raquete reduzida, considerando as quicadas nas bordas. O HUD de jogo fica em uma barra reservada na parte superior e mostra o total de rebatidas e o estado do power-up, incluindo usos e duração restantes. O placar usa a fonte sans-serif de fallback do Godot, com nomes de equipe e três quadrados de progresso por lado, preenchidos conforme a pontuação; o painel do power-up traz nome, equipe beneficiada, usos e rebatidas restantes. A interface escala com a largura da janela para continuar legível e sem sobreposição. Cada saque é anunciado por um aviso breve com o emblema e a cor da equipe que serve; ao pontuar, a lateral e a linha de gol da equipe acendem por um instante. A tela de vitória escurece a arena e apresenta o vencedor com emblema, nome, placar final e a instrução de tecla para iniciar outra partida. A bola e as raquetes ficam limitadas à arena abaixo dessa barra. O HUD de debug começa oculto; use **F3** para alternar sua visibilidade. Quando aberto, fica no canto inferior esquerdo e mostra a velocidade atual da bola e as rebatidas de cada IA. Os contadores de rebatidas persistem entre pontos e zeram quando uma nova partida começa. O primeiro rally começa a 1.140 px/s para dar tempo de entender o jogo. Depois de cada ponto, o próximo rally começa a 1.500 px/s. A aceleração normal aumenta 10% a cada dois rebatimentos até 3.000 px/s; Rebote potente aumenta a velocidade em cada rebatida do dono, podendo passar desse limite, mas sem ultrapassar 3.540 px/s (3.000 × 1,18). Na rebatida adversária, ela volta a 3.000 px/s. Há efeitos de deformação nas colisões, uma trilha curta que acompanha a velocidade da bola, um anel de impacto e pequenas faíscas coloridas com física quando a bola atinge uma raquete; as faíscas quicam com amortecimento nas bordas da arena. As raquetes têm contorno, faixa interna e brilho em camadas nas cores de cada equipe, e o destaque do power-up troca essas camadas para a cor do efeito ativo.

O menu inicial é uma tela de transmissão sobre a arena escurecida: o letreiro geométrico do HUD reaparece em escala maior, Cyan Circuit e Magenta Volt emolduram a seleção com seus emblemas e o losango amarelo da bola funciona como cursor. Os três modos de jogo e a opção **Sair** aparecem em cartões angulares com foco neon, realce em degradê ciano/magenta e transição rápida ao confirmar; **Sair** encerra o jogo. O menu usa a fonte de fallback do Godot, escala com a janela e não depende de arquivos de arte.

O menu de pausa segue o mesmo template visual do menu inicial, com dois cartões angulares em vez dos três modos. Ele congela a partida e oferece **Continuar**, que retoma o rally com a mesma posição, direção e velocidade da bola e as mesmas posições das raquetes, e **Menu principal**, que encerra a partida e restaura placar, rebatidas, speed, power-up e tamanho das raquetes aos valores padrão antes de mostrar a tela de abertura. **ESC** ou **P** abre a pausa durante a partida; **ESC** ou **P** também retoma pelo menu. Enquanto a pausa está aberta, o jogador não controla as raquetes.

O primeiro power-up e as aparições seguintes são agendados após intervalos aleatórios de 5 a 15 rebatidas totais da partida. Se o efeito anterior ainda estiver ativo quando o intervalo terminar, o próximo item aparece assim que ele terminar. A bola precisa tocar o item para coletá-lo; quem recebe é a IA da última raquete que rebateu a bola. Se ninguém coletar o item em cinco rebatidas, ele desaparece. Cada efeito tem um símbolo geométrico próprio no item, e a moldura, o brilho e os detalhes usam a cor do efeito; enquanto disponível, o item pulsa e gira discretamente. O catálogo contém: dobrar ou reduzir pela metade a altura da raquete; Freio na bola, que deixa a dona rebater na velocidade atual e faz a adversária devolvê-la 8% mais lenta; aumentar a velocidade em 18% nos até quatro rebatimentos da raquete afetada, podendo passar de 3.000 px/s, mas sem ultrapassar 3.540 px/s (3.000 × 1,18). Quando a raquete adversária rebate a bola durante Rebote potente, a velocidade volta a 3.000 px/s e o tamanho visual volta ao normal. Defesa extra tem uma carga e permanece ativa por até 14 rebatidas totais, mas termina ao salvar uma falha. Cada efeito tem duração própria em rebatidas totais: raquete dobrada 6, raquete reduzida 5, Freio na bola e Rebote potente 8 e Defesa extra 14; efeitos sem `duration_hits` no catálogo usam o padrão de `active_duration_hits` (10) no nó `PowerUp`, e rebatidas das duas IAs contam. A raquete afetada ganha brilho e os efeitos de velocidade atualizam o HUD de debug.

## Executar

Instale o Godot 4.7.x, abra `project.godot` no editor do Godot e use **Executar projeto**. Também é possível iniciar o jogo em um terminal aberto na pasta do projeto:

```text
godot --path .
```

O comando pressupõe que o executável do Godot esteja disponível no `PATH`. Caso contrário, substitua `godot` pelo caminho do executável instalado no seu sistema.

O projeto abre a cena principal `main.tscn` em tela cheia. O renderer configurado é `gl_compatibility`. O jogo não precisa de dependências externas para ser executado. **GUT 9.7.1** é usado apenas no desenvolvimento e nos testes; o jogo não depende do addon para executar.

## Recursos visuais e licenças

O projeto não usa arquivos externos de arte, fonte, ícone ou áudio. Os elementos visuais são gerados em tempo de execução com recursos nativos do Godot:

| Recurso | Origem | Licença |
| --- | --- | --- |
| Arena, HUD, placar, emblemas, power-ups e menu | Código do projeto com `CanvasItem._draw()`, `Polygon2D`, `Line2D` e controles nativos | Código próprio; nenhum arquivo de mídia importado |
| Tipografia | `ThemeDB.fallback_font`, fonte sans-serif embutida no Godot | Conforme a distribuição do Godot; não há fonte própria no repositório |
| GUT 9.7.1 | `addons/gut/`, usado somente em desenvolvimento e testes | MIT |

Como não há recursos importados, não existe uma pasta `assets/` neste momento. Se um arquivo externo for adicionado, coloque-o em `assets/fonts/`, `assets/icons/` ou `assets/audio/`, conforme o tipo, e registre aqui e em `guia-visual.md` a origem, a licença e qualquer atribuição exigida. O teste `test/integration/test_scene_resources.gd` verifica que as cenas carregam suas dependências e que a fonte de fallback está disponível.

## Testes

A suíte automatizada usa **GUT 9.7.1**, gratuito e compatível com Godot 4.7.x. Os testes ficam em `test/unit/` e `test/integration/`; o addon fica em `addons/gut/` e é usado somente durante o desenvolvimento.

### Executar a suíte

Na pasta do projeto, execute no PowerShell:

```powershell
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit
```

Se o executável não estiver no `PATH`, substitua `godot` pelo caminho instalado. Neste ambiente, por exemplo:

```powershell
& "C:\Users\wellington\Desktop\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit
```

O GUT mostra no terminal a quantidade de testes aprovados, falhos e ignorados, junto das mensagens de falha. Para exportar também os resultados de execução em JUnit XML, crie a pasta `reports/` e acrescente `-gjunit_xml_file=reports/gut-results.xml` ao comando. Esse arquivo registra resultados dos testes; não é um relatório de cobertura de código.

### Plano de testes automatizados

- `test/unit/test_ball.gd`: saques, sinal de velocidade, reinício da contagem do rally, aceleração e limite, Rebote potente com limite de 3.000 × 1,18 (3.540 px/s) e retorno ao limite/tamanho normal na rebatida adversária, Freio com rebatida da dona na velocidade atual e devolução adversária 8% mais lenta, colisões com paredes, falhas, Defesa extra, coleta varrida, trilha visual e identificação da última raquete que rebateu.
- `test/unit/test_paddle.gd`: posição e colisão, previsão com reflexão, movimento limitado, zona morta, dimensão dos efeitos, camadas visuais da raquete e decisões de mira.
- `test/unit/test_power_up.gd`: aparecimento, janela de cinco rebatidas, coleta e proprietário, duração padrão/configurável, duração de 20 rebatidas da Defesa extra, cargas por raquete, sinais, estado do HUD, cores e símbolo do item, pulso disponível e redimensionamento.
- `test/unit/test_debug_hud.gd` e `test/unit/test_spark_effects.gd`: visibilidade, velocidade e contagens do HUD de debug; quantidade, expiração e quique das partículas, além do anel de impacto.
- `test/unit/test_game_menu.gd`: layout do menu em diferentes tamanhos de janela, escala, cartões de modo e Sair, ciclo de foco, cantos do destaque, cursor da bola, seleção única, transição de confirmação, início da partida pelo botão e pedido de saída após a transição.
- `test/unit/test_pause_menu.gd`: cartões de continuar e menu principal, layout responsivo, ciclo de foco, transição de confirmação, retomada por ESC e manutenção da pausa ao voltar ao menu principal.
- `test/integration/test_menu_flow.gd`: menu pausando a partida, seleção por botão, retomada do jogo, aplicação dos modos PvP e AI vs AI, estado inicial do rally e conexão do cartão Sair com o encerramento do jogo.
- `test/integration/test_pause_flow.gd`: abertura da pausa por ESC/P, congelamento da bola e das raquetes, retomada sem alterar posição, direção ou velocidade, e restauração dos valores padrão ao voltar ao menu principal.
- `test/integration/test_main_flow.gd`: cena e caminhos dos nós, conexões de sinais, velocidades de saque, placar e vitória de ambos os lados, aviso de saque, transição de ponto, revelação da tela de vitória, persistência e reinício de contagens, aplicação de efeitos, Defesa extra contando como rebatida, aparecimento atrasado, intervalo de spawn, teclas Enter/F3, escala responsiva do HUD e limites após redimensionamento.
- `test/integration/test_scene_resources.gd`: carregamento e instanciação de `main.tscn`, das cenas de bola, raquete, menu inicial e pausa, além da disponibilidade da fonte sans-serif de fallback sem arquivo de fonte externo.
- `test/integration/test_visual_verification.gd`: limites de bola, raquetes e power-up em várias resoluções, ausência de sobreposição entre logo, placar e painel do power-up, ajuste de fonte do painel, contraste das cores principais e atualização dos efeitos de colisão e do destaque do power-up durante a partida.

Os testes validam intervalos e invariantes quando há aleatoriedade, sem depender de um efeito ou trajetória sorteada em particular. A partida e seus componentes são exercitados em modo headless para manter os casos rápidos e reproduzíveis. GUT fornece o resultado dos testes; não foi configurado neste projeto um coletor de cobertura de código.

### Verificação visual e regressão

Complemente a suíte com uma verificação manual no Godot para o que depende de apresentação: tela de abertura e foco entre cartões, painel do HUD e placar, destaque da raquete, animações, faíscas, tela de vitória e layout após redimensionamento. Para cada bug que possa ser reproduzido automaticamente, mantenha um teste de regressão. Toda funcionalidade nova deve ter testes unitários; mudanças que conectam sistemas também precisam de testes de integração.
## Estrutura

```text
.
├── AGENTS.md              # Orientações para agentes que alterarem o projeto
├── README.md              # Visão geral, regras e instruções de execução
├── guia-visual.md         # Paleta, identidade das equipes e critérios visuais
├── melhoria.md            # Plano de melhorias visuais
├── project.godot          # Configuração do projeto, janela e cena de entrada
├── main.tscn               # Cena principal e composição do jogo
├── main.gd                 # Inicialização, atualização e regras da partida
├── main.gd.uid             # Identificador de recurso do script principal
├── addons/
│   └── gut/                # Framework gratuito de testes, usado no desenvolvimento
├── scenes/
│   ├── ball.tscn           # Nó visual da bola
│   ├── game_menu.tscn      # Tela de abertura com cartões de modo e foco por teclado
│   ├── pause_menu.tscn     # Menu de pausa com continuar e voltar ao menu principal
│   └── paddle.tscn         # Nó visual reutilizado pelas duas raquetes
├── scripts/
│   ├── arena.gd            # Fundo, linha central, placar, HUD e tela de vitória
│   ├── ball.gd             # Movimento, saques, colisões e velocidade da bola
│   ├── paddle.gd           # Movimento, controle humano, previsão da IA e animação das raquetes
│   ├── menu_screen.gd      # Layout, desenho e foco compartilhados pelos menus
│   ├── game_menu.gd        # Cartões de modo sobre o template visual do menu
│   ├── pause_menu.gd       # Cartões de continuar e voltar ao menu principal
│   ├── spark_effects.gd    # Faíscas físicas geradas nos rebatimentos
│   ├── debug_hud.gd        # HUD alternável de velocidade e rebatidas por IA
│   ├── power_up.gd         # Catálogo de efeitos, aparecimento, coleta e duração
│   └── power_up_symbol.gd  # Símbolos geométricos desenhados para cada efeito
└── test/
	├── unit/                 # Testes unitários em GDScript
	└── integration/          # Testes de cenas, sinais, recursos e regras em conjunto
```

## Regras e implementação

- `game_menu.gd` desenha a tela de abertura como uma transmissão sobre a arena escurecida, com letreiro, emblemas, cartões angulares, cursor em forma de bola e foco neon; mantém o layout responsivo, a navegação por ↑/↓/Enter/mouse e pausa a partida enquanto o menu está aberto. O cartão **Sair** emite `quit_requested`, que `main.gd` conecta ao encerramento do jogo. `menu_screen.gd` concentra layout, desenho e foco compartilhados; `pause_menu.gd` reutiliza esse template com os cartões Continuar e Menu principal, congela a árvore durante a pausa e só altera o estado da partida ao confirmar uma opção.
- `main.gd` abre o menu, aplica o modo escolhido, conecta os sinais da bola, atualiza as entidades, conta as rebatidas e reinicia o placar. Ele também abre a pausa por ESC/P, retoma sem tocar em bola ou raquetes e, ao voltar ao menu principal, reinicia placar, rebatidas, power-up, velocidade e tamanho das raquetes antes de recriar o menu inicial.
- `ball.gd` implementa o movimento e as colisões por código, sem nós de física. A aceleração normal aumenta a velocidade em 10% a cada segundo rebatimento, até 3.000 px/s; Rebote potente aumenta 18% em cada rebatida da raquete afetada, limitando a velocidade a 3.540 px/s (3.000 × 1,18), e volta a 3.000 px/s quando a raquete adversária rebate. Freio faz a dona rebater na velocidade de referência e a adversária devolver a bola 8% mais lenta. O primeiro saque de uma partida começa em 1.140 px/s; saques após pontos começam em 1.500 px/s e reiniciam a contagem de rebatimentos do rally. A velocidade é comunicada pelo sinal `speed_changed` no saque e sempre que muda, inclusive pelos power-ups.
- `power_up.gd` mantém os efeitos em `EFFECTS`, cada um com sua duração própria em `duration_hits` (raquete dobrada 6, raquete reduzida 5, Freio na bola e Rebote potente 8, Defesa extra 14), e `active_duration_hits` (padrão: 10) serve de reserva para efeitos sem `duration_hits`. Defesa extra tem uma carga e termina ao salvar uma falha. Freio na bola e Rebote potente também têm quatro usos nos rebatimentos da raquete afetada. `main.gd` sorteia intervalos de 5 a 15 rebatidas totais para as aparições. O tipo é sorteado uniformemente a partir de `EFFECT_IDS`. Para adicionar um efeito, inclua sua configuração e seu identificador em `EFFECTS` e `EFFECT_IDS`.
- `arena.gd` desenha o campo em camadas (degradê central, vinheta e marcações discretas), a moldura recortada com cantos nas cores das equipes, as linhas de gol ciano e magenta, o letreiro CYBERPONG, o placar com emblemas, nomes de Cyan Circuit e Magenta Volt e pips de pontos, o aviso de saque, a transição de ponto, a apresentação da equipe vencedora e o HUD superior com escala responsiva, cujos textos do painel reduzem para caber em janelas menores; a área de jogo começa abaixo dessa barra. Ao pontuar, a lateral e a linha de gol da equipe acendem e o cartão recebe um destaque breve que desaparece sozinho ou ao iniciar uma nova partida. A tela de vitória tem entrada animada, placar final e uma tecla Enter desenhada para deixar clara a reinicialização.
- `debug_hud.gd` mostra no canto inferior esquerdo a velocidade e as rebatidas por IA; F3 alterna sua visibilidade.
- `paddle.gd` calcula onde a bola deve chegar, com atraso de reação, zona de tolerância e velocidade limitada para que a IA possa errar. No modo humano, o lado esquerdo responde a W/S ou às setas, e o direito às setas. Quando há um power-up disponível, a IA tenta direcionar a bola ao efeito positivo ou afastá-la do negativo, considerando as reflexões nas bordas. Também atualiza dimensão, colisão e destaque visual quando recebe um efeito.
- `arena.gd` desenha a arena e o HUD diretamente, sem cena de interface separada; a tela de abertura e o menu de pausa são cenas `Control` próprias, desenhadas sobre o template compartilhado de `menu_screen.gd`.
- `spark_effects.gd` simula faíscas com gravidade e quique amortecido nas bordas da área de jogo, removendo-as ao fim do efeito.
- A resolução de viewport configurada em `project.godot` é 2880 × 1620, com modo de janela em tela cheia.
