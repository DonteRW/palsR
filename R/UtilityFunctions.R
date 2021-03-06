# UtilityFuntions.R
#
# Utility functions for PALS R package
#
# Gab Abramowitz UNSW 2014 (palshelp at gmail dot com)
#

# Function for crashing semi-gracefully:
CheckError = function(errtext,errcode='U1:'){
	if(errtext != 'ok'){
		# Additionally report command line call
		calltext = paste(commandArgs(),collapse=' ')
		alltext = paste(errtext,calltext)
		# If error, write to std error
		cat(alltext,' ^ \n',file=stderr()); stop(alltext,call. = FALSE)
	}
}
CheckIfAllFailed = function(outinfo){
	# Checks if all requested analyses failed (e.g. in which case don't run summary table function)
	allfail = TRUE
	for(a in 1:length(outinfo)){
		if(is.null(outinfo[[a]]$error)){
			allfail = FALSE
		}
	}
	return(allfail)
}
PrintAnalysisResult = function(output){
	# Just prints info about each analysis run from a Master Analysis Script
	for(i in 1: length(output[["files"]])){
		cat('Output ',i,':')
		cat('  type:',output[["files"]][[i]]$type,'\n')
		if(!is.null(output[["files"]][[i]]$error)){
			cat('  ERROR: ',output[["files"]][[i]]$error,'\n')
		}else{
			cat('  filename:',output[["files"]][[i]]$filename,'\n')
			cat('  bench error:',output[["files"]][[i]]$bencherror,'\n')
			cat('  first metric for model - ',output[["files"]][[i]]$metrics[[1]]$name,':',
				output[["files"]][[i]]$metrics[[1]]$model_value,'\n')
		}
	}
	
}

LegendText = function(data,plotobs=TRUE){
	# Returns text vector of legend names for a plot.
	# If no obs line in the plot (e.g. error plot), first index will be model, else obs
	# If for some reason a benchmark failed (e.g. missing variable), colours are adjusted to make them 
	# consistent across different plots 
	legendtext = c()
	if(plotobs){ # i.e. obs line will be part of the plot
		legendtext[1] = data$obs$name
	}
	legendtext = c(legendtext, data$model$name)
	if(data$bench$exist){
		legendtext = c(legendtext, data$bench[[ data$bench$index[1] ]]$name)
		if(data$bench$howmany == 2){
			legendtext = c(legendtext, data$bench[[ data$bench$index[2] ]]$name)
		}else if(data$bench$howmany == 3){
			legendtext = c(legendtext, data$bench[[ data$bench$index[2] ]]$name)
			legendtext = c(legendtext, data$bench[[ data$bench$index[3] ]]$name)
		}
	}
	return(legendtext)
}
FindRangeViolation = function(varin,varrange){
	offendingValue=0 # init
	for(i in 1:length(varin)){
		if(varin[i]<varrange[1] | varin[i]>varrange[2]){
			offendingValue = varin[i]
			return(offendingValue)
		}
	}
	return(offendingValue) 
}

CheckVersionCompatibility = function(filepath1,filepath2){
	# Given tow netcdf files produced by PALS, checks that
	# they're produced using the same dataset name and version.
	fid1=open.ncdf(filepath1,readunlim=FALSE) # open file 1
	fid2=open.ncdf(filepath2,readunlim=FALSE) # open file 2
	# Get PALS data set name and version for both files:
	DsetName1 = att.get.ncdf(fid1,varid=0,attname='PALS_dataset_name')
	DsetName2 = att.get.ncdf(fid2,varid=0,attname='PALS_dataset_name')
	DsetVer1 = att.get.ncdf(fid1,varid=0,attname='PALS_dataset_version')
	DsetVer2 = att.get.ncdf(fid2,varid=0,attname='PALS_dataset_version')
	if(tolower(DsetName1$value) != tolower(DsetName2$value)){
		#CheckError(paste('B3: Data set name in observed data',
		#	'file and benchmark file is different:',
		#	DsetName1$value,DsetName2$value))
	}
	if(tolower(DsetVer1$value) != tolower(DsetVer2$value)){
		#CheckError(paste('B3: Data set version in observed data',
		#	'file and benchmark file is different:',
		#	DsetVer1$value,DsetVer2$value))
	}
}
#
# Strips path from filename: 
stripFilename = function(fpath) {
	fsplit = strsplit(fpath,'/')
	fcharvec = as.character(fsplit[[1]])
	fname = fcharvec[length(fcharvec)]
	return(fname)
}
#
# Set raster output graphics file resolution:
getResolution = function(analysisType){
	if(analysisType=='default'){
    	iwidth=1100
    	iheight=800
    }else if(analysisType=='ObsAnalysis'){
    	iwidth=900
    	iheight=600
    }else if(analysisType=='QCplotsSpreadsheet'){
    	iwidth=900
    	iheight=600
    }else if(analysisType=='BenchAnalysis'){
    	iwidth=900
    	iheight=600
    }else{
    	CheckError('I2: Unknown analysis type requested in getResolution.')
    }
    ires = list(width=iwidth,height=iheight)
    return(ires)
}
#
# Set output file type:
setOutput = function(analysisType) {
	outtype = 'png'
	outfilename = paste(uuid(), outtype, sep='.')
	ires = getResolution('default')
#	if(analysisType=='QCplotsSpreadsheet'){
#		fsize = 24	
#	}else{
		fsize = ceiling(ires$width / 1500 * 24) # set font size
#	}
	# Set output file type, if not to screen:
	if (outtype == 'pdf' ) {
		pdf(file=outfilename, paper='a4r', width=11, height=8)
	}else if (outtype=='ps') {
		postscript(file=outfilename, paper='special', width=11, height=8)
	}else if (outtype == 'png') {
		png(file=outfilename, width=ires$width, height=ires$height, pointsize=fsize)
	}else if(outtype == 'jpg'){
		jpeg(file=outfilename, width=ires$width, height=ires$height, pointsize=fsize)
	}else{
		CheckError(paste('I1: Requested output format not recognised:',outtype))
	}
	return(outfilename);
}

# UUID generator:
uuid = function(uppercase=FALSE) {
	## Version 4 UUIDs have the form xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
	## where x is any hexadecimal digit and y is one of 8, 9, A, or B
	## e.g., f47ac10b-58cc-4372-a567-0e02b2c3d479
 
	hex_digits <- c(as.character(0:9), letters[1:6])
	hex_digits <- if (uppercase) toupper(hex_digits) else hex_digits
	 
	y_digits <- hex_digits[9:12]
	 
	paste(
	  paste0(sample(hex_digits, 8, replace=TRUE), collapse=''),
	  paste0(sample(hex_digits, 4, replace=TRUE), collapse=''),
	  paste0('4', paste0(sample(hex_digits, 3, replace=TRUE), collapse=''), collapse=''),
	  paste0(sample(y_digits,1), paste0(sample(hex_digits, 3, replace=TRUE), collapse=''), collapse=''),
	  paste0(sample(hex_digits, 12, replace=TRUE), collapse=''),
	  sep='-')
}
