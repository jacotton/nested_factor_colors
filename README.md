## nested_factor_colors

### auto-generate nice-ish colors for nested factors

I often want to make nice colors for factors automatically in R, and do so for arbitrary numbers of factors. Recently I needed to make colors for nested factors, such that factors share similar colots if they share membership of higher-level groups.

Works by generating a set of candidate colors, using random hues in HCL colorspace, then using k-means or trimmed k-means iteratively to find centroids for each level, moving up the factor levels. 

Very much inspired by [iwanthue](https://medialab.github.io/iwanthue/)


The R file contains an example input (test1). you should be able to:
source("nested_factor_colors.R")
colors_picked <- nested_factor_colors3(test1)
swatchplot(colors_picked$colors)
test1 <- cbind(test1,colors_picked)

**nested_factor_colors3(factors,initial_mult=30,use_kmeans=T)**

#### Parameters

- factors: is a dataframe with >=1 columns of factors that are nested, with the most incluisve in column 1 and the next in column 2 etc.
- initial_mult: the number of candidate colors picked initially for each lowest-level factor level.
- use_kmeans: use simple kmeans if TRUE, otherwise use trimmed kmeans, trimming 10%

### return value

a list of 3 objects:
- colors: a vector of RGB colors names for the lowest-level factors. This is probably what you want
- HCLobj: a vector of 'HCL' objects - internal to the colorspace library, but useful if you are messing about with the output colors
- names: the names of the corresponding lowest-level colors, in the input order


#### Caveats
- not tested if you mess up and the factors aren't nested.. 
- if you get errors with 'empty cluster has been detected' then try increasing
initial_mult - the number of candidate points tried for each point the algorithm  returns.. I think this will only happen with really big sets of colors and with use_kmeans=FALSE

jamescotton.email@gmail.com

