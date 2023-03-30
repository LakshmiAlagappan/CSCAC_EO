# CSCAC_EO
CSCAC is part of my industrial PhD thesis in NUS School of Computing. CSCAC (Class-specific Correction and Classification) is a framework to perform both standardization of spectra to mitigate batch effects as well as classification of samples accurately. Here, we show the application of CSCAC on an edible oil dataset.

1. Download the repository
2. Models_Results folder: Some of the intermediate results have been stored to save the users time while running the code for illustration.
    -> Note that CCA and CSCAC (CCA) intermediate results are not stored in github because the files are too large for github
3. Data folder: Contains NIR spectra belonging to 5 different batches and 14 different oil types
4. helper.R: Contains all the helper and auxilary functions.
5. preprocessing.R: Contains the steps to preprocess the spectra and split the dataset into training, transfer and testing spectra 
7. Run main_flow.R 
