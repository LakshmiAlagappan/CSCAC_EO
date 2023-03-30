
# Set the working directory to be the location where the project folder is saved
wdir <- paste0("C:/Users/alagl/OneDrive - Wilmar International Limited/Desktop/IPP Research/Projects/CSCAC_EO")
setwd(wdir)
# Directory where data for the project is stored
rds_data_dir = paste0(wdir,"/Data")
# directory where the model results will be stored
model_results_dir = paste0(wdir, "/Models_Results")

dir.create(plot_results_dir)
dir.create(model_results_dir)


source("C:/Users/alagl/OneDrive - Wilmar International Limited/Desktop/IPP Research/Projects/helpers.R")


###### Splitting of the dataset ###### 

# Primary batch B1, Secondary batch B2,3,4,5

# transfer_all and test_all are lists of length 5. 
# transfer_all[[1]] is the training spectra from batch 1
# transfer_all[[x]] contains transfer spectra from batch x
# test_all[[x]] contains testing spectra from batch x

#source("./preprocessing.R")
transfer_all = readRDS(paste0(model_results_dir,"/transfer_all.rds"))
test_all = readRDS(paste0(model_results_dir,"/test_all.rds"))

###### Models #######

dir.create(paste0(model_results_dir, "/Simple_PDS"))
dir.create(paste0(model_results_dir, "/Simple_CCA"))
dir.create(paste0(model_results_dir, "/Simple_PCPDS"))
dir.create(paste0(model_results_dir, "/CSPDS"))
dir.create(paste0(model_results_dir, "/CSCCA"))
dir.create(paste0(model_results_dir, "/CSPCPDS"))

tr_i = 1
te_i = 3
p_name = paste0("Tr_",tr_i, "_Te_", te_i)
train = transfer_all[[tr_i]]
tst = test_all[[te_i]]
trans = transfer_all[[te_i]]
ans_df = data.frame()
###### PCLDA ######
pcs_num = 4
pclda_res = build_test_pclda(train, tst, "class", pcs_num,FALSE)
raw_df = rbind(train, tst[tst$class != "Novel",])
pclda_metrics = calc_indexes(raw_df,"Raw", raw_df$batch, raw_df$class)
mac_pclda = pclda_res$mac
nac_pclda = pclda_res$nac
ans_df = rbind(ans_df, data.frame("Method" = "PCLDA", "MCA" = mac_pclda, "NCA" = nac_pclda))

###### SIMCA ######
simca_comp = 1
simca_res = build_test_simca(train, tst, "class", simca_comp)
raw_df = rbind(train, tst[tst$class != "Novel",])
simca_metrics = calc_indexes(raw_df,"SIMCA_Raw", raw_df$batch, raw_df$class)
mac_simca = simca_res$mac
nac_simca = simca_res$nac
ans_df = rbind(ans_df, data.frame("Method" = "SIMCA", "MCA" = mac_simca, "NCA" = nac_simca))

###### PDS-PCLDA ######
fname = paste0(model_results_dir, "/Simple_PDS/sim_pds_", p_name, ".rds")
if (file.exists(fname)) {
  sim_pds_mod = readRDS(fname)
}else{
  sim_pds_mod = build_pds_model(train, trans, 3, 2, "class", FALSE)
  saveRDS(sim_pds_mod, fname)
}
sim_pds_adj = test_pds_model(tst, sim_pds_mod$model, FALSE)
pds_df = rbind(train, sim_pds_adj[sim_pds_adj$class != "Novel",])
pds_pclda_metrics = calc_indexes(pds_df,"Sim_PDS",pds_df$batch, pds_df$class)
sim_pds_pclda = build_test_pclda(train, sim_pds_adj, "class", pcs_num,FALSE)
mac_pds_pclda = sim_pds_pclda$mac
nac_pds_pclda = sim_pds_pclda$nac
ans_df = rbind(ans_df, data.frame("Method" = "PDS-PCLDA", "MCA" = mac_pds_pclda, "NCA" = nac_pds_pclda))

