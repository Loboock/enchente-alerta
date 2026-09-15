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
