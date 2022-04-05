
# Requisitos

- 1 - Reservar IP externo fixo ao futuro servidor
- 2 - Ter definido o dominio que será usando no manager. Ex.: manager.exemple.com
- 3 - Criar entrada do domínio escolhido no DNS apontando para o IP fixo reservado
- 4 - Abrir as portas 80 e 443 para a internet para que o Lets Encrypt possa ser validado. Fechar as portas após validação.
- 5 - Ficar atendo no email da Squad, inserido nas variáveis de setup,  para renovar o certificado.
- 6 - Manter a porta 35443 para acesso web, sem redirect de 80 para 35443. Por mais que esteja com SSL tipo A vamos dificultar as tentativas de acesso e bruteforce em portas não padrão. 