####### PDS-SIMCA ######
fname = paste0(model_results_dir, "/Simple_PDS/sim_pds_", p_name, ".rds")
if (file.exists(fname)) {
  sim_pds_mod = readRDS(fname)
}else{
  sim_pds_mod = build_pds_model(train, trans, 3, 2, "class", FALSE)
  saveRDS(sim_pds_mod, fname)
}
sim_pds_adj = test_pds_model(tst, sim_pds_mod$model, FALSE)
pds_df = rbind(train, sim_pds_adj[sim_pds_adj$class != "Novel",])
pds_simca_metrics = calc_indexes(pds_df,"SIMCA_Sim_PDS",pds_df$batch, pds_df$class)
sim_pds_simca = build_test_simca(train, sim_pds_adj, "class", simca_comp)
mac_pds_simca = sim_pds_simca$mac
nac_pds_simca = sim_pds_simca$nac
ans_df = rbind(ans_df, data.frame("Method" = "PDS-SIMCA", "MCA" = mac_pds_simca, "NCA" = nac_pds_simca))

####### CSCAC (PDS) ######
# A: Modelling Step
main_pop_model = build_pop_classification_model(train, "class")
fname = paste0(model_results_dir, "/CSPDS/cspds_", p_name, ".rds")
if (file.exists(fname)) {
  cspds_mod = readRDS(fname)
}else{
  # A: Modelling Step
  cspds_mod = build_cspds_model(train, trans, 3, 2, lst = "class", FALSE)
  saveRDS(cspds_mod, fname)
}
fname = paste0(model_results_dir, "/CSPDS/Adj_cspds", p_name, ".rds")
if (file.exists(fname)){
  cspds_adj = readRDS(fname)
}else{
  # B: Transfer-Classification Step
  cspds_adj = test_cspds_model(tst, cspds_mod$model, main_pop_model, FALSE)
  saveRDS(cspds_adj, fname)
}
print(cspds_adj$res)
depth_sc_here = 2#as.numeric(readline(prompt = "Enter Depth Threshold: "))
# C: Misclassification Detection Step
cspds_res = test_misclassification_detection(cspds_adj, main_pop_model, depth_sc_here,plot_flag =  FALSE)
mac_cspds = cspds_res$mac
nac_cspds = cspds_res$nac
cspds_df = rbind(train, cspds_adj$adj_test_df[cspds_adj$adj_test_df$class != "Novel",])
cspds_metrics = calc_indexes(cspds_df,"CSPDS", cspds_df$batch, cspds_df$class)
ans_df = rbind(ans_df, data.frame("Method" = "CSCAC (PDS)", "MCA" = mac_cspds, "NCA" = nac_cspds))

####### CCA-PCLDA ######
fname = paste0(model_results_dir, "/Simple_CCA/sim_cca_", p_name, ".rds")
if (file.exists(fname)) {
  sim_cca_mod = readRDS(fname)
}else{
  sim_cca_mod = build_cca_model(train, trans, 0, "class", FALSE)
  saveRDS(sim_cca_mod, fname)
}
sim_cca_adj = test_cca_model(tst, sim_cca_mod$model, FALSE)
cca_df = rbind(train, sim_cca_adj[sim_cca_adj$class != "Novel",])
cca_pclda_metrics = calc_indexes(cca_df,"Sim_CCA",cca_df$batch, cca_df$class)
sim_cca_pclda = build_test_pclda(train, sim_cca_adj, "class", pcs_num, FALSE)
mac_cca_pclda = sim_cca_pclda$mac
nac_cca_pclda = sim_cca_pclda$nac
ans_df = rbind(ans_df, data.frame("Method" = "CCA-PCLDA", "MCA" = mac_cca_pclda, "NCA" = nac_cca_pclda))

###### CCA-SIMCA ######
fname = paste0(model_results_dir, "/Simple_CCA/sim_cca_", p_name, ".rds")
if (file.exists(fname)) {
  sim_cca_mod = readRDS(fname)
}else{
  sim_cca_mod = build_cca_model(train, trans, 0, "class", FALSE)
  saveRDS(sim_cca_mod, fname)
}
sim_cca_adj = test_cca_model(tst, sim_cca_mod$model, FALSE)
cca_df = rbind(train, sim_cca_adj[sim_cca_adj$class != "Novel",])
cca_simca_metrics = calc_indexes(cca_df,"SIMCA_Sim_CCA", cca_df$batch, cca_df$class)
sim_cca_simca = build_test_simca(train, sim_cca_adj, "class", simca_comp)
mac_cca_simca = sim_cca_simca$mac
nac_cca_simca = sim_cca_simca$nac
ans_df = rbind(ans_df, data.frame("Method" = "CCA-SIMCA", "MCA" = mac_cca_simca, "NCA" = nac_cca_simca))

