USE ECOMM; 

SELECT* FROM customer_churn;

-- DISABLE SQL SAFE UPDATES

SET SQL_SAFE_UPDATES = 0;

--  DATA CLEANING 
--  HANDLING MISSING VALUES


SELECT* FROM customer_churn WHERE WarehouseToHome IS NULL;
SELECT* FROM customer_churn WHERE HourSpendOnApp IS NULL;
SELECT* FROM CUSTOMER_CHURN WHERE OrderAmountHikeFromlastYear IS NULL;
SELECT* FROM customer_churn WHERE DaySinceLastOrder IS NULL;

-- IMPUTE AND ROUND OFF 

SET @WarehouseToHome_AVG = (SELECT ROUND(AVG(WarehouseToHome)) FROM customer_churn);
SELECT @WarehouseToHome_AVG;

SET @HourSpendOnApp_AVG = (SELECT ROUND(AVG(HourSpendOnApp)) FROM customer_churn);
SELECT @HourSpendOnApp_AVG;

SET @OrderAmountHikeFromlastYear_AVG = (SELECT ROUND(AVG(OrderAmountHikeFromlastYear)) FROM customer_churn);
SELECT @OrderAmountHikeFromlastYear_AVG;

SET @DaySinceLastOrder_AVG = (SELECT ROUND(AVG(DaySinceLastOrder)) FROM customer_churn);
SELECT @DaySinceLastOrder_AVG ;

-- IMPUTE THE MISSING VALUES
UPDATE customer_churn
SET WarehouseToHome = if(WarehouseToHome IS NULL, @WarehouseToHome_AVG, WarehouseToHome),
	HourSpendOnApp =  IF(HourSpendOnApp IS NULL, @HourSpendOnApp_AVG, HourSpendOnApp),
    OrderAmountHikeFromlastYear = IF(OrderAmountHikeFromlastYear IS NULL, @OrderAmountHikeFromlastYear_AVG,  OrderAmountHikeFromlastYear),
    DaySinceLastOrder = IF(DaySinceLastOrder IS NULL, @DaySinceLastOrder_AVG, DaySinceLastOrder);

-- IMPUTE Tenure, CouponUsed, OrderCount

SELECT TENURE, COUNT(*) FROM customer_churn group by TENURE ORDER BY count(*) DESC;

SET @TENURE_MODE = (SELECT TENURE FROM customer_churn group by TENURE ORDER BY count(*) DESC LIMIT 1);
SELECT @TENURE_MODE;

SET @COUPONUSED_MODE = (SELECT COUPONUSED FROM Customer_churn group by COUPONUSED ORDER BY count(*) DESC LIMIT 1);
SELECT  @COUPONUSED_MODE;

SET @ORDERCOUNT_MODE = (SELECT ORDERCOUNT FROM CUSTOMER_CHURN GROUP BY ORDERCOUNT ORDER BY count(*) DESC LIMIT 1);
SELECT @ORDERCOUNT_MODE;

-- IMPUTED VALUES
UPDATE CUSTOMER_CHURN
SET TENURE = if(TENURE IS NULL, @TENURE_MODE, TENURE),
    COUPONUSED = if(COUPONUSED IS NULL, @COUPONUSED_MODE, COUPONUSED),
    ORDERCOUNT = IF(ORDERCOUNT IS NULL, @ORDERCOUNT_MODE, ORDERCOUNT);
    
    -- HANDLE OUTLIERS
    
DELETE FROM CUSTOMER_CHURN
WHERE WarehouseToHome > 100;

SELECT WarehouseToHome FROM CUSTOMER_CHURN;

-- DEALING WITH INCONSISTENCIES

SELECT PreferredLoginDevice, PreferedOrderCat FROM CUSTOMER_CHURN;

UPDATE CUSTOMER_CHURN
SET PreferredLoginDevice = if(PreferredLoginDevice = 'Phone' , 'MOBILE PHONE' , PreferredLoginDevice),	
PreferedOrderCat = IF(PreferedOrderCat = 'MOBILE', 'MOBILE PHONE', PreferedOrderCat);
    
SELECT PreferredLoginDevice, PreferedOrderCat FROM CUSTOMER_CHURN;

-- STANDARDIZE PAYMENT MODE VALUES

UPDATE CUSTOMER_CHURN
SET PreferredPaymentMode = CASE
							  WHEN PreferredPaymentMode = 'COD' THEN 'Cash on Delivery'
                              WHEN PreferredPaymentMode = 'CC' THEN 'Credit Card'
                              ELSE PreferredPaymentMode
						END;

SELECT PreferredPaymentMode FROM Customer_churn;

-- DATA TRANSFORMATION
-- COLUMN RENAMING

ALTER TABLE CUSTOMER_CHURN
RENAME COLUMN PreferedOrderCat TO PreferredOrderCat, 
RENAME COLUMN HourSpendOnApp TO HoursSpentOnApp;

-- CREATING NEW COLUMN

SELECT* FROM CUSTOMER_CHURN;

ALTER TABLE CUSTOMER_CHURN
ADD COLUMN ComplaintReceived ENUM('YES', 'NO'),
ADD COLUMN ChurnStatus ENUM('CHURNED', 'ACTIVE');

