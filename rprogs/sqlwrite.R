# ================================================================================================ #
# Description: This function was picked up from RODBC:::sqlwrite and edited to fix a recurring bug
#   in the original code, that prevents us from writing tables into schemas with a hypen("-") character
#   in the schemaname. We tried to use square brackets around the schemaname to work around this issue,
#   but then the RODBC::sqlColumns function fails as it tries to check if the table already exists in
#   exists in the database; it is unable to match the [schemaname] in the database (due to the square 
#   brackets). As a fix, we added "gsub" code to strip out the square brackets from tablename when the 
#   RODBC::sqlColumns function is invoked. The fix has been applied on line 33, 46, 80. In addition, all
#   unexported (internal) RODBC function calls have been appended with "RODBC:::" for the call to work from
#   outside the RODBC namespace. After compiling the function, use "assignNameSpace" command to replace the
#   RODBC sqlwrite function with this function. 
#
# Editor: V Benny
#
# Dependencies:
# RODBC
#
# Notes:
#   Has only been tested with fast=FALSE so far. Make sure this is how the sqlSave invocation is done
#   from your code.
#   Example: 
#     sqlSave(conn, linked_rep_weights, tablename = "[DL-MAA2016-15].of_gss_calibrated_weights", verbose = TRUE, 
#         fast=FALSE)
#
# History: 
# 04 Oct 2017 SIA v1
# ================================================================================================ #
sqlwrite <- function (channel, tablename, mydata, test = FALSE, fast = TRUE, 
                      nastring = NULL, verbose = FALSE) 
{
  if (!RODBC:::odbcValidChannel(channel)) 
    stop("first argument is not an open RODBC channel")
  colnames <- as.character(RODBC:::sqlColumns(channel, gsub("\\[|\\]","", tablename))[4L][, 
                                                                      1L])
  colnames <- RODBC:::mangleColNames(colnames)
  cnames <- paste(RODBC:::quoteColNames(channel, colnames), collapse = ", ")
  dbname <- RODBC:::quoteTabNames(channel, tablename)
  if (!fast) {
    for (i in seq_along(mydata)) if (is.logical(mydata[[i]])) 
      mydata[[i]] <- as.character(mydata[[i]])
    data <- as.matrix(mydata)
    if (nchar(enc <- attr(channel, "encoding")) && is.character(data)) 
      data <- iconv(data, to = enc)
    colnames(data) <- colnames
    cdata <- sub("\\([[:digit:]]*\\)", "", RODBC:::sqlColumns(channel, 
                                                              gsub("\\[|\\]","", tablename))[, "DATA_TYPE"])
    tdata <- RODBC:::sqlTypeInfo(channel)
    nr <- match(cdata, tdata[, 2L])
    tdata <- as.matrix(tdata[nr, 4:5])
    tdata[is.na(nr), ] <- "'"
    for (cn in seq_along(cdata)) {
      td <- as.vector(tdata[cn, ])
      if (is.na(td[1L])) 
        next
      if (identical(td, rep("'", 2L))) 
        data[, cn] <- gsub("'", "''", data[, cn])
      data[, cn] <- paste(td[1L], data[, cn], td[2L], 
                          sep = "")
    }
    data[is.na(mydata)] <- if (is.null(nastring)) 
      "NULL"
    else nastring[1L]
    for (i in 1L:nrow(data)) {
      query <- paste("INSERT INTO", dbname,
                     "(", cnames, 
                     ") VALUES (", paste(data[i, colnames], collapse = ", "), 
                     ")")
      if (verbose) 
        cat("Query: ", query, "\n", sep = "")
      if (RODBC:::odbcQuery(channel, query) < 0) 
        return(-1L)
    }
  }
  else {
    query <- paste("INSERT INTO", dbname, 
                   "(", cnames, ") VALUES (", 
                   paste(rep("?", ncol(mydata)), collapse = ","), ")")
    if (verbose) 
      cat("Query: ", query, "\n", sep = "")
    coldata <- RODBC:::sqlColumns(channel, gsub("\\[|\\]","", tablename))[c(4L, 5L, 
                                                        7L, 9L)]
    if (any(is.na(m <- match(colnames, coldata[, 1])))) 
      return(-1L)
    if (any(notOK <- (coldata[, 3L] == 0L))) {
      types <- coldata[notOK, 2]
      tdata <- RODBC:::sqlTypeInfo(channel)
      coldata[notOK, 3L] <- tdata[match(types, tdata[, 
                                                     2L]), 3L]
    }
    if (RODBC:::odbcUpdate(channel, query, mydata, coldata[m, ], 
                           test = test, verbose = verbose, nastring = nastring) < 
        0) 
      return(-1L)
  }
  print("Edited sqlwrite function executed.")
  return(invisible(1L))
}
