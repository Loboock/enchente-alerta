CONTEXTO
Estou desenvolvendo o "Enchente Alerta", um aplicativo mobile (Flutter, Dart e Firebase) que envia alertas de alagamento em tempo real para moradores de regiões de risco. O slogan do app é "Informação que te protege". O app tem as telas de Login, Cadastro, Recuperar senha e Perfil, e uma barra de navegação com Início (mapa), Avisos, Histórico, Perfil e Guia.

Meu repositório de documentação contém: requisitos, personas, benchmark, estudo de caso, pesquisa e protótipos de baixa e alta fidelidade.

OBJETIVO
Me ajude a desenvolver o diagrama de classes (modelo de domínio) do app, representando as principais entidades, seus atributos, métodos e relacionamentos.

O QUE PRECISO
1. Identificar as entidades principais do domínio (por exemplo: Usuário, Endereço, Alerta, Área de risco, Estação de monitoramento, Mapa, Notificação, Histórico e Guia).
2. Para cada classe, definir:
   - atributos, com nome e tipo;
   - métodos principais, com parâmetros e retorno.
3. Definir os relacionamentos entre as classes, indicando:
   - o tipo (associação, agregação, composição, dependência);
   - a cardinalidade (1, 0..1, 0..*, 1..*);
   - um rótulo que explique cada relação.
4. Incluir enumerações quando fizer sentido, como o nível de alerta.

REGRAS
- Nomes de classes, atributos e métodos em português, sem acentos, no padrão camelCase (PascalCase para classes).
- Foco no domínio: sem classes de tela, widgets ou detalhes de infraestrutura.
- Cada classe deve ter uma responsabilidade clara.
- Se algo estiver ambíguo, diga qual suposição você adotou em vez de inventar em silêncio.

FORMATO DA ENTREGA
- Um diagrama renderizado, usando Mermaid (classDiagram).
- Um arquivo HTML de no máximo 200 linhas, que eu possa abrir direto no navegador.
- Depois do diagrama, um resumo curto explicando as entidades, os principais relacionamentos e as suposições feitas.
- No final, me diga quais documentos do repositório seriam úteis para refinar o modelo.
