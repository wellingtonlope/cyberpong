# Guia visual

## Direção

O jogo segue a linguagem de uma transmissão de e-sports arcade: arena escura, geometria precisa e acentos neon ciano e magenta. A interface deve parecer parte da quadra, com painéis compactos e informação organizada por importância. O movimento e os efeitos podem chamar atenção por instantes, sem encobrir a bola ou as linhas do campo.

## Equipes

| Lado | Nome | Cor | Símbolo geométrico |
| --- | --- | --- | --- |
| Esquerdo | **Cyan Circuit** | Ciano `#14FAFF` | Hexágono aberto com um ponto central e dois pequenos traços de circuito. |
| Direito | **Magenta Volt** | Magenta `#FF1FB8` | Raio angular dentro de um losango aberto. |

Os símbolos devem continuar distinguíveis em uma cor só e em tamanho pequeno. Nome, posição e símbolo reforçam a cor; a cor não deve ser o único meio de identificar cada equipe.

## Paleta

Os valores hexadecimais abaixo são a representação aproximada de 8 bits das cores já definidas nos scripts; as constantes existentes continuam sendo a referência ao implementar visuais.

| Uso | Cor |
| --- | --- |
| Fundo externo | `#05080D` |
| Campo | `#090E17` |
| Painéis | `#030609` |
| Divisórias e texto secundário | `#2E3D52` / `#94ADCC` |
| Texto principal | `#E6F0FF` |
| Cyan Circuit | `#14FAFF` |
| Magenta Volt | `#FF1FB8` |
| Bola | `#FFEB1F` |
| Item disponível | `#FFC729` |
| Raquete dobrada | `#40FF6B` |
| Raquete reduzida | `#FF4D33` |
| Freio na bola | `#3D9EFF` |
| Rebote potente | `#FF8F2E` |
| Defesa extra | `#9E6BFF` |
| Linha de gol / alerta | `#FF141F` |

As cores de power-up identificam efeitos, enquanto ciano e magenta identificam equipes. Reserve vermelho para gol ou alerta. Use fundos de baixa luminosidade para que a bola amarela e as entidades de jogo se destaquem.

## Forma, contorno e brilho

- Prefira polígonos, linhas, arcos e retângulos desenhados no Godot. Formas angulares e simples combinam com a quadra e permanecem nítidas em movimento.
- Use contornos finos, de 1 a 2 unidades lógicas multiplicadas por `GAME_SCALE`; deixe contornos mais fortes para a moldura do campo e cartões de placar.
- Construa o brilho com um halo amplo e discreto e um núcleo nítido. Mantenha o halo translúcido e curto; ele não deve apagar o contorno da bola, da raquete ou do power-up.
- Ícones devem usar silhuetas reconhecíveis e poucos traços. Combine símbolo e cor no item e repita o nome no HUD para não depender apenas da cor ou de um caractere tipográfico.

## Tipografia e leitura durante o jogo

Use a fonte sans-serif de fallback do Godot enquanto não houver necessidade de incluir uma fonte externa. Mantenha uma família tipográfica, com números do placar maiores que títulos de painel e detalhes. Use texto principal claro e texto secundário azul acinzentado; evite texto fino sobre brilho ou cor saturada.

Ordem de leitura: placar e bola; raquetes e limites da quadra; item e estado do power-up; detalhes do HUD. Mantenha o fundo e as marcações de campo discretos. O símbolo e a cor devem identificar cada lado rapidamente, e os dados do power-up devem continuar legíveis na barra superior. Bola, raquetes e item permanecem abaixo do HUD e dentro dos limites da arena.

## Tela de créditos

Antes da transmissão, a tela de créditos apresenta o estúdio sem competir com a arena:

- Fundo preto integral (`#000000`), cobrindo toda a janela; nenhum elemento da arena deve aparecer atrás.
- O avatar fica centralizado acima do nome, com largura/altura proporcionais à janela e sem moldura.
- O nome **Moron Souls Productions** é escrito em branco puro, centralizado, com a fonte de fallback do Godot e uma linha de separação clara entre ícone e texto.
- A entrada e a saída usam fade curto; a permanência deve dar tempo de ler o nome sem atrasar o acesso ao menu. Qualquer tecla ou clique encerra a tela.
- Não adicione cartões, botões, emblemas das equipes ou o letreiro CYBERPONG a essa tela.

## Menu inicial

A tela de abertura deve parecer parte da transmissão, não uma caixa de diálogo sobre o jogo. Use a arena escurecida como fundo, mantenha o letreiro geométrico e os emblemas das equipes e trate os modos como cartões de transmissão.

- O conteúdo fica em uma coluna central com largura limitada; use a mesma escala responsiva do HUD e mantenha margem livre da barra superior.
- Cada modo é um cartão angular com título, descrição curta e uma etiqueta (`LOCAL`, `SOLO`, `AUTO`). O cartão em foco recebe contorno mais claro, brilho curto, cantos ciano/magenta e a linha superior em degradê.
- O cursor é o losango amarelo da bola, com uma trilha curta; ele desliza entre os cartões e não substitui o foco de teclado.
- O rodapé mostra as teclas de navegação e confirmação no mesmo estilo de keycap da tela de vitória. O foco precisa continuar visível sem depender apenas de cor.
- A entrada e a confirmação podem usar fade, varredura e um pulso breve, mas nenhuma animação deve atrasar a leitura das opções.
- Não use `PanelContainer`, botões com o tema padrão do Godot, cantos arredondados ou assets externos.

## Menu de pausa

O menu de pausa reutiliza o mesmo template de transmissão do menu inicial, com dois cartões angulares e o cursor da bola. Mantenha o título CYBERPONG, os emblemas das equipes e os cartões **Continuar** e **Menu principal**, com o rodapé de teclas no estilo de keycap. O fundo escurece a partida congelada atrás do painel; nenhuma opção deve alterar a posição das raquetes, a direção da bola ou a velocidade enquanto o menu está aberto.

## Recursos e licenças

O único arquivo de imagem é o avatar da tela de créditos, `assets/icons/moronsouls_avatar.png`, originado do canal do YouTube [@moronsouls4405](https://www.youtube.com/@moronsouls4405) e recortado sem o fundo. Os efeitos sonoros em `assets/audio/` são sintetizados proceduralmente para o projeto via `scripts/generate_audio.py` (código próprio, sem dependências externas). Registre neste guia a origem e a licença de qualquer novo asset externo. Para todo o restante, use os recursos nativos do Godot já adotados pelo projeto, como `Polygon2D`, `Label`, `ColorRect`, `TextureRect` e os métodos de desenho de `CanvasItem`. O ícone deve manter transparência nas bordas e pode ser substituído sem alterar o fundo preto ou o texto branco da tela.
