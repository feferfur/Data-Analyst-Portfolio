-- 1. Отобразите все записи из таблицы `company` по компаниям, которые закрылись.

SELECT *
FROM company
WHERE status = 'closed';

-- 2. Отобразите количество привлечённых средств для новостных компаний США. Используйте данные из таблицы company. Отсортируйте таблицу по убыванию значений в поле funding_total.

SELECT funding_total
FROM company
WHERE category_code = 'news'
  AND country_code = 'USA'
ORDER BY funding_total DESC;

-- 3. Найдите общую сумму сделок по покупке одних компаний другими в долларах. Отберите сделки, которые осуществлялись только за наличные с 2011 по 2013 год включительно.

SELECT SUM(price_amount)
FROM acquisition
WHERE term_code = 'cash'
  AND EXTRACT(YEAR FROM acquired_at) BETWEEN 2011 AND 2013;

-- 4. Отобразите имя, фамилию и названия аккаунтов людей в поле network_username, у которых названия аккаунтов начинаются на 'Silver'.

SELECT first_name,
       last_name,
       twitter_username
FROM people
WHERE twitter_username LIKE 'Silver%';

-- 5. Выведите на экран всю информацию о людях, у которых названия аккаунтов в поле `network_username` содержат подстроку 'money', а фамилия начинается на 'K'.

SELECT *
FROM people
WHERE twitter_username LIKE '%money%'
  AND last_name LIKE 'K%';

-- 6. Для каждой страны отобразите общую сумму привлечённых инвестиций, которые получили компании, зарегистрированные в этой стране. Страну, в которой зарегистрирована компания, можно определить по коду страны. Отсортируйте данные по убыванию суммы.

SELECT country_code,
       SUM(funding_total) AS sum
FROM company
GROUP BY country_code
ORDER BY sum DESC;

-- 7. Составьте таблицу, в которую войдёт дата проведения раунда, а также минимальное и максимальное значения суммы инвестиций, привлечённых в эту дату.
-- Оставьте в итоговой таблице только те записи, в которых минимальное значение суммы инвестиций не равно нулю и не равно максимальному значению.

SELECT funded_at,
       MIN(raised_amount),
       MAX(raised_amount)
FROM funding_round
GROUP BY funded_at
HAVING MIN(raised_amount) <> 0
AND MIN(raised_amount) <> max(raised_amount);

-- 8. Создайте поле с категориями:
--     - Для фондов, которые инвестируют в 100 и более компаний, назначьте категорию `high_activity`.
--     - Для фондов, которые инвестируют в 20 и более компаний до 100, назначьте категорию `middle_activity`.
--     - Если количество инвестируемых компаний фонда не достигает 20, назначьте категорию `low_activity`.
--    Отобразите все поля таблицы `fund` и новое поле с категориями.

SELECT *,
       CASE
           WHEN invested_companies < 20 THEN 'low_activity'
           WHEN invested_companies >= 20
                AND invested_companies < 100 THEN 'middle_activity'
           WHEN invested_companies >= 100 THEN 'high_activity'
       END AS category
FROM fund;

-- 9. Для каждой из категорий, назначенных в предыдущем задании, посчитайте округлённое до ближайшего целого числа среднее количество инвестиционных раундов, в которых фонд принимал участие. Выведите на экран категории и среднее число инвестиционных раундов. Отсортируйте таблицу по возрастанию среднего.

WITH sub AS
  (SELECT *,
          CASE
              WHEN invested_companies>=100 THEN 'high_activity'
              WHEN invested_companies>=20 THEN 'middle_activity'
              ELSE 'low_activity'
          END AS activity
   FROM fund)
SELECT activity,
       ROUND(AVG(investment_rounds)) AS round_rounds
FROM sub
GROUP BY activity
ORDER BY round_rounds;

-- 10. Проанализируйте, в каких странах находятся фонды, которые чаще всего инвестируют в стартапы.
-- Для каждой страны посчитайте минимальное, максимальное и среднее число компаний, в которые инвестировали фонды этой страны, основанные с 2010 по 2012 год включительно. Исключите страны с фондами, у которых минимальное число компаний, получивших инвестиции, равно нулю.
-- Выгрузите десять самых активных стран-инвесторов: отсортируйте таблицу по среднему количеству компаний от большего к меньшему. Затем добавьте сортировку по коду страны в лексикографическом порядке.

SELECT country_code,
       MIN(invested_companies),
       MAX(invested_companies),
       AVG(invested_companies)
FROM fund
WHERE extract(YEAR FROM founded_at) BETWEEN 2010 AND 2012
GROUP BY country_code
HAVING MIN(invested_companies) != 0
ORDER BY AVG(invested_companies) DESC, country_code
LIMIT 10;

-- 11. Отобразите имя и фамилию всех сотрудников стартапов. Добавьте поле с названием учебного заведения, которое окончил сотрудник, если эта информация известна.

