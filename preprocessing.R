nov = "4"
# Batch 1 (Primary Batch)
b1 = readRDS(paste0(rds_data_dir,"/Batch_1.rds")) #Reading Raw data
b1_tr_te = split_transfer_test(b1, "class", nov, 4) #Splitting into transfer and test while keep 14 exclusively in test
b1_train_pp = correct_bsc(trim(b1_tr_te[[1]],1,1751)) #preprocessing train/transfer
b1_test_pp = correct_bsc(trim(b1_tr_te[[2]],1,1751)) #preprocessing test

# Batch 2 (Secondary Batch)
b2 = readRDS(paste0(rds_data_dir,"/Batch_2.rds"))
b2_tr_te = split_transfer_test(b2, "class", nov, 4)
b2_transfer_pp = correct_bsc(trim(b2_tr_te[[1]],1,1751))
b2_test_pp = correct_bsc(trim(b2_tr_te[[2]],1,1751))

# Batch 3 (Secondary Batch)
b3 = readRDS(paste0(rds_data_dir,"/Batch_3.rds"))
b3_tr_te = split_transfer_test(b3, "class", nov, 4)
b3_transfer_pp = correct_bsc(trim(b3_tr_te[[1]],1,1751))
b3_test_pp = correct_bsc(trim(b3_tr_te[[2]],1,1751))

# Batch 4 (Secondary Batch)
b4 = readRDS(paste0(rds_data_dir,"/Batch_4.rds"))
b4_tr_te = split_transfer_test(b4, "class", nov, 4)
b4_transfer_pp = correct_bsc(interpolate(trim(b4_tr_te[[1]],1102,2919),b1_train_pp))
b4_test_pp = correct_bsc(interpolate(trim(b4_tr_te[[2]],1102,2919),b1_train_pp))

# Batch 5 (Secondary Batch)
b5 = readRDS(paste0(rds_data_dir,"/Batch_5.rds"))
b5_tr_te = split_transfer_test(b5, "class", nov, 4)
b5_transfer_pp = correct_bsc(interpolate(trim(b5_tr_te[[1]],1102,2919),b1_train_pp))
b5_test_pp = correct_bsc(interpolate(trim(b5_tr_te[[2]],1102,2919),b1_train_pp))

transfer_all = list(b1_train_pp,b2_transfer_pp, b3_transfer_pp, 
                    b4_transfer_pp, b5_transfer_pp)
test_all = list(b1_test_pp,b2_test_pp, b3_test_pp, b4_test_pp, b5_test_pp)

saveRDS(transfer_all, paste0(model_results_dir,"/transfer_all.rds"))
saveRDS(test_all, paste0(model_results_dir,"/test_all.rds"))
