# deleteDB.PractI.MoshkovichG.R
# Name: Gulnas Moshkovich
# Semester: Summer B 2026
# Assignment: Final Project - Maison Beaumont Affinage - Schema Deletion
#
# Drops all tables for the Maison Beaumont Affinage database on
# Aiven MySQL, in reverse dependency order.
#
# Drop order (reverse of createDB's creation order):
#   1. aging_records          (depends on batches, caves)
#   2. batches                (depends on cheese_types, suppliers)
#   3. caves                  (depends on affineurs, cave_type_specifications)
#   4. cave_type_specifications
#   5. affineurs              (depends on guilds)
#   6. guilds
#   7. suppliers
#   8. cheese_type_cultures   (depends on cheese_types)
#   9. cheese_types

library(RMySQL)

# Connection settings
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

# Drop tables in reverse dependency order
dbSendStatement(mydb, "DROP TABLE IF EXISTS aging_records")
dbSendStatement(mydb, "DROP TABLE IF EXISTS batches")
dbSendStatement(mydb, "DROP TABLE IF EXISTS caves")
dbSendStatement(mydb, "DROP TABLE IF EXISTS cave_type_specifications")
dbSendStatement(mydb, "DROP TABLE IF EXISTS affineurs")
dbSendStatement(mydb, "DROP TABLE IF EXISTS guilds")
dbSendStatement(mydb, "DROP TABLE IF EXISTS suppliers")
dbSendStatement(mydb, "DROP TABLE IF EXISTS cheese_type_cultures")
dbSendStatement(mydb, "DROP TABLE IF EXISTS cheese_types")

# Confirm and disconnect
cat("Tables remaining after drop:\n")
print(dbListTables(mydb))

dbDisconnect(mydb)