WITH e AS
  (SELECT person_id,
          instituition
   FROM education)
SELECT p.first_name,
       p.last_name,
       e.instituition
FROM people AS p
LEFT JOIN e ON p.id = e.person_id;

-- 12. Для каждой компании найдите количество учебных заведений, которые окончили её сотрудники. Выведите название компании и число уникальных названий учебных заведений. Составьте топ-5 компаний по количеству университетов.

WITH subsub AS
  (SELECT person_id,
          instituition
   FROM education
   WHERE instituition IS NOT NULL),
     sub AS
  (SELECT subsub.instituition,
          p.company_id
   FROM subsub
   JOIN people AS p ON p.id = subsub.person_id)
SELECT c.name,
       COUNT(DISTINCT sub.instituition) AS inst_count
FROM company AS c
LEFT JOIN sub ON sub.company_id = c.id
GROUP BY c.name
ORDER BY inst_count DESC
LIMIT 5;

-- 13. Составьте список с уникальными названиями закрытых компаний, для которых первый раунд финансирования оказался последним.

SELECT DISTINCT c.name
FROM company AS c
JOIN funding_round AS fr ON c.id = fr.company_id
WHERE c.status = 'closed'
  AND fr.is_first_round = 1
  AND fr.is_last_round = 1;


-- 14. Составьте список уникальных номеров сотрудников, которые работают в компаниях, отобранных в предыдущем задании.

SELECT DISTINCT p.id
FROM company AS c
JOIN funding_round AS fr ON c.id = fr.company_id
JOIN people AS p ON c.id = p.company_id
WHERE c.status = 'closed'
  AND fr.is_first_round = 1
  AND fr.is_last_round = 1;

-- 15. Составьте таблицу, куда войдут уникальные пары с номерами сотрудников из предыдущей задачи и учебным заведением, которое окончил сотрудник.

SELECT p.id,
       e.instituition
FROM company AS c
JOIN funding_round AS fr ON c.id = fr.company_id
JOIN people AS p ON c.id = p.company_id
JOIN education AS e ON p.id = e.person_id
WHERE c.status = 'closed'
  AND fr.is_first_round = 1
  AND fr.is_last_round = 1
GROUP BY p.id,
         e.instituition;

16. Посчитайте количество учебных заведений для каждого сотрудника из предыдущего задания. При подсчёте учитывайте, что некоторые сотрудники могли окончить одно и то же заведение дважды.

SELECT p.id,
       COUNT(e.instituition)
FROM company AS c
JOIN people AS p ON c.id = p.company_id
LEFT JOIN education AS e ON p.id = e.person_id
WHERE c.status = 'closed'
  AND c.id IN
    (SELECT company_id
     FROM funding_round
     WHERE is_first_round = 1
       AND is_last_round = 1)
  AND e.instituition IS NOT NULL
GROUP BY p.id;

17. Дополните предыдущий запрос и выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники разных компаний. Нужно вывести только одну запись, группировка здесь не понадобится.

SELECT AVG(inst_count)
FROM
  (SELECT p.id,
          COUNT(e.instituition) AS inst_count
   FROM company AS c
   JOIN people AS p ON c.id = p.company_id
   LEFT JOIN education AS e ON p.id = e.person_id
   WHERE c.status = 'closed'
     AND c.id IN
       (SELECT company_id
        FROM funding_round
        WHERE is_first_round = 1
          AND is_last_round = 1)
     AND e.instituition IS NOT NULL
   GROUP BY p.id) AS sub;

-- 18. Напишите похожий запрос: выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники Socialnet.

SELECT AVG(inst_count)
FROM
  (SELECT p.id,
          COUNT(e.instituition) AS inst_count
   FROM company AS c
   JOIN people AS p ON c.id = p.company_id
   LEFT JOIN education AS e ON p.id = e.person_id
   WHERE c.name = 'Facebook'
     AND e.instituition IS NOT NULL
   GROUP BY p.id) AS sub;

-- 19. Составьте таблицу из полей:
--     - name_of_fund — название фонда;
--     - name_of_company — название компании;
--     - amount — сумма инвестиций, которую привлекла компания в раунде.
--     В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов, а раунды финансирования проходили с 2012 по 2013 год включительно.

SELECT f.name AS name_of_fund,
       c.name AS name_of_company,
       fr.raised_amount AS amount
FROM investment AS i
JOIN fund AS f ON i.fund_id = f.id
JOIN company AS c ON i.company_id = c.id
JOIN funding_round AS fr ON i.funding_round_id = fr.id
WHERE c.milestones > 6
  AND EXTRACT(YEAR FROM fr.funded_at) BETWEEN 2012 AND 2013;

