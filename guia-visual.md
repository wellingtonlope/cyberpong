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

## Recursos e licenças

Não são necessários arquivos de arte, fontes ou ícones externos. Use os recursos nativos do Godot já adotados pelo projeto, como `Polygon2D`, `Label` e os métodos de desenho de `CanvasItem`. Assim, não há licenças externas ou créditos adicionais a registrar. Se um asset externo for adotado no futuro, registre neste guia sua origem, licença e atribuição exigida.
