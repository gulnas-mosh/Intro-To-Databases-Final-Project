# createDB.PractI.MoshkovichG.R
# Name: Gulnas Moshkovich
# Semester: Summer B 2026
# Assignment: Final Project - Maison Beaumont Affinage - Schema Creation
#
# Realizes the 3NF schema designed in Part B
# Table names, keys, and foreign keys breakdowm:
#
#   1. cheese_types
#   2. cheese_type_cultures  (FK -> cheese_types)   [fixes 1NF violation on CulturesAdded]
#   3. suppliers
#   4. guilds
#   5. affineurs             (FK -> guilds)
#   6. cave_type_specifications                     [fixes transitive dependency through CaveType]
#   7. caves                 (FK -> affineurs, cave_type_specifications)
#   8. batches               (FK -> cheese_types, suppliers)
#   9. aging_records         (FK -> batches, caves)
#
# Tables are created in this order so no foreign key references a table that
# doesn't exist yet

library(RMySQL)

db_host_aiven <- Sys.getenv("DB_HOST")
db_port_aiven <- as.integer(Sys.getenv("DB_PORT"))
db_name_aiven <- Sys.getenv("DB_NAME")
db_user_aiven <- Sys.getenv("DB_USER")
db_pwd_aiven  <- Sys.getenv("DB_PASSWORD")

# Connect securely using the embedded certificate
db_cert <- "-----BEGIN CERTIFICATE-----
MIIERDCCAqygAwIBAgIUW1UKnJrctcFTRgPkgID5dqABwAwwDQYJKoZIhvcNAQEM
BQAwOjE4MDYGA1UEAwwvMzA0NjZjNzYtMzBlYi00N2Q1LWJmN2MtOTI1MDJjZTA3
NzA3IFByb2plY3QgQ0EwHhcNMjYwODAzMDUxNzQxWhcNMzYwNzMxMDUxNzQxWjA6
MTgwNgYDVQQDDC8zMDQ2NmM3Ni0zMGViLTQ3ZDUtYmY3Yy05MjUwMmNlMDc3MDcg
UHJvamVjdCBDQTCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGBAKktoIqT
ppOSWuhXKvkZTlb+lei94CS943eJbvo4PZRGyANx0nlckvTmfRkj6MfCmdg1Niml
n1X23X29BgXYAuAG2m6mt7+6iQpigrCZU3oRcyDmXi1eYjWwf/D3N9TZ7kVSiNc1
VNkGkSFBFBc/+DDxEq7MIjAa9O0j8Z4ad1f6YwkvV2AAkX+e9M53C7b0FnyqL9bp
SuB76gf8xF6puZANUBU2qie9oTfn4/z4Tt7HgSf8L0A/VTRkuiPc2dvBxcDn/72g
qZr10v7JxQ3e8yEnc8SaXUPlhJQYJlvcxdKMDse6sLvM8FK8CbgufXdvX8mVCX+F
/sZltY+WNd8r4+zFwTfGBsj81Iu5yalG+Xk0ucax0lw3vuTJOt35zt8My9WDKMFJ
I3MjeipphZj9pMZN0nBo1y8OmjLYzLLp6RoByKMt/v9Q+vzNVaH443OeVqYq4X1b
UnRW5gdkLsROm2DlsX7zNMTMa0BliCSsQlEOQk9WP7aPrs7SlxFcWXR1oQIDAQAB
o0IwQDAdBgNVHQ4EFgQUWZK4aXKMchLeJkAW6OEDxMbr3NQwEgYDVR0TAQH/BAgw
BgEB/wIBADALBgNVHQ8EBAMCAQYwDQYJKoZIhvcNAQEMBQADggGBADjxFcC8ld/p
cwXbx1WQnXTEHma9gYfNYYeetRD8kwvB6UtQqsqig+vq8hevvyBbq2cHn0TXSCxN
KMDt32T5nVkeAd5mB3tOM1VbtC1+bIUTqIm7THAlPyzN6w7xO8TzLKFRRjVbfhIB
B6AJ80FXb+cF1L9szy/dDKUy5mWBdwXbAQ6hObRUSCERVkyy2Wdu1CfwE6G7d/Mc
S8mEZ0TLoyXoW3B8LVWzdWzssahpe1+hywVIrwMmcLeqcSMeSi48Xo1oAXOU18t2
89hONKBHw9o60C0SBEMnIyYvtKYYcEDFr3vnS3vIIb8p39mlcmx01iVF0qM4zc8d
8GUrQKQIjRK6DA6A03wgCaweWHIhkZnLHBvCvzzniuP3PJ1iT3YsAGqz8JkgTOUb
HV24kx+Kqyavwhx/mv4J8bjRVJFIAuxf+fqXBft1FPTFm7Z9pwedEdAjY/4Nh1lC
o+jpepWr3zKFjpVsYqdqI8BgTGiZkYZSaijCcJ0QF30RR4k6bKbL4Q==
-----END CERTIFICATE-----"

