#!/bin/bash
echo "=== Nível 1: verificando se o arquivo existe ==="
if [ ! -f index.html ]; then
  echo "ERRO: index.html não encontrado!"
  exit 1
fi
echo "OK: index.html existe"

echo "=== Nível 2: verificando conteúdo ==="
if ! grep -q "Pipeline CI/CD funcionando" index.html; then
  echo "ERRO: conteúdo esperado não encontrado!"
  exit 1
fi
echo "OK: conteúdo correto"

echo "=== Nível 3: verificando se o container responde ==="
docker build -t devops-app:test .
docker run -d --name test-container -p 8081:80 devops-app:test
sleep 5

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://172.31.21.35:8081)

docker stop test-container
docker rm test-container
docker rmi devops-app:test

if [ "$HTTP_STATUS" != "200" ]; then
  echo "ERRO: container retornou status $HTTP_STATUS"
  exit 1
fi
echo "OK: container respondeu com status 200"

echo "=== Todos os testes passaram! ==="
