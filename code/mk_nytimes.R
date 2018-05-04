#' A theme I often use -- NYTimes variation
#'
#' @param ... parameters to pass to theme()
#'
#' @return None
#' @export
#' @import ggplot2

mk_nytimes <- function(...) {
    ## http://minimaxir.com/2015/02/ggplot-tutorial/
    ## paste0('https://timogrossenbacher.ch/2016/12/',
    ##        'beautiful-thematic-maps-with-ggplot2-only/')
    ## https://github.com/hrbrmstr/hrbrthemes/blob/master/R/theme-ipsum.r
    
    ## Colos — stick with the ggplot2() greys
    c_bg    <- "white"
    c_grid  <- "grey80"
    c_btext <- "grey5"
    c_mtext <- "grey30"
    
    # Begin construction of chart
    theme_bw(base_size = 12, base_family = "Arial Narrow") +
        
        # Region
        theme(panel.background = element_rect(fill = c_bg, color = c_bg),
              plot.background  = element_rect(fill = c_bg, color = c_bg),
              panel.border     = element_blank()) +
        
        # Grid
        theme(panel.grid.major = element_blank(),
              panel.grid.minor = element_blank()) +
        
        # Legend
        theme(legend.position = c(0, 1),
              legend.justification = c(0, 1),
              legend.key           = element_rect(fill = NA, color = NA),
              legend.background    = element_rect(fill = "transparent", color = NA),
              legend.text          = element_text(color = c_mtext)) +
        
        # Titles, labels, etc.
        theme(plot.title     = element_text(color = c_btext, vjust = 1.25,
                                            face = "bold", size = 18),
              axis.text      = element_text(size = 10, color = c_mtext),
              axis.title.x   = element_text(size = 12, color = c_mtext,
                                            hjust = 1),
              axis.title.y   = element_text(size = 12, color = c_mtext,
                                            hjust = 1)) +
        # Facets
        theme(strip.background = element_rect(fill = c_bg, color = c_btext),
              strip.text = element_text(size = 10, color = c_btext)) +
        
        # Plot margins
        theme(plot.margin = unit(c(0.35, 0.2, 0.3, 0.35), "cm")) +
        
        # Additionals
        theme(...)
}
