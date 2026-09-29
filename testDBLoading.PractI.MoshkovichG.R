# testDBLoading.PractI.MoshkovichG.R
# Name: Gulnas Moshkovich
# Semester: Summer B 2026
# Assignment: Final Project - Maison Beaumont Affinage - Test Data Loading Process
#
# Loads the CSV and connects to the database, then checks that the
# data in the database matches the data in the CSV. Prints PASS or
# FAIL for each check.

library(RMySQL)
library(sqldf)
options(sqldf.driver = "SQLite")

# Connect
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

# Load the CSV from its URL
csv_url <- "https://s3.us-east-2.amazonaws.com/artificium.us/datasets/Maison-Beaumont-Affinage.csv"
df.raw <- read.csv(csv_url, header = TRUE, stringsAsFactors = FALSE)
cat("Loaded", nrow(df.raw), "rows from CSV to validate.\n\n")

# Function: check_equal
# Input: short name for the check,value from the CSV, value from the database
# Output: prints PASS or FAIL with both values
check_equal <- function(label, csv_value, db_value) {
  status <- if (csv_value == db_value) "PASS" else "FAIL"
  cat(sprintf("[%s] %s -- CSV: %s | DB: %s\n", status, label, csv_value, db_value))
}

# 1. Unique cheese types
csv_cheese_types <- length(unique(df.raw$CheeseTypeID))
db_cheese_types  <- dbGetQuery(mydb, "SELECT COUNT(*) AS n FROM cheese_types")$n
check_equal("Unique cheese types", csv_cheese_types, db_cheese_types)

# 2. Unique farm supplier countries
csv_farm_countries <- length(unique(df.raw$FarmCountry))
db_farm_countries  <- dbGetQuery(mydb, "SELECT COUNT(DISTINCT farm_country) AS n FROM suppliers")$n
check_equal("Unique farm countries", csv_farm_countries, db_farm_countries)

# 3. Unique cave countries
csv_cave_countries <- length(unique(df.raw$CaveCountry))
db_cave_countries  <- dbGetQuery(mydb, "SELECT COUNT(DISTINCT cave_country) AS n FROM caves")$n
check_equal("Unique cave countries", csv_cave_countries, db_cave_countries)

# 4. Unique batches
csv_batches <- length(unique(df.raw$BatchID))
db_batches  <- dbGetQuery(mydb, "SELECT COUNT(*) AS n FROM batches")$n
check_equal("Unique batches (productions)", csv_batches, db_batches)

# 5. First and last production dates
csv_first_date <- as.character(min(as.Date(df.raw$ProductionDate)))
csv_last_date  <- as.character(max(as.Date(df.raw$ProductionDate)))
db_dates <- dbGetQuery(mydb, "SELECT MIN(production_date) AS first_date, MAX(production_date) AS last_date FROM batches")
check_equal("First production date", csv_first_date, db_dates$first_date)
check_equal("Last production date",  csv_last_date,  db_dates$last_date)

cat("\n Comparisons \n")

