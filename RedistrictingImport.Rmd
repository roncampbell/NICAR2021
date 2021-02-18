---
title: "Step by Step: Importing the PL 94 File"
author: "Ronald Campbell"
date: "2/18/2021"
output: html_document
---

The first major release from the 2020 Census will be the Redistricting file, also known as PL 94-171 for the 1975 law that required it. The file will detail population, race and housing counts down to the block level. Like everything else in the 2020 Census, it is months behind schedule and now is expected to be released around Sept. 30, six months late.

State and local politicians will use the file to draw legislative boundaries. Journalists, scholars and planners will use it to answer questions about local communities:

* Which areas have grown, shrunk or stagnated over the past decade?
* Is my state, county, city or neighborhood "minority majority"?
* Which neighborhoods are becoming more racially diverse?
* Which neighborhoods are becoming more segregated?
* Which neighborhoods are mostly renter- or mostly owner-occupied, and has that changed in the past decade?

If you have used the American Community Survey, you'll find the 2020 Census hard going at first. The raw files are big, and even the technical documentation can seem overwhelming. We'll walk you through it, using prototype files released by the Census Bureau.

Remember: These are prototypes -- not the real thing. The data comes from a dress rehearsal for the 2020 Census that the bureau conducted in Providence County, RI, in 2018. I also tested my script using the real 2010 data for Maryland; there have been minor changes from 2010 to the prototype outline for 2020.

The script I'm using here is in [R version 4.0.3](https://cran.r-project.org/). You could certainly do something similar in any flavor of SQL. I strongly recommend against trying this in Excel.

Before we get into the script, here are a few housekeeping notes:

