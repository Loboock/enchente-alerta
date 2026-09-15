## 2.1 Funcionalidades

### 1. Alertas de risco de enchentes

**Descrição:**
O aplicativo enviará alertas aos usuários quando houver risco de enchentes na região cadastrada, informando o nível de risco e orientações básicas de segurança.

**Necessidade do usuário que atende:**
Permite que moradores sejam avisados com antecedência sobre possíveis situações de risco, possibilitando que tomem medidas preventivas.

**Justificativa:**
É uma das principais funcionalidades do projeto, pois atua diretamente sobre o problema da falta de informação e de comunicação rápida durante situações de enchente.

---

### 2. Mapa de áreas de risco

**Descrição:**
Apresentar um mapa com a localização do usuário e a identificação de regiões que apresentam risco de alagamento ou enchente.

**Necessidade do usuário que atende:**
Permite que o usuário compreenda visualmente quais áreas próximas apresentam risco e evite locais perigosos.

**Justificativa:**
A visualização das áreas de risco facilita a compreensão das informações, principalmente para usuários que precisam tomar decisões rápidas durante uma situação de emergência.

---

### 3. Consulta de ocorrências

**Descrição:**
Permitir que o usuário consulte ocorrências de enchentes e alagamentos registradas na região, incluindo informações sobre o local e a situação identificada.

**Necessidade do usuário que atende:**
Ajuda o usuário a conhecer situações que estão acontecendo ou aconteceram recentemente em sua região.

**Justificativa:**
A funcionalidade contribui para manter a população informada e permite acompanhar a evolução dos problemas relacionados às enchentes.

---

### 4. Rotas e locais seguros

**Descrição:**
Indicar locais considerados mais seguros e orientar o usuário sobre caminhos que devem ser evitados durante uma situação de enchente.

**Necessidade do usuário que atende:**
Ajuda moradores a se deslocarem com maior segurança quando determinadas vias ou regiões estiverem alagadas.

**Justificativa:**
Durante uma enchente, algumas rotas podem se tornar perigosas ou impossíveis de utilizar. A funcionalidade auxilia na tomada de decisão e pode reduzir a exposição dos usuários a áreas de risco.

---

### 5. Cadastro da localização do usuário

**Descrição:**
Permitir que o usuário informe ou autorize o aplicativo a utilizar sua localização para receber informações e alertas relacionados à sua região.

**Necessidade do usuário que atende:**
Receber informações relevantes para o local onde mora ou está naquele momento.

**Justificativa:**
Os riscos de enchentes podem variar de uma região para outra. Dessa forma, utilizar a localização permite tornar os alertas mais relevantes e evitar o recebimento de informações desnecessárias.

---

### 6. Comunicação de ocorrências pelos usuários

**Descrição:**
Permitir que usuários registrem e comuniquem ocorrências, como alagamentos, enchentes e vias bloqueadas, informando o local e, quando possível, adicionando uma descrição ou imagem.

**Necessidade do usuário que atende:**
Possibilita que o próprio usuário informe situações de risco que estejam acontecendo em sua região.

**Justificativa:**
A participação da comunidade aumenta a quantidade de informações disponíveis e pode contribuir para que outras pessoas sejam informadas mais rapidamente sobre uma ocorrência.

---

### 7. Histórico de alertas e ocorrências

**Descrição:**
Disponibilizar um histórico das notificações e ocorrências registradas no aplicativo.

**Necessidade do usuário que atende:**
Permite consultar informações anteriores e acompanhar os eventos registrados em sua região.

**Justificativa:**
O histórico facilita o acompanhamento das ocorrências e pode ajudar o usuário a compreender quais regiões apresentam problemas recorrentes.

---

### 8. Orientações de segurança

**Descrição:**
Disponibilizar informações e recomendações sobre como agir antes, durante e após uma enchente, incluindo cuidados e comportamentos que devem ser adotados.

**Necessidade do usuário que atende:**
Oferece orientação para usuários que não sabem como agir diante de uma situação de enchente.

