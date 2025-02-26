#' Scatter plot
#'
#' Scatter plot supporting groups.
#'
#' @docType methods
#' @name ScatterView
#' @rdname ScatterView
#' @aliases ScatterView
#'
#' @param data Data frame.
#' @param x A character, specifying the x-axis.
#' @param y A character, specifying the y-axis.
#' @param label An integer or a character specifying the column used as the label, default value is 0 (row names).
#'
#' @param model One of "none" (default), "ninesquare", "volcano", and "rank".
#' @param x_cut An one or two-length numeric vector, specifying the cutoff used for x-axis.
#' @param y_cut An one or two-length numeric vector, specifying the cutoff used for y-axis.
#' @param slope A numberic value indicating slope of the diagonal cutoff.
#' @param intercept A numberic value indicating intercept of the diagonal cutoff.
#' @param auto_cut Boolean or numeric, specifying how many standard deviation will be used as cutoff.
#' @param auto_cut_x Boolean or numeric, specifying how many standard deviation will be used as cutoff on x-axis.
#' @param auto_cut_y Boolean or numeric, specifying how many standard deviation will be used as cutoff on y-axis
#' @param auto_cut_diag Boolean or numeric, specifying how many standard deviation will be used as cutoff on diagonal.
#'
#' @param groups A character vector specifying groups. Optional groups include "top", "mid", "bottom",
#' "left", "center", "right", "topleft", "topcenter", "topright", "midleft", "midcenter",
#' "midright", "bottomleft", "bottomcenter", "bottomright".
#' @param group_col A vector of colors for specified groups.
#' @param groupnames A vector of group names to show on the legend.
#'
#' @param label.top Boolean, specifying whether label top hits.
#' @param top Integer, specifying the number of top terms in the groups to be labeled.
#' @param toplabels Character vector, specifying terms to be labeled.
#'
#' @param display_cut Boolean, indicating whether display the dashed line of cutoffs.
#'
#' @param color A character, specifying the column name of color in the data frame.
#' @param shape A character, specifying the column name of shape in the data frame.
#' @param size A character, specifying the column name of size in the data frame.
#' @param alpha A numeric, specifying the transparency of the dots.
#'
#' @param main Title of the figure.
#' @param xlab Title of x-axis
#' @param ylab Title of y-axis.
#' @param legend.position Position of legend, "none", "right", "top", "bottom", or
#' a two-length vector indicating the position.
#' @param ... Other available parameters in function 'geom_text_repel'.
#'
#' @return An object created by \code{ggplot}, which can be assigned and further customized.
#'
#' @author Wubing Zhang
#'
#' @examples
#' file3 = file.path(system.file("extdata", package = "MAGeCKFlute"),
#' "testdata/mle.gene_summary.txt")
#' dd = ReadBeta(file3)
#' ScatterView(dd, x = "Pmel1_Ctrl", y = "Pmel1", label = "Gene",
#' auto_cut = 1, groups = "topright", top = 5, display_cut = TRUE)
#' ScatterView(dd, x = "Pmel1_Ctrl", y = "Pmel1", label = "Gene",
#' auto_cut = 2, model = "ninesquare", top = 5, display_cut = TRUE)
#'
#' @import ggplot2 ggrepel
#' @export
#'
#'

ScatterView<-function(data, x = "x", y = "y", label = 0,
                      model = c("none", "ninesquare", "volcano", "rank")[1],
                      x_cut = NULL, y_cut = NULL, slope = 1, intercept = NULL,
                      auto_cut = FALSE, auto_cut_x = auto_cut,
                      auto_cut_y = auto_cut, auto_cut_diag = auto_cut,
                      groups = NULL, group_col = NULL, groupnames = NULL,
                      label.top = TRUE, top = 0, toplabels = NULL,
                      display_cut = FALSE, color = NULL, shape = 16, size = 1, alpha = 0.6,
                      main = NULL, xlab = x, ylab = y, legend.position = "none", ...){
  requireNamespace("ggplot2", quietly=TRUE) || stop("need ggplot package")
  requireNamespace("ggrepel", quietly=TRUE) || stop("need ggrepel package")
  data = as.data.frame(data, stringsAsFactors = FALSE)
  data = data[!(is.na(data[,x])|is.na(data[,y])), ]
  ## Add label column in the data frame.
  if(label==0) data$Label = rownames(data)
  else data$Label = as.character(data[, label])

  ## Compute the cutoff used for each dimension.
  model = tolower(model)
  if(model == "ninesquare"){
    if(length(x_cut)==0)
      x_cut = c(-CutoffCalling(data[,x], 2), CutoffCalling(data[,x], 2))
    if(length(y_cut)==0)
      y_cut = c(-CutoffCalling(data[,y], 2), CutoffCalling(data[,y], 2))
    if(length(intercept)==0)
      intercept = c(-CutoffCalling(data[,y]-slope*data[,x], 2),
                    CutoffCalling(data[,y]-slope*data[,x], 2))
  }
  if(model == "volcano"){
    if(length(x_cut)==0)
      x_cut = c(-CutoffCalling(data[,x], 2), CutoffCalling(data[,x], 2))
    if(length(y_cut)==0) y_cut = -log10(0.05)
  }
  if(model == "rank"){
    if(length(x_cut)==0)
      x_cut = c(-CutoffCalling(data[,x], 2), CutoffCalling(data[,x], 2))
  }
  ## Update the cutoff when user set the auto_cut option
  if(auto_cut_x)
    x_cut = c(-CutoffCalling(data[,x], auto_cut_x), CutoffCalling(data[,x], auto_cut_x))
  if(auto_cut_y)
    y_cut = c(-CutoffCalling(data[,y], auto_cut_y), CutoffCalling(data[,y], auto_cut_y))
  if(auto_cut_diag)
    intercept = c(-CutoffCalling(data[,y]-slope*data[,x], auto_cut_diag),
                  CutoffCalling(data[,y]-slope*data[,x], auto_cut_diag))

  ## Decide the colored groups
  avail_groups = c("topleft", "topright", "bottomleft", "bottomright",
                   "midleft", "topcenter", "midright", "bottomcenter", "midcenter",
                   "top", "mid", "bottom", "left", "center", "right", "none")
  ## Select the colors
  mycolour = c("#1f78b4", "#fb8072", "#33a02c", "#ff7f00",
               "#bc80bd", "#66c2a5", "#6a3d9a", "#fdb462", "#ffed6f",
               "#e78ac3", "#fdb462", "#8da0cb", "#66c2a5", "#fccde5", "#fc8d62", "#d9d9d9")
  names(mycolour) = avail_groups

  if(model == "ninesquare") groups = c("midleft", "topcenter", "midright", "bottomcenter")
  if(model == "volcano") groups = c("topleft", "topright")
  if(model == "rank") groups = c("left", "right")
  groups = intersect(groups, avail_groups)

  ## Annotate the groups in the data frame
  if(length(x_cut)>0){
    idx1 = data[,x] < min(x_cut)
    idx2 = data[,x] > max(x_cut)
  }else{
    idx1 = NA
    idx2 = NA
  }
  if(length(y_cut)>0){
    idx3 = data[,y] < min(y_cut)
    idx4 = data[,y] > max(y_cut)
  }else{
    idx3 = NA
    idx4 = NA
  }
  if(length(intercept)>0){
    idx5 = data[,y]<slope*data[,x]+min(intercept)
    idx6 = data[,y]>slope*data[,x]+max(intercept)
  }else{
    idx5 = NA; idx6 = NA
  }
  data$group="none"
  for(gr in groups){
    if(gr=="topleft") idx = cbind(idx1, idx4, idx6)
    if(gr=="topcenter") idx = cbind(!idx1, !idx2, idx4, idx6)
    if(gr=="topright") idx = cbind(idx2, idx4, idx6)
    if(gr=="midleft") idx = cbind(idx1, idx6 , !idx3, !idx4)
    if(gr=="midcenter") idx = cbind(!idx1, !idx2, !idx3, !idx4, !idx5, !idx6)
    if(gr=="midright") idx = cbind(idx2, !idx3, !idx4, idx5)
    if(gr=="bottomleft") idx = cbind(idx1, idx3, idx5)
    if(gr=="bottomcenter") idx = cbind(!idx1, !idx2, idx3, idx5)
    if(gr=="bottomright") idx = cbind(idx2, idx3, idx5)
    if(gr=="top"){
      if(length(y_cut)>0 & length(intercept)>0)
         idx = idx4 & idx6
      else if(length(y_cut)>0)
        idx = idx4
      else idx = idx6
    }
    if(gr=="mid") idx = (!idx3) & (!idx4)
    if(gr=="bottom"){
      if(length(y_cut)>0 & length(intercept)>0)
        idx = idx3 & idx5
      else if(length(y_cut)>0)
        idx = idx3
      else idx = idx5
    }
    if(gr=="left"){
      if(length(x_cut)>0 & length(intercept)>0)
        if(slope>0) idx = idx1 & idx6 else idx = idx1 & idx5
      else if(length(x_cut)>0)
        idx = idx1
      else
        if(slope>0) idx = idx6 else idx = idx5
    }
    if(gr=="center") idx = (!idx1) & (!idx2)
    if(gr=="right"){
      if(length(x_cut)>0 & length(intercept)>0)
        if(slope>0) idx = idx2 & idx5 else idx = idx2 & idx6
        else if(length(x_cut)>0)
          idx = idx2
        else
          if(slope>0) idx = idx5 else idx = idx6
    }
    ## Assign groups
    if(is.null(ncol(idx))){
      if(sum(!is.na(idx))>0) data$group[idx] = gr
      else warning("No cutpoint for group:", gr)
    }else{
      idx = idx[, !is.na(idx[1,])]
      if(is.null(ncol(idx)))
        warning("No cutpoint for group:", gr)
      else if(ncol(idx)<4 & gr=="midcenter")
        warning("No cutpoint for group:", gr)
      else
        data$group[rowSums(idx)==ncol(idx)] = gr
    }
  }
  data$group=factor(data$group, levels = unique(c(groups, "none")))
  ## Group names
  if(length(groupnames)!=length(groups)) groupnames = groups
  if(length(groups)>0) names(groupnames) = groups
  if(length(group_col)==length(groups)) mycolour[groups] = group_col
  if(length(groups)==0) mycolour["none"] = "#FF6F61"

  ## Label top gene names ##
  data$rank = top + 1
  for(g in groups){
    idx1 = data$group==g
    x_symb = 0; y_symb = 0;
    if(g=="topleft"){ x_symb = 1; y_symb = -1 }
    if(g=="topcenter"){ x_symb = 0; y_symb = -1 }
    if(g=="topright"){ x_symb = -1; y_symb = -1 }
    if(g=="midleft"){ x_symb = 1; y_symb = 0 }
    if(g=="midright"){ x_symb = -1; y_symb = 0 }
    if(g=="bottomleft"){ x_symb = 1; y_symb = 1 }
    if(g=="bottomcenter"){ x_symb = 0; y_symb = 1 }
    if(g=="bottomright"){ x_symb = -1; y_symb = 1 }
    if(g=="top"){ x_symb = 0; y_symb = -1 }
    if(g=="bottom"){ x_symb = 0; y_symb = 1 }
    if(g=="left"){ x_symb = 1; y_symb = 0 }
    if(g=="right"){ x_symb = -1; y_symb = 0 }
    tmp = data[,c(x,y)]
    tmp[,x] = (tmp[,x]-min(tmp[,x])) / (max(tmp[,x])-min(tmp[,x]))
    tmp[,y] = (tmp[,y]-min(tmp[,y])) / (max(tmp[,y])-min(tmp[,y]))
    data$rank[idx1] = rank((x_symb*tmp[,x]+y_symb*tmp[,y])[idx1])
  }
  data$rank[data$rank==0] = Inf
  if(mode(toplabels)=="list"){
    data$Label[data$rank>top & !(data$Label %in% unlist(toplabels))] = ""
    data$group = data$Label;
    if(length(toplabels)>0){
      tmp = stack(toplabels)
      tmp = tmp[!duplicated(tmp[,1]), ]
      rownames(tmp) = tmp[,1]
      data$group[data$group%in%tmp[,1]] = as.character(tmp[data$group[data$group%in%tmp[,1]], 2])
      data$group[!(data$group%in%tmp[,2]) & data$group!=""] = "Top hits"
    }
  }else{
    data$Label[data$rank>top & !(data$Label %in% toplabels)] = ""
  }

  ## Color issue
  if(is.null(color)){
    color = "group"
  }else if(length(color)==1){
    if(!color%in%colnames(data)){
      data$color = color
      color = "color"
    }
  }else{
    data$color = color[1]
    color = "color"
    warning("Only the first color is took.")
  }

  ## Plot the scatter figure ##
  gg = data

  ## Plot the figure
  gg = gg[order(gg[,color]), ]
  p = ggplot(gg, aes_string(x, y, label="Label", color = color))
  p = p + ggrepel::geom_label_repel(aes_string(x, y, label="Label", color = color),
                                    segment.color = "black",
                                    min.segment.length = 0,
                                    point.padding = 0.1,
                                    box.padding = 0.6,
                                    seed = 1027, #For reproduction.
                                    ...)
  if(all(c(shape,size)%in%colnames(gg)))
    p = p + geom_point(aes_string(shape = shape, size = size), alpha = alpha)
  else if(shape%in%colnames(gg))
    p = p + geom_point(aes_string(shape = shape), size = size, alpha = alpha)
  else if(size%in%colnames(gg))
    p = p + geom_point(aes_string(size = size), shape = shape, alpha = alpha)
  else
    p = p + geom_point(size = size, shape = shape, alpha = alpha)

  ## Customize colors
  if(color=="group"){
    if(mode(toplabels)!="list")
      p = p + scale_color_manual(values = mycolour[names(groupnames)], labels = groupnames)
    else
      p = p + scale_color_manual(values = c("#d9d9d9", "#fb8072", "#80b1d3", "#fdb462",
                                            "#bc80bd", "#b3de69", "#bebada", "#8dd3c7",
                                            "#ffffb3", "#fccde5", "#ccebc5", "#ffed6f"))
  }else{
    if(mode(gg[,color])=="numeric")
      p = p + scale_color_gradient2(low = "#377eb8", high = "#e41a1c", midpoint = 0)
    else if(!"try-error"%in%class(try(col2rgb(gg[1,color]),silent=TRUE))){
      mycolour = unique(gg[,color]); names(mycolour) = mycolour
      p = p + scale_color_manual(values = mycolour)
    }else{
      p = p + scale_color_brewer(type = "div")
    }
  }

  if(label.top)
    p = p
  if(display_cut){
    if(length(x_cut)>0)
      p = p + geom_vline(xintercept = x_cut,linetype = "dotted")
    if(length(y_cut)>0)
      p = p + geom_hline(yintercept = y_cut,linetype = "dotted")
    if(length(intercept)>0)
      p = p + geom_abline(slope=slope, intercept=intercept, linetype = "dotted")
  }
  p = p + labs(x=xlab, y = ylab, title = main, color = NULL)
  p = p + theme_bw(base_size = 14)
  p = p + theme(plot.title = element_text(hjust = 0.5))
  p = p + theme(legend.position = legend.position)

  return(p)
}


#' Quantile of normal distribution.
#'
#' Compute cutoff from a normal-distributed vector.
#'
#' @docType methods
#' @name CutoffCalling
#' @rdname CutoffCalling
#'
#' @param d A numeric vector.
#' @param scale Boolean or numeric, specifying how many standard deviation will be used as cutoff.
#'
#' @return A numeric value.
#' @export
#' @examples
#' CutoffCalling(rnorm(10000))

CutoffCalling=function(d, scale=2){
  param=1
  if(is.logical(scale) & scale){
    param = round(length(d) / 20000, digits = 1)
  }else if(is.numeric(scale)){param = scale}

  Control_mean=0
  sorted_beta=sort(abs(d))
  temp=quantile(sorted_beta,0.68)
  temp_2=qnorm(0.84)
  cutoff=round(temp/temp_2,digits = 3)
  names(cutoff)=NULL
  cutoff=cutoff*param
  return(cutoff)
}
