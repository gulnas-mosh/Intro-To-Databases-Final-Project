# configBusinessLogic.PractI.MoshkovichG.R
# Name: Gulnas Moshkovich
# Semester: Summer B 2026
# Assignment: Final Project - Maison Beaumont Affinage - Business Logic
#
# Creates a stored procedure named storeProduct that adds a new
# production record (batch) to the database, then demonstrates that it
# works by calling it and checking the row landed in the batches table.

library(RMySQL)

# Connect
db_host_aiven <- Sys.getenv("DB_HOST")
db_port_aiven <- as.integer(Sys.getenv("DB_PORT"))
db_name_aiven <- Sys.getenv("DB_NAME")
db_user_aiven <- Sys.getenv("DB_USER")
db_pwd_aiven  <- Sys.getenv("DB_PASSWORD")

db_cert <- 
"-----BEGIN CERTIFICATE-----
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

# Drop the procedure first if it already exists, so this script can be
# re-run from a clean state.
dbSendStatement(mydb, "DROP PROCEDURE IF EXISTS storeProduct")

# Define storeProduct by building the SQL as pieces joined with paste0(), then
# send it with dbSendStatement()
sql <- paste0(
  "CREATE PROCEDURE storeProduct(",
  "  IN p_batch_id VARCHAR(10),",
  "  IN p_production_date DATE,",
  "  IN p_batch_size_liters INT,",
  "  IN p_wheels_produced INT,",
  "  IN p_coagulant_type VARCHAR(30),",
  "  IN p_cheese_type_id VARCHAR(10),",
  "  IN p_supplier_id VARCHAR(10))",
  " BEGIN",
  "   INSERT INTO batches (batch_id, production_date, batch_size_liters,",
  "     wheels_produced, coagulant_type, cheese_type_id, supplier_id)",
  "   VALUES (p_batch_id, p_production_date, p_batch_size_liters,",
  "     p_wheels_produced, p_coagulant_type, p_cheese_type_id, p_supplier_id);",
  " END"
)
dbSendStatement(mydb, sql)

cat("storeProduct created.\n\n")

# Check to see that it works
new_batch_id <- "BT9001"

call_sql <- paste0(
  "CALL storeProduct('", new_batch_id, "', ",
  "'2026-08-09', ",
  "480, ",
  "60, ",
  "'Animal Rennet', ",
  "'CT01', ",
  "'SP01')"
)

# collects the first result set, then removes any additional result sets
# so the next query on this connection does not error out.
rs <- dbSendQuery(mydb, call_sql)
data <- fetch(rs, n = -1)
while (dbMoreResults(mydb) == TRUE) {
  dbNextResult(mydb)
}

cat("Called storeProduct with batch_id =", new_batch_id, "\n\n")

# Confirm the new row actually landed in batches
check <- dbGetQuery(mydb, paste0(
  "SELECT * FROM batches WHERE batch_id = '", new_batch_id, "'"))

if (nrow(check) == 1) {
  cat("PASS - storeProduct worked. New row found:\n")
  print(check)
} else {
  cat("FAIL - no row found for batch_id", new_batch_id, "\n")
}

dbDisconnect(mydb)