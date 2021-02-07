-- 1.	How many line items appear on expense report 760017?
SELECT COUNT(expLineItemNum) FROM ExpLineItem WHERE expReportNum = 760017;

-- 2.	Generate a list of all invoices that have not been paid.  Include all columns from the invoice table in this query.
SELECT * FROM Invoice WHERE remitAmount is NULL;

-- 3.	Who are the users who are located in the same state as the sales rep assigned to their company?
    --  Confused by question.. below is customers who live in the same state as their sales rep
select custNum, salesRep, empNum, custState, empState
from Customer inner join Employee 
on Customer.salesRep = Employee.empNum 
where custState = empState;
    -- And this query captures users whose company (customer)’s sales rep lives in the same state as them (the user)
select userID, userState, empNum, empState
from Customer 
inner JOIN Users 
    on Users.custNum =  Customer.custNum
inner join Employee
    on Customer.salesRep = Employee.empNum 
where userState = empState;


-- 4.	Who are the customers that have more than 15 disabled user accounts?
SELECT  Customer.custNum, COUNT(Users.accountDisabled)
FROM Customer
inner join Users 
    on Customer.custNum = Users.custNum
WHERE Users.accountDisabled = 'true'
GROUP BY Customer.custNum
HAVING count(Users.accountDisabled) > 15;


-- 5.	What is the first and last name of all employees who have five letter first names?
SELECT empFName, empLName FROM Employee 
WHERE 
    LENGTH(empFName) = 5
AND    
    LENGTH(empLName) = 5;

/* 6.	Generate a report showing name of each employee submitting an expense report, the restaurant 
        name (would be captured in lineItemCompany), the date, the amount, the number of diners, the alcohol amount, 
        and the percent of the total bill spent on alcohol for all employees in the Atlanta office who spent more than 
        30% of their total bill on alcohol.*/
SELECT itemDate, reportNum, fName, lName, restaurant, numDiners, total, alcoholAmt, alcoholAmt/total from
	(select  ExpLineItem.lineItemDate as itemDate, ExpLineItem.expReportNum as reportNum, ExpLineItem.expLineItemNum as lineItem, 
	Employee.empFName as fName, Employee.empLName as lName, Employee.office, ExpLineItem.lineItemCompany as restaurant, 
		ExpLineItem.lineItemAmt as total
	from Employee inner join ExpReport 
	ON Employee.empNum = ExpReport.empNum 
	inner JOIN 
		ExpLineItem on ExpReport.expReportNum = ExpLineItem.expReportNum 
	WHERE Employee.office = 'Atlanta' ) as hold
inner join Meals on hold.reportNum = Meals.expReportNum and hold.lineItem = Meals.expLineItemNum
HAVING (alcoholAmt/total) >= .3 ORDER BY total/alcoholAmt DESC
;
-- 7.	What is the average expense amount for a plane ticket?
select AVG(lineItemAmt) from AirTravel
inner join ExpLineItem on 
AirTravel.expReportNum = ExpLineItem.expReportNum
AND 
AirTravel.expLineItemNum = ExpLineItem.expLineItemNum;

/* 8.	Who are the customers that have a sales rep in the Chicago office and have more than 30 active user accounts 
(account is not disabled)?  Display the name of the customer and the number of active user accounts sorted by the 
number of active users in descending order.*/
select custName, salesRep, empNum, office, count(accountDisabled) as numActive from 
(SELECT * FROM Customer
inner join Employee
on Customer.salesRep = Employee.empNum
where Employee.office = 'Chicago') as hold
join Users on 
hold.custNum = Users.custNum 
where accountDisabled = 'false'
GROUP BY custName, salesRep, empNum, office 
having numActive > 30 ORDER BY numActive DESC
;

/* 9.	For all expense reports submitted in the year 2020, what is the total amount spent in each line item category?  
        Only include categories that have more than 50 line item expenses in your results.*/
SELECT lineItemCat, COUNT(ExpLineItem.lineItemAmt) as countCat,
        Sum(ExpLineItem.lineItemAmt) as sumCat FROM ExpReport JOIN ExpLineItem 
on ExpReport.expReportNum = ExpLineItem.expReportNum
where YEAR(expReportDate) = 2020
GROUP BY lineItemCat
HAVING countCat > 50;

-- 10.	Who are the customers that have more than 30 users that have logged in within the last 180 days?
Select * from  
    (
    SELECT Customer.custName, Customer.CustNum, 
        COUNT(userID) as activeUsers 
    FROM Users JOIN Customer on Users.CustNum = Customer.custNum
    WHERE lastLogon >= CURDATE() - INTERVAL 6 MONTH
    GROUP BY Customer.custName, Customer.custNum
    ) as hold
WHERE activeUsers > 30 order by activeUsers;

-- 11.	Who is the boss of the Sales rep that is linked to order number 210292?
Select Boss.empNum as bossNum, Boss.empFName as bossFName, Boss.empLName, 
Customer.salesRep, Invoice.invoiceNum FROM Employee as Boss, Employee as SalesRep
JOIN Customer on SalesRep.empNum = Customer.salesRep
JOIN Invoice on Customer.custNum = Invoice.custNum
WHERE invoiceNum = '210292' AND Boss.empNum = SalesRep.reportsTo;

