\docType{data}
\name{DATANAME}
\alias{DATANAME}
\title{ANZG Species Sensitivity Data}
\format{
An object of class \code{tbl_df} (inherits from \code{tbl}, \code{data.frame}) with XNRX rows and XNCX columns.
}
\usage{
DATANAME
}
\description{
ANZG Species Sensitivity Data provided by the Department of Agriculture Water and the Environment, Australia.

These data are licensed under CC BY 4.0 (summary of terms provided here:
{\url{https://creativecommons.org/licenses/by/4.0/legalcode/}}).

Additional information is available from the
Water Quality website at {\url{https://www.waterquality.gov.au/}}.
}

\details{
Additional information may be available from the primary source for each chemical:

\describe{
XX
}

The columns are as follows, noting that some information may not be available for all chemicals:

\describe{
COLDATA

Where toxicity measure is not a chronic NEC, EC10 or NOEC value, concentration has been converted using the appropriate default ratio, as follows: 10 from acute EC50/LC50 to chronic EC10; 5 from chronic EC50 to EC10; 2.5 from LOEC to EC10. Please see the primary reference material for more information.
}
}
\examples{
head(DATANAME)
}
\keyword{datasets}
