

-- GBAC 7212 – Quiz 3
-- Using the ProductivIT database, write SQL commands that would answer the following:
-- 1.	Display the customer name, sales rep first & last names, and state for all customers that are located in the same state as their sales rep.
SELECT empFName, empLname, custName, empState as commonState
 FROM Employee join Customer on Employee.empNum = Customer.salesRep
 WHERE empState = custState;

-- 2.	What is the average amount spent on plane tickets for each of the different airlines (Hint: airline name would appear in the lineItemCompany column).
SELECT lineItemCompany, AVG(lineItemAmt) as avgTicketCost FROM ExpLineItem 
WHERE lineItemCat = 'Air Travel'
GROUP BY lineItemCompany;

-- 3.	Who has had an expense report approved by another employee with a lower salary?  
--Display the submitter’s empNum and salary along with the approver’s empNum and salary in your results and remove any duplicates
select DISTINCT(Submitter.empNum) as submitterNum, Submitter.empSalary as submitterSalary, 
Approver.empNum as approverNum, Approver.empSalary as approverSalary from 
Employee as Submitter join ExpReport on Submitter.empNum = ExpReport.empNum 
inner join Employee as Approver ON 
ExpReport.expRepApprovedBy = Approver.empNum
WHERE Submitter.empSalary > Approver.empSalary;

-- 4.	Who are the customers that pay their invoices, on average, within 20 days? 
--Display the customer name and the average time it takes to pay invoices for each customer in your results. 
    --(Hint: the amount of time to pay an invoice is the difference between the invoice date and the remit date)
SELECT Customer.custName, avg(remitDate-InvoiceDate) as avgTimeToPay
 from Customer NATURAL JOIN Invoice
 GROUP BY Customer.custName
 HAVING avg(remitDate-InvoiceDate) <= 20;

-- 5.	Which customers meet ALL of the following criteria (include only the customer name in your results and remove all duplicate values):
-- a.	Have “Inc” in their name, no rows will be returned.  There are no companies with "inc" in their name.  
SELECT Customer.custName from Customer where custName REGEXP 'inc';
-- b.	Have a sales rep in the Atlanta office
SELECT DISTINCT(Customer.custName) from Customer inner join Employee on Customer.salesRep = Employee.empNum
where Employee.office = "Atlanta";
-- c.	Have at least one user in the state of Florida (‘FL’)
SELECT DISTINCT(Customer.custName) from Customer natural join Users where Users.userState = "FL";

-- 6.	Generate a report that the name of the employee, the expense report number, the company (the name of the hotel where the employee stayed), 
--and the nightly rate (total bill/number of nights) for those employees who stayed in either a ‘King’ or ‘Queen’ room type and had a nightly room rate
-- that was higher than the average nightly rate of all employees who stayed in a suite (e.g. ‘suite’ appears somewhere in the roomType field)
SELECT Employee.empFName, Employee.empLName, ExpReport.expReportNum, lineItemCompany ,(ExpLineItem.lineItemAmt/Lodging.lodgingNights) as nightlyRate 
from ExpLineItem NATURAL JOIN Lodging natural join ExpReport inner join Employee on ExpReport.empNum = Employee.empNum
WHERE (ExpLineItem.lineItemAmt/Lodging.lodgingNights) >
        (select AVG(e.lineItemAmt/l.lodgingNights) as avgSuite from ExpLineItem e NATURAL JOIN Lodging l WHERE l.roomType REGEXP 'suite')
AND (roomType = 'Queen' OR roomType='King') ORDER BY nightlyRate;

-- 7.	Generate a list of unique company names listed somewhere in the database in alphabetical order.  
--This would include both the name of customers and the names of companies that expenses were charged to (in the line item table).
select distinct(hold.company) From 
(SELECT custName as company from Customer
UNION 
SELECT lineItemCompany as company  from  ExpLineItem) as hold
ORDER BY company;

-- 8.	Generate a report that shows the complete details for line items that have a lineItemCat of “Air Travel” or “Rental Car”.  
--The report should display all columns from the expLineItem table and all columns from both the AirTravel and CarRental tables, 
--where applicable based on the lineItemCat.
SELECT * FROM ExpLineItem INNER JOIN CarRental ON ExpLineItem.expReportNum = CarRental.expReportNum 
INNER JOIN AirTravel ON ExpLineItem.expReportNum = AirTravel.expReportNum 
WHERE lineItemCat = "Air Travel" OR lineItemCat = "Rental Car"