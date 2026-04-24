# 🚀 DevOps Pipeline — CI/CD com Jenkins, Docker e Kubernetes

Este projeto demonstra a implementação de um pipeline CI/CD completo utilizando Jenkins, Docker e Kubernetes (K3s), hospedado em uma instância EC2 na AWS.

---

## 🏗️ Arquitetura

```
EC2 c7i-flex.large (AWS)
├── Ubuntu 22.04 LTS
├── Docker          → build e hospedagem do Jenkins
├── K3s             → orquestração dos containers
└── Jenkins         → pipeline CI/CD (roda como container Docker)
```

### Fluxo do Pipeline

```
git push (GitHub)
      ↓
GitHub Webhook notifica o Jenkins
      ↓
Jenkins executa o Jenkinsfile
      ↓
Testes automatizados (3 níveis)
      ↓
Docker builda a imagem
      ↓
Imagem importada para o K3s
      ↓
kubectl aplica os manifests
      ↓
Aplicação no ar ✅
```

---

## 🛠️ Tecnologias Utilizadas

### AWS EC2 — c7i-flex.large
Instância de computação em nuvem que hospeda toda a infraestrutura. O tipo `c7i-flex.large` foi escolhido por oferecer 2 vCPUs e 4 GB de RAM, sendo suficiente para rodar o stack completo (K3s + Docker + Jenkins), e por ser elegível ao free tier da AWS.

### Docker
Responsável por empacotar a aplicação em uma imagem portável e por hospedar o Jenkins em um container isolado. A utilização do Docker garante que a aplicação funcione de forma idêntica em qualquer ambiente.

**Por que Docker e não instalar diretamente no servidor?**
- Isolamento entre serviços
- Facilidade de restart e atualização
- Portabilidade da aplicação

### K3s (Kubernetes)
Distribuição leve do Kubernetes, ideal para ambientes com recursos limitados. Responsável por orquestrar os containers em produção, garantindo que a aplicação fique sempre no ar, reiniciando automaticamente em caso de falha.

**Por que Kubernetes?**
- Self-healing: reinicia pods que caem automaticamente
- Gerenciamento declarativo de estado
- Escalabilidade horizontal com simples configuração

### Jenkins
Servidor de automação que detecta mudanças no repositório GitHub via Webhook e executa o pipeline automaticamente. Roda como container Docker com volume persistente para não perder configurações ao reiniciar.

**Por que Jenkins?**
- Automação completa do processo de build e deploy
- Integração nativa com GitHub via Webhook
- Histórico de builds e logs centralizados

---

## 🧪 Testes Automatizados

O pipeline executa 3 níveis de teste antes de qualquer deploy:

| Nível | O que testa | Como |
|---|---|---|
| 1 | Arquivo existe | Verifica se `index.html` está presente |
| 2 | Conteúdo correto | Verifica se o conteúdo esperado está no HTML |
| 3 | Container responde | Sobe um container temporário e faz uma requisição HTTP |

Se qualquer nível falhar, o pipeline é cancelado e a versão anterior permanece no ar.

---

## 📁 Estrutura do Projeto

```
DevOps/
├── Dockerfile              # Empacota a aplicação com nginx
├── Jenkinsfile             # Define as etapas do pipeline
├── index.html              # Aplicação web estática
├── test.sh                 # Script de testes automatizados
├── .gitignore
└── k8s/
    ├── deployment.yaml     # Define os pods e réplicas no K3s
    └── service.yaml        # Expõe a aplicação externamente
```

---

## ⚙️ Configuração da Infraestrutura

### Pré-requisitos
- Conta AWS com instância EC2 `c7i-flex.large` rodando Ubuntu 22.04
- Repositório GitHub com Webhook configurado

### Portas abertas no Security Group

| Porta | Protocolo | Finalidade |
|---|---|---|
| 22 | TCP | Acesso SSH |
| 8080 | TCP | Interface do Jenkins |
| 30080 | TCP | Aplicação em produção |
| 6443 | TCP | API do K3s |

### Instalação

**1. Docker**
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker ubuntu
```

**2. K3s**
```bash
curl -sfL https://get.k3s.io | sh -
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown ubuntu:ubuntu ~/.kube/config
export KUBECONFIG=~/.kube/config
```

**3. Jenkins (via Docker)**
```bash
docker volume create jenkins-data

docker run -d \
  --name jenkins \
  --restart=always \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins-data:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(which docker):/usr/bin/docker \
  -v /home/ubuntu/devops-project:/home/ubuntu/devops-project \
  -v /run/k3s:/run/k3s \
  -v /usr/local/bin/k3s:/usr/local/bin/k3s \
  jenkins/jenkins:lts-jdk21
```

---

## 🔄 Configuração do Pipeline

### Webhook GitHub
Em **Settings → Webhooks → Add webhook**:
- Payload URL: `http://<IP-EC2>:8080/github-webhook/`
- Content type: `application/json`
- Trigger: `Just the push event`

### Job no Jenkins
- Tipo: **Pipeline**
- Definition: **Pipeline script from SCM**
- SCM: **Git**
- Repository URL: `https://github.com/EricDiasLemos/DevOps.git`
- Branch: `*/main`
- Script Path: `Jenkinsfile`
- Build Trigger: `GitHub hook trigger for GITScm polling`

---

## 🚢 Deploy

A aplicação é exposta via **NodePort** na porta `30080`:

```
http://<IP-EC2>:30080
```

O Kubernetes mantém **2 réplicas** da aplicação em execução simultânea, garantindo alta disponibilidade.

---

## 📊 Monitoramento

**Via terminal:**
```bash
kubectl get pods
kubectl get services
kubectl get all
kubectl logs <nome-do-pod>
```

**Via Kubernetes Dashboard:**
```
https://<IP-EC2>:30443
```

---

## 🔐 Segurança

- Jenkins hospedado em container Docker isolado
- Acesso ao cluster K3s via kubeconfig com IP interno
- Socket do Docker com permissões controladas
- Swap de segurança para estabilidade de memória

---

## 📝 Lições Aprendidas

- A chave GPG do repositório Jenkins expirou em março/2026, exigindo instalação via Docker
- O Jenkins rodando em container não enxerga o filesystem da EC2 sem volumes montados
- O kubeconfig usa `127.0.0.1` por padrão — dentro do container Docker precisa ser substituído pelo IP interno da EC2
- O socket do K3s (`/run/k3s/containerd/containerd.sock`) precisa de permissão `666` para ser acessado pelo Jenkins

---

*Projeto desenvolvido como estudo de DevOps com foco em CI/CD, containerização e orquestração de containers.*
