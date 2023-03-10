USE upi_system;
DROP PROCEDURE IF EXISTS createBank;
DELIMITER //
CREATE PROCEDURE createBank(
	bank_name VARCHAR(50),
    bank_reg_id INT,
    routing_number INT,
    building_number INT,
    street_name VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    pin VARCHAR(6))
BEGIN
	INSERT INTO bank (bank_name, bank_reg_id, routing_number, building_number, street_name, city, state, pin)
    VALUES (bank_name, bank_reg_id, routing_number, building_number, street_name, city, state, pin);
END//
DELIMITER ;



SELECT * FROM bank;

CALL createbank("SBI", 1 , 12345 , 12 , "University Road" , "Jammu", "J&K", "180006");

DROP PROCEDURE IF EXISTS createBankAccount;
DELIMITER //
CREATE PROCEDURE createBankAccount(
ssn VARCHAR(8),
branch_id VARCHAR(5),
account_number VARCHAR(10),
balance DOUBLE,
date_of_creation DATE)
BEGIN
    IF (checkLength(ssn, 8) != 1) THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SSN has to have 8 Character';
	END IF;
	IF (checkLength(branch_id, 5) != 1) THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Branch ID is invalid';
	END IF;
	IF (checkLength(account_number, 10) != 1) THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account number should be 10 digits';
	END IF;
	IF (balance < 0) THEN 
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Deposite money cannot be negative';
	END IF;
    INSERT INTO bank_account (ssn, branch_id, account_number, balance) VALUES (ssn, branch_id, account_number, 0);
   	CALL depositeMoneyInBank(account_number, balance, date_of_creation);
END//
DELIMITER ;

USE upi_system;

select * FROM branch;
select * from bank_account;
SELECT * FROM bank_transactions;
SELECT * FROM individual;
CALL addIndividual("12345678", "Prajwal", "Shenoy", "44", "1209 Boylston St", "Boston", "MA", "02215", "9294219425", "12345");
CALL addIndividual("12345679", "Paarthvi", "Sharma", "18", "143 Park Drive", "Boston", "MA", "02215", "9142336508", "123456");
CALL createBankAccount("12345678", "SBI01", "1234567890", 500, "2022-11-23");
CALL depositeMoneyInBank("1234567890", 1000, "2022-11-23");
CALL withdrawMoneyfromBank("1234567890", 600, "2022-11-23");

DROP PROCEDURE IF EXISTS bankTransaction;
DELIMITER //
CREATE PROCEDURE bankTransaction(
account_number_sender VARCHAR(10),
account_number_receiver VARCHAR(10),
amount_to_transfer double)
BEGIN
	IF (checkLength(account_number_sender, 10) != 1) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account number should be 10 characters';
	END IF;
    UPDATE bank_account SET amount = (amount + amount_to_transfer) WHERE account_number = account_number_receiver;
    UPDATE bank_account SET amount = (amount - amount_to_transfer) WHERE account_number = account_number_sender;
END//
DELIMITER ;

DROP PROCEDURE IF EXISTS withdrawMoneyfromBank;
DELIMITER //
CREATE PROCEDURE withdrawMoneyfromBank(
	account_number VARCHAR(10),
    amount DOUBLE,
    date_of_transaction DATE)
BEGIN
	DECLARE fetched_branch_id VARCHAR(5);
	IF (checkLength(account_number, 10) != 1) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account number should be 10 digits long';
	END IF;
	IF (amount < 0) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Withdrawal amount should be greater than 0';
	END IF;
	IF (SELECT COUNT(account_number) FROM bank_account WHERE account_number = account_number != 1) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Account number is invalid';
	END IF;
	IF (SELECT balance < amount FROM bank_account WHERE account_number = account_number) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient balance';
	END IF;
    UPDATE bank_account SET balance = (balance - amount) WHERE account_number = account_number;
   	SELECT branch_id INTO fetched_branch_id FROM bank_account WHERE account_number = account_number;
	INSERT INTO bank_transactions (SELECT incrementNextTransactionId(fetched_branch_id), "DEBIT", 
		account_number, "InPerWithd", date_of_transaction, amount, "In person withdrawal");
END//
DELIMITER ;
    
DROP PROCEDURE IF EXISTS viewAccountDetails;
DELIMITER //
CREATE PROCEDURE viewAccountDetails(
	fetched_ssn VARCHAR(8))
BEGIN
	IF (checkLength(fetched_ssn, 8) != 1) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SSN should be 8 digits long';
	END IF;
	IF (SELECT COUNT(account_number) FROM bank_account WHERE account_number = account_number != 1) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No accounts associated with this SSN';
	END IF;
   	SELECT bank_name, branch.branch_id, account_number, balance, branch.building_number, branch.street_name, branch.city, branch.pin 
	FROM bank_account 
    JOIN branch ON  bank_account.branch_id = branch.branch_id
    JOIN bank ON bank.bank_reg_id = branch.bank_reg_id where ssn = fetched_ssn;
END//
DELIMITER ;
CALL viewAccountDetails("12345679");

DROP PROCEDURE IF EXISTS viewTransaction;
DELIMITER //
CREATE PROCEDURE viewTransaction(
	fetched_accountNumber VARCHAR(10))
BEGIN
SELECT * from bank_transactions where personal_account_details = fetched_accountNumber;
END//
DELIMITER ;
CALL viewTransaction("0000000007");

DROP PROCEDURE IF EXISTS viewUPITransaction;
DELIMITER //
CREATE PROCEDURE viewUPITransaction(
fetched_emailID VARCHAR(50))
BEGIN
SELECT upi_transaction_id, balance, bank_transactions.* from upi_customer
JOIN bank_account ON upi_customer.account_number = bank_account.account_number
JOIN bank_transactions ON bank_account.account_number = bank_transactions.personal_account_details
JOIN upi_transaction ON bank_transactions.bank_transaction_id  =  upi_transaction.personal_transaction_id 
where email_id = fetched_emailID ;
END//
DELIMITER ;

DROP PROCEDURE IF EXISTS viewUPIConsumer;
DELIMITER //
CREATE PROCEDURE viewUPIConsumer(
fetched_ssn VARCHAR(50))
BEGIN
select consumer.account_number, email_id from upi_customer
JOIN consumer on consumer.account_number = upi_customer.account_number where ssn = fetched_ssn;
END//
DELIMITER ;

DROP PROCEDURE IF EXISTS viewUPIMerchant;
DELIMITER //
CREATE PROCEDURE viewUPIMerchant(
fetched_ssn VARCHAR(50))
SELECT merchant.account_number, email_id, gst_number, fee_percentage FROM merchant 
JOIN upi_customer ON merchant.account_number = upi_customer.account_number where ssn = fetched_ssn;
END//
DELIMITER ;