###### CSCAC (CCA) ######
# A: Modelling Step
main_pop_model = build_pop_classification_model(train, "class")
fname = paste0(model_results_dir, "/CSCCA/cscca_", p_name, ".rds")
if (file.exists(fname)){
  cscca_mod = readRDS(fname)
}else{
  # A: Modelling Step
  cscca_mod = build_cscca_model(train, trans, 0, "class", FALSE)
  saveRDS(cscca_mod, fname)
}
fname = paste0(model_results_dir, "/CSCCA/Adj_cscca_", p_name, ".rds")
if (file.exists(fname)){
  cscca_adj = readRDS(fname)
}else{
  # B: Transfer-Classification Step
  cscca_adj = test_cscca_model(tst, cscca_mod$model, main_pop_model,FALSE)
  saveRDS(cscca_adj, fname)
}
print(cscca_adj$res)
depth_sc_here = 2#as.numeric(readline(prompt = "Enter Depth Threshold: "))
# C: Misclassification Detection Step
cscca_res = test_misclassification_detection(cscca_adj, main_pop_model, depth_sc_here, FALSE)
mac_cscca = cscca_res$mac
nac_cscca = cscca_res$nac
cscca_df = rbind(train, cscca_adj$adj_test_df[cscca_adj$adj_test_df$class != "Novel",])
cscca_metrics = calc_indexes(cscca_df,"CSCCA", cscca_df$batch, cscca_df$class)
ans_df = rbind(ans_df, data.frame("Method" = "CSCAC (CCA)", "MCA" = mac_cscca, "NCA" = nac_cscca))

###### PCPDS-PCLDA ######
fname = paste0(model_results_dir, "/Simple_PCPDS/sim_pcpds_", p_name, ".rds")
if (file.exists(fname)) {
  sim_pcpds_mod = readRDS(fname)
}else{
  sim_pcpds_mod = build_pcpds_model(train, trans, 1, 1, 8,"class", FALSE)
  saveRDS(sim_pcpds_mod, fname)
}
sim_pcpds_adj = test_pcpds_model(tst, sim_pcpds_mod$model, FALSE)
pcpds_df = rbind(train, sim_pcpds_adj[sim_pcpds_adj$class != "Novel",])
pcpds_pclda_metrics = calc_indexes(pcpds_df,"Sim_PCPDS",pcpds_df$batch, pcpds_df$class)
sim_pcpds_pclda = build_test_pclda(train, sim_pcpds_adj, "class", pcs_num,FALSE)
mac_pcpds_pclda = sim_pcpds_pclda$mac
nac_pcpds_pclda = sim_pcpds_pclda$nac
ans_df = rbind(ans_df, data.frame("Method" = "PCPDS-PCLDA", "MCA" = mac_pcpds_pclda, "NCA" = nac_pcpds_pclda))

###### PCPDS-SIMCA ######
fname = paste0(model_results_dir, "/Simple_PCPDS/sim_pcpds_", p_name, ".rds")
if (file.exists(fname)) {
  sim_pcpds_mod = readRDS(fname)
}else{
  sim_pcpds_mod = build_pcpds_model(train, trans, 1, 1, 8,"class", FALSE)
  saveRDS(sim_pcpds_mod, fname)
}
sim_pcpds_adj = test_pcpds_model(tst, sim_pcpds_mod$model, FALSE)
pcpds_df = rbind(train, sim_pcpds_adj[sim_pcpds_adj$class != "Novel",])
pcpds_simca_metrics = calc_indexes(pcpds_df,"SIMCA_Sim_PCPDS", pcpds_df$batch, pcpds_df$class)
sim_pcpds_simca = build_test_simca(train, sim_pcpds_adj, "class", simca_comp)
mac_pcpds_simca = sim_pcpds_simca$mac
nac_pcpds_simca = sim_pcpds_simca$nac
ans_df = rbind(ans_df, data.frame("Method" = "PCPDS-SIMCA", "MCA" = mac_pcpds_simca, "NCA" = nac_pcpds_simca))

