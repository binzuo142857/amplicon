# 绘制beta多样性 Constrained PCoA图+置信椭圆 Beta Constrained PCoA + stat ellipse
# 输入文件为距离矩阵，如QIIME/USEARCH生成距离矩阵文件
# This is the function named 'beta_cpcoa_dis'
# which draw Constrained PCoA scatter plot with stat ellipse, and reture a ggplot2 object
#
#' @title Plotting beta diversity scatter plot of Constrained PCoA
#' @description Input distance matrix and metadata, and manual set metadata column names.
#' ggplot2 show CPCoA with color and stat ellipse.
#' @param dis distance type for caucluate, default "bray_curtis", alternative "unifrac, unifrac_binary, jaccard、manhatten, euclidean".
#' @param metadata matrix or dataframe, including sampleID and groupID;
#' @param groupID column name for groupID.
#' @param ellipse stat ellipse, T or F.
#' @param label sample name showing, T or F.
#' @details
#' By default, returns beta CPCoA coordinate
#' The available diversity indices include the following:
#' \itemize{
#' \item{most used indices: bray_curtis, unifrac, unifrac_binary, jaccard}
#' \item{other used indices: manhatten, euclidean}
#' }
#' @return ggplot2 object.
#' @author Contact: Yong-Xin Liu \email{metagenome@@126.com}
#' @references
#'
#' Yong-Xin Liu, Yuan Qin, Tong Chen, Meiping Lu, Xubo Qian, Xiaoxuan Guo & Yang Bai.
#' A practical guide to amplicon and metagenomic analysis of microbiome data.
#' Protein Cell, 2020, DOI: \url{https://doi.org/10.1007/s13238-020-00724-8}
#'
#' Jingying Zhang, Yong-Xin Liu, Na Zhang, Bin Hu, Tao Jin, Haoran Xu, Yuan Qin, Pengxu Yan, Xiaoning Zhang, Xiaoxuan Guo, Jing Hui, Shouyun Cao, Xin Wang, Chao Wang, Hui Wang, Baoyuan Qu, Guangyi Fan, Lixing Yuan, Ruben Garrido-Oter, Chengcai Chu & Yang Bai.
#' NRT1.1B is associated with root microbiota composition and nitrogen use in field-grown rice.
#' Nature Biotechnology, 2019(37), 6:676-684, DOI: \url{https://doi.org/10.1038/s41587-019-0104-4}
#'
#' @seealso beta_cpcoa_dis
#' @examples
#' # example data: OTU table, rownames is OTU_xxx, colnames is SampleID
#' data(beta_bray_curtis)
#' # example data: metadata or design, include SampleID, genotype and site
#' data(metadata)
#' # Set 2 parameters: otu table, metadata, and distance type and groupID using default "bray_curtis" and "genotype"
#' beta_cpcoa_dis(beta_bray_curtis, metadata)
#' # Set 3 parameters: distance matrix, metadata, and groupID as "site"
#' beta_cpcoa_dis(beta_bray_curtis, metadata, "site")
#' # Set 5 parameters: distance matrix, metadata, and groupID as using "genotype", open stat elipse and sample label
#' beta_cpcoa_dis(beta_bray_curtis, metadata, groupID = "genotype", ellipse = T, label = T)
#' @export



beta_cpcoa_dis <- function(distance_mat, metadata, groupID = "genotype", ellipse = T, label = F) {

  # 依赖关系检测与安装
  p_list = c("ggplot2", "vegan", "ggrepel")
  for(p in p_list){
    if (!requireNamespace(p)){
    install.packages(p)}
    library(p, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)}

  # 测试默认参数
  # distance_mat = beta_bray_curtis
  # data(metadata)
  # groupID = "genotype"
  # ellipse = T
  # label = F

  # 交叉筛选
  idx = rownames(metadata) %in% colnames(distance_mat)
  metadata = metadata[idx,]
  distance_mat = distance_mat[rownames(metadata), rownames(metadata)]

  # 提取样品组信息,默认为group可指定
  sampFile = as.data.frame(metadata[, groupID],row.names = row.names(metadata))
  colnames(sampFile)[1] = "group"

  if (length(unique(sampFile$group)) > 2){

  # 函数提取CCA中主要结果
  variability_table = function(cca){
    chi = c(cca$tot.chi, cca$CCA$tot.chi, cca$CA$tot.chi)
    variability_table = cbind(chi, chi/chi[1])
    colnames(variability_table) = c("inertia", "proportion")
    rownames(variability_table) = c("total", "constrained", "unconstrained")
    return(variability_table)
  }

  # Constrained analysis OTU table by genotype
  capscale.gen = capscale(as.dist(distance_mat) ~ group, data=sampFile, add=F, sqrt.dist=T)

  # ANOVA-like permutation analysis
  perm_anova.gen = anova.cca(capscale.gen, permutations = 1000, parallel = 4)

  # generate variability tables and calculate confidence intervals for the variance
  var_tbl.gen = variability_table(capscale.gen)
  eig = capscale.gen$CCA$eig
  variance = var_tbl.gen["constrained", "proportion"]
  p.val = perm_anova.gen[1, 4]

  # extract the weighted average (sample) scores
  points = as.data.frame(capscale.gen$CCA$wa)
  points = cbind(sampFile, points[rownames(points),])

  # plot CPCo 1 and 2
  p = ggplot(points, aes(x=CAP1, y=CAP2, color=group)) + geom_point(alpha=.7, size=2) +
    labs(x=paste("CPCo 1 (", format(100 * eig[1] / sum(eig), digits=4), "%)", sep=""),
         y=paste("CPCo 2 (", format(100 * eig[2] / sum(eig), digits=4), "%)", sep=""), color=groupID) +
    ggtitle(paste(format(100 * variance, digits=3), " % of variance; P = ",format(p.val, digits=2),sep="")) +
    theme_classic() + theme(text=element_text(family="sans", size=7))
  # 是否添加置信椭圆
  if (ellipse == T){
    p = p + stat_ellipse(level=0.68)
  }
  # 是否显示样本标签
  if (label == T){
    p = p + geom_text_repel(label = paste(rownames(points)), colour="black", size=3)
  }
  p
  }else{
    print("Selected groupID column at least have 3 groups!!!")
  }
}
