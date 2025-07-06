#!/bin/bash
# Hacer ejecutables los nuevos scripts SSL
chmod +x scripts/manage-ssl-certificates.sh
chmod +x final-clean.sh

echo "✅ Scripts SSL configurados como ejecutables"
echo ""
echo "🔒 Nuevas funcionalidades SSL disponibles:"
echo "• make manage-ssl    - Gestor interactivo SSL"
echo "• make list-ssl      - Listar certificados"
echo "• make upload-ssl    - Subir certificados"
echo "• make verify-ssl    - Verificar certificados"
echo ""
echo "📁 Documentación SSL: cat SSL-MULTIDOMINIO.md"