**Justificativa:**
Além de informar sobre o risco, o aplicativo precisa ajudar o usuário a tomar decisões adequadas. As orientações tornam a ferramenta mais útil em situações de emergência.

## 2.2 Requisitos funcionais

Os requisitos funcionais descrevem as principais funções que o aplicativo **EnchenteAlerta** deverá realizar.

### RF01 — Alertas de chuvas e alagamentos
O sistema deve enviar notificações ao usuário sobre chuvas fortes e possíveis alagamentos na região.

### RF02 — Mapa de pontos críticos
O sistema deve apresentar um mapa com os pontos de alagamento informados pela comunidade.

### RF03 — Comunicação de alagamento
O sistema deve permitir que o usuário informe rapidamente que está observando a água subir, realizando o registro de forma anônima.

### RF04 — Rotas de fuga
O sistema deve permitir que o usuário visualize rotas de fuga para locais seguros durante uma situação de emergência.

### RF05 — Localização de abrigos
O sistema deve apresentar no mapa os abrigos municipais próximos ao usuário.

### RF06 — Guia de preparação
O sistema deve disponibilizar orientações sobre o que fazer antes, durante e depois de uma enchente.

### RF07 — Mapa offline
O sistema deve permitir que o usuário baixe previamente o mapa de rotas de fuga para consulta mesmo sem conexão com a internet.

### RF08 — Alertas por localização
O sistema deve permitir que o usuário ative ou desative o recebimento de alertas relacionados à sua localização.

### RF09 — Atualização das informações
O sistema deve atualizar os pontos de alagamento e demais informações de emergência conforme novos registros forem recebidos.

---

## 2.3 Requisitos não funcionais

Os requisitos não funcionais definem características e condições que o aplicativo deverá atender, considerando principalmente o uso durante situações de emergência.

### RNF01 — Usabilidade
O usuário deve conseguir acessar a funcionalidade principal de encontrar uma rota de fuga em, no máximo, 3 interações.

### RNF02 — Acessibilidade
A interface deve utilizar textos legíveis, alto contraste e elementos de tamanho adequado para facilitar a utilização durante situações de emergência.

### RNF03 — Modo noturno
O aplicativo deve possuir uma interface adequada para utilização em ambientes escuros, utilizando o modo noturno como padrão ou opção de visualização.

### RNF04 — Desempenho
As principais funcionalidades do aplicativo devem ser carregadas rapidamente, principalmente os alertas, pontos críticos e rotas de fuga.

### RNF05 — Conectividade
O sistema deve continuar permitindo o acesso às rotas de fuga previamente baixadas mesmo quando não houver conexão com a internet.

### RNF06 — Segurança e privacidade
As informações relacionadas aos usuários devem ser protegidas, seguindo as boas práticas de segurança e os princípios da LGPD.

### RNF07 — Anonimato
Os registros realizados por usuários sobre pontos de alagamento não devem expor sua identidade.

### RNF08 — Compatibilidade
O aplicativo deve ser compatível com dispositivos móveis e diferentes tamanhos de tela.

### RNF09 — Confiabilidade
Os alertas e informações de emergência devem ser apresentados de forma clara e confiável, evitando informações ambíguas que possam prejudicar a tomada de decisão.

### RNF10 — Alto contraste
A combinação de azul-escuro e amarelo deve proporcionar boa visibilidade e reforçar a identificação de situações de alerta.

### RNF11 — Facilidade de interação
As principais ações do aplicativo devem exigir poucos passos, considerando que o usuário pode estar em uma situação de estresse ou emergência.

### RNF12 — Armazenamento de dados
O sistema deve armazenar os registros de pontos de alagamento e demais informações necessárias para manter o mapa e os alertas atualizados.

## 2.4 CRUD

Esta seção descreve as operações de Criar, Ler, Atualizar e Deletar (CRUD) previstas para as principais entidades do aplicativo **EnchenteAlerta**.