# one row per batch, found the same way as the lookup tables in
# loadDB, using GROUP BY instead of picking rows out one at a time
csv_batches_df <- sqldf("select BatchID as batch_id,
                                BatchSizeLiters as batch_size_liters,
                                WheelsProduced as wheels_produced
                           from `df.raw`
                          group by BatchID")

# 6. Average batch size (liters)
csv_avg_batch_size <- round(mean(csv_batches_df$batch_size_liters), 2)
db_avg_batch_size  <- round(dbGetQuery(mydb, "SELECT AVG(batch_size_liters) AS avg_size FROM batches")$avg_size, 2)
check_equal("Average batch size (liters)", csv_avg_batch_size, db_avg_batch_size)

# 7. Total wheels produced across all batches
csv_total_wheels <- sum(csv_batches_df$wheels_produced)
db_total_wheels  <- dbGetQuery(mydb, "SELECT SUM(wheels_produced) AS total FROM batches")$total
check_equal("Total wheels produced", csv_total_wheels, db_total_wheels)

cat("\n Additional Checks \n")

# 8. aging_records should have one row per CSV row, since we did
# not remove any repeated rows when loading that table
csv_rows <- nrow(df.raw)
db_aging_records <- dbGetQuery(mydb, "SELECT COUNT(*) AS n FROM aging_records")$n
check_equal("aging_records row count vs CSV row count", csv_rows, db_aging_records)

# 9. Count distinct (cheese type, culture) pairs after splitting the
# comma-separated CulturesAdded column, one cheese type at a time.
# Splitting on ", " (comma and space) instead of just "," means no
# extra space is left on any token, so no trimming step is needed.
cheese_cultures_df <- sqldf("select CheeseTypeID as cheese_type_id,
                                    CulturesAdded as cultures_added
                               from `df.raw`
                              group by CheeseTypeID")
n.cheese_types <- nrow(cheese_cultures_df)

# count how many cultures each cheese type has, to know the total number of
# rows needed before building anything
culture_counts <- vector("numeric", n.cheese_types)
for (i in 1:n.cheese_types) {
  culture_counts[i] <- length(unlist(strsplit(cheese_cultures_df$cultures_added[i], ", ")))
}
total_pairs <- sum(culture_counts)

# pre-allocate both columns at their final size, then fill them in
# one culture at a time using a running position counter
cult_cheese_type_id <- vector("character", total_pairs)
cult_culture_name   <- vector("character", total_pairs)
pos <- 1
for (i in 1:n.cheese_types) {
  cultures <- unlist(strsplit(cheese_cultures_df$cultures_added[i], ", "))
  for (culture in cultures) {
    cult_cheese_type_id[pos] <- cheese_cultures_df$cheese_type_id[i]
    cult_culture_name[pos]   <- culture
    pos <- pos + 1
  }
}
csv_culture_pairs <- length(cult_culture_name)
db_culture_pairs  <- dbGetQuery(mydb, "SELECT COUNT(*) AS n FROM cheese_type_cultures")$n
check_equal("Distinct (cheese type, culture) pairs", csv_culture_pairs, db_culture_pairs)

# 10. Number of distinct guilds and affineurs
csv_guilds <- length(unique(df.raw$GuildID))
db_guilds  <- dbGetQuery(mydb, "SELECT COUNT(*) AS n FROM guilds")$n
check_equal("Unique guilds", csv_guilds, db_guilds)

csv_affineurs <- length(unique(df.raw$AffineurID))
db_affineurs  <- dbGetQuery(mydb, "SELECT COUNT(*) AS n FROM affineurs")$n
check_equal("Unique affineurs", csv_affineurs, db_affineurs)


# 11. Checks by picking one batch and seeing its values match exactly,
# which() finds the row position(s) where BatchID matches.Takes the first one 
# with [1] since a batch can show twice (once per cave it aged in).
sample_batch_id <- df.raw$BatchID[1]
p <- which(df.raw$BatchID == sample_batch_id)[1]
csv_sample <- df.raw[p, ]
db_sample  <- dbGetQuery(mydb, sprintf(
  "SELECT production_date, batch_size_liters, wheels_produced, coagulant_type
     FROM batches WHERE batch_id = '%s'", sample_batch_id))

check_equal(paste("Spot check", sample_batch_id, "- production_date"),
            as.character(as.Date(csv_sample$ProductionDate)), db_sample$production_date)
check_equal(paste("Spot check", sample_batch_id, "- batch_size_liters"),
            csv_sample$BatchSizeLiters, db_sample$batch_size_liters)
check_equal(paste("Spot check", sample_batch_id, "- wheels_produced"),
            csv_sample$WheelsProduced, db_sample$wheels_produced)
check_equal(paste("Spot check", sample_batch_id, "- coagulant_type"),
            csv_sample$CoagulantType, db_sample$coagulant_type)


# Disconnect
dbDisconnect(mydb)
cat("\nValidation complete.\n")