mydb <- dbConnect(RMySQL::MySQL(),
                  user     = db_user_aiven,
                  password = db_pwd_aiven,
                  dbname   = db_name_aiven,
                  host     = db_host_aiven,
                  port     = db_port_aiven,
                  sslmode  = "require",
                  sslcert  = db_cert)

# 1. cheese_types
# Direct dependency CheeseTypeID. Attributes: name, animal, fat, age, rind.
# Removes the transitive dependency BatchID had on these through CheeseTypeID.
dbSendStatement(mydb, "
CREATE TABLE IF NOT EXISTS cheese_types (
    cheese_type_id     VARCHAR(10)  PRIMARY KEY,
    cheese_type_name   VARCHAR(100) NOT NULL,
    milk_animal        VARCHAR(20)  NOT NULL,
    milk_fat_percent   INT          NOT NULL,
    target_age_weeks   INT          NOT NULL,
    rind_style         VARCHAR(30)  NOT NULL,
    CHECK (milk_animal IN ('Cow','Goat','Sheep')),
    CHECK (rind_style IN ('Bandaged','Bloomy','Natural','Washed')),
    CHECK (milk_fat_percent BETWEEN 0 AND 100)
)
")

# 2. cheese_type_cultures, fixes 1NF violation on CulturesAdded
# CulturesAdded has multiple cultures separated by commas per value. Made it so 
# one row per (cheese_type_id, culture_name) pair instead.
dbSendStatement(mydb, "
CREATE TABLE IF NOT EXISTS cheese_type_cultures (
    cheese_type_id  VARCHAR(10)  NOT NULL,
    culture_name    VARCHAR(100) NOT NULL,
    PRIMARY KEY (cheese_type_id, culture_name),
    FOREIGN KEY (cheese_type_id) REFERENCES cheese_types(cheese_type_id)
)
")

# 3. suppliers
# Direct dependency SupplierID, farm attributes
# Removes the transitive dependency BatchID had on these through SupplierID.
dbSendStatement(mydb, "
CREATE TABLE IF NOT EXISTS suppliers (
    supplier_id         VARCHAR(10)  PRIMARY KEY,
    farm_name           VARCHAR(100) NOT NULL,
    farm_region         VARCHAR(100),
    farm_country        VARCHAR(50),
    animal_breed        VARCHAR(50),
    farm_certification  VARCHAR(30)  NOT NULL DEFAULT 'Conventional',
    CHECK (farm_certification IN ('AOC','Conventional','Organic','PDO','Raw Milk'))
)
")

# 4. guilds
# GuildHeadquarters was a value that inlcuded both the country and city.
# Split into guild_city & guild_country.
dbSendStatement(mydb, "
CREATE TABLE IF NOT EXISTS guilds (
    guild_id       VARCHAR(10)  PRIMARY KEY,
    guild_name     VARCHAR(100) NOT NULL,
    guild_city     VARCHAR(100),
    guild_country  VARCHAR(50)
)
")

# 5. affineurs (FK -> guilds)
# Direct dependency AffineurID. Attributes: name/email/guild.
# Removes the transitive dependency CaveID had on these through AffineurID.
dbSendStatement(mydb, "
CREATE TABLE IF NOT EXISTS affineurs (
    affineur_id     VARCHAR(10)  PRIMARY KEY,
    affineur_name   VARCHAR(100) NOT NULL,
    affineur_email  VARCHAR(100),
    guild_id        VARCHAR(10)  NOT NULL,
    FOREIGN KEY (guild_id) REFERENCES guilds(guild_id)
)
")

# 6. cave_type_specifications
# CaveType -> humidity/temp was transitive, not direct. CaveID only
# determines these through CaveType
dbSendStatement(mydb, "
CREATE TABLE IF NOT EXISTS cave_type_specifications (
    cave_type          VARCHAR(30) PRIMARY KEY,
    cave_humidity_pct  INT NOT NULL,
    cave_temp_celsius  INT NOT NULL,
    CHECK (cave_type IN ('Cellar','Natural','Ripening Room','Tunnel')),
    CHECK (cave_humidity_pct BETWEEN 0 AND 100)
)
")

# 7. caves (FK -> affineurs, cave_type_specifications)
# The remaining of CaveID's direct dependencies after humidity/temp
# moved out above.
dbSendStatement(mydb, "
CREATE TABLE IF NOT EXISTS caves (
    cave_id       VARCHAR(10)  PRIMARY KEY,
    cave_name     VARCHAR(100) NOT NULL,
    cave_type     VARCHAR(30)  NOT NULL,
    cave_country  VARCHAR(50),
    cave_region   VARCHAR(100),
    affineur_id   VARCHAR(10)  NOT NULL,
    FOREIGN KEY (cave_type)   REFERENCES cave_type_specifications(cave_type),
    FOREIGN KEY (affineur_id) REFERENCES affineurs(affineur_id)
)
")

# 8. batches (FK -> cheese_types, suppliers)
# BatchID -> these attributes was a partial dependency on the
# (BatchID, CaveID) candidate key.
dbSendStatement(mydb, "
CREATE TABLE IF NOT EXISTS batches (
    batch_id           VARCHAR(10)  PRIMARY KEY,
    production_date    DATE         NOT NULL,
    batch_size_liters  INT          NOT NULL,
    wheels_produced    INT          NOT NULL,
    coagulant_type     VARCHAR(30)  NOT NULL,
    cheese_type_id     VARCHAR(10)  NOT NULL,
    supplier_id        VARCHAR(10)  NOT NULL,
    CHECK (coagulant_type IN ('Animal Rennet','Microbial Rennet','Vegetable Rennet')),
    FOREIGN KEY (cheese_type_id) REFERENCES cheese_types(cheese_type_id),
    FOREIGN KEY (supplier_id)    REFERENCES suppliers(supplier_id)
)
")

# 9. aging_records (FK -> batches, caves)
# The other partial dependency on (BatchID, CaveID) - CaveID's aging
# attributes, now keyed on the full composite by aging_id.
dbSendStatement(mydb, "
CREATE TABLE IF NOT EXISTS aging_records (
    aging_id                    INT AUTO_INCREMENT PRIMARY KEY,
    batch_id                    VARCHAR(10) NOT NULL,
    cave_id                     VARCHAR(10) NOT NULL,
    aging_start_date            DATE        NOT NULL,
    aging_weeks                 INT         NOT NULL,
    turning_frequency_per_week  INT         NOT NULL,
    washing_solution            VARCHAR(50) NOT NULL DEFAULT 'None',
    final_rind_color            VARCHAR(50),
    quality_grade                VARCHAR(5),
    CHECK (washing_solution IN ('Beer','Brine','Cider','Lard','Marc de Bourgogne','None','White Wine')),
    FOREIGN KEY (batch_id) REFERENCES batches(batch_id),
    FOREIGN KEY (cave_id)  REFERENCES caves(cave_id),
    UNIQUE (batch_id, cave_id)
)
")

print("Tables created:")
print(dbListTables(mydb))

dbDisconnect(mydb)