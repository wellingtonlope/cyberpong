# Pong Simples

Um jogo de Pong 2D feito em Godot 4 e GDScript. Duas IAs disputam automaticamente em uma arena neon: Cyan Circuit joga à esquerda em ciano, e Magenta Volt joga à direita em magenta. A partida termina quando uma delas alcança três pontos, o equivalente a uma melhor de cinco.

## Como jogar

- Observe a partida automática entre as duas IAs; não há controle manual das raquetes.
- A primeira IA a marcar três pontos vence.
- Pressione **Enter** depois do fim da partida para começar outra.
- Pressione **F3** para mostrar ou ocultar o HUD de debug.

As IAs acompanham a trajetória da bola, mas têm velocidade limitada e uma pequena zona de tolerância. Quando há um power-up disponível, a IA tenta alcançar os efeitos benéficos — raquete dobrada, freio na bola, rebote potente e defesa extra — e evitar a raquete reduzida, considerando as quicadas nas bordas. O HUD de jogo fica em uma barra reservada na parte superior e mostra o total de rebatidas e o estado do power-up, incluindo usos e duração restantes. A bola e as raquetes ficam limitadas à arena abaixo dessa barra. O HUD de debug começa oculto; use **F3** para alternar sua visibilidade. Quando aberto, fica no canto inferior esquerdo e mostra a velocidade atual da bola e as rebatidas de cada IA. Os contadores de rebatidas persistem entre pontos e zeram quando uma nova partida começa. O primeiro rally começa a 1.140 px/s para dar tempo de entender o jogo. Depois de cada ponto, o próximo rally começa a 1.500 px/s. A aceleração normal aumenta 10% a cada dois rebatimentos até 3.000 px/s; Rebote potente aumenta a velocidade em cada rebatida do dono, podendo passar desse limite. Na rebatida adversária, ela volta a 3.000 px/s. Há efeitos de deformação nas colisões e pequenas faíscas coloridas com física quando a bola atinge uma raquete; elas quicam com amortecimento nas bordas da arena.

O primeiro power-up e as aparições seguintes são agendados após intervalos aleatórios de 5 a 15 rebatidas totais da partida. Se o efeito anterior ainda estiver ativo quando o intervalo terminar, o próximo item aparece assim que ele terminar. A bola precisa tocar o item para coletá-lo; quem recebe é a IA da última raquete que rebateu a bola. Se ninguém coletar o item em cinco rebatidas, ele desaparece. O catálogo contém: dobrar ou reduzir pela metade a altura da raquete; Freio na bola, que deixa a dona rebater na velocidade atual e faz a adversária devolvê-la 8% mais lenta; aumentar a velocidade em 18% nos até cinco rebatimentos da raquete afetada, podendo passar de 3.000 px/s. Quando a raquete adversária rebate a bola durante Rebote potente, a velocidade volta a 3.000 px/s e o tamanho visual volta ao normal. Defesa extra tem uma carga e permanece ativa por até 20 rebatidas totais, mas termina ao salvar uma falha. Os demais efeitos duram dez rebatidas totais por padrão; esse limite pode ser ajustado em `active_duration_hits` no nó `PowerUp`, e rebatidas das duas IAs contam. A raquete afetada ganha brilho e os efeitos de velocidade atualizam o HUD de debug.

## Executar

Instale o Godot 4.7.x, abra `project.godot` no editor do Godot e use **Executar projeto**. Também é possível iniciar o jogo em um terminal aberto na pasta do projeto:

```text
godot --path .
```

O comando pressupõe que o executável do Godot esteja disponível no `PATH`. Caso contrário, substitua `godot` pelo caminho do executável instalado no seu sistema.

O projeto abre a cena principal `main.tscn` em tela cheia. O renderer configurado é `gl_compatibility`. O jogo não precisa de dependências externas para ser executado. **GUT 9.7.1** é usado apenas no desenvolvimento e nos testes; o jogo não depende do addon para executar.

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

- `test/unit/test_ball.gd`: saques, sinal de velocidade, reinício da contagem do rally, aceleração e limite, Rebote potente e retorno ao limite/tamanho normal na rebatida adversária, Freio com rebatida da dona na velocidade atual e devolução adversária 8% mais lenta, colisões com paredes, falhas, Defesa extra, coleta varrida e identificação da última raquete que rebateu.
- `test/unit/test_paddle.gd`: posição e colisão, previsão com reflexão, movimento limitado, zona morta, dimensão dos efeitos e decisões de mira.
- `test/unit/test_power_up.gd`: aparecimento, janela de cinco rebatidas, coleta e proprietário, duração padrão/configurável, duração de 20 rebatidas da Defesa extra, cargas por raquete, sinais, estado do HUD e redimensionamento.
- `test/unit/test_debug_hud.gd` e `test/unit/test_spark_effects.gd`: visibilidade, velocidade e contagens do HUD de debug; quantidade, expiração e quique das partículas.
- `test/integration/test_main_flow.gd`: cena e caminhos dos nós, conexões de sinais, velocidades de saque, placar e vitória de ambos os lados, persistência e reinício de contagens, aplicação de efeitos, Defesa extra contando como rebatida, aparecimento atrasado, intervalo de spawn, teclas Enter/F3 e limites após redimensionamento.

