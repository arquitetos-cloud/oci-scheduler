# OCI-Scheduler

Bem-vindo ao Script de Agendado para OCI (Oracle Cloud Infrastructure).

O script **OCI-Scheduler**: é um único script de Scheduler e Auto Scaling para todos os recursos OCI que oferecem suporte a operações de ampliação/redução e ligar/desligar.

```
   -t config  - Seção do arquivo de configuração a ser usada (perfil de locação)
   -ip        - Usar entidades de instância para autenticação (Principals)
   -dt        - Use entidades de instância (Principals) com token de delegação para cloud shell
   -a         - Ação - Tudo, Cima, Baixo (Padrão Tudo)
   -tag       - Tag a ser usada (Programação Padrão)
   -rg        - Filtrar por região
   -ic        - Incluir compartimento ocid
   -ec        - Excluir compartimento ocid
   -ignrtime  - Ignorar o timezone da região (Usar o hora do servidor)
   -printocid - Exibir o ocid no resumo
   -topic     - Tópico para resumo enviado (na região de origem)
   -h         - ajuda
```

# Lista de serviços suportados

- Compute VMs: On/Off
- Instance Pools: On/Off and Scaling (# of instances)
- Database VMs: On/Off
- Database Baremetal Servers: Scaling (# of CPUs)
- Database Exadata CS: Scaling (# of CPUs)*
- Autonomous Databases: On/Off and Scaling (# of CPUs)
- Oracle Digital Assistant: On/Off
- Oracle Analytics Cloud: On/Off and Scaling (between 2-8 oCPU and 10-12 oCPU)
- Oracle Integration Service: On/Off
- Load Balancer: Scaling (between 10, 100, 400, 8000 Mbps)**
- MySQL Service: On/Off***
- GoldenGate: On/Off
- Data Integration Workspaces: On/Off
- Visual Builder (v2 Native OCI version): On/Off

# Como instalar

Primeiramente você precisa provisionar uma compute instância com a imagem <b>Oracle Autonomous Linux 7.x</b>. Depois de provisionar a maquina, você precisa logar nela e executar o seguinte comando:

```shell
curl -fsSL https://raw.githubusercontent.com/arquitetos-cloud/oci-scheduler/main/install.sh | bash
```

Assim que o processo for concluído, você precisará acessar o console do OCI para criar um grupo e uma politica dando permissão para que essa instância possa orquestrar.

1. **Criação do grupo dinamico**

Logue em sua conta OCI, copie a **OCID** da instância que você criou, pois ele será utilizado para criarmos um grupo dinamico. Depois de copiar o **OCID**, clique em **Identidade e Segurança** e depois em **Criar Grupo Dinâmico**, no compo Nome, digite um nome para o grupo como por exemplo **OCI-Scheduler**, no campo Regra coloque o conteúdo abaixo substituindo a frase "**your_OCID_of_your_Compute_Instance**" pelo OCID da instância que você copiou:

```
ANY {instance.id = 'your_OCID_of_your_Compute_Instance'}
```

2. **Criação da política**

Para criarmos a política que vai dar as devidas permissões ao grupo que criamos, vá em **Identidade e Segurança** e clique em **Políticas**, depois clique em **Criar Política**. No campo Nome, digite um nome para essa política como por exemplo **PL-OCI-Scheduler**, no campo Construtor de Políticas, clique no botão **Mostrar editor manual** e escreva o conteúdo abaixo:

```
allow dynamic-group OCI-Scheduler to manage all-resources in tenancy
```

Caso você tenha dado outro nome ao grupo dinâmico, modifique o nome **OCI-Scheduler** para o nome do grupo que você escolheu, depois disso clique em Criar.

Tudo pronto, agora a instância já possui as permissões que precisa para fazer a orquestração.

3. **Criação das TAGS**

O processo de criação das tags pode ser automatizado pelo script **CreateNameSpaces.py**, para isso execute a linha de comando abaixo ma instância criada:

python /usr/local/oci-scheduler/CreateNameSpaces.py

Depois que o script criar as Tags, o processo de instalação estará concluído.
# Como utilizar

Para controlar o que aumentar/diminuir ou ligar/desligar, você precisa criar uma tag predefinida chamada **Schedule**.
Como parte do processo de setup, o script CreateNameSpaces.py faz isso para você.

Um único recurso pode conter várias tags. A prioridade das tags é a seguinte (de baixa a alta)

- Qualquer dia (Anyday)
- Weekday or Weekend (Dia de semana ou fim de semana)
- Day of the week (Dia da semana como segunda, terça...)
- Day of the month (Dia do mês como 1 = 1 dia do mes ou 15 = 15 dia do mes)

### Valores para as tags AnyDay, Weekday, Weekend e Day of week:

O valor da tag precisa conter 24 números e/ou curingas caracteres de curinga como por exemplo o caracter "*", caso contrário é ignorado. Esses caracteres devem ser separados por vírgulas. Se o valor for 0, ele desligará o recurso (se houver suporte para esse recurso). Qualquer número maior que 0 redimensionará o recurso para esse número ou liga o recurso caso não suporte o dimencionamento.

Quando um caracter de curinga for usado "*", o serviço permanecerá inalterado por essa hora. Por exemplo, a programação abaixo ativará uma instância de computação à noite, mas permite que o usuário gerencie o estado durante o dia.

Schedule.AnyDay : 0,0,0,0,0,0,0,0,\*,\*,\*,\*,\*,\*,\*,\*,0,0,0,0,0,0,0,0

### Valores para tags DayOfMonth

A tag DayOfMonth permite definir um recurso em um dia específico do mês. Isso pode ser especificado por dia: tamanho.

Para cada dia <b>Apenas um valor</b> pode ser especificado! Este valor é válido para todas as horas desse dia.

A tag de exemplo abaixo agenda o recurso no dia 1º do mês para 4, no dia 3 do mês para 2 e no dia 28 do mês de volta para 5:

Schedule.DayOfMonth : 1:4,3:2,28:4

O script suporta 3 métodos em execução: All, Up, Down

- All: Isso executará qualquer operação de dimensionamento e ligar/desligar
- Down: Isso executará apenas operações de desligamento e redução de shape
- Up: Isso executará apenas operações de ativação e ampliação

O pensamento por trás disso é que a maioria dos recursos OCI são cobrados por hora. Portanto, você provavelmente deseja executar operações de redução/desligamento
pouco antes do final da hora e ligue e aumente as operações logo após a hora.

Para garantir que o script seja executado o mais rápido possível, todas as operações de bloqueio (ligar, aguardar a disponibilidade e redimensionar) são executadas em threads separados. Eu recomendo que você execute ações de redução 2 minutos antes do final da hora e execute ações de redução logo após a hora.

Você pode implantar este script em qualquer lugar que desejar, desde que o local tenha acesso à Internet para os serviços da API OCI.