###### CSCAC (PCPDS) ######
# A: Modelling Step
main_pop_model = build_pop_classification_model(train, "class")
fname = paste0(model_results_dir, "/CSPCPDS/cspcpds_", p_name, ".rds")
if (file.exists(fname)){
  cspcpds_mod = readRDS(fname)
}else{
  # A: Modelling Step
  cspcpds_mod = build_cspcpds_model(train, trans, 1,1,8,"class", FALSE)
  saveRDS(cspcpds_mod, fname)
}
fname = paste0(model_results_dir, "/CSPCPDS/Adj_cspcpds_", p_name, ".rds")
if (file.exists(fname)){
  cspcpds_adj = readRDS(fname)
}else{
  # B: Transfer-Classification Step
  cspcpds_adj = test_cspcpds_model(tst, cspcpds_mod$model, main_pop_model, FALSE)
  saveRDS(cspcpds_adj, fname)
}
print(cspcpds_adj$res)
depth_sc_here = 2#as.numeric(readline(prompt = "Enter Depth Threshold: "))
# C: Misclassification Detection Step
cspcpds_res = test_misclassification_detection(cspcpds_adj, main_pop_model, depth_sc_here, FALSE)
mac_cspcpds = cspcpds_res$mac
nac_cspcpds = cspcpds_res$nac
cspcpds_df = rbind(train, cspcpds_adj$adj_test_df[cspcpds_adj$adj_test_df$class != "Novel",])
cspcpds_metrics = calc_indexes(cspcpds_df,"CSPCPDS",cspcpds_df$batch, cspcpds_df$class)
ans_df = rbind(ans_df, data.frame("Method" = "CSCAC (PCPDS)", "MCA" = mac_cspcpds, "NCA" = nac_cspcpds))


###### MCA and NCA Table ######
ans_df$MCA = round(ans_df$MCA,2)
print(ans_df)

###### Standardization Plots ######
c5 = c("#073f9e", #Blue
         "#ad0400",  #Red
         "#721e94",  #Purple
         "#245c00",  #Green
         "#aa4500")  #Orange 


Tr_Te = rbind(train, tst)
Tr_Te_pca = prcomp(Tr_Te$NIR, TRUE)
p1 = plot_pca(Tr_Te_pca, 1, 2, FALSE,c5, Tr_Te$batch, Tr_Te$class, c("Before Correction", "Batch", "Class"))+theme_Publication(base_size = 18)+  ggplot2::theme(legend.position = "bottom", legend.direction = "horizontal")

name = "Aft Correction by CSCAC(PCPDS)"
Tr_adjTe = cspcpds_df
Tr_adjTe_pca = prcomp(Tr_adjTe$NIR, TRUE)
p2 = plot_pca(Tr_adjTe_pca, 1, 2, FALSE,c5, Tr_adjTe$batch, Tr_adjTe$class, c(name, "Batch", "Class"))+theme_Publication(base_size = 18)+  ggplot2::theme(legend.position = "bottom", legend.direction = "horizontal")

ggpubr::ggarrange(p1,p2,ncol= 2, common.legend = TRUE)

####### Standardization Metrics ######
mat = matrix(nrow = 1,ncol = 7)
rownames(mat) = p_name
colnames(mat) = c("RAW", "PDS", "CSCAC (PDS)", "CCA", "CSCAC (CCA)", "PCPDS", "CSCAC (PCPDS)")
get_metrics = function(metind, pcn){
  mat[,1] = pclda_metrics[pclda_metrics$PC == pcn,metind]
  mat[,2] = pds_pclda_metrics[pds_pclda_metrics$PC == pcn,metind]
  mat[,3] = cspds_metrics[cspds_metrics$PC == pcn,metind]
  mat[,4] = cca_pclda_metrics[cca_pclda_metrics$PC == pcn,metind]
  mat[,5] = cscca_metrics[cscca_metrics$PC == pcn,metind]
  mat[,6] = pcpds_pclda_metrics[pcpds_pclda_metrics$PC == pcn,metind]
  mat[,7] = cspcpds_metrics[cspcpds_metrics$PC == pcn,metind]
  return(t(mat))
}
pcn = "1"
a = get_metrics("Batch Contrib", pcn)
b = get_metrics("WCSS", pcn)
c = get_metrics("BCSS", pcn)
d = get_metrics("B/W", pcn)
df = round(data.frame(a,b,c,d),2)
colnames(df) = c("Batch Contrib", "WCSS", "BCSS", "BCSS/WCSS")
print(paste0("PC ", pcn, ": Metrics for training spectra from B", tr_i,
             " and adjusted testing spectra from B", te_i))
print(df)

