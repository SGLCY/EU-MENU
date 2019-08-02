# EU-MENU

This repository holds some scripts related to the EU-MENU data    

## Map FoodEx2 to FoodEx1 categorisation

The script _Map_fdx2_fdx1-EFSA.R_ maps the consumption data from the FoodEx2 to the FoodEx1 food classification system.    

To use the script you will need the following:    

*EU MENU files*

* CONSUMPTION.xlsx - The consumption data
* SUBJECTS.xlsx    - The subjects information
* Foodex1.xlsx     - The foodEx1 food categorisation mapping file. (you can get this from this repository)

*EFSA catalogue browser data*

* MTX_10.xlsx - You get this from the (updated .ecf file (catalog) and the new Catalogue Browser)

   To get the MTX_10.xlsx file follow these steps [a very rough guide]

   1. Downloaded the latest version of [EFSA Catalogues Browser 1.2.5](https://github.com/openefsa/catalogue-browser/wiki/External-EFSA's-users)

   2. Downloaded the latest .ecf file [MTX_FULL_10_0.ecf  - 07/02/2019](https://github.com/openefsa/catalogue-browser/wiki/Use-the-tool-without-DCF-account)
   (keep an eye for newer versions)
   
   Then within the catalogue browser

   NB:if a previous cataloque is loaded, then you have to first `Close cataloque` from the File menu    
   a) FILE -> IMPORT the .ecf file you have downloaded in Step 2
   b) FILE -> Open cataloque, and select the catalogue you have just installed
   c) Select  "Exposure Hierarchy" in the middle panel
   d) Tools -> Export Excel

*The following R libraries*

* tidyverse - for data wrangling
* readxl    - read _.xlsx_ files from disk
* writexl   - write _.xlsx_ files on disk

## Create ImproRisk Templates

The script _Create ImproRisk Templates - EU-MENU.R_ creates the templates for [ImproRisk]([!http://www.improrisk.com/) tool

It creates 2 templates:    

a) General Population - consumption of pregnant women is removed
b) Pregnant women


You will need the following:

a) a vector of the pregnant women EFSA ids (ORSUBCODE) named `preg_women_ids`
b) SUBJECTS.xlsx - the EFSA SUBJECTS file
c) CONSUMPTION MAPPED file from fdx2 to fdx1 for all subjects. This is the file that you have created using the _Map_fdx2_fdx1-EFSA.R_ script above (or using your own way)

In the script you can find more the step by step process and explanations how it works