-- SET VALUES IN THE COLUMN
UPDATE CUSTOMER_CHURN
SET 
     ComplaintReceived = IF(COMPLAIN = 1, 'YES', 'NO'),
     ChurnStatus = IF(CHURN = 1, 'Churned', 'Active');

SELECT* FROM CUSTOMER_CHURN;

-- COLUMN DROPPING
ALTER TABLE CUSTOMER_CHURN
DROP COLUMN CHURN,
DROP COLUMN COMPLAIN;

SELECT* FROM CUSTOMER_CHURN;

--  DATA EXPLORATION AND ANALYSIS
-- count of churned and active customers
SELECT Churnstatus, count(CHURNSTATUS) CHURN_COUNT FROM CUSTOMER_CHURN group by CHURNSTATUS;

--  average tenure of customers
SELECT avg(TENURE) AS AVG_TENURE FROM CUSTOMER_CHURN WHERE CHURNSTATUS = 'CHURNED';

--  total cashback amount earned by customers
SELECT SUM(CashbackAmount) AS TOTAL_CASHBACK_AMT FROM CUSTOMER_CHURN WHERE ChurnStatus = 'CHURNED';

-- the percentage of churned customers
SELECT CHURNSTATUS, concat(ROUND(COUNT(*)/ (SELECT COUNT(*) FROM CUSTOMER_CHURN)*100, 2), '%') AS CHURN_PERCENT
  FROM CUSTOMER_CHURN
  WHERE Complaintreceived = 'yes'
  group by churnstatus;
  
  
--  the gender distribution of customers
SELECT GENDER, count(COMPLAINTRECEIVED) AS GENDER_DISTRIBUTION FROM CUSTOMER_CHURN
WHERE COMPLAINTRECEIVED = 'YES'
group by GENDER;

--  the city tier with the highest number of churned customers

SELECT CityTier, count(ChurnStatus = 'CHURNED') AS MAX_CHURNED_CUSTOMER 
FROM CUSTOMER_CHURN 
WHERE PreferredOrderCat = 'Laptop & Accessory'
group by CITYTIER;

--  the most preferred payment mode

SELECT PreferredPaymentMode, count(CHURNSTATUS) AS PREFERRED_PAYMENT_MODE FROM CUSTOMER_CHURN 
WHERE CHURNSTATUS = 'ACTIVE'
group by PreferredPaymentMode;

--  the preferred login device(s) among customers
SELECT PreferredLoginDevice, COUNT(PreferredLoginDevice) AS PREFERRED_LOGIN_DEVICE FROM CUSTOMER_CHURN 
WHERE DaySinceLastOrder > '10'
group by PreferredLoginDevice;

--  the number of active customers who spent more than 3 hours

SELECT HoursSpentOnApp, COUNT(CHURNSTATUS) AS ACTIVE_CUSTOMERS
FROM CUSTOMER_CHURN
WHERE HoursSpentOnApp > '3' AND CHURNSTATUS = 'ACTIVE'
GROUP BY HoursSpentOnApp;

--  the average cashback amount received by customers

SELECT avg(CashbackAmount) AS AVG_CASHBACK FROM CUSTOMER_CHURN
WHERE HoursSpentOnApp <= '2';

--  the maximum hours spent on the app by customers

SELECT PreferredOrderCat, max(HoursSpentOnApp) AS MAX_TIME_SPENT 
FROM CUSTOMER_CHURN
group by PreferredOrderCat;

--  the average order amount hike from last year for customers

SELECT MaritalStatus, avg(OrderAmountHikeFromlastYear) AS AVG_AMT_HIKE 
FROM CUSTOMER_CHURN
group by MaritalStatus;

--  the total order amount hike from last year for customers

SELECT SUM(OrderAmountHikeFromlastYear) AS TOTAL_AMT_HIKE 
FROM CUSTOMER_CHURN 
WHERE MaritalStatus = 'SINGLE' AND
PreferredLoginDevice = 'MOBILE PHONE';

--  the average number of devices registered among customers

SELECT AVG(NumberOfDeviceRegistered) AS AVG_DEVICES
FROM CUSTOMER_CHURN
WHERE PreferredPaymentMode = 'UPI';

--  the city tier with the highest number of customers
 
SELECT CityTier, count(*) AS HIGHEST_NUMBER_OF_CUSTOMERS
FROM CUSTOMER_CHURN
group by CityTier;

--  the marital status of customers with the highest number of addresses

SELECT MaritalStatus, count(NumberOfAddress) AS HIGHEST_NUMBER_OF_ADDRESS
FROM CUSTOMER_CHURN
group by MaritalStatus;

--  the gender that utilized the highest number of coupons

SELECT Gender, COUNT(CouponUsed) AS highest_number_of_coupons
FROM CUSTOMER_CHURN
group by GENDER;

--  the average satisfaction score in each of the preferred order categories

SELECT PreferredOrderCat, ROUND(avg(SatisfactionScore)) AS AVG_SCORE
FROM CUSTOMER_CHURN
group by PreferredOrderCat;


