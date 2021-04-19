
# 3 dependencies:

library(colorspace)
library(rlang)
library(tclust)

#test example
test1 <- data.frame(continents=c(rep("Asia",5),rep("Europe",3),rep("Africa",4)),region=c(rep("East Asia",3),"South Asia","South Asia","Iberian","Iberian","East Europe","Soutern Africa","Southern Africa","East Africa","East Africa"),countries=c("Japan","Korea","China","India","Nepal","Spain","Portugal","Poland","Lesotho","Botswana","Ethiopia","Eritrea"))

#input is a dataframe with >=1 columns of factors that are nested, with the most
#inclusive in column 1 and the next in column 2 etc.
#not tested if you mess up and the factors aren't nested.. 
#e.g. if a level 3 factor is in a level 1 different from others in the same level 2 category.
#
#if you get errors with 'empty cluster has been detected' then try increasing
#initial_mult - the number of candidate points tried for each point the algorithm 
#returns.. I think this will opnly happen with really big sets of colors
# if you have problems with it, I'll think aagin!
# more likely to be a problem if you set use_kmeans to FALSE - then you use trimmed kmeans, which is a bit experimental
#
# return value is a list of 3 objects - 
# most useful is colors - a vector of RGB colors names
# also a list of 'HCL' objects - internal to the colorspace library, but useful
# if you are messing about with the output colors
# finally 'names'  - the names of the corresponding lowest-level colors
#
#names is in the input order
#
# colors_picked <- nested_factor_colors3(test1)
# swatchplot(colors_picked$colors)
# test1 <- cbind(test1,colors_picked)

nested_factor_colors3 <- function(factors,initial_mult=30,use_kmeans=T) { 
full_sample <- length(unique(factors[,ncol(factors)]))
initial_sample_size <- initial_mult*full_sample
#now HCL again, but more controlled
#first generate H, C
#for convenience, store as H, L, C in arrays
color_sample_Hue <- runif(initial_sample_size,min=1,max=359)
color_sample_Lumin <- sample(40:60,initial_sample_size,replace=T)
color_sample <- cbind(color_sample_Hue,color_sample_Lumin)
for (level in 1:ncol(factors)) {
	#this order for polarLUV constructor
	if (level == 1) { 
		nvals <- length(unique(factors[,level]))
		if (use_kmeans) { 
		level_centers <- kmeans(color_sample,centers=nvals) 
		} else {
			level_centers <- tkmeans(color_sample,alpha=0.1,k=nvals)
			level_centers$centers <- t(level_centers$centers)
		}
		#level_centers <- kmeans(color_sample,centers=nvals)
		rownames(level_centers$centers) <- unique(factors[,level])
		
	} else {
		higher_level <- length(level_centers$size)
		#this can be in a different order to unique(factors,1)
		vals_per_factor <- rowSums(table(factors[,c(level-1,level)]) > 0)
		vals_per_factor <-  vals_per_factor[match(unique(factors[,level-1]),names(vals_per_factor))]
		max_cluster_so_far = 0
		level_centers2 <- c()
		color_sample_2 <- c()
		for (i in 1:higher_level) { 
			t <- table(factors[,c(level-1,level)])
			t <- t[match(unique(factors[,level-1]),rownames(t)),]
			names_here <- names(which(t[i,] > 0))
			color_sample_bit <- color_sample[level_centers$cluster == i,]
			if (use_kmeans) { 
				level_centers_here <- 
				kmeans(color_sample_bit,centers=vals_per_factor[i]) 
			} else {
				level_centers_here <- 
				tkmeans(color_sample_bit,alpha=0.1,k=vals_per_factor[i])
			#i <0 
			#annoyingly, tkmeans has the centers array the other way around #GRRRR - R!
				level_centers_here$centers <- t(level_centers_here$centers)
			}
			rownames(level_centers_here$centers) <- names_here
			names(level_centers_here$size) <- names_here
			level_centers2$cluster = c(level_centers2$cluster , level_centers_here$cluster + max_cluster_so_far)
			level_centers2$centers = rbind(level_centers2$centers,level_centers_here$centers)
			level_centers2$size = c(level_centers2$size,level_centers_here$size)
			max_cluster_so_far = max(level_centers2$cluster)
			color_sample_2 <- rbind(color_sample_2,color_sample_bit)
		}
		level_centers <- level_centers2
		color_sample <- color_sample_2
	}
}

	color_sample_Chroma <- apply(level_centers$centers,1,function(x) max_chroma(x[1],x[2])-5)
	colors <- cbind(level_centers$centers,color_sample_Chroma)
	#for convenience, store as H, L, C in arrays
	HCL_colors <- 
	polarLUV(H=colors[,1],C=colors[,3],L=colors[,2])
	r <- list()
	r$HCLobj <- HCL_colors
	r$colors <- hex(HCL_colors)
	r$names <- rownames(level_centers$centers)
	input_order <- match(factors[,ncol(factors)],r$names)
	r$names <- r$names[input_order]
	r$colors <- r$colors[input_order]
	r$HCLobj <- r$HCLobj[input_order]
	r
}
