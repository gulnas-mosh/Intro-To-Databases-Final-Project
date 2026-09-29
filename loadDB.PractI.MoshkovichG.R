# loadDB.PractI.MoshkovichG.R
# Name: Gulnas Moshkovich
# Semester: Summer B 2026
# Assignment: Final Project - Maison Beaumont Affinage - Data Loading
#
# Loads the Maison-Beaumont-Affinage CSV from its URL, splits it into
# normalized tables and inserts each table
# into the Aiven MySQL database created by createDB.PractI.MoshkovichG.R.
#
# Load order (same order as createDB):
#   1. cheese_types
#   2. cheese_type_cultures
#   3. suppliers
#   4. guilds
#   5. affineurs
#   6. cave_type_specifications
#   7. caves
#   8. batches
#   9. aging_records

library(RMySQL)
library(sqldf)

# sqldf will try to use the current database connection as its
# backing store, which does not work with MySQL. Force it to use
# SQLite instead. (from assignment hints)
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
# stringsAsFactors is set to FALSE because several columns below need to be 
# split with strsplit(), which does not work directly on a factor.
csv_url <- "https://s3.us-east-2.amazonaws.com/artificium.us/datasets/Maison-Beaumont-Affinage.csv"
df.raw <- read.csv(csv_url, header = TRUE, stringsAsFactors = FALSE)
cat("Loaded", nrow(df.raw), "rows from CSV.\n")

# Function: toSQLString
# Input: a single value from a data frame column
# Output: a text version of x ready to place inside a SQL INSERT
#         statement (quoted and with internal quotes doubled for text,
#         or the word NULL for a missing value)
toSQLString <- function(x) {
  if (is.na(x) || x == "") return("NULL")
  if (is.numeric(x)) return(as.character(x))
  paste0("'", gsub("'", "''", x), "'")
}

# Function: batch_insert
# Input: the database connection, the name of the table to insert into,
#        a data frame whose columns match the table's columns,
#        how many rows to put in each INSERT statement
# Output: TRUE if every batch inserted the expected number of rows,
#         FALSE otherwise
batch_insert <- function(conn, table, df, batch_size = 200) {
  n <- nrow(df)
  if (n == 0) return(TRUE)
  cols <- paste(names(df), collapse = ", ")
  total_inserted <- 0
  all_ok <- TRUE
  
  for (start in seq(1, n, by = batch_size)) {
    end <- min(start + batch_size - 1, n)
    row_strings <- character(end - start + 1)
    for (i in start:end) {
      vals <- character(ncol(df))
      for (j in 1:ncol(df)) {
        vals[j] <- toSQLString(df[i, j])
      }
      row_strings[i - start + 1] <- paste0("(", paste(vals, collapse = ", "), ")")
    }
    sql <- paste0("INSERT INTO ", table, " (", cols, ") VALUES ",
                  paste(row_strings, collapse = ", "))
    
    ps <- dbSendStatement(conn, sql)
    rows_affected <- dbGetRowsAffected(ps)
    dbClearResult(ps)
    
    expected <- end - start + 1
    if (rows_affected < expected) {
      cat("WARNING:", table, "- expected", expected, "rows affected, got", rows_affected, "\n")
      all_ok <- FALSE
    }
    total_inserted <- total_inserted + rows_affected
  }
  cat("Inserted", total_inserted, "of", n, "rows into", table, "\n")
  return(all_ok)
}

# Start a transaction for the whole load, so that either every table
# loads correctly or none of them do
txnFailed <- FALSE
dbExecute(mydb, "START TRANSACTION")

