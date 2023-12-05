-- SQL Project By Shreya Gupta 

use adventureworks;

-- *************************************************************************************************************************************** ------------------
-- What are the top 10 highest selling products in the database?
-- (methpd - Used salesorderdetail as base table, LineTotal as Sales)

SELECT productid, product_name, SUM(LineTotal) AS Total_sales
FROM (
    SELECT sod.productid, p.Name as product_name, sod.LineTotal
    FROM adventureworks.salesorderdetail AS sod
    JOIN adventureworks.product AS p
    ON sod.ProductID = p.ProductID
) AS subquery
GROUP BY productid
ORDER BY SUM(LineTotal) DESC
LIMIT 10;

-- *************************************************************************************************************************************** ------------------

-- 2. Who are the top 10 highest spending customers in the data along with their address and address type information?
-- (method - Used salesorderheader as base table, TotalDue as sales)


SELECT
    subquery.CustomerID,
    subquery.customer_name,
    subquery.total_purchase,
    a.City,
    cr.Name AS country,
    a.AddressLine1 AS address
FROM (
    SELECT
        soh.CustomerID,
        CONCAT(c.FirstName, ' ', c.LastName) AS customer_name,
        SUM(soh.TotalDue) AS total_purchase
    FROM
        adventureworks.salesorderheader AS soh
    JOIN adventureworks.contact AS c ON soh.ContactID = c.ContactID
    GROUP BY soh.CustomerID, customer_name
) AS subquery
JOIN adventureworks.salesorderheader AS soh ON subquery.CustomerID = soh.CustomerID
JOIN adventureworks.address AS a ON soh.BillToAddressID = a.AddressID
JOIN adventureworks.stateprovince AS sp ON a.StateProvinceID = sp.StateProvinceID
JOIN adventureworks.countryregion AS cr ON sp.CountryRegionCode = cr.CountryRegionCode
GROUP BY subquery.CustomerID, subquery.customer_name, subquery.total_purchase, a.City, cr.Name, a.AddressLine1
ORDER BY subquery.total_purchase DESC
LIMIT 10;


-- *************************************************************************************************************************************** ------------------

-- 3. Calculate the Sales by Sales Reason Name and Reason Type. Also find the best and worst performing Sales Reason in terms of Sales
-- (Method - Used salesorderheader as base table, TotalDue as sales)

SELECT
    Name,
    ReasonType,
    SUM(TotalDue) AS total_sales
FROM (
    SELECT
        sr.Name,
        sr.ReasonType,
        soh.TotalDue
    FROM
        adventureworks.salesorderheader AS soh
    JOIN adventureworks.salesorderheadersalesreason AS sohsr ON soh.SalesOrderID = sohsr.SalesOrderID
    JOIN adventureworks.salesreason AS sr ON sohsr.SalesReasonID = sr.SalesReasonID
) AS subquery
GROUP BY Name, ReasonType
ORDER BY SUM(TotalDue) DESC;


-- *************************************************************************************************************************************** ------------------

-- 4. Calculate the average number of orders shipped by different Ship methods for each month and year
-- (Method - Use salesorderheader as base table, TotalDue as sales)
-- Created a Line chart to depict this information.


SELECT
    YEAR(shipdate) AS shipment_year,
    MONTH(shipdate) AS shipment_month,
    shipmethodid,
    COUNT(DISTINCT salesorderid) AS order_count
FROM adventureworks.salesorderheader
GROUP BY shipment_year, shipment_month, shipmethodid
ORDER BY shipment_year, shipment_month, shipmethodid;


SELECT
    YEAR(shipdate) AS shipment_year,
    MONTH(shipdate) AS shipment_month,
    shipmethodid,
    COUNT(DISTINCT salesorderid) AS order_count,
    AVG(COUNT(DISTINCT salesorderid)) OVER (PARTITION BY YEAR(shipdate), shipmethodid) AS avg_per_year,
    AVG(COUNT(DISTINCT salesorderid)) OVER (PARTITION BY MONTH(shipdate), shipmethodid) AS avg_per_month
FROM adventureworks.salesorderheader
GROUP BY shipment_year, shipment_month, shipmethodid
ORDER BY shipment_year, shipment_month, shipmethodid;