The technical documentation for PL 94, though often dense, is invaluable. You can find it [here](https://www2.census.gov/programs-surveys/decennial/rdo/technical-documentation/2020Census/2018Prototype_PL94_171_TechDoc_v2.pdf ).

Second, I'll refer throughout to the prototype data file. That's available [here](https://www2.census.gov/programs-surveys/decennial/2020/program-management/data-product-planning/Prototype_Redistricting_File--PL_94-171/).

Third, if you want to find your region's 2010 data, you have some good options. Investigative Reporters & Editors hosts an [archive](http://census.ire.org/) of Summary File 1 for both 2010 and 2000. If you want to find PL 94 data from 2010, you can go back to the original source, the Census Bureau itself,  [here](https://www2.census.gov/census_2010/01-Redistricting_File--PL_94-171/).

The Census Bureau releases a separate PL 94 file for each state. "File" is a misnomer because there actually are four files -- a fixed-width geography file and three comma-separated variable (csv) data files. Each of the files, whether it is fixed-format or csv, ends with the two letter extension "pl".

One more thing: The files have no column headers. None, zip, nada.

The geography file contains more than 100 variables. If you're like me, you will only care about a handful of these vraiables. The most crucial by far is called "SUMLEV", short for Summary Level. This three-digit code tells whether a particular row describes the entire state, a county, a place (city or town), a tract or something else.

The first five variables in each of the data files also appear in the geography file: FILEID (always "PLST" in the PL 94 files), STUSAB (the state postal abbreviation), CHARITER, CIFSN and LOGRECNO. 

File 1 contains two tables -- 71 variables (yes, 71) on race and 73 on Hispanic status by race. With the five geographic variables at the front, that makes 149 variables in File 1.

File 2 contains three tables -- 71 variables on race for the voting age population (age 18 and over),  73 variables on Hispanic status by race for the voting age population) and 3 variables on housing (total housing units, total occupied and total vacant), making 152 variables in File 2.

File 3 is new this census. In addition to the five geographic variables it contains 10 columns on people living in group quarters -- jails, nursing homes, college dorms and military quarters, totaling 15 variables in File 3.

The geography file and Files 1 and 2 are, let's face it, obnoxiously long. Unless you're working on a Ph.D., you really don't need every column. You'll see below my attempts to deal with that.

```{r, warning=FALSE, message=FALSE}
library(tidyverse)
library(data.table)
```

First we import the geography file. I simply skipped many fields that I did not want by expanding the width to cover several fields simultaneously; that's why you see some widths of 32,  60 or even 125. It's also the reason some fields are named "Misc" or "Misc1." 

```{r, warning=FALSE, message=FALSE}
PL_94_2020_geo_RI <- 
  read_fwf("rigeo2018.pl",
                          fwf_widths(c(6,2,3,2,2,3,2,7,60,51,1,1,
                                       2,8,3,2,68,5,2,8,6,1,4,60,
                                       5,32,2,2,2,2,2,62,14,14,
                                       100,125,1,1,9,9,11,12,2,
                                       1,5),
                                     c("FILEID","STUSAB","SUMLEV",
                                       "Geovar","Geocomp","CHARITER",
                                       "CIFSN","LOGRECNO","Geoid",
                                       "Geocode","Region",
                                       "Division","StFIPS","StNS",
                                       "County","CoClass","Misc1",
                                       "Place","PlClass","PlNS",
                                       "Tract","BlkGrp","Block",
                                       "Misc2","CBSA","Misc3",
                                       "CD116","CD118","CD119",
                                       "CD120","CD121","Misc4",
                                       "AREALAND","AREAWATER",
                                       "BaseName","NAME",
                                       "FUNCSTAT","GCUNI",
                                       "POP100","HU100",
                                       "INTPTLAT","INTPTLON",
                                       "LSADC","PARTFLAG","UGA")))
```

Now we'll start importing the data files. I'm using the R data.table package because its select() function let's me choose which columns I want. The only fields that you  must take in each data file are the first five, the ones that link back to the geography file. After that, the choice is up to you.

I chose a handful of variables in Files 1 and 2 - just the basic racial and Hispanic counts -- and all of File 3. 

A note about selecting columns by number: Let's be honest -- we journalists suck at math. But if we want the first few columns in the second table in a 149-column file, and we know that there were five introductory columns followed by 71 columns in the first table, then it's 5 + 71 = 76, which means we want the, um, 77th column. Don't be embarassed; it took me a minute. 

```{r, warning=FALSE, message=FALSE}
PL94_2020_f1_RI <- 
  fread("ri000012018.pl",
        select = c(1:14, 77:87),
        col.names = c("FILEID","STUSAB","CHARITER","CIFSN",
                      "LOGRECNO","Totpop","Onerace","White",
                      "Black","AmInd","Asian","PacIsl","Other",
                      "MultiRace","Totpop1","Hispanic",
                      "NonHispanic","NHOnerace","NHWhite","NHBlack",
                      "NHAmInd","NHAsian","NHPacIsl","NHOther",
                      "NHMulti"))
```

File 2 is nearly identical to File 1, except that it contains information on the voting age population (people aged 18 and over). It also has a third table, this one on housing, with three columns - total, occupied and vacant. Except for the housing table, I handle it exactly like File 1.

This time, figuring out where the columns I want is easy. I know from simple math that there are 152 columns in the file, and I know the last three columns are the housing table.

```{r, warning=FALSE, message=FALSE}
PL94_2020_f2_RI <- 
  fread("ri000022018.pl",
        select = c(1:14, 77:87, 150:152),
        col.names = c("FILEID","STUSAB","CHARITER","CIFSN",
                      "LOGRECNO","Totpop18","Onerace18","White18",
                      "Black18","AmInd18","Asian18","PacIsl18",
                      "Other18","MultiRace18","Totpop1_18",
                      "Hispanic18","NonHispanic18","NHOneRace18",
                      "NHWhite18","NHBlack18","NHAmInd18",
                      "NHAsian18","NHPacIsl18","NHOther18",
                      "NHMulti18","HUTotal","HUOcc","HUVac"))
```

Finally, we'll grab File 3, which contains the group quarters table. This is the only file that we can't compare to 2010. It's also the easiest to import. We grab the whole thing.

```{r, warning=FALSE, message=FALSE}
PL94_2020_f3_RI <- 
  fread("ri000032018.pl",
        col.names = c("FILEID","STUSAB","CHARITER","CIFSN",
                     "LOGRECNO","GpQtrTot","InstPop","CorexAdult",
                     "CorexJuv","NursPop","OthInstPop","NonInstPop",
                     "StuHousing","Military","OthNonInst"))
```

That completes the import. I'll leave you to the fun part: Figuring out what it all means!