--  the total order count for customers who prefer using credit cards and have the maximum satisfaction score

SELECT max(SatisfactionScore) FROM CUSTOMER_CHURN;

SELECT SatisfactionScore, count(OrderCount) AS TOTAL_ORDER_COUNT FROM CUSTOMER_CHURN
WHERE PreferredPaymentMode = 'CREDIT CARD'  and SatisfactionScore = '5'
group by SatisfactionScore;

--  customers are there who spent only one hour on the app and days since their last order was more than 5

SELECT* FROM CUSTOMER_CHURN WHERE HoursSpentOnApp = '1' AND
DaySinceLastOrder > '5';

-- the average satisfaction score of customers who have complained

SELECT ComplaintReceived, avg(SatisfactionScore) AS AVG_SCORE_OF_COMPLAINED
FROM CUSTOMER_CHURN
WHERE ComplaintReceived = 'YES';

-- customers are there in each preferred order category

SELECT PreferredOrderCat, count(*) AS CAT_WISE_CUSTOMER 
FROM CUSTOMER_CHURN
group by PreferredOrderCat;

--  the average cashback amount received by married customers

SELECT avg(CashbackAmount) AS AVG_CASHBACK_RECEIVED FROM CUSTOMER_CHURN
WHERE MaritalStatus = 'MARRIED';

--  the average number of devices registered by customers who are not using Mobile Phone as their preferred login device

SELECT PreferredLoginDevice, avg(NumberOfDeviceRegistered) AS AVG_NUMBER_OF_DEVICES
FROM CUSTOMER_CHURN
WHERE PreferredLoginDevice != 'MOBILE PHONE'
group by PreferredLoginDevice;

--  the preferred order category among customers who used more than 5 coupons

SELECT CustomerID, PreferredOrderCat FROM CUSTOMER_CHURN WHERE CouponUsed > '5';

--  the top 3 preferred order categories with the highest average cashback amount

SELECT PreferredOrderCat, avg(CashbackAmount) AS AVG_CASHBACK_AMT
FROM CUSTOMER_CHURN 
group by PreferredOrderCat
order by AVG_CASHBACK_AMT DESC
LIMIT 3;

--  the preferred payment modes of customers whose average tenure is 10 months and have placed more than 500 orders

SELECT PreferredPaymentMode, COUNT(*) AS CUSTOMER_COUNT, ROUND(avg(TENURE)) AS AVG_TENURE, sum(OrderCount) AS TOTAL_ORDERS
FROM CUSTOMER_CHURN
group by PreferredPaymentMode
HAVING TOTAL_ORDERS > 500 AND
AVG_TENURE = 10;

--  Categorize customers based on their distance from the warehouse to home

SELECT
	CASE
        WHEN WarehouseToHome <= 5 THEN 'VERY CLOSE DISTANCE'
        WHEN WarehouseToHome <= 10 THEN 'CLOSE DISTANCE'
        WHEN WarehouseToHome <= 15 THEN 'MODERATE DISTANCE'
        ELSE 'FAR DISTANCE' 
        END AS DISTANCE_CATEGORY,
 count(*) AS CHURN_CUST
 FROM CUSTOMER_CHURN
 WHERE CHURNSTATUS = 'CHURNED'
 group by DISTANCE_CATEGORY;
 
--  the customer’s order details who are married, live in City Tier-1, and their order counts are more than the average number of orders placed by all customers

SELECT* FROM CUSTOMER_CHURN
WHERE MaritalStatus = 'MARRIED' AND CityTier = 1
AND ORDERCOUNT > (SELECT AVG(ORDERCOUNT) FROM CUSTOMER_CHURN);

--  Create a ‘customer_returns’ table in the ‘ecomm’ database

USE ECOMM;

CREATE TABLE Customer_Returns(
	ReturnID int PRIMARY KEY,
    CustomerID int,
    ReturnDate date,
    RefundAmount decimal(10,2),
    
    FOREIGN KEY (CUSTOMERID) references CUSTOMER_CHURN(CUSTOMERID)
    );


--  INSERT

INSERT INTO customer_returns(ReturnID, CustomerID, ReturnDate, RefundAmount) 
VALUES(
 '1001', '50022', '2023-01-01', '2130'
);

SELECT * FROM CUSTOMER_RETURNS;

INSERT INTO customer_returns(ReturnID, CustomerID, ReturnDate, RefundAmount) 
VALUES(
'1002', '50316', '2023-01-23', '2000'),
('1003', '51099', '2023-02-14', '2290'),
('1004', '52321', '2023-03-08', '2510'),
('1005', '52928', '2023-03-20', '3000'),
('1006', '53749', '2023-04-17', '1740'),
('1007', '54206', '2023-04-21', '3250'),
('1008', '54838', '2023-04-30', '1990');

--  the return details along with the customer details of those who have churned and have made complaints.

SELECT R.*, C.*
FROM CUSTOMER_RETURNS R
JOIN CUSTOMER_CHURN C ON R.CUSTOMERID = C.CUSTOMERID
WHERE C.ComplaintReceived = 'YES'
  AND C.ChurnStatus = 'CHURNED';






