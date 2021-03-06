#apeShift functions
#' formatApe
#' Function to take the input of a GenBank .gb or Plasmid Editor .ape flat file and format into a data frame
#' Note that this function currently treats unknown upper and lower boundaries as known - e.g.,
#' a location specified as '<1..121' indicates that the feature starts before the first sequenced base, and continues
#' to base 121 (inclusive). However, this is treated as the feature consisting of bases 1-121.
#' Also does not currently support join(complement(), complement()) files, but DOES support
#' complement(join()) type files.
#'
#' @param apeContents
#'
#' @return
#' @export
#'
#' @examples
#'

formatApe <- function(apeContents){
  
  #Identify where the origin sequence starts
  #featureLoc     <- grep("^FEATURES",       apeContents)
  
  #Get location of all top-level fields
  #topFieldList  <- grep("^[^\\s]",          apeContents[1:(featureLoc - 1)], perl = TRUE)
  #subFieldList  <- grep("^[\\s]{1,3}[\\S]", apeContents[1:(featureLoc - 1)], perl = TRUE)
  #fullFieldList <- sort(c(topFieldList, subFieldList))
  
  #fieldTable <- data.frame(fieldName = character(length(fullFieldList)), fieldValue = character(length(fullFieldList)))
  #for(i in 1:length(fullFieldList)){
  #  matchTerm <- strsplit(apeContents[fullFieldList[i]], " ")[[1]][1]
  #  if(matchTerm != ""){
  #    fieldTable$fieldName[i] <- matchTerm
  #  }
  #  matchTerm <- stripWhiteSpace(matchTerm)
  #}
  
  #Get fields for the class, and assign their values
  locus      <- sub("\\s+",     "", gsub("LOCUS",      "", grep("^LOCUS",        apeContents, value = TRUE)))
  #name      <- strsplit(locus, "\\s{2,}", perl = TRUE)[[1]][2]
  definition <- sub("\\s+",     "", gsub("DEFINITION", "", grep("^DEFINITION",   apeContents, value = TRUE)))
  accession  <- sub("\\s+",     "", gsub("ACCESSION",  "", grep("^ACCESSION",    apeContents, value = TRUE)))
  version    <- sub("\\s+",     "", gsub("VERSION",    "", grep("^VERSION",      apeContents, value = TRUE)))
  source     <- sub("\\s+",     "", gsub("SOURCE",     "", grep("^SOURCE",       apeContents, value = TRUE)))
  organism   <- sub("\\s+",     "", gsub("ORGANISM",   "", grep("^\\s*ORGANISM", apeContents, value = TRUE)))
  #reference  <- sub("\\s+",     "", gsub("REFERENCE",  "", grep("^REFERENCE",    apeContents, value = TRUE)))
  #authors    <- sub("\\s+",     "", gsub("AUTHORS",    "", grep("^\\s*AUTHORS",  apeContents, value = TRUE)))
  #title      <- sub("\\s+",     "", gsub("TITLE",      "", grep("^\\s*TITLE",    apeContents, value = TRUE)))
  
  #Get the reference(s)
  #references <- grep()
  
  
  comments   <- gsub("\\s{2,}", "", gsub("COMMENT",    "", grep("^COMMENT",      apeContents, value = TRUE)))
  comments   <- comments[which(comments != "")]
  
  
  #featureIndexStart <- grep("^FEATURES", apeContents, value = FALSE)
  featureIndexStop  <- grep("^ORIGIN",   apeContents, value = FALSE)
  
  #Get the indices of each feature
  featureIndices  <- grep("^\\s+[a-zA-Z0-9_\\-\\']+\\s+[a-zA-Z\\>\\<]*\\({0,1}[0-9]+[\\.][\\.][\\>\\<]{0,1}[0-9]+[\\>\\<]{0,1}\\){0,1}", apeContents)
  featureIndices1 <- grep("^\\s+[a-zA-Z0-9_\\-\\']+\\s+complement", apeContents)
  featureIndices2 <- grep("^\\s+[a-zA-Z0-9_\\-\\']+\\s+join", apeContents)
  featureIndices  <- unique(sort(c(featureIndices, featureIndices1, featureIndices2)))
  
  #Get the sequence
  seqLines <- grep("[0-9]+", apeContents[featureIndexStop:length(apeContents)], value = TRUE, perl = TRUE)
  seqStart <- as.numeric(strsplit(gsub("\\s{2,}", "", seqLines[1]), " ")[[1]][1])
  seq <- gsub("\\s+",   "", seqLines)
  seq <- gsub("[0-9]+", "", seq)
  seq <- paste(seq, collapse = '')
  
  featList <- list()
  
  #Get all values associated with each feature
  for(i in 1:length(featureIndices)){
    curFeat <- strsplit(gsub("^\\s{2,}", "", apeContents[featureIndices[i]]), "\\s{2,}", perl = TRUE)
    attType <- curFeat[[1]][1]
    
    #Get the index/indices of the feature
    if(i < length(featureIndices)){
      indexStop <- featureIndices[i + 1] - 1
    } else {
      indexStop <- featureIndexStop - 1
    }
    
    featureString <- paste(apeContents[featureIndices[i]:(indexStop - 1)], collapse = "")
    indexString   <- strsplit(featureString, "\\/", fixed = FALSE)[[1]][1]
    indexString   <- gsub("^\\s*[0-9]+", "", indexString, perl = TRUE)
    indexString   <- gsub("[a-zA-Z_]*", "", indexString, perl = TRUE)
    indexString   <- gsub("\\'", "", indexString, perl = TRUE)
    indexString   <- gsub("\\s*", "", indexString, perl = TRUE)
    indexString   <- gsub("\\(", "", indexString,  perl = TRUE)
    indexString   <- gsub("\\)", "", indexString,  perl = TRUE)
    indexString   <- gsub("\\>", "", indexString,  perl = TRUE)
    indexString   <- gsub("\\<", "", indexString,  perl = TRUE)
    
    #If the indices of the feature are complicated by a join
    if(grepl("join\\(", curFeat, ignore.case = TRUE)){
      #If on the complement strand
      if(grepl("complement\\(", curFeat, ignore.case = TRUE)){
        orientation <- "complement"
        #Get the string containing the join info
        #joinString <- grep("complement\\([a-zA-Z0-9\\,\\.\\s\\>\\<]+\\)", perl = TRUE, ignore.case = TRUE, value = TRUE)
      } else {
        #String is in default orientation
        orientation <- "default"
        #Get the string containing the join info
        #joinString <- grep("join\\([0-9\\,\\.\\s\\>\\<]+\\)", joinS, perl = TRUE, ignore.case = TRUE, value = TRUE)
      }
      #Do a bunch of cleaning steps to get the start and end joining indices into a list
      #Remove "complement("
      #jS <- gsub("complement\\(", "", joinString)
      #Remove "join("
      #jS <- gsub("join", "", jS)
      #Remove any lone "("
      #jS <- gsub("\\(", "", jS)
      #Remove ending ")"
      #jS <- gsub("\\)", "", jS)
      #Get rid of newline characters
      #jS <- gsub("\\\n", "", jS)
      #Remove any ">" or "<" characters
      #jS <- gsub("\\>", "", jS, perl = TRUE)
      #jS <- gsub("\\<", "", jS, perl = TRUE)
      #Split into start and stop indices
      jS <- strsplit(indexString, split = ",", fixed = TRUE)
      jSStart <-  as.numeric(sapply(strsplit(unlist(jS), split = "\\.\\.", fixed = FALSE), "[", 1))
      jSEnd   <-  as.numeric(sapply(strsplit(unlist(jS), split = "\\.\\.", fixed = FALSE), "[", 2))
      
      seqFeat <- paste(substr(rep(seq, length(jSStart)), jSStart, jSEnd), collapse = "")
      
      #Input NAs for startIn and stopIn
      startIn <- NA
      stopIn  <- NA
      
    } else {
      if(grepl("complement", curFeat, ignore.case = TRUE)){
        orientation <- "complement"
        startIn <- as.numeric(                strsplit(gsub("complement\\(", "", gsub("\\<", "", gsub("\\>", "", indexString, perl = TRUE), perl = TRUE)), "\\.\\.", perl = TRUE)[[1]][1])
        stopIn  <- as.numeric(gsub("\\)", "", strsplit(gsub("complement\\(", "", gsub("\\<", "", gsub("\\>", "", indexString, perl = TRUE), perl = TRUE)), "\\.\\.", perl = TRUE)[[1]][2]))
        
      } else {
        orientation <- "default"
        startIn <- as.numeric(strsplit(gsub("\\<", "", gsub("\\>", "", indexString, perl = TRUE)), "\\.\\.", perl = TRUE)[[1]][1])
        stopIn  <- as.numeric(strsplit(gsub("\\<", "", gsub("\\>", "", indexString, perl = TRUE)), "\\.\\.", perl = TRUE)[[1]][2])
        #print(indexString)
        #print(startIn)
        #print(stopIn)
      }
      jSStart <- NA
      jSEnd   <- NA
      
      #Get the corresponding sequence
      seqFeat <- substr(seq, startIn, stopIn)
    }
    
    
    if(i < length(featureIndices)){
      featValues <- getFeatureValues(apeContents[featureIndices[i]:(featureIndices[i + 1] - 1)])
    } else {
      featValues <- getFeatureValues(apeContents[featureIndices[i]:(featureIndexStop - 1)])
    }

    featValues[1, 1] <- "feature_type"
    featValues$value[1] <- gsub("\"", "", attType)
    featValues[2, 1] <- "featStart"
    featValues$value[2] <- startIn
    featValues[3, 1] <- "featEnd"
    featValues$value[3] <- stopIn
    featValues[4, 1] <- "orientation"
    featValues$value[4] <- orientation
    featValues[5, 1] <- "joinStart"
    featValues$value[5] <- list(jSStart)
    featValues[6, 1] <- "joinStop"
    featValues$value[6] <- list(jSEnd)
    featValues[7, 1] <- "genomicContext"
    featValues$value[7] <- as.character(seqFeat)
    featValues[8, 1] <- "featureSequence"
    featValues$value[8] <- toupper((if(orientation == "complement"){reverseComplement(as.character(seqFeat))} else {as.character(seqFeat)}))
    featList[[i]] <- featValues
  }
  
  
  
  ape <- list(locus, definition, accession, version, source, organism, comments, featList, seqStart, seq)
  names(ape) <- list("LOCUS", "DEFINITION", "ACCESSION", "VERSION", "SOURCE", "ORGANISM", "COMMENT", "FEATURES", "seqStart", "ORIGIN")
  
  class(ape) <- "apePlasmid"
  
  return(ape)
}