-- 20. Выгрузите таблицу, в которой будут такие поля:
--     - название компании-покупателя;
--     - сумма сделки;
--     - название компании, которую купили;
--     - сумма инвестиций, вложенных в купленную компанию;
--     - доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций, округлённая до ближайшего целого числа.
--     Не учитывайте те сделки, в которых сумма покупки равна нулю. Если сумма инвестиций в компанию равна нулю, исключите такую компанию из таблицы.
--     Отсортируйте таблицу по сумме сделки от большей к меньшей, а затем по названию купленной компании в лексикографическом порядке. Ограничьте таблицу первыми десятью записями.

WITH subsub AS
  (SELECT acquiring_company_id,
          acquired_company_id,
          price_amount
   FROM acquisition
   WHERE price_amount > 0),
     sub AS
  (SELECT c.name AS acquired_company,
          c.funding_total,
          subsub.acquiring_company_id,
          subsub.price_amount
   FROM company AS c
   RIGHT JOIN subsub ON c.id = subsub.acquired_company_id)
SELECT company.name AS acquiring_company,
       sub.price_amount,
       sub.acquired_company,
       sub.funding_total,
       round(sub.price_amount / sub.funding_total) AS ratio
FROM sub
LEFT JOIN company ON company.id = sub.acquiring_company_id
WHERE sub.funding_total > 0
ORDER BY sub.price_amount DESC,
         sub.acquired_company
LIMIT 10;

-- 21. Выгрузите таблицу, в которую войдут названия компаний из категории social, получившие финансирование с 2010 по 2013 год включительно. Проверьте, что сумма инвестиций не равна нулю. Выведите также номер месяца, в котором проходил раунд финансирования.

SELECT c.name,
       EXTRACT(MONTH FROM funded_at) AS round_month
FROM company AS c
JOIN funding_round AS fr ON c.id = fr.company_id
WHERE c.category_code = 'social'
  AND EXTRACT(YEAR FROM fr.funded_at) BETWEEN 2010 AND 2013
  AND fr.raised_amount <> 0;

-- 22. Отберите данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды. Сгруппируйте данные по номеру месяца и получите таблицу, в которой будут поля:
--     - номер месяца, в котором проходили раунды;
--     - количество уникальных названий фондов из США, которые инвестировали в этом месяце;
--     - количество компаний, купленных за этот месяц;
--     - общая сумма сделок по покупкам в этом месяце.

WITH fr AS
  (SELECT extract(MONTH FROM funded_at) AS MONTH,
          id
   FROM funding_round
   WHERE extract(YEAR FROM funded_at) BETWEEN 2010 AND 2013),
     a AS
  (SELECT extract(MONTH FROM acquired_at) AS MONTH,
          COUNT(acquired_company_id) AS acquired_count,
          SUM(price_amount) AS deal_sum
   FROM acquisition
   WHERE extract(YEAR FROM acquired_at) BETWEEN 2010 AND 2013
   GROUP BY MONTH),
     i AS
  (SELECT investment.funding_round_id,
          f.name
   FROM investment
   JOIN fund AS f ON f.id = investment.fund_id
   WHERE fund_id in
       (SELECT id
        FROM fund
        WHERE country_code = 'USA')),
     sub AS
  (SELECT MONTH,
          COUNT(DISTINCT name) AS fund_count
   FROM fr
   LEFT JOIN i ON fr.id = i.funding_round_id
   GROUP BY MONTH)
SELECT sub.month,
       sub.fund_count,
       a.acquired_count,
       a.deal_sum
FROM sub
LEFT JOIN a ON sub.month = a.month;

-- 23. Составьте сводную таблицу и выведите среднюю сумму инвестиций для стран, в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах. Данные за каждый год должны быть в отдельном поле. Отсортируйте таблицу по среднему значению инвестиций за 2011 год от большего к меньшему.

WITH inv_2011 AS
  (SELECT country_code,
          AVG(funding_total) AS avg_total_2011
   FROM company
   WHERE extract(YEAR
                 FROM founded_at) = 2011
   GROUP BY country_code),
     inv_2012 AS
  (SELECT country_code,
          avg(funding_total) AS avg_total_2012
   FROM company
   WHERE extract(YEAR
                 FROM founded_at) = 2012
   GROUP BY country_code),
     inv_2013 AS
  (SELECT country_code,
          avg(funding_total) AS avg_total_2013
   FROM company
   WHERE extract(YEAR
                 FROM founded_at) = 2013
   GROUP BY country_code)
SELECT inv_2011.country_code,
       inv_2011.avg_total_2011,
       inv_2012.avg_total_2012,
       inv_2013.avg_total_2013
FROM inv_2011
JOIN inv_2012 ON inv_2011.country_code = inv_2012.country_code
JOIN inv_2013 ON inv_2011.country_code = inv_2013.country_code
ORDER BY inv_2011.avg_total_2011 DESC;