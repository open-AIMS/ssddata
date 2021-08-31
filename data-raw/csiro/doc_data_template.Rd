\docType{data}
\name{csiro_data}
\alias{csiro_data}
\title{Species Sensitivity Data provided by CSIRO}
\format{
An object of class \code{tbl_df} (inherits from \code{tbl}, \code{data.frame}) with XNRX rows and XNCX columns.
}
\usage{
DATANAME
}
\description{
Species Sensitivity Data provided by the Commonwealth Scientific and Industrial Research Organisation of Australia.
}

\details{
Additional information may be available from the primary source for each chemical:

\describe{
XX
}

The columns are as follows, noting that not all information are available for all chemicals:

\describe{
COLDATA

Where toxicity measure is not a chronic NEC, EC10 or NOEC value, concentration has been converted using the appropriate default ratio, as follows: 10 from acute EC50/LC50 to chronic EC10; 5 from chronic EC50 to EC10; 2.5 from LOEC to EC10. Please see the primary reference material for more information.

All concentration data are ug/L unless otherwise stated.
}
}
\examples{
head(DATANAME)
}
\keyword{datasets}