# 1. cheese_types
# find one row per cheese type using GROUP BY. CulturesAdded is selected in a
# separate query below since it is not needed in this table.
cheese_types <- sqldf("select CheeseTypeID as cheese_type_id,
                              CheeseTypeName as cheese_type_name,
                              MilkAnimal as milk_animal,
                              MilkFatPercent as milk_fat_percent,
                              TargetAgeWeeks as target_age_weeks,
                              RindStyle as rind_style
                         from `df.raw`
                        group by CheeseTypeID")
if (!batch_insert(mydb, "cheese_types", cheese_types)) txnFailed <- TRUE

# 2. cheese_type_cultures
# CulturesAdded holds a comma-separated list of culture names, so we
# split it into tokens with strsplit(), one cheese type at a time.
# Splitting on ", " (comma and space) instead of just "," means no
# extra space is left, so no trimming step is needed.
cheese_cultures <- sqldf("select CheeseTypeID as cheese_type_id,
                                 CulturesAdded as cultures_added
                            from `df.raw`
                           group by CheeseTypeID")
n.cheese_types <- nrow(cheese_cultures)

# count how many cultures each cheese type has, to know the total number of 
# rows needed before building anything
culture_counts <- vector("numeric", n.cheese_types)
for (i in 1:n.cheese_types) {
  culture_counts[i] <- length(unlist(strsplit(cheese_cultures$cultures_added[i], ", ")))
}
total_pairs <- sum(culture_counts)

# pre-allocate both columns at their final size, then fill them in
# one culture at a time using a running position counter
cult_cheese_type_id <- vector("character", total_pairs)
cult_culture_name   <- vector("character", total_pairs)
pos <- 1
for (i in 1:n.cheese_types) {
  cultures <- unlist(strsplit(cheese_cultures$cultures_added[i], ", "))
  for (culture in cultures) {
    cult_cheese_type_id[pos] <- cheese_cultures$cheese_type_id[i]
    cult_culture_name[pos]   <- culture
    pos <- pos + 1
  }
}
cheese_type_cultures <- data.frame(cheese_type_id = cult_cheese_type_id,
                                   culture_name = cult_culture_name,
                                   stringsAsFactors = FALSE)
if (!batch_insert(mydb, "cheese_type_cultures", cheese_type_cultures)) txnFailed <- TRUE

# 3. suppliers
suppliers <- sqldf("select SupplierID as supplier_id,
                           FarmName as farm_name,
                           FarmRegion as farm_region,
                           FarmCountry as farm_country,
                           AnimalBreed as animal_breed,
                           FarmCertification as farm_certification
                      from `df.raw`
                     group by SupplierID")
if (!batch_insert(mydb, "suppliers", suppliers)) txnFailed <- TRUE

# 4. guilds
# GuildHeadquarters holds "City, Country" in one column, split
# it into two columns with strsplit()
guilds_raw <- sqldf("select GuildID as guild_id,
                            GuildName as guild_name,
                            GuildHeadquarters as guild_headquarters
                       from `df.raw`
                      group by GuildID")
n.guilds <- nrow(guilds_raw)
guild_city <- vector("character", n.guilds)
guild_country <- vector("character", n.guilds)
for (i in 1:n.guilds) {
  parts <- unlist(strsplit(guilds_raw$guild_headquarters[i], ", "))
  guild_city[i] <- parts[1]
  guild_country[i] <- parts[2]
}
guilds <- data.frame(guild_id = guilds_raw$guild_id,
                     guild_name = guilds_raw$guild_name,
                     guild_city = guild_city,
                     guild_country = guild_country,
                     stringsAsFactors = FALSE)
if (!batch_insert(mydb, "guilds", guilds)) txnFailed <- TRUE

# 5. affineurs
affineurs <- sqldf("select AffineurID as affineur_id,
                           AffineurName as affineur_name,
                           AffineurEmail as affineur_email,
                           GuildID as guild_id
                      from `df.raw`
                     group by AffineurID")
if (!batch_insert(mydb, "affineurs", affineurs)) txnFailed <- TRUE

# 6. cave_type_specifications
cave_type_specifications <- sqldf("select CaveType as cave_type,
                                          CaveHumidityPct as cave_humidity_pct,
                                          CaveTempCelsius as cave_temp_celsius
                                     from `df.raw`
                                    group by CaveType")
if (!batch_insert(mydb, "cave_type_specifications", cave_type_specifications)) txnFailed <- TRUE

# 7. caves
caves <- sqldf("select CaveID as cave_id,
                       CaveName as cave_name,
                       CaveType as cave_type,
                       CaveCountry as cave_country,
                       CaveRegion as cave_region,
                       AffineurID as affineur_id
                  from `df.raw`
                 group by CaveID")
if (!batch_insert(mydb, "caves", caves)) txnFailed <- TRUE

# 8. batches
batches <- sqldf("select BatchID as batch_id,
                         ProductionDate as production_date,
                         BatchSizeLiters as batch_size_liters,
                         WheelsProduced as wheels_produced,
                         CoagulantType as coagulant_type,
                         CheeseTypeID as cheese_type_id,
                         SupplierID as supplier_id
                    from `df.raw`
                   group by BatchID")
if (!batch_insert(mydb, "batches", batches)) txnFailed <- TRUE

# 9. aging_records
# every row in df.raw is already one aging event, so no GROUP BY
aging_records <- sqldf("select BatchID as batch_id,
                               CaveID as cave_id,
                               AgingStartDate as aging_start_date,
                               AgingWeeks as aging_weeks,
                               TurningFrequencyPerWeek as turning_frequency_per_week,
                               WashingSolution as washing_solution,
                               FinalRindColor as final_rind_color,
                               QualityGrade as quality_grade
                          from `df.raw`")
if (!batch_insert(mydb, "aging_records", aging_records)) txnFailed <- TRUE

if (txnFailed) {
  dbExecute(mydb, "ROLLBACK")
  cat("Transaction rolled back - no data was saved.\n")
} else {
  dbExecute(mydb, "COMMIT")
  cat("Transaction committed.\n")
}

dbDisconnect(mydb)
cat("Load complete.\n")