-- 12.	What is the total dollar value of all expenses paid for queen sized hotel room types?
/* 　This includes all expenses for those with Queen roomTypes, including Hotel, Hotel Stay, Place to stay, Room, Lodging, food for team, 
restaurant meal, group lunch, meal for myself, dinner, group dinner, lunch, sales dinner, meal, client entertainment, dinner with client*/
SELECT CONCAT('$', FORMAT(expensesForQueenRooms, 2)) as expensesForQueenRooms  FROM
(SELECT sum(lineItemAmt) as expensesForQueenRooms from 
ExpLineItem join Lodging on ExpLineItem.expLineItemNum = Lodging.expLineItemNum
WHERE roomType = 'Queen')as hold;

/* 13.	What is the average cost per night for each hotel that an expense has been submitted for? 
        (the names of hotels would be listed in “lineItemCompany”? */
SELECT CONCAT('$', FORMAT(nightlyRate, 2)) as avgNightlyRate  FROM
(select AVG(lineItemAmt/lodgingNights) as nightlyRate
from ExpLineItem join Lodging on ExpLineItem.expLineItemNum = Lodging.expLineItemNum
WHERE lineItemCat = 'Lodging') as hold;

-- 14.	How much money has been spent paying in airfare for employees to fly into the Atlanta airport?
SELECT CONCAT('$', FORMAT(avgATLFare, 2)) as avgATLFare  FROM
(select AVG(lineItemAmt) as avgATLFare from ExpLineItem join AirTravel on 
ExpLineItem.expLineItemNum = AirTravel.expLineItemNum
where destination = 'Atlanta') as hold;

-- 15.	Which current/active hourly employees earn less than the average hourly rate of all current/active employees?
--SELECT AVG(empHourlyRate) from Employee as avgSalary;
select empNum, empFName, empLName, empHourlyRate from Employee  
WHERE empHourlyrate < (select avg(empHourlyrate) from Employee) AND 
        empTerminationDate is NULL
ORDER BY empHourlyRate;

-- 16.	Which customers have more than 10 users located in the same state (userState would be the same as custState)?
SELECT Customer.custNum, custState, count(Users.userState) as numUserSameState  from 
Customer join Users on Customer.custNum = Users.custNum
WHERE Customer.custState = Users.userState
group by Customer.custNum, custState
HAVING numUserSameState > 10;

/* 17.	Generate a report that shows all current, salaried employees and the number of customers they serve as the 
        sales rep (if they are not a sales rep, then the count should be zero). */
SELECT Employee.empNum, count(Customer.custNum) numCustomers
FROM Employee left JOIN Customer on Employee.empNum = Customer.SalesRep
WHERE Employee.empSalary is not null AND Employee.empTerminationDate is NULL
GROUP BY Employee.empNum
ORDER BY numCustomers DESC;

/* 18.	Who are the salaried employees that earn at least 95% of their boss’ salary?  Display the subordinate’s full 
        name and salary along with the boss’ full name and salary.*/
SELECT Emp.empFName as empFName, Emp.empLName as empLName, Emp.empSalary as empSalary, 
        Boss.empFNAme as bossFNme, Boss.empLName as bossLName, Boss.empSalary as bossSalary 
FROM Employee as Emp, Employee as Boss
WHERE Emp.empSalary >= (.95*Boss.empSalary) AND 
    Boss.empNum = Emp.reportsTo;

/* 19.	Which employees have submitted an expense report with a below average first class plane ticket 
         (e.g. their first class plane ticket was less than the average of all first class plane tickets)?*/
SELECT DISTINCT Employee.empNum, ExpLineItem.lineItemAmt ticketCost, ExpLineItem.lineItemCompany airline 
FROM Employee join ExpReport
on Employee.empNum = ExpReport.empNum join ExpLineItem
on ExpReport.expReportNum = ExpLineItem.expReportNum join AirTravel
ON ExpLineItem.expLineItemNum = AirTravel.expLineItemNum
WHERE AirTravel.airServiceClass = "First" and ExpLineItem.lineItemCat = "Air Travel"
    AND ExpLineItem.lineItemAmt < (select avg(ExpLineItem.lineItemAmt) from ExpLineItem join AirTravel on 
                                    ExpLineItem.expLineItemNum=AirTravel.expLineItemNum
                                    WHERE AirTravel.airServiceClass = "First" and ExpLineItem.lineItemCat = "Air Travel") ;

/* 20.	Which expense report purpose has been assigned to the most expense reports?  Your result should display 
        just one row that lists the purposeDesc and the number of expense reports that have been assigned that purpose 
        (no matter the percentage).*/
select purposeDesc, count(ExpRepPurpose.purposeID) as categoryTotal  from 
ExpRepPurpose JOIN Purpose on ExpRepPurpose.purposeID = Purpose.purposeID
group by ExpRepPurpose.purposeID, purposeDesc order by categoryTotal desc;

/*
SET @total := (SELECT COUNT(purposeID) FROM ExpRepPurpose);
SELECT @total;

Select  percentTotal, purposeID, purposeDesc FROM 
(select ExpRepPurpose.purposeID, count(ExpRepPurpose.purposeID)/@total as percentTotal, purposeDesc from 
ExpRepPurpose JOIN Purpose on ExpRepPurpose.purposeID = Purpose.purposeID
group by ExpRepPurpose.purposeID , purposeDesc 
order by percentTotal desc) as hold
GROUP BY purposeID, purposeDesc LIMIT 1;*/
