BULK INSERT customers
FROM 'C:\Users\HP\Desktop\db\dim_customers.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',      
    ROWTERMINATOR = '\n',       
    TABLOCK,
    CODEPAGE = '65001'          
);

BULK INSERT products
FROM 'C:\Users\HP\Desktop\db\dim_products.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',     
    ROWTERMINATOR = '\n',      
    TABLOCK,
    CODEPAGE = '65001'           
);

BULK INSERT fact_sales
FROM 'C:\Users\HP\Desktop\db\fact_sales.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',    
    ROWTERMINATOR = '\n',     
    TABLOCK,
    CODEPAGE = '65001'           
);