getFeatures <- function(plasmid, qual = NULL, qualValue = NULL){
  if(!is.null(qual) || !is.null(qualValue)){
    plasRet <- list()
    
    if(!is.null(qual)) {
      plasRet <- plasmid$FEATURES[grepl(paste(qual, collapse = "|"), lapply(plasmid$FEATURES, "[[", 1))]
    }
    
    if(!is.null(qualValue)) {
      if(length(plasRet) > 0){
        
        plasQualVal <- plasmid$FEATURES[grepl(paste(qualValue, collapse = "|"), lapply(plasmid$FEATURES, "[[", 2))]
        plasRet <- append(plasRet, plasQualVal)
        
      } else {
        plasRet <- plasmid$FEATURES[grepl(paste(qualValue, collapse = "|"), lapply(plasmid$FEATURES, "[[", 2))]
        
      }
    }
    return(plasRet)
    
  } else {
    
    return(plasmid$FEATURES)
  }
}

#' getFeatureValues
#'
#' @param featureLines
#'
#' @return
#' @export
#'
#' @examples
#'

getFeatureValues <- function(featureLines){
  require(stringr)
  #Get all the lines that start a qualifier
  valueLines <- grep("/", featureLines, perl = TRUE)
  #Create a data frame to hold the qualifiers
  df <- data.frame(qualifier = character(length(valueLines) + 8), value = c(length(valueLines) + 8), stringsAsFactors = FALSE)
  #Write dynamic qualifiers after the mandatory first five qualifiers (feature_type, featStart, featEnd, orientation, join)
  row <- 9
  
  df$value <- NA
  
  #For each qualifier
  for(i in 1:length(valueLines)){
    #Get the name of the qualifier
    valName <- gsub("\\s+/", "", strsplit(featureLines[valueLines[i]], "=", fixed = TRUE)[[1]][1])
    
    #Determine if the qualifier spans multiple lines, and stitch the lines together if so
    if(stringr:::str_count(featureLines[valueLines[i]], "\"") >= 1){
      if(i < length(valueLines)){
        searchLines <- sapply(valueLines[i]:(valueLines[i + 1] - 1), function(x) featureLines[x])
        
      } else {
        searchLines <- sapply(valueLines[i]:length(featureLines), function(x) featureLines[x])
        
      }

      searchLine <- paste(searchLines, sep = "")
      #searchLine <- paste0(featureLines[valueLines[i]], featureLines[valueLines[i] + 1])
    } else {
      searchLine <- featureLines[i]
    }
    
    #Get the value for the qualifier
    valVal <- gsub("\\s+", " ", strsplit(searchLine, "=", fixed = TRUE)[[1]][2])
    valVal <- gsub("\"", "", valVal)
    
    #Put in data frame
    df[row, 1] <- valName
    df[row, 2] <- valVal
    #Advance the row counter
    row <- row + 1
  }
  
  return(df)
}



