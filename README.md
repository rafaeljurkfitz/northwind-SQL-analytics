# Relatórios Avançados em SQL Northwind

## Objetivo

Este repositório tem como objetivo apresentar relatórios avançados construídos em SQL. As análises disponibilizadas aqui podem ser aplicadas em empresas de todos os tamanhos que desejam se tornar mais analíticas. Através destes relatórios, organizações poderão extrair insights valiosos de seus dados, ajudando na tomada de decisões estratégicas.

## Relatórios que vamos criar

1. **Relatórios de Receita**

    * Qual foi o total de receitas no ano de 1997?

    ```sql
    CREATE VIEW total_revenues_1997_view AS
    SELECT
        SUM((order_details.unit_price) * order_details.quantity * (1.0 - order_details.discount)) AS total_revenues_1997
    FROM
        order_details
        INNER JOIN
            (
                SELECT
                    order_id 
                FROM
                    orders 
                WHERE
                    EXTRACT(YEAR
                FROM
                    order_date) = '1997'
    ) 
    AS ord 
    ON ord.order_id = order_details.order_id;
    ```

    * Faça uma análise de crescimento mensal e o cálculo de YTD

    ```sql
    CREATE VIEW view_receitas_acumuladas AS
    WITH ReceitasMensais AS 
    (
        SELECT
            EXTRACT(YEAR 
        FROM 
            orders.order_date) AS Ano,
            EXTRACT(MONTH
        FROM
            orders.order_date) AS Mes,
            SUM(order_details.unit_price * order_details.quantity * (1.0 - order_details.discount)) AS Receita_Mensal
        FROM
            orders
            INNER JOIN
                order_details
                ON orders.order_id = order_details.order_id
        GROUP BY
            EXTRACT(YEAR
        FROM
            orders.order_date),
            EXTRACT(MONTH
        FROM
            orders.order_date)
    )
    ,
    ReceitasAcumuladas AS
    (
        SELECT
            Ano,
            Mes,
            Receita_Mensal,
            SUM(Receita_Mensal) OVER (PARTITION BY Ano
        ORDER BY
            Mes) AS Receita_YTD
        FROM
            ReceitasMensais
    )
    SELECT
        Ano,
        Mes,
        Receita_Mensal,
        Receita_Mensal - LAG(Receita_Mensal) OVER (PARTITION BY Ano
    ORDER BY
        Mes) AS Diferenca_Mensal,
        Receita_YTD,
        (
            Receita_Mensal - LAG(Receita_Mensal) OVER (PARTITION BY Ano
        ORDER BY
            Mes)
        )
        / LAG(Receita_Mensal) OVER (PARTITION BY Ano
    ORDER BY
        Mes) * 100 AS Percentual_Mudanca_Mensal
    FROM
        ReceitasAcumuladas
    ORDER BY
        Ano,
        Mes;
    ```

2. **Segmentação de clientes**

    * Qual é o valor total que cada cliente já pagou até agora?

    ```sql
    CREATE VIEW view_total_revenues_per_customer AS
    SELECT 
        c.company_name, 
        SUM(od.unit_price * od.quantity * (1.0 - od.discount)) AS total_costumer_spend
    FROM 
        orders o
        INNER JOIN
            customers c 
            ON o.customer_id = c.customer_id
        INNER JOIN
            order_details od 
            ON o.order_id = od.order_id
    GROUP BY
        c.company_name
    ORDER BY
        total_costumer_spend DESC;
    ```

    * Separe os clientes em 5 grupos de acordo com o valor pago por cliente

    ```sql
    CREATE VIEW view_total_revenues_per_customer_group AS
    SELECT 
        c.company_name, 
        SUM(od.unit_price * od.quantity * (1.0 - od.discount)) AS total_costumer_spend,
        NTILE(5) OVER (
    ORDER BY
        SUM(od.unit_price * od.quantity * (1.0 - od.discount)) as group_number 
    FROM 
        orders o
        INNER JOIN
            customers c 
            ON o.customer_id = c.customer_id
        INNER JOIN
            order_details od 
            ON o.order_id = od.order_id
    GROUP BY
        c.company_name
    ORDER BY
        total_costumer_spend DESC;
    ```

    * Agora somente os clientes que estão nos grupos 3, 4 e 5 para que seja feita uma análise de Marketing especial com eles

    ```sql
    CREATE VIEW clients_to_marketing AS
    WITH costumers_for_marketing AS
    (
        SELECT 
            c.company_name, 
            SUM(od.unit_price * od.quantity * (1.0 - od.discount)) AS total_costumer_spend,
            NTILE(5) OVER (
        ORDER BY
            SUM(od.unit_price * od.quantity * (1.0 - od.discount)) as group_number 
        FROM 
            orders o
            INNER JOIN
                customers c 
                ON o.customer_id = c.customer_id
            INNER JOIN
                order_details od 
                ON o.order_id = od.order_id
        GROUP BY
            c.company_name
        ORDER BY
            total_costumer_spend DESC;
    )

    SELECT
        *
    FROM 
        costumers_for_marketing
    WHERE
        group_number >= 3;
    ```

