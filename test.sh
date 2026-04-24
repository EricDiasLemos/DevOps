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

echo "=== Todos os testes passaram! ==="