Os testes validam intervalos e invariantes quando há aleatoriedade, sem depender de um efeito ou trajetória sorteada em particular. A partida e seus componentes são exercitados em modo headless para manter os casos rápidos e reproduzíveis. GUT fornece o resultado dos testes; não foi configurado neste projeto um coletor de cobertura de código.

### Verificação visual e regressão

Complemente a suíte com uma verificação manual no Godot para o que depende de apresentação: painel do HUD e placar, destaque da raquete, animações, faíscas, tela de vitória e layout após redimensionamento. Para cada bug que possa ser reproduzido automaticamente, mantenha um teste de regressão. Toda funcionalidade nova deve ter testes unitários; mudanças que conectam sistemas também precisam de testes de integração.
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
│   └── paddle.tscn         # Nó visual reutilizado pelas duas raquetes
├── scripts/
│   ├── arena.gd          # Fundo, linha central, placar, HUD e tela de vitória
│   ├── ball.gd           # Movimento, saques, colisões e velocidade da bola
│   ├── paddle.gd         # Movimento, previsão da IA e animação das raquetes
│   ├── spark_effects.gd  # Faíscas físicas geradas nos rebatimentos
│   ├── debug_hud.gd      # HUD alternável de velocidade e rebatidas por IA
│   └── power_up.gd       # Catálogo de efeitos, aparecimento, coleta e duração
└── test/
	├── unit/               # Testes unitários em GDScript
	└── integration/        # Testes de cenas, sinais e regras em conjunto
```

## Regras e implementação

- `main.gd` conecta os sinais da bola, atualiza as entidades, conta as rebatidas e reinicia o placar. A escala visual e os parâmetros gerais ficam no início desse script.
- `ball.gd` implementa o movimento e as colisões por código, sem nós de física. A aceleração normal aumenta a velocidade em 10% a cada segundo rebatimento, até 3.000 px/s; Rebote potente aumenta 18% em cada rebatida da raquete afetada e volta a 3.000 px/s quando a raquete adversária rebate. Freio faz a dona rebater na velocidade de referência e a adversária devolver a bola 8% mais lenta. O primeiro saque de uma partida começa em 1.140 px/s; saques após pontos começam em 1.500 px/s e reiniciam a contagem de rebatimentos do rally. A velocidade é comunicada pelo sinal `speed_changed` no saque e sempre que muda, inclusive pelos power-ups.
- `power_up.gd` mantém os efeitos em `EFFECTS`, controla a janela de cinco rebatidas e a duração configurável em `active_duration_hits` (padrão: 10 rebatidas totais). Defesa extra tem uma carga e duração própria de até 20 rebatidas. Freio na bola e Rebote potente também têm cinco usos nos rebatimentos da raquete afetada. `main.gd` sorteia intervalos de 5 a 15 rebatidas totais para as aparições. O tipo é sorteado uniformemente a partir de `EFFECT_IDS`. Para adicionar um efeito, inclua sua configuração e seu identificador em `EFFECTS` e `EFFECT_IDS`.
- `arena.gd` desenha o letreiro CYBERPONG, o placar com emblemas e nomes de Cyan Circuit e Magenta Volt, a apresentação da equipe vencedora e o HUD superior; a área de jogo começa abaixo dessa barra.
- `debug_hud.gd` mostra no canto inferior esquerdo a velocidade e as rebatidas por IA; F3 alterna sua visibilidade.
- `paddle.gd` calcula onde a bola deve chegar, com atraso de reação, zona de tolerância e velocidade limitada para que a IA possa errar. Quando há um power-up disponível, a IA tenta direcionar a bola ao efeito positivo ou afastá-la do negativo, considerando as reflexões nas bordas. Também atualiza dimensão, colisão e destaque visual quando recebe um efeito.
- `arena.gd` desenha a arena e a interface diretamente, sem cena de interface separada.
- `spark_effects.gd` simula faíscas com gravidade e quique amortecido nas bordas da área de jogo, removendo-as ao fim do efeito.
- A resolução de viewport configurada em `project.godot` é 2880 × 1620, com modo de janela em tela cheia.
