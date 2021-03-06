% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/bindist.R
\docType{class}
\name{bindist-class}
\alias{bindist-class}
\alias{bindist}
\alias{bindist-method}
\alias{$,bindist-method}
\alias{$<-,bindist-method}
\title{Class \code{"bindist"}}
\description{
An object of class \code{"bindist"} represents the relevant fixed-width
range of binding site from the feature and number of possible binding site
in each range.
}
\section{Objects from the Class}{
 Objects can be created by calls of the form
\code{new("bindist", counts="integer", mids="integer",
halfBinSize="integer", bindingType="character", featureType="character")}.
}

\seealso{
\link{preparePool}, \link{peakPermTest}
}
\keyword{classes}