-- *************************************************************************************************************************************** ------------------

-- 5. Calculate the count of orders, maximum and minimum shipped by different Credit Card Type for each month and year
-- (Method - Used salesorderheader as base table, TotalDue as sales)

SELECT
    shipment_year,
    shipment_month,
    CardType,
    MAX(order_count) AS max_orders,
    MIN(order_count) AS min_orders
FROM (
    SELECT
        YEAR(ShipDate) AS shipment_year,
        MONTH(ShipDate) AS shipment_month,
        CardType,
        COUNT(SalesOrderID) AS order_count
    FROM adventureworks.salesorderheader AS soh
    JOIN adventureworks.creditcard AS c ON soh.CreditCardID = c.CreditCardID
    GROUP BY YEAR(ShipDate), MONTH(ShipDate), CardType
) AS subquery
GROUP BY shipment_year, shipment_month, CardType
ORDER BY shipment_year, shipment_month, CardType;


SELECT
    shipment_year,
    shipment_month,
    CardType,
    sum(order_count) AS total_order
FROM (
    SELECT
        YEAR(ShipDate) AS shipment_year,
        MONTH(ShipDate) AS shipment_month,
        CardType,
        COUNT(SalesOrderID) AS order_count
    FROM adventureworks.salesorderheader AS soh
    JOIN adventureworks.creditcard AS c ON soh.CreditCardID = c.CreditCardID
    GROUP BY YEAR(ShipDate), MONTH(ShipDate), CardType
) AS subquery
GROUP BY shipment_year, shipment_month, CardType
ORDER BY shipment_year, shipment_month, CardType;

-- *************************************************************************************************************************************** ------------------

-- 6. Which are the top 3 highest selling Sales Person by Territory for each month and year
-- (Method - Used salesorderheader as base table, TotalDue as sales)

SELECT
    TerritoryID,
    Territory_name,
    salespersonid,
    orderyear,
    ordermonth,
    totalsales,
    salesrank
FROM (
    SELECT
        ter.TerritoryID as TerritoryID ,
        ter.Name as Territory_name,
        soh.SalesPersonID,
        YEAR(soh.OrderDate) AS OrderYear,
        MONTH(soh.OrderDate) AS OrderMonth,
        SUM(soh.TotalDue) AS TotalSales,
        RANK() OVER (PARTITION BY YEAR(soh.OrderDate), MONTH(soh.OrderDate), ter.TerritoryID
            ORDER BY SUM(soh.TotalDue) DESC) AS SalesRank
    FROM adventureworks.SalesOrderHeader AS soh
    INNER JOIN adventureworks.SalesTerritory AS ter ON soh.TerritoryID = ter.TerritoryID
    GROUP BY ter.TerritoryID, ter.Name, soh.SalesPersonID, OrderYear, OrderMonth
) AS subquery
WHERE salesrank IN (1, 2, 3)
ORDER BY TerritoryID, orderyear, ordermonth, salesrank;


SELECT
    SalesPersonID,
    TerritoryID,
    MONTH(SOD.OrderDate) AS Months,
    YEAR(SOD.OrderDate) AS years,
    SUM(SOD.TotalDue) AS sales
FROM adventureworks.SalesOrderHeader AS SOD
GROUP BY
    SalesPersonID,
    TerritoryID,
    Months,
    years
ORDER BY
    sales DESC;


-- *************************************************************************************************************************************** ------------------

-- 7. Calculate the count of employees and average tenure per department name and department group name.
-- (Method - Used employee as base table, Tenure is calculated in days – from Hire date to today)


SELECT
    dp.Name AS DepartmentName,
    dp.GroupName AS DepartmentGroupName,
    COUNT(e.EmployeeID) AS EmployeeCount,
    AVG(TIMESTAMPDIFF(DAY, e.HireDate, CURDATE())) AS AverageTenureInDays
FROM adventureworks.employee AS e
JOIN adventureworks.EmployeeDepartmentHistory  AS edh ON e.EmployeeID = edh.EmployeeID
JOIN adventureworks.department AS dp ON edh.DepartmentID = dp.DepartmentID
GROUP BY dp.Name, dp.GroupName
ORDER BY dp.Name, dp.GroupName;