getExonLocus <- function(gene){
  #Get the features from the Gene
  geneF    <- getFeatures(gene)
  cdsFlag  <- FALSE
  mRNAFlag <- FALSE
  
  #Get all the exons
  exonList <- which(sapply(sapply(geneF, "[", 2), "[", 1) == "exon")
  
  #If there are no exons, use CDS
  if(length(exonList) < 1){
    exonList <- which(sapply(sapply(geneF, "[", 2), "[", 1) == "CDS")
    cdsFlag  <- TRUE
  }
  
  #If there are no CDS, use mRNA
  #If there are no exons, use CDS
  if(length(exonList) < 1){
    exonList <- which(sapply(sapply(geneF, "[", 2), "[", 1) == "mRNA")
    mRNAFlag <- FALSE
  }
  
  if(length(exonList) < 1){
    return("Error: No exons, CDS, or mRNA")
    
  } else {
    geneExons <- list()
    
    if(cdsFlag){
     
       for(p in 1:length(exonList)){
         curBit <- geneF[exonList[p]][[1]]
         if(is.na(curBit[2, 2]) && is.na(curBit[3, 2])){
           joinS  <- curBit[5, 2]
           joinE  <- curBit[6, 2]
           
           for(q in 1:length(joinS[[1]])){
             subGene <- curBit
             subGene[2, 2] <- joinS[[1]][q]
             subGene[3, 2] <- joinE[[1]][q]
             tFrame <- data.frame(qualifier = "number", value = q)
             subGene <- rbind(subGene, tFrame)
             geneExons <- rlist:::list.append(geneExons, subGene)
           }
         } else {
           geneExons <- geneF[exonList]
         }
         
         
       }
      
    } else {
      geneExons <- geneF[exonList]
    }

    #Determine if exons are numbered
    numberedLength <- "number" %in% sapply(geneExons, "[[", 1)
    
    exonTable <- data.frame(start            = numeric(length(geneExons)), 
                            stop             = numeric(length(geneExons)),
                            length           = numeric(length(geneExons)),
                            type             = character(length(geneExons)),
                            orientation      = character(length(geneExons)),
                            Exon_Num         = numeric(length(geneExons)),
                            stringsAsFactors = FALSE)
      
    if(numberedLength){
      for(i in 1:length(geneExons)){
        exonTable[i, 1] <- as.numeric(geneExons[[i]][2, 2])
        exonTable[i, 2] <- as.numeric(geneExons[[i]][3, 2])
        exonTable[i, 3] <- as.numeric(geneExons[[i]][3, 2]) - as.numeric(geneExons[[i]][2, 2])
        exonTable[i, 4] <- geneExons[[i]][1, 2]
        exonTable[i, 5] <- geneExons[[i]][4, 2]
        exonTable[i, 6] <- geneExons[[i]][which(geneExons[[i]]$qualifier == "number"),2]
      }
      
    } else {
      for(i in 1:length(geneExons)){
        exonTable[i, 1] <- as.numeric(geneExons[[i]][2, 2])
        exonTable[i, 2] <- as.numeric(geneExons[[i]][3, 2])
        exonTable[i, 3] <- as.numeric(geneExons[[i]][3, 2]) - as.numeric(geneExons[[i]][2, 2])
        exonTable[i, 4] <- geneExons[[i]][1, 2]
        exonTable[i, 5] <- geneExons[[i]][4, 2]
        exonTable[i, 6] <- i
      }
    }
    
    return(exonTable)
  }
}