### Ocorrência de alagamento

| Operação | Descrição |
|----------|-----------|
| **Create** | Usuário registra uma nova ocorrência de alagamento (RF03), informando local e, quando possível, descrição ou imagem, de forma anônima (RNF07). |
| **Read** | Usuário consulta ocorrências registradas na região, visualizadas no mapa de pontos críticos (RF02). |
| **Update** | Sistema atualiza o status da ocorrência (ex: alagamento resolvido) conforme novos registros forem recebidos (RF09). |
| **Delete** | Ocorrências antigas ou desatualizadas são removidas/expiradas automaticamente pelo sistema após um período, mantendo o mapa atualizado. |

### Alerta

| Operação | Descrição |
|----------|-----------|
| **Create** | Sistema gera um novo alerta de risco com base em dados meteorológicos ou registros da comunidade (RF01). |
| **Read** | Usuário visualiza os alertas ativos para sua região. |
| **Update** | Sistema atualiza o nível de risco do alerta conforme a situação evolui. |
| **Delete** | Alerta é encerrado/removido quando o risco deixa de existir. |

### Rota de fuga / Abrigo

| Operação | Descrição |
|----------|-----------|
| **Create** | Defesa Civil ou administrador cadastra novos abrigos e rotas de fuga disponíveis (RF05). |
| **Read** | Usuário consulta rotas de fuga e abrigos próximos, inclusive offline, via mapa previamente baixado (RF04, RF07). |
| **Update** | Administrador atualiza informações de um abrigo (ex: capacidade, disponibilidade) ou de uma rota (ex: via interditada). |
| **Delete** | Abrigo ou rota é removido caso deixe de estar disponível. |

### Preferências de localização do usuário

| Operação | Descrição |
|----------|-----------|
| **Create** | Usuário cadastra/autoriza sua localização para receber alertas relevantes (RF08). |
| **Read** | Sistema consulta a localização salva para filtrar alertas e pontos próximos. |
| **Update** | Usuário altera a localização cadastrada ou o status de ativação dos alertas. |
| **Delete** | Usuário desativa o compartilhamento de localização, removendo o dado do sistema (RNF06). |

## 2.5 Priorização

As funcionalidades foram classificadas de acordo com sua importância para o objetivo principal do **EnchenteAlerta**, considerando o cenário de emergência apresentado no estudo de caso.

### Essenciais

São indispensáveis para que o aplicativo cumpra sua proposta principal de prevenção e segurança.

- **1. Alertas de risco de enchentes**  
  É essencial porque permite avisar o usuário sobre situações de risco antes que o problema se agrave.

- **2. Mapa de áreas de risco**  
  É essencial para que o usuário consiga identificar regiões perigosas e evitar áreas de alagamento.

- **4. Rotas e locais seguros**  
  É uma das principais funções do aplicativo durante uma emergência, permitindo encontrar caminhos mais seguros e locais de abrigo.

- **6. Comunicação de ocorrências pelos usuários**  
  É importante para que a própria comunidade possa informar novos alagamentos e situações de risco.

- **8. Orientações de segurança**  
  É essencial para fornecer instruções sobre como agir antes, durante e depois de uma enchente.

### Importantes

São funcionalidades que agregam valor ao aplicativo, mas que não impedem seu funcionamento principal caso sejam desenvolvidas posteriormente.

- **5. Cadastro da localização do usuário**  
  Torna os alertas mais relevantes para a região do usuário e permite oferecer informações relacionadas à sua localização.

- **3. Consulta de ocorrências**  
  Permite acompanhar situações registradas na região e melhora o acesso às informações sobre enchentes e alagamentos.

### Secundárias

Podem ser desenvolvidas posteriormente, pois não são fundamentais para a resposta imediata a uma situação de emergência.

- **7. Histórico de alertas e ocorrências**  
  É útil para consultar eventos anteriores e identificar ocorrências recorrentes, mas não é essencial para orientar o usuário durante uma emergência.
