# Benchmark — EnchenteAlerta

Este documento apresenta a análise de soluções já existentes relacionadas ao problema de alagamentos e enchentes, com o objetivo de identificar pontos fortes, fracos e oportunidades de diferenciação para o EnchenteAlerta.

## 1. Alagou

### Principais funcionalidades
- Reporta pontos alagados em tempo real.
- Consulta áreas alagadas usando dados georreferenciados.
- Tem origem acadêmica e está disponível em plataforma web.

### Pontos positivos
- Sistema simples e direto: reportar e consultar.
- Baseia-se em inteligência coletiva — quanto mais gente usa, melhor ele fica.
- Foco em evitar áreas de risco, não apenas alertar sobre elas.

### Pontos negativos
- Depende ativamente da participação da comunidade para funcionar da melhor forma.
- Aparentemente não tem funções como rotas de fuga, abrigos ou guia de preparação.
- Não apresenta suporte a uso offline, o que pode se tornar um problema.

### Interface/experiência
- Interface parece simples e não muito complicada.
- Há dúvidas em relação à acessibilidade.
- Não há informação visível sobre modo noturno, alto contraste ou foco em situação de pânico.

### O que pode ser aproveitado ou melhorado no projeto
- Aproveitar: a lógica de reporte colaborativo em tempo real, similar ao botão "Estou vendo água subir" do EnchenteAlerta.
- Melhorar: adicionar rotas de fuga, abrigos, guia de preparação, modo offline e modo noturno de alto contraste — pontos que o Alagou não cobre.

---

## 2. AlertaBlu 

### Principais funcionalidades
* Rotas de fuga em tempo real: o usuário informa origem e destino, e o app traça o caminho mais seguro, desviando de áreas alagadas e bloqueios. 
* Indicação de abrigos ativos.
* Dados de estações pluviométricas, previsão do tempo, alertas de deslizamento e status de barragens.
* Recursos de acessibilidade para pessoas com deficiência visual.
* Monitoramento do nível do rio em tempo real. 
* Mapa de áreas de risco. 
* Registro de ocorrências com localização e fotos. 

### Pontos positivos
* Reconhecido nacionalmente como boa prática em Defesa Civil (2025 e 2026). 
* Integra dados oficiais (geolocalização + monitoramento hídrico).
* Possui alertas personalizados por localização. 
* Permite que o usuário registre ocorrências. 
* Possui recursos de acessibilidade, incluindo suporte a leitores de tela. 

### Pontos negativos
* Cobertura limitada a um único município (Blumenau), não escala para outras regiões sem adaptação. 
* Não há menção a modo offline, algo crítico quando a internet cai durante a enchente. 
* A grande quantidade de informações, usuário precisa navegar por diferentes funcionalidades para encontrar algumas informações. 
* A proposta é bastante ampla, enquanto em uma situação de emergência o usuário pode precisar de uma ação extremamente rápida e direta. 

### Interface/experiência
* A interface prioriza informações e monitoramento. O aplicativo apresenta diversos dados meteorológicos, níveis do rio, mapas e avisos. 
* A experiencia pode ser um pouco confusa para quem é novo no app e/ou para quem está em emergência  

### O que pode ser aproveitado ou melhorado no projeto
* Podemos aproveitar as funcionalidades de rota de fuga, indicações de abrigos e recursos de acessibilidade. 
* Alertas meteorológicos; 
* Níveis de risco; 
* Integração com Defesa Civil. 
* Para ser melhorado a quantidade de informação na tela inicial, a cobertura do mapa 

### O que nosso aplicativo poderá fazer de diferente ou melhor?
* Podemos fazer um modo offline para situações críticas 
* Modo de emergência- Como o aplicativo será usado em ruas escuras e alagadas, a interface pode ter um modo específico: alto contraste, textos grandes, poucos elementos, botões grandes, amarelo para alertas, azul-escuro como fundo, informações essenciais primeiro, rotas de fuga disponíveis offline. 
---

## 3. COR.Rio

### Principais funcionalidades
- Monitoramento em tempo real de trânsito, tempo, sirenes e estações pluviométricas.
- Estágio operacional da cidade em níveis de 1 a 5, conforme a gravidade da situação.
- Reporte de ocorrências pelo próprio usuário (acidentes, quedas de árvore etc.).
- Mapa com pontos de apoio, lista de sirenes e estações pluviométricas.

### Pontos positivos
- Cobre várias frentes ao mesmo tempo (clima, trânsito, sirenes, chuva) em um só app.
- Interface recentemente reformulada, com resumo principal logo na tela inicial.
- Dados oficiais e confiáveis, direto do órgão municipal responsável (Centro de Operações Rio).

### Pontos negativos
- Nota baixa nas lojas de aplicativos (2,4 estrelas), sugerindo problemas de usabilidade ou estabilidade.
- App muito amplo (trânsito + clima + sirenes + mobilidade), o que pode deixar a experiência menos focada em emergências específicas de enchente.
- Não apresenta guia de preparação (antes/durante/depois) nem rotas de fuga específicas para enchente.

### Interface/experiência
- Usa cores (verde, amarelo, vermelho) para indicar nível de normalidade/atenção em cada categoria.
- Bastante informação na tela ao mesmo tempo, o que pode dificultar leitura rápida em situação de pânico.
- Não há menção clara de modo noturno ou alto contraste voltado especificamente para enchente.

### O que pode ser aproveitado ou melhorado no projeto
- Aproveitar: a ideia de estágio operacional (nível de gravidade) e o uso de estações pluviométricas para prever risco.
- Melhorar: simplificar a interface para focar só no que importa durante uma enchente (sem trazer trânsito geral e mobilidade urbana), além de garantir modo offline e alto contraste, que o COR.Rio não evidencia.
## Fontes consultadas

- Alagou — https://alagou.com.br/
- AlertaBlu - https://defesacivil.blumenau.sc.gov.br/p/home
- Cor.rio - https://play.google.com/store/apps/details?id=bugarin.t.comando&hl=pt_BR