apeShift <- function(plasmid1, oligos){
  plasmid <- plasmid1
  #Get the oligos that will eventually be inserted into the plasmid
  oligo5F <-  gsub("[acgt]", "", oligos[1])
  oligo5R <-  gsub("[acgt]", "", oligos[2])
  oligo3F <-  gsub("[acgt]", "", oligos[3])
  oligo3R <-  gsub("[acgt]", "", oligos[4])
  
  #Find where the overhangs in the plasmid are
  uniGuideSites <- findUniGuideSites(plasmid$FEATURES)
  
  #Get the index values of all the locations of the overhangs
  fiveS  <- as.numeric(plasmid$FEATURES[[uniGuideSites[1]]][3, 2]) + 1
  fiveE  <- as.numeric(plasmid$FEATURES[[uniGuideSites[2]]][2, 2]) - 1
  threeS <- as.numeric(plasmid$FEATURES[[uniGuideSites[3]]][3, 2]) + 1
  threeE <- as.numeric(plasmid$FEATURES[[uniGuideSites[4]]][2, 2]) - 1
  
  #Find and adjust features that are downstream of the whole thing, which will need to be re-indexed
  downstreamF    <- which(as.numeric(sapply(sapply(plasmid$FEATURES, '[[', 2), '[[', 2)) > fiveE)
  downstreamBoth <- which(as.numeric(sapply(sapply(plasmid$FEATURES, '[[', 2), '[[', 2)) > threeE)
  
  #Find features that overlap with deleted sections, which will need to be removed
  delete5 <- union(intersect(which(as.numeric(sapply(sapply(plasmid$FEATURES, '[[', 2), '[[', 2)) >= fiveS), 
                             which(as.numeric(sapply(sapply(plasmid$FEATURES, '[[', 2), '[[', 2)) <= fiveE)), 
                   intersect(which(as.numeric(sapply(sapply(plasmid$FEATURES, '[[', 2), '[[', 3)) >= fiveS), 
                             which(as.numeric(sapply(sapply(plasmid$FEATURES, '[[', 2), '[[', 3)) <= fiveE)))
  
  delete3 <- union(intersect(which(as.numeric(sapply(sapply(plasmid$FEATURES, '[[', 2), '[[', 2)) >= threeS), 
                             which(as.numeric(sapply(sapply(plasmid$FEATURES, '[[', 2), '[[', 2)) <= threeE)), 
                   intersect(which(as.numeric(sapply(sapply(plasmid$FEATURES, '[[', 2), '[[', 3)) >= threeS), 
                             which(as.numeric(sapply(sapply(plasmid$FEATURES, '[[', 2), '[[', 3)) <= threeE)))
  
  #Shift the start and stop indices for downstream features
  for(i in downstreamF){
    plasmid$FEATURES[[i]][[2]][[2]] <- as.numeric(plasmid$FEATURES[[i]][[2]][[2]]) - (fiveE - fiveS + 1) + nchar(oligo5F)
    plasmid$FEATURES[[i]][[2]][[3]] <- as.numeric(plasmid$FEATURES[[i]][[2]][[3]]) - (fiveE - fiveS + 1) + nchar(oligo5F)
  }
  
  for(j in downstreamBoth){
    plasmid$FEATURES[[j]][[2]][[2]] <- as.numeric(plasmid$FEATURES[[j]][[2]][[2]]) - ((threeE - threeS + 1)) + nchar(oligo3F)
    plasmid$FEATURES[[j]][[2]][[3]] <- as.numeric(plasmid$FEATURES[[j]][[2]][[3]]) - ((threeE - threeS + 1)) + nchar(oligo3F)
  }
  
  #Remove to-be deleted sequence from origin and replace with oligos
  stringi::stri_sub(plasmid$ORIGIN, fiveS, fiveE)                                                                                 <- oligo5F
  stringi::stri_sub(plasmid$ORIGIN, threeS - (fiveE - fiveS) + nchar(oligo5F) - 1, threeE - (fiveE - fiveS) + nchar(oligo5F) - 1) <- oligo3F
  
  #Remove features that need to be deleted
  plasmid$FEATURES[c(delete5, delete3)] <- NULL
  
  #Add oligo features
  fiveFQT  <- data.frame(qualifier = c("feature_type", 
                                       "featStart", 
                                       "featEnd", 
                                       "orientation", 
                                       "joinStart", 
                                       "joinStop", 
                                       "genomicContext", 
                                       "featureSequence", 
                                       "locus_tag", 
                                       "ApEinfo_fwdcolor", 
                                       "ApEinfo_revcolor", 
                                       "ApEinfo_graphicformat"), 
                         value     = c("misc_feature", 
                                       fiveS, 
                                       fiveS + nchar(oligo5F) - 1, 
                                       "default", 
                                       NA, 
                                       NA, 
                                       "", 
                                       oligo5F, 
                                       "5' forward GTagHD oligonucleotide insert", 
                                       "#ff0000", 
                                       "#ff0000", 
                                       "arrow_data {{0 1 2 0 0 -1} {} 0} width 5 offset 0"), 
                         stringsAsFactors = FALSE)  
  
  threeFQT <- data.frame(qualifier = c("feature_type", 
                                       "featStart", 
                                       "featEnd", 
                                       "orientation", 
                                       "joinStart", 
                                       "joinStop", 
                                       "genomicContext", 
                                       "featureSequence", 
                                       "locus_tag", 
                                       "ApEinfo_fwdcolor", 
                                       "ApEinfo_revcolor", 
                                       "ApEinfo_graphicformat"), 
                         value     = c("misc_feature", 
                                       threeS - (fiveE - fiveS) + nchar(oligo5F) - 1, 
                                       threeS - (fiveE - fiveS) + nchar(oligo5F) + nchar(oligo3F) - 2, 
                                       "default", 
                                       NA, 
                                       NA, 
                                       "", 
                                       oligo3F, 
                                       "3' forward GTagHD oligonucleotide insert", 
                                       "#ff0000", 
                                       "#ff0000", 
                                       "arrow_data {{0 1 2 0 0 -1} {} 0} width 5 offset 0"), 
                         stringsAsFactors = FALSE) 
  
  plasmid <- createNewFeature(plasmid, fiveFQT)
  plasmid <- createNewFeature(plasmid, threeFQT)
  
  return(plasmid)
}


