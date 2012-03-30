getEnrichedPATH <- 
function(annotatedPeak, orgAnn, pathAnn, feature_id_type="ensembl_gene_id", maxP=0.01, minPATHterm=10, multiAdjMethod=NULL)
{	
	if (missing(annotatedPeak)){
		stop("Missing required argument annotatedPeak!")	
	}
	if (!grepl("^org\\...\\.eg\\.db",orgAnn)){
		message("No valid organism specific PATH gene mapping package as parameter orgAnn is passed in!")
		stop("Please refer http://www.bioconductor.org/packages/release/data/annotation/ for available org.xx.eg.db packages")
	}
	if(!.checkLoadedPackage(orgAnn,TRUE)){
		stop(paste("Need to load",orgAnn,"before using getEnrichedPATH. Try \n\"library(",orgAnn,")\""))
	}
	if (missing(pathAnn)){
		stop("Missing required argument pathAnn. \n
			 pathAnn is the database with annotation object that maps Entrez Gene to pathway identifies named as xxxxxEXTID2PATHID 
			 and pathway identifies to pathway names named as xxxxxPATHID2NAME.")
	}
	if(!.checkLoadedPackage(pathAnn,TRUE)){
		stop(paste("Need to load",pathAnn,"before using getEnrichedPATH. Try \n\"library(",pathAnn,")\""))
	}
	extid2path<- paste(gsub(".db$","",pathAnn),"EXTID2PATHID", sep="")
	path2name<- paste(gsub(".db$","",pathAnn),"PATHID2NAME", sep="")
	if(length(objects(paste("package",pathAnn,sep=":"),pattern=extid2path))!=1 & 
	   length(objects(paste("package",pathAnn,sep=":"),pattern=path2name))!=1 ){
		stop("argument pathAnn is not the annotation data with objects named as xxxxxEXTID2PATHID and/or xxxxxPATHID2NAME")
	}
	if (class(annotatedPeak) == "RangedData"){
		feature_ids = unique(annotatedPeak$feature)
	}else if (class(annotatedPeak)  ==  "character"){
		feature_ids = unique(annotatedPeak)
	}else{
		stop("annotatedPeak needs to be RangedData type with feature variable holding the feature id or a character vector holding the IDs of the features used to annotate the peaks!")
	}
	if (feature_id_type == "entrez_id"){
		entrezIDs <- feature_ids
	}else{
		entrezIDs <- convert2EntrezID(feature_ids, orgAnn, feature_id_type)
	}
	
	extid2path <- get(extid2path)
	mapped_genes <- mappedkeys(extid2path)
#get all the entrez_ids in the species
	mapped_genes <- mapped_genes[mapped_genes %in% mappedkeys(get(paste(gsub(".db","",orgAnn),"SYMBOL",sep="")))]
	totalN.genes=length(unique(mapped_genes))
	thisN.genes = length(unique(entrezIDs))
	xx <- as.list(extid2path[mapped_genes])
	all.PATH <- do.call(rbind, lapply(mapped_genes,function(x1)
									  {
									  temp = unlist(xx[names(xx) ==x1])
									  if (length(temp) >0)
									  {
									  temp1 =matrix(temp,ncol=1,byrow=TRUE)
									  cbind(temp1,rep(x1,dim(temp1)[1]))
									  }
									  }))
	this.PATH <- do.call(rbind, lapply(entrezIDs,function(x1)
									   {
									   temp = unlist(xx[names(xx) ==x1])
									   if (length(temp) >0)
									   {
									   temp1 =matrix(temp,ncol=1,byrow=TRUE)
									   cbind(temp1,rep(x1,dim(temp1)[1]))
									   }
									   }))
	
	colnames(all.PATH)<-c("path.id","EntrezID")
	colnames(this.PATH)<-c("path.id","EntrezID")
	
	path.all<-as.character(all.PATH[,"path.id"])
	path.this<-as.character(this.PATH[,"path.id"])
	
	total = length(path.all)
	this = length(path.this)
	
	all.count = getUniqueGOidCount(as.character(path.all[path.all!=""]))
	this.count = getUniqueGOidCount(as.character(path.this[path.this!=""]))
	
	selected = hyperGtest(all.count,this.count, total, this)
	
	selected = data.frame(selected)
	
	colnames(selected) = c("path.id", "count.InDataset", "count.InGenome", "pvalue", "totaltermInDataset", "totaltermInGenome")
	
	if (is.null(multiAdjMethod))
	{
		s = selected[as.numeric(as.character(selected[,4]))<maxP & as.numeric(as.character(selected[,3]))>=minPATHterm,]
	}
	else
	{
		procs = c(multiAdjMethod)
		res <- mt.rawp2adjp(as.numeric(as.character(selected[,4])), procs)
        adjp = unique(res$adjp)
		colnames(adjp)[1] = colnames(selected)[4]
		colnames(adjp)[2] = paste(multiAdjMethod, "adjusted.p.value", sep=".")
		selected[,4] = as.numeric(as.character(selected[,4]))
		bp1 = merge(selected, adjp, all.x=TRUE)
		
		s = bp1[as.numeric(as.character(bp1[,dim(bp1)[2]]))<maxP &  !is.na(bp1[,dim(bp1)[2]]) & as.numeric(as.character(bp1[,4]))>=minPATHterm,]
	}
	
	path.id <- gsub("[^0-9]","",as.character(s$path.id))
	species <- gsub("[0-9]","",as.character(s$path.id)[1])
	path2name <- get(path2name)
	pathterm <- mget(unique(path.id),path2name,ifnotfound=NA)
	pathterm <- do.call(rbind, lapply(pathterm,function(.ele){paste(.ele,collapse=";")}))
	if(is.null(dim(pathterm))){
		stop("No enriched pathway can be found.")
	}
	colnames(pathterm) = "PATH"
	rownames(pathterm) = paste(species,rownames(pathterm),sep="")
	
	selected1 = merge(s, pathterm, by.x="path.id", by.y="row.names")
	
	selected = merge(this.PATH, selected1)
	
	selected
}

.checkLoadedPackage<-function(package, character.only = FALSE){
	if(!character.only)
		package <- as.character(substitute(package))
	loaded <- paste("package", package, sep=":") %in% search()
	return(loaded)
}