3. **Top 10 Produtos Mais Vendidos**

    * Identificar os 10 produtos mais vendidos.

    ```sql
    SELECT 
        p.product_name, SUM((od.unit_price * od.quantity * (1.0 - od.discount))) AS sales
    FROM 
        products p
    INNER JOIN
        order_details od
        on od.product_id = p.product_id
    GROUP BY
        p.product_name
    ORDER BY
        sales DESC
    LIMIT 10
    ```

4. **Clientes do Reino Unido que Pagaram Mais de 1000 Dólares**

    * Quais clientes do Reino Unido pagaram mais de 1000 dólares?

    ```sql
    CREATE VIEW uk_clients_who_pay_more_then_1000 AS
    SELECT 
        c.contact_name, SUM((od.unit_price * od.quantity * (1.0 - od.discount))) AS sales
    FROM 
        customers c
    INNER JOIN 
        orders o
        on o.customer_id = c.customer_id
    INNER JOIN
        order_details od
        on o.order_id = od.order_id
    WHERE 
        LOWER(c.country) = 'uk'
    GROUP BY
        c.contact_name
    HAVING 
        SUM((od.unit_price * od.quantity * (1.0 - od.discount))) >= 1000
    ORDER BY
        sales DESC
    ```

## Contexto

O banco de dados `Northwind` contém os dados de vendas de uma empresa  chamada `Northwind Traders`, que importa e exporta alimentos especiais de todo o mundo.

O banco de dados Northwind é ERP com dados de clientes, pedidos, inventário, compras, fornecedores, remessas, funcionários e contabilidade.

O conjunto de dados Northwind inclui dados de amostra para o seguinte:

* **Fornecedores:** Fornecedores e vendedores da Northwind
* **Clientes:** Clientes que compram produtos da Northwind
* **Funcionários:** Detalhes dos funcionários da Northwind Traders
* **Produtos:** Informações do produto
* **Transportadoras:** Os detalhes dos transportadores que enviam os produtos dos comerciantes para os clientes finais
* **Pedidos e Detalhes do Pedido:** Transações de pedidos de vendas ocorrendo entre os clientes e a empresa

O banco de dados `Northwind` inclui 14 tabelas e os relacionamentos entre as tabelas são mostrados no seguinte diagrama de relacionamento de entidades.

![northwind](https://github.com/lvgalvao/Northwind-SQL-Analytics/blob/main/pics/northwind-er-diagram.png?raw=true)

## Configuração Inicial

### Manualmente

Utilize o arquivo SQL fornecido, `nortwhind.sql`, para popular o seu banco de dados.

### Com Docker e Docker Compose

**Pré-requisito**: Instale o Docker e Docker Compose

* [Começar com Docker](https://www.docker.com/get-started)
* [Instalar Docker Compose](https://docs.docker.com/compose/install/)
  
### Passos para configuração com Docker  

1. **Iniciar o Docker Compose** Execute o comando abaixo para subir os serviços:

    ```bash
    docker-compose up
    ```

    Aguarde as mensagens de configuração, como:  

    ```csharp
    Creating network "northwind_psql_db" with driver "bridge"
    Creating volume "northwind_psql_db" with default driver
    Creating volume "northwind_psql_pgadmin" with default driver
    Creating pgadmin ... done
    Creating db      ... done
    ```

2. **Conectar o PgAdmin** Acesse o PgAdmin pelo URL: [http://localhost:5050](http://localhost:5050), com a senha `postgres`.  

    Configure um novo servidor no PgAdmin:

    * **Aba General**:
        * Nome: db
    * **Aba Connection**:
        * Nome do host: db
        * Nome de usuário: postgres
        * Senha: postgres Em seguida, selecione o banco de dados "northwind".

3. **Parar o Docker Compose** Pare o servidor iniciado pelo comando `docker-compose up` usando Ctrl-C e remova os contêineres com:

    ```bash
    docker-compose down
    ```

4. **Arquivos e Persistência** Suas modificações nos bancos de dados Postgres serão persistidas no volume Docker `postgresql_data` e podem ser recuperadas reiniciando o Docker Compose com `docker-compose up`. Para deletar os dados do banco, execute:  

    ```bash
    docker-compose down -v
    ```
