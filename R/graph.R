#' Plot an interactive dependency graph
#'
#' @param dep_info Output from analyze_internal_dependencies_multi()
#' @param include_disconnected If FALSE, exclude isolated nodes
#' @return A visNetwork HTML widget
#' @export
plot_interactive_dependency_graph <- function(dep_info, include_disconnected = TRUE) {
  dep_map <- dep_info$dependency_map
  env <- dep_info$env
  all_code_lines <- dep_info$all_code_lines
  function_file_map <- dep_info$function_file_map

  functions <- names(dep_map)
  all_called <- unique(unlist(dep_map))
  all_nodes <- unique(c(functions, all_called))

  # Enhanced nodes with tooltip
  node_list <- lapply(all_nodes, function(fname) {
    src_file <- function_file_map[[fname]]
    ns_label <- paste0(basename(src_file), "::", fname)
    if (exists(fname, envir = env)) {
      fn <- get(fname, envir = env)
      args <- tryCatch(deparse(args(fn)), error = function(e) "N/A")
      args <- gsub("^function", "", args[1])

      body_exprs <- as.list(body(fn))
      ret_expr <- NULL
      return_call <- Filter(
        function(x) is.call(x) && identical(x[[1]], as.name("return")),
        body_exprs
      )
      if (length(return_call) > 0) {
        ret_expr <- deparse(return_call[[1]][[2]])
      } else if (length(body_exprs) > 0) {
        ret_expr <- deparse(tail(body_exprs, 1)[[1]])
      }

      src_file <- function_file_map[[fname]]
      doc_line <- grep(
        paste0(fname, "\\s*<-\\s*function"),
        all_code_lines
      )[1] - 1
      doc <- if (!is.na(doc_line) &&
        doc_line > 0 &&
        grepl("^\\s*#'", all_code_lines[doc_line])) {
        sub("^\\s*#'\\s*", "", all_code_lines[doc_line])
      } else {
        ""
      }

      data.frame(
        id = fname,
        label = ns_label,
        shape = "box",
        color = "lightblue",
        title = paste0(
          "<b>Function:</b> ", fname, "<br>",
          "<b>Args:</b> ", htmlEscape(args), "<br>",
          "<b>Returns:</b> ",
          if (!is.null(ret_expr)) htmlEscape(ret_expr) else "?", "<br>",
          "<b>Source:</b> ", htmlEscape(src_file), "<br>",
          if (nzchar(doc)) {
            paste0("<b>Description:</b> ", htmlEscape(doc), "<br>")
          } else {
            ""
          }
        ),
        stringsAsFactors = FALSE
      )
    } else {
      data.frame(
        id = fname,
        label = ns_label,
        shape = "ellipse",
        color = "gray",
        title = paste0("<b>Function:</b> ", fname),
        stringsAsFactors = FALSE
      )
    }
  })

  nodes <- do.call(rbind, node_list)
  nodes <- nodes[!duplicated(nodes$id), ]

  edges <- do.call(rbind, lapply(names(dep_map), function(from) {
    to_list <- dep_map[[from]]
    if (length(to_list) == 0) {
      return(NULL)
    }
    data.frame(
      from = from,
      to = to_list,
      arrows = "to",
      width = 2,
      stringsAsFactors = FALSE
    )
  }))

  # Find center node (node with most total edges - incoming + outgoing)
  if (!is.null(edges) && nrow(edges) > 0) {
    edge_counts <- table(c(edges$from, edges$to))
    center_node <- names(edge_counts)[which.max(edge_counts)]

    # Create igraph object to calculate shortest paths
    g <- igraph::graph_from_data_frame(edges, directed = TRUE, vertices = nodes$id)

    # Calculate shortest path distances from center node to all other nodes
    distances <- igraph::distances(g, v = center_node, mode = "all")

    # Convert distances to a named vector for easy lookup
    dist_vector <- as.numeric(distances[1, ])
    names(dist_vector) <- colnames(distances)

    # Define color palette based on distance (hops from center)
    # Using very distinct colors for first 6 hops for maximum contrast
    color_palette <- c(
      "0" = "#8B0000", # Center node - Dark Red
      "1" = "#0000FF", # 1 hop away - Pure Blue
      "2" = "#008000", # 2 hops away - Pure Green
      "3" = "#FF8C00", # 3 hops away - Dark Orange
      "4" = "#9400D3", # 4 hops away - Violet
      "5" = "#FF1493", # 5 hops away - Deep Pink
      "6" = "#00CED1", # 6 hops away - Dark Turquoise
      "7" = "#FFD700", # 7 hops away - Gold
      "8" = "#32CD32", # 8 hops away - Lime Green
      "9" = "#FF4500", # 9 hops away - Orange Red
      "10" = "#8A2BE2", # 10 hops away - Blue Violet
      "11" = "#DC143C", # 11 hops away - Crimson
      "12" = "#00FFFF", # 12 hops away - Cyan
      "13" = "#ADFF2F", # 13 hops away - Green Yellow
      "14" = "#FF69B4", # 14 hops away - Hot Pink
      "15" = "#4169E1", # 15 hops away - Royal Blue
      "16" = "#228B22", # 16 hops away - Forest Green
      "17" = "#FF6347", # 17 hops away - Tomato
      "18" = "#9932CC", # 18 hops away - Dark Orchid
      "19" = "#FF0000", # 19 hops away - Pure Red
      "20" = "#00FF00", # 20 hops away - Pure Lime
      "Inf" = "#D3D3D3" # Unreachable nodes - Light Gray
    )

    # Set fixed position for center node and physics properties for others
    nodes$physics <- TRUE
    nodes$fixed <- FALSE
    nodes$x <- NA
    nodes$y <- NA

    # Assign colors based on distance from center
    nodes$distance <- sapply(nodes$id, function(id) {
      if (id == center_node) {
        return(0)
      }
      dist <- dist_vector[id]
      if (is.na(dist) || is.infinite(dist)) {
        return(Inf)
      }
      return(dist)
    })

    # Filter out disconnected nodes if requested
    if (!include_disconnected) {
      connected_nodes <- nodes$distance != Inf
      nodes <- nodes[connected_nodes, ]

      # Also filter edges to only include those between connected nodes
      if (!is.null(edges) && nrow(edges) > 0) {
        edges <- edges[edges$from %in% nodes$id & edges$to %in% nodes$id, ]
      }
    }

    # Apply colors based on distance
    nodes$color <- sapply(nodes$distance, function(d) {
      if (d == Inf) {
        return(color_palette["Inf"])
      }
      if (d <= length(color_palette) - 1) {
        return(color_palette[as.character(d)])
      }
      return("dimgray") # For distances > 20
    })

    # Define text colors for readability based on background color
    text_colors <- c(
      "#8B0000" = "white", # Dark Red - white text
      "#0000FF" = "white", # Pure Blue - white text
      "#008000" = "white", # Pure Green - white text
      "#FF8C00" = "black", # Dark Orange - black text
      "#9400D3" = "white", # Violet - white text
      "#FF1493" = "white", # Deep Pink - white text
      "#00CED1" = "black", # Dark Turquoise - black text
      "#FFD700" = "black", # Gold - black text
      "#32CD32" = "black", # Lime Green - black text
      "#FF4500" = "white", # Orange Red - white text
      "#8A2BE2" = "white", # Blue Violet - white text
      "#DC143C" = "white", # Crimson - white text
      "#00FFFF" = "black", # Cyan - black text
      "#ADFF2F" = "black", # Green Yellow - black text
      "#FF69B4" = "black", # Hot Pink - black text
      "#4169E1" = "white", # Royal Blue - white text
      "#228B22" = "white", # Forest Green - white text
      "#FF6347" = "black", # Tomato - black text
      "#9932CC" = "white", # Dark Orchid - white text
      "#FF0000" = "white", # Pure Red - white text
      "#00FF00" = "black", # Pure Lime - black text
      "#D3D3D3" = "black", # Light Gray - black text
      "dimgray" = "white" # Dim Gray - white text
    )

    # Apply text colors based on background color
    nodes$font.color <- sapply(nodes$color, function(color) {
      if (color %in% names(text_colors)) {
        return(text_colors[color])
      }
      return("black") # Default to black for unknown colors
    })

    # Fix center node at coordinates (0, 0)
    center_idx <- which(nodes$id == center_node)
    if (length(center_idx) > 0) {
      nodes$physics[center_idx] <- FALSE
      nodes$fixed[center_idx] <- TRUE
      nodes$x[center_idx] <- 0
      nodes$y[center_idx] <- 0
      # Make center node larger
      nodes$size <- 25
      nodes$size[center_idx] <- 35
    }

    # Add distance information to tooltip
    nodes$title <- sapply(seq_len(nrow(nodes)), function(i) {
      original_title <- nodes$title[i]
      distance_info <- if (nodes$distance[i] == 0) {
        "<b>Role:</b> Center Node (Most Connected)<br>"
      } else if (nodes$distance[i] == Inf) {
        "<b>Distance:</b> Unreachable from center<br>"
      } else {
        paste0("<b>Distance from center:</b> ", nodes$distance[i], " hops<br>")
      }
      paste0(distance_info, original_title)
    })
  }

  visNetwork(nodes, edges, width = "100%", height = "100vh") %>%
    visEdges(smooth = list(enabled = TRUE, type = "continuous")) %>%
    visNodes(font = list(
      size = 20,
      strokeWidth = 2, # Add text outline for better readability
      strokeColor = "black" # Black outline around text
    )) %>%
    visInteraction(navigationButtons = TRUE, dragNodes = TRUE) %>%
    visOptions(
      autoResize = TRUE,
      width = "100%",
      height = "100%"
    ) %>%
    visPhysics(
      solver = "forceAtlas2Based",
      forceAtlas2Based = list(
        gravitationalConstant = -15,
        centralGravity = 0.01,
        springLength = 200,
        springConstant = 0.02,
        damping = 0.95,
        avoidOverlap = 1
      ),
      stabilization = list(
        enabled = TRUE,
        iterations = 500,
        updateInterval = 50,
        onlyDynamicEdges = FALSE,
        fit = TRUE
      ),
      timestep = 0.35,
      adaptiveTimestep = TRUE
    ) %>%
    visEvents(
      stabilizationIterationsDone = "function () {
        this.setOptions({physics: false});
      }",
      dragStart = "function (params) {
        if (params.nodes.length > 0) {
        var id = params.nodes[0];
        var node = this.body.data.nodes.get(id);
        // Only allow dragging if node is not fixed
        if (!node.fixed) {
            this.body.data.nodes.update({id: id, fixed: {x: false, y: false}});
        }
        }
    }",
        dragEnd = "function (params) {
        if (params.nodes.length > 0) {
        var id = params.nodes[0];
        var node = this.body.data.nodes.get(id);
        // Only update position if node is not fixed
        if (!node.fixed) {
            this.body.data.nodes.update({id: id, fixed: {x: true, y: true}});
        }
        }
    }"
    )
}
