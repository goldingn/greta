# plot legend
library (DiagrammeR)
library (raster)

ns <- 0.3
# bespoke set of nodes for legend
# pad operation with some invisible nodes to get in the right position
nodes1 <- create_node_df(n = 6,
                         label = c("data",
                                   "variable",
                                   "distribution",
                                   "",
                                   "operation",
                                   ""),
                         type = "lower",
                         style = "filled",
                         fontcolor = greta_col('dark'),
                         fontname = 'Helvetica',
                         fontsize = 12,
                         fillcolor = c('white',
                                       greta_col('super_light'),
                                       greta_col('lighter'),
                                       'white',
                                       'lightgray',
                                       'white'),
                         color = c(greta_col('lighter'),
                                   greta_col('lighter'),
                                   greta_col('light'),
                                   'white',
                                   'lightgray',
                                   'white'),
                         penwidth = 2,
                         shape = c("square", "circle", "diamond", "circle", "circle", "circle"),
                         width = c(0.5, 0.6, 1, 0.01, 0.2, 0.01),
                         height = c(0.5, 0.6, 0.8, 0.01, 0.2, 0.01))

gr1 <- create_graph(nodes1)
gr1$global_attrs[1, 'value'] <- 'dot'
f_nodes <- tempfile(fileext = '.png')
export_graph(gr1, file_name = f_nodes,
             width = 1005,
             height = 249)

ns <- 0.01
nodes2 <- create_node_df(n = 4,
                         label = '',
                         type = "lower",
                         alpha = 0,
                         style = "filled",
                         fillcolor = rep('#ffffff00', 4),
                         color = rep('#ffffff00', 4),
                         shape = rep("circle", 4),
                         width = rep(ns, 4))

edges2 <- create_edge_df(from = c(1, 3),
                         to = c(2, 4),
                         label = c('deterministic', 'stochastic'),
                         color = rep('Gainsboro', 2),
                         fontname = 'Helvetica',
                         fontcolor = greta_col('dark'),
                         fontsize = 12,
                         penwidth = 3,
                         style = c('solid', 'dashed'))

gr2 <- create_graph(nodes2, edges2)
gr2$global_attrs[1, 'value'] <- 'dot'
f_edges <- tempfile(fileext = '.png')

export_graph(gr2, file_name = f_edges,
             width = 631,
             height = 249)

# combine the two panels into one

# load images
nodes <- brick(f_nodes)
edges <- brick(f_edges)

# drop 2 pixels on each side to deal with crappy rendering of graphs
nodes <- crop(nodes, extent(nodes) - 4)
edges <- crop(edges, extent(edges) - 4)

dim_pixels <- c(width = round(1005 + 631 + 1005/16),
                height = 249)

dim_inches <- dim_pixels / 10

# layout with a gap inbetween
mat <- matrix(rep(c(1, 2, 3), c(16, 1, 10)),
              nrow = 1)

png('plotlegend.png',
    width = dim_pixels['width'] * 2,
    height = dim_pixels['height'] * 2)

layout(mat)
raster::plotRGB(nodes, maxpixels = Inf)
plot.new()
raster::plotRGB(edges, maxpixels = Inf)

dev.off()


pdf('plotlegend.pdf',
    width = dim_inches['width'],
    height = dim_inches['height'])

layout(mat)
raster::plotRGB(nodes, maxpixels = Inf)
plot.new()
raster::plotRGB(edges, maxpixels = Inf)

dev.off()