writeApe <- function(plasmid, fileName){
  #Open file output
  sink(file = fileName, append = FALSE, type = "output")
  
  #Header items
  cat(  paste0("LOCUS       ", plasmid$LOCUS),      sep = "\n")
  cat(  paste0("DEFINITION  ", plasmid$DEFINITION), sep = "\n")
  cat(  paste0("ACCESSION   ", plasmid$ACCESSION),  sep = "\n")
  cat(  paste0("VERSION     ", plasmid$VERSION),    sep = "\n")
  cat(  paste0("SOURCE      ", plasmid$SOURCE),     sep = "\n")
  cat(  paste0("  ORGANISM  ", plasmid$ORGANISM),   sep = "\n")
  
  #Print comments
  for(i in 1:length(plasmid$COMMENT)){
    cat(paste0("COMMENT     ",         plasmid$COMMENT[i]), sep = "\n")
  }
  
  cat(  paste0("FEATURES             Location/Qualifiers"), sep = "\n")
  
  #Print features
  for(j in 1:length(plasmid$FEATURES)){
    #Print labels
    if(plasmid$FEATURES[[j]]$value[4] == "complement"){
      
      #if(is.na(plasmid$FEATURES[[j]]$value[5])){
      #For joins
      
      #} else {
      cat(paste0("     ", plasmid$FEATURES[[j]]$value[1],
                 paste(rep(" ", 16 - nchar(plasmid$FEATURES[[j]]$value[1])), collapse = ""),
                 "complement(",
                 plasmid$FEATURES[[j]]$value[2],
                 "..",
                 plasmid$FEATURES[[j]]$value[3],
                 ")"),
          sep = "\n")
      #}
      
      
      #} else if(is.na(plasmid$FEATURES[[j]]$value[5])){
      #for joins
    } else {
      cat(paste0("     ",
                 plasmid$FEATURES[[j]]$value[1],
                 paste(rep(" ", 16 - nchar(plasmid$FEATURES[[j]]$value[1])), collapse = ""),
                 plasmid$FEATURES[[j]]$value[2],
                 "..",
                 plasmid$FEATURES[[j]]$value[3]),
          sep = "\n")
    }
    
    #Print feature definitions and values
    if(nrow(plasmid$FEATURES[[j]]) >= 9){
      for(k in 9:nrow(plasmid$FEATURES[[j]])){
        cat(paste0("                     /",
                   plasmid$FEATURES[[j]]$qualifier[k],
                   "=\"",
                   plasmid$FEATURES[[j]]$value[k],
                   "\""),
            sep = "\n")
      }
    }
  }
  
  cat(paste0("ORIGIN"), sep = "\n")
  seq       <- plasmid$ORIGIN
  seqLength <- nchar(seq)
  
  #Print/format sequence
  for(i in 1:(ceiling(seqLength / 60))){
    v <- 1 + (60 * (i - 1))
    
    cat(paste0(paste(rep(" ", 9 - nchar(as.character(v))), collapse = ""),
               v,
               " ",
               substr(seq, start =  1 + (60 * (i - 1)), stop = 10 + (60 * (i - 1))),
               " ",
               substr(seq, start = 11 + (60 * (i - 1)), stop = 20 + (60 * (i - 1))),
               " ",
               substr(seq, start = 21 + (60 * (i - 1)), stop = 30 + (60 * (i - 1))),
               " ",
               substr(seq, start = 31 + (60 * (i - 1)), stop = 40 + (60 * (i - 1))),
               " ",
               substr(seq, start = 41 + (60 * (i - 1)), stop = 50 + (60 * (i - 1))),
               " ",
               substr(seq, start = 51 + (60 * (i - 1)), stop = 60 + (60 * (i - 1)))),
        sep = "\n")
  }
  
  cat("//", sep = "\n")
  
  sink()
}

