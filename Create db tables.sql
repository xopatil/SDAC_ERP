USE erp;

CREATE TABLE Users (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    MailID VARCHAR(255) NOT NULL UNIQUE,
    Name VARCHAR(255) NOT NULL,
    Password VARCHAR(255) NOT NULL,
    Role ENUM('Admin', 'Regular') NOT NULL
);

CREATE TABLE Products (
    ProductID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Category VARCHAR(255) NOT NULL,
    Cost DECIMAL(10, 2) NOT NULL,
    Selling_Price DECIMAL(10, 2) NOT NULL,
    Stock INT NOT NULL,
    Reorder_Level INT NOT NULL,
    Supplier_Info VARCHAR(255),
    Expiry_Date DATE,
    Sales_Data INT DEFAULT 0
);

CREATE TABLE Customers (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Email VARCHAR(255) NOT NULL UNIQUE,
    Phone VARCHAR(15) NOT NULL,
    Address TEXT,
    Purchase_History TEXT,
    Loyalty_Points INT DEFAULT 0
);

CREATE TABLE Sales (
    SaleID INT AUTO_INCREMENT PRIMARY KEY,
    ProductID INT NULL,
    CustomesysrID INT NOT NULL,
    Date DATE NOT NULL,
    Quantity INT NOT NULL,
    Total_Amount DECIMAL(10, 2) NOT NULL,
    Payment_Method ENUM('Cash', 'Card', 'Online') NOT NULL,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE SET NULL,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE Feedback (
    FeedbackID INT AUTO_INCREMENT PRIMARY KEY,
    ProductID INT NOT NULL,
    CustomerID INT NOT NULL,
    Comments TEXT,
    Ratings INT CHECK (Ratings BETWEEN 1 AND 5),
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    Response TEXT,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE CASCADE,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE Logs (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    Algorithm_Name VARCHAR(255),
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    Results TEXT
);
