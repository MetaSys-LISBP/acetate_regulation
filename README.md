# Kinetic modeling of glucose and acetate metabolisms in *Escherichia coli*

## Overview

These R scripts perform all analyses detailed in the following publication:

> Control and regulation of acetate overflow in *Escherichia coli*
> 
> Millard et al., 2021, eLife, doi: [10.7554/eLife.63661](https://doi.org/10.7554/eLife.63661)

All models are available in COPASI format in the directory `/model/cps/`, with the experimental data used for model calibration. The final kinetic model is also available in SBML format in the 
directory `/model/sbml/` and from the Biomodels database (http://www.ebi.ac.uk/biomodels/) under identifier MODEL2005050001.

Details on the calculations can be found in the [original publication](https://doi.org/10.7554/eLife.63661) and in the R scripts.

## Dependencies

Some R packages are required.

`RColorBrewer`, `stringr` and `gplots` can be installed
by running the following command in an R console:

```bash
install.packages(c("RColorBrewer", "gplots", "stringr"))
```

`CoRC` can be installed
using the following command:

```bash
install.packages("remotes")
library(remotes)
remotes::install_github("jpahle/CoRC")
library(CoRC)
CoRC::getCopasi()
```

Additional information on CoRC installation and usage are available from the CoRC repository (https://github.com/jpahle/CoRC) an in the associated publication (Föster et al., Bioinformatics, 2021, doi: [10.1093/bioinformatics/btab033](https://doi.org/10.1093/bioinformatics/btab033)).

## Usage

To run all analyses detailed in the publication and reproduce Figures 1, 3-6 and all Supplementary figures:

- go to the code directory, e.g.:

```bash
cd /home/usr/data/acetate_regulation/
```

- open an R session:

```bash
R
```

- run calculations, starting from model construction to regulation analyses:

```bash
source("1-Model_construction.R")
```

```bash
source("2-Model_validation.R")
```

```bash
source("3-Metabolic_control_analyses.R")
```

```bash
source("4-Regulation_analyses.R")
```

The code is open-source and available under GPLv3 license.

## How to cite
Millard P., Enjalbert B., Uttenweiler-Joseph S., Portais J.C., and Letisse F. Control and regulation of acetate overflow in *Escherichia coli*. eLife, 2021, doi: [10.7554/eLife.63661](https://doi.org/10.7554/eLife.63661)

## Authors
Pierre Millard

## Contact
:email: Pierre Millard, pierre.millard@insa-toulouse.fr