createNewFeature <- function(plasmid, qualTable){
  if(all.equal(qualTable[1:4,1], unlist(list("feature_type", "featStart", "featEnd", "orientation")))){
    if((qualTable[4, 2] != "default") && (qualTable[4, 2] != "complement")){
      stop("Error: Orientation must be 'default' or 'complement'")
    } else if(!(as.numeric(qualTable[3, 2]) > as.numeric(qualTable[2, 2]))){
      stop("Error: 'featStart' and 'featEnd' must be numeric, and featStart must be less than featEnd.")
    } else {
      names(qualTable) <- c("qualifier", "value")
      len <- length(plasmid$FEATURES)
      plasmid$FEATURES[[len + 1]] <- qualTable
      return(plasmid)
    }
  } else {
    stop("Error: New plasmid features must be in table format and with row 1 = 'feature_type', 2 = 'featStart', 3 = 'featEnd', and 4 = 'orientation'")
  }
}

readApe <- function(inFile){
  
  #If the file exists, do stuff
  #if(validateFileExists(inFile)){
    #Read in the ape file
    apeContents <- readLines(inFile, warn = TRUE)
  #}
  
  return(formatApe(apeContents))
}


findUniGuideSites <- function(apeContents){
  UseMethod("findUniGuideSites", apeContents)
}

findUniGuideSites.list <- function(apeContents){
  featList <- apeContents
  sites    <- grep(              "BfuAI site 1 overhang", featList)
  sites    <- append(sites, grep("BfuAI site 2 overhang", featList))
  sites    <- append(sites, grep("BspQI site 1 overhang", featList))
  sites    <- append(sites, grep("BspQI site 2 overhang", featList))
  return(sites)
}

findUniGuideSites.apePlasmid <- function(apeContents){
  featList <- getFeatures(apeContents)
  sites    <- grep(              "BfuAI site 1 overhang", featList)
  sites    <- append(sites, grep("BfuAI site 2 overhang", featList))
  sites    <- append(sites, grep("BspQI site 1 overhang", featList))
  sites    <- append(sites, grep("BspQI site 2 overhang", featList))
  return